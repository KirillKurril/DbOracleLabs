CREATE OR REPLACE PROCEDURE ROLLBACK_IN_SECONDS(offset_seconds IN NUMBER) AS
    rollback_time TIMESTAMP;
BEGIN
    EXECUTE IMMEDIATE 'ALTER TRIGGER C##ADMIN_USER.STUDENTS_LOGGER DISABLE';
    EXECUTE IMMEDIATE 'ALTER TRIGGER C##ADMIN_USER.GROUPS_LOGGER DISABLE';

    rollback_time := SYSTIMESTAMP - NUMTODSINTERVAL(offset_seconds, 'SECOND');

    DBMS_OUTPUT.PUT_LINE('Starting rollback for ' || offset_seconds || ' seconds. Target time: ' || rollback_time);

    FOR rec IN (
        SELECT * 
        FROM GROUPS_AUDIT
        WHERE ACTION_DATE >= rollback_time
        ORDER BY ACTION_DATE DESC
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('Processing record: Action Type = ' || rec.ACTION_TYPE || ', Group ID = ' || rec.GROUP_ID);

        IF rec.ACTION_TYPE = 'DELETE' THEN
            INSERT INTO GROUPS (ID, NAME)
            VALUES (rec.GROUP_ID, rec.GROUP_NAME);
            DBMS_OUTPUT.PUT_LINE('Отмена действия над группой DELETE: Group ID = ' || rec.GROUP_ID || ', Name = ' || rec.GROUP_NAME);

        ELSIF rec.ACTION_TYPE = 'INSERT' THEN
            DELETE FROM GROUPS
            WHERE ID = rec.GROUP_ID;
            DBMS_OUTPUT.PUT_LINE('Отмена действия над группой INSERT: Deleted Group ID = ' || rec.GROUP_ID || ', Name = ' || rec.GROUP_NAME);

        ELSIF rec.ACTION_TYPE = 'UPDATE' THEN
            UPDATE GROUPS
            SET NAME = rec.OLD_GROUP_NAME
            WHERE ID = rec.GROUP_ID;
            DBMS_OUTPUT.PUT_LINE('Отмена действия над группой UPDATE: Group ID = ' || rec.GROUP_ID || ', Old Name = ' || rec.OLD_GROUP_NAME);
        END IF;

        DELETE FROM GROUPS_AUDIT
        WHERE AUDIT_ID = rec.AUDIT_ID;
        
        DBMS_OUTPUT.PUT_LINE('Deleted AUDIT_ID = ' || rec.AUDIT_ID || ' from audit table');
    END LOOP;



    FOR rec IN (
        SELECT * 
        FROM STUDENTS_AUDIT
        WHERE ACTION_DATE >= rollback_time
        ORDER BY ACTION_DATE DESC
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('Processing record: Action Type = ' || rec.ACTION_TYPE || ', Student ID = ' || rec.STUDENT_ID);

        IF rec.ACTION_TYPE = 'DELETE' THEN
            INSERT INTO STUDENTS (ID, NAME, GROUP_ID)
            VALUES (rec.STUDENT_ID, rec.STUDENT_NAME, rec.GROUP_ID);
            DBMS_OUTPUT.PUT_LINE('Отмена действия над студентом DELETE: Student ID = ' || rec.STUDENT_ID || ', Name = ' || rec.STUDENT_NAME || ', Group ID = ' || rec.GROUP_ID);

        ELSIF rec.ACTION_TYPE = 'INSERT' THEN
            DELETE FROM STUDENTS
            WHERE ID = rec.STUDENT_ID;
            DBMS_OUTPUT.PUT_LINE('Отмена действия над студентом INSERT: Deleted Student ID = ' || rec.STUDENT_ID || ', Name = ' || rec.STUDENT_NAME || ', Group ID = ' || rec.GROUP_ID);

        ELSIF rec.ACTION_TYPE = 'UPDATE' THEN
            UPDATE STUDENTS
            SET NAME = rec.OLD_STUDENT_NAME,
                GROUP_ID = rec.OLD_GROUP_ID
            WHERE ID = rec.STUDENT_ID;
            DBMS_OUTPUT.PUT_LINE('Отмена действия над студентом UPDATE: Student ID = ' || rec.STUDENT_ID || ', Old Name = ' || rec.OLD_STUDENT_NAME || ', Old Group ID = ' || rec.OLD_GROUP_ID);
        END IF;

        DELETE FROM STUDENTS_AUDIT
        WHERE AUDIT_ID = rec.AUDIT_ID;

        DBMS_OUTPUT.PUT_LINE('Deleted AUDIT_ID = ' || rec.AUDIT_ID || ' from audit table');
    END LOOP;

    EXECUTE IMMEDIATE 'ALTER TRIGGER C##ADMIN_USER.STUDENTS_LOGGER ENABLE';
    EXECUTE IMMEDIATE 'ALTER TRIGGER C##ADMIN_USER.GROUPS_LOGGER ENABLE';    

    COMMIT;
END;
