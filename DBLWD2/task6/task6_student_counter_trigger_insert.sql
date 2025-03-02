CREATE OR REPLACE TRIGGER update_group_on_insert
AFTER INSERT ON STUDENTS
FOR EACH ROW
BEGIN
    IF NOT trigger_state.cascade_delete_students_is_active THEN
        UPDATE GROUPS
        SET C_VAL = C_VAL + 1
        WHERE ID = :NEW.GROUP_ID;
    END IF;
END;