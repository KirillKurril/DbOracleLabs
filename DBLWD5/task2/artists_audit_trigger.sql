CREATE OR REPLACE TRIGGER artists_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON artists
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        INSERT INTO audit_artists (
            audit_id, operation_type, artist_id, 
            new_artist_name, new_country, new_formed_date
        ) VALUES (
            audit_seq.NEXTVAL, 'INSERT', :NEW.artist_id,
            :NEW.artist_name, :NEW.country, :NEW.formed_date
        );
    ELSIF UPDATING THEN
        INSERT INTO audit_artists (
            audit_id, operation_type, artist_id,
            old_artist_name, new_artist_name,
            old_country, new_country,
            old_formed_date, new_formed_date
        ) VALUES (
            audit_seq.NEXTVAL, 'UPDATE', :OLD.artist_id,
            :OLD.artist_name, :NEW.artist_name,
            :OLD.country, :NEW.country,
            :OLD.formed_date, :NEW.formed_date
        );
    ELSIF DELETING THEN
        INSERT INTO audit_artists (
            audit_id, operation_type, artist_id,
            old_artist_name, old_country, old_formed_date
        ) VALUES (
            audit_seq.NEXTVAL, 'DELETE', :OLD.artist_id,
            :OLD.artist_name, :OLD.country, :OLD.formed_date
        );
    END IF;
END;
/