CREATE TRIGGER check_student_id_unique
BEFORE INSERT ON STUDENTS
FOR EACH ROW
DECLARE
    matches_number NUMBER;
BEGIN
    SELECT COUNT(*) INTO matches_number
        FROM STUDENTS
        WHERE ID = :NEW.ID; 

    IF matches_number > 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Student ID already exists.');
    END IF;    
END;
