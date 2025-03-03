CREATE OR REPLACE TRIGGER trg_audit_tracks
AFTER INSERT OR UPDATE OR DELETE ON tracks
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        INSERT INTO audit_tracks (
            audit_id, operation_type, track_id, 
            new_album_id, new_track_name, 
            new_duration_seconds
        ) VALUES (
            audit_seq.NEXTVAL, 'INSERT', :NEW.track_id,
            :NEW.album_id, :NEW.track_name, 
            :NEW.duration_seconds
        );
    ELSIF UPDATING THEN
        INSERT INTO audit_tracks (
            audit_id, operation_type, track_id,
            old_album_id, new_album_id,
            old_track_name, new_track_name,
            old_duration_seconds, new_duration_seconds
        ) VALUES (
            audit_seq.NEXTVAL, 'UPDATE', :OLD.track_id,
            :OLD.album_id, :NEW.album_id,
            :OLD.track_name, :NEW.track_name,
            :OLD.duration_seconds, :NEW.duration_seconds
        );
    ELSIF DELETING THEN
        INSERT INTO audit_tracks (
            audit_id, operation_type, track_id,
            old_album_id, old_track_name, 
            old_duration_seconds
        ) VALUES (
            audit_seq.NEXTVAL, 'DELETE', :OLD.track_id,
            :OLD.album_id, :OLD.track_name, 
            :OLD.duration_seconds
        );
    END IF;
END;
/