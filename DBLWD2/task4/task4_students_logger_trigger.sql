CREATE OR REPLACE TRIGGER students_logger
AFTER INSERT OR UPDATE OR DELETE ON STUDENTS
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        INSERT INTO UNIFIED_AUDIT (
            ENTITY_TYPE, 
            ENTITY_ID, 
            ENTITY_NAME, 
            ACTION_TYPE, 
            GROUP_ID
        )
        VALUES (
            'STUDENT', 
            :NEW.ID, 
            :NEW.NAME, 
            'INSERT', 
            :NEW.GROUP_ID
        );
    ELSIF UPDATING THEN
        INSERT INTO UNIFIED_AUDIT (
            ENTITY_TYPE, 
            ENTITY_ID, 
            ENTITY_NAME, 
            ACTION_TYPE, 
            GROUP_ID,
            OLD_ENTITY_NAME, 
            OLD_GROUP_ID
        )
        VALUES (
            'STUDENT', 
            :NEW.ID, 
            :NEW.NAME, 
            'UPDATE', 
            :NEW.GROUP_ID,
            :OLD.NAME, 
            :OLD.GROUP_ID
        );
    ELSIF DELETING THEN
        INSERT INTO UNIFIED_AUDIT (
            ENTITY_TYPE, 
            ENTITY_ID, 
            ENTITY_NAME, 
            ACTION_TYPE, 
            GROUP_ID
        )
        VALUES (
            'STUDENT', 
            :OLD.ID, 
            :OLD.NAME, 
            'DELETE', 
            :OLD.GROUP_ID
        );
    END IF;
END;