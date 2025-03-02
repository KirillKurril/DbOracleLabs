CREATE OR REPLACE PROCEDURE ROLLBACK_IN_SECONDS(offset_seconds IN NUMBER) AS
    rollback_time TIMESTAMP;
BEGIN
    -- Отключение триггеров в начале процедуры
    EXECUTE IMMEDIATE 'ALTER TRIGGER C##ADMIN_USER.STUDENTS_LOGGER DISABLE';
    EXECUTE IMMEDIATE 'ALTER TRIGGER C##ADMIN_USER.GROUPS_LOGGER DISABLE';

    rollback_time := SYSTIMESTAMP - NUMTODSINTERVAL(offset_seconds, 'SECOND');

    DBMS_OUTPUT.PUT_LINE('Starting rollback for ' || offset_seconds || ' seconds. Target time: ' || rollback_time);

    FOR rec IN (
        SELECT * 
        FROM UNIFIED_AUDIT
        WHERE ACTION_DATE >= rollback_time
        ORDER BY ACTION_DATE DESC
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('Processing: ' || rec.ENTITY_TYPE || ' ID=' || rec.ENTITY_ID);
        DBMS_OUTPUT.PUT_LINE('Action=' || rec.ACTION_TYPE);
        DBMS_OUTPUT.PUT_LINE('Time=' || rec.ACTION_DATE);

        IF rec.ENTITY_TYPE = 'STUDENT' THEN
            IF rec.ACTION_TYPE = 'DELETE' THEN
                INSERT INTO STUDENTS (ID, NAME, GROUP_ID)
                VALUES (rec.ENTITY_ID, rec.ENTITY_NAME, rec.GROUP_ID);
                
                DBMS_OUTPUT.PUT_LINE('Restored student: ID=' || rec.ENTITY_ID);
                DBMS_OUTPUT.PUT_LINE('Name=' || rec.ENTITY_NAME);
                DBMS_OUTPUT.PUT_LINE('Group ID=' || rec.GROUP_ID);
            
            ELSIF rec.ACTION_TYPE = 'INSERT' THEN
                DELETE FROM STUDENTS
                WHERE ID = rec.ENTITY_ID;
                
                DBMS_OUTPUT.PUT_LINE('Removed student: ID=' || rec.ENTITY_ID);
            
            ELSIF rec.ACTION_TYPE = 'UPDATE' THEN
                UPDATE STUDENTS
                SET NAME = rec.OLD_ENTITY_NAME,
                    GROUP_ID = rec.OLD_GROUP_ID
                WHERE ID = rec.ENTITY_ID;
                
                DBMS_OUTPUT.PUT_LINE('Reverted student update: ID=' || rec.ENTITY_ID);
                DBMS_OUTPUT.PUT_LINE('Old Name=' || rec.OLD_ENTITY_NAME);
                DBMS_OUTPUT.PUT_LINE('Old Group ID=' || rec.OLD_GROUP_ID);
            END IF;
        
        ELSIF rec.ENTITY_TYPE = 'GROUP' THEN
            IF rec.ACTION_TYPE = 'DELETE' THEN
                INSERT INTO GROUPS (ID, NAME, C_VAL)
                VALUES (rec.ENTITY_ID, rec.ENTITY_NAME, rec.С_VAL);
                
                DBMS_OUTPUT.PUT_LINE('Restored group: ID=' || rec.ENTITY_ID);
                DBMS_OUTPUT.PUT_LINE('Name=' || rec.ENTITY_NAME);
                DBMS_OUTPUT.PUT_LINE('C_VAL=' || rec.С_VAL);
            
            ELSIF rec.ACTION_TYPE = 'INSERT' THEN
                DELETE FROM GROUPS
                WHERE ID = rec.ENTITY_ID;
                
                DBMS_OUTPUT.PUT_LINE('Removed group: ID=' || rec.ENTITY_ID);
            
            ELSIF rec.ACTION_TYPE = 'UPDATE' THEN
                UPDATE GROUPS
                SET NAME = rec.OLD_ENTITY_NAME,
                    C_VAL = rec.OLD_C_VAL
                WHERE ID = rec.ENTITY_ID;
                
                DBMS_OUTPUT.PUT_LINE('Reverted group update: ID=' || rec.ENTITY_ID);
                DBMS_OUTPUT.PUT_LINE('Old Name=' || rec.OLD_ENTITY_NAME);
                DBMS_OUTPUT.PUT_LINE('Old C_VAL=' || rec.OLD_C_VAL);
            END IF;
        END IF;

        DELETE FROM UNIFIED_AUDIT
        WHERE AUDIT_ID = rec.AUDIT_ID;
    END LOOP;

    EXECUTE IMMEDIATE 'ALTER TRIGGER C##ADMIN_USER.STUDENTS_LOGGER ENABLE';
    EXECUTE IMMEDIATE 'ALTER TRIGGER C##ADMIN_USER.GROUPS_LOGGER ENABLE';

    COMMIT;
END;