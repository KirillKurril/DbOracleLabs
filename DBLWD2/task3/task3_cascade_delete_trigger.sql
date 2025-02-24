CREATE OR REPLACE TRIGGER cascade_delete_students
AFTER DELETE ON "GROUPS"
FOR EACH ROW
BEGIN
    DELETE FROM STUDENTS
    WHERE GROUP_ID = :OLD.ID;    
END;
