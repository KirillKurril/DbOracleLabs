CREATE OR REPLACE TRIGGER update_group_on_delete
AFTER DELETE ON STUDENTS
FOR EACH ROW
BEGIN
    IF NOT trigger_state.cascade_delete_students_is_active THEN
        UPDATE GROUPS
        SET C_VAL = C_VAL - 1
        WHERE ID = :OLD.GROUP_ID;
    END IF;
END;
