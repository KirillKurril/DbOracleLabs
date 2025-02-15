CREATE TRIGGER check_group_name_unique
BEFORE INSERT ON "GROUPS"
FOR EACH ROW
DECLARE
    matches_number NUMBER;
BEGIN
    SELECT COUNT(*) INTO matches_number
        FROM "GROUPS"
        WHERE NAME = :NEW.NAME; 

    IF matches_number > 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Group with this name already exists.');
    END IF;    
END;
