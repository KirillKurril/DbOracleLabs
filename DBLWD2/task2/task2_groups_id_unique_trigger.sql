CREATE TRIGGER check_group_id_unique
BEFORE INSERT ON "GROUPS"
FOR EACH ROW
DECLARE
    matches_number NUMBER;
BEGIN
    SELECT COUNT(*) INTO matches_number
        FROM "GROUPS"
        WHERE ID = :NEW.ID; 

    IF matches_number > 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Group with this id already exists.');
    END IF;    
END;
