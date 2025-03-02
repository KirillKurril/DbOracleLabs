CREATE OR REPLACE TRIGGER cascade_delete_students
BEFORE DELETE ON "GROUPS"
FOR EACH ROW
BEGIN
    trigger_state.cascade_delete_students_is_active := TRUE;
    
    DELETE FROM STUDENTS
    WHERE GROUP_ID = :OLD.ID;    

    trigger_state.cascade_delete_students_is_active := FALSE;
END;
