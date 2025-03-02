CREATE OR REPLACE TRIGGER groups_logger
AFTER INSERT OR UPDATE OR DELETE ON GROUPS
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        INSERT INTO UNIFIED_AUDIT (
            ENTITY_TYPE, 
            ENTITY_ID, 
            ENTITY_NAME, 
            ACTION_TYPE, 
            С_VAL
        )
        VALUES (
            'GROUP', 
            :NEW.ID, 
            :NEW.NAME, 
            'INSERT', 
            :NEW.C_VAL
        );
    ELSIF UPDATING THEN
        INSERT INTO UNIFIED_AUDIT (
            ENTITY_TYPE, 
            ENTITY_ID, 
            ENTITY_NAME, 
            ACTION_TYPE, 
            С_VAL,
            OLD_ENTITY_NAME,
            OLD_C_VAL
        )
        VALUES (
            'GROUP', 
            :NEW.ID, 
            :NEW.NAME, 
            'UPDATE', 
            :NEW.C_VAL,
            :OLD.NAME,
            :OLD.C_VAL
        );
    ELSIF DELETING THEN
        INSERT INTO UNIFIED_AUDIT (
            ENTITY_TYPE, 
            ENTITY_ID, 
            ENTITY_NAME, 
            ACTION_TYPE, 
            С_VAL
        )
        VALUES (
            'GROUP', 
            :OLD.ID, 
            :OLD.NAME, 
            'DELETE', 
            :OLD.C_VAL
        );
    END IF;
END;