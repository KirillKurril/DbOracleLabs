CREATE OR REPLACE TRIGGER check_group_exists
BEFORE INSERT OR UPDATE ON STUDENTS
FOR EACH ROW
DECLARE
    v_group_exists NUMBER;
BEGIN
    IF :NEW.GROUP_ID IS NOT NULL THEN
        SELECT COUNT(*) INTO v_group_exists
        FROM GROUPS
        WHERE ID = :NEW.GROUP_ID;

        IF v_group_exists = 0 THEN
            RAISE_APPLICATION_ERROR(-20010, 
                'Group with ID ' || :NEW.GROUP_ID || ' doesnt exist');
        END IF;
    END IF;
END;