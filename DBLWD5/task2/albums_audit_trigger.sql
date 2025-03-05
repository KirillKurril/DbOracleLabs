CREATE OR REPLACE TRIGGER albums_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON albums
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        INSERT INTO audit_albums (
            audit_id, operation_type, album_id, 
            new_artist_id, new_album_name, 
            new_release_date, new_total_tracks
        ) VALUES (
            audit_seq.NEXTVAL, 'INSERT', :NEW.album_id,
            :NEW.artist_id, :NEW.album_name, 
            :NEW.release_date, :NEW.total_tracks
        );
        DBMS_OUTPUT.PUT_LINE('Album Insert: ID=' || :NEW.album_id || ', Name=' || :NEW.album_name);
    ELSIF UPDATING THEN
        INSERT INTO audit_albums (
            audit_id, operation_type, album_id,
            old_artist_id, new_artist_id,
            old_album_name, new_album_name,
            old_release_date, new_release_date,
            old_total_tracks, new_total_tracks
        ) VALUES (
            audit_seq.NEXTVAL, 'UPDATE', :OLD.album_id,
            :OLD.artist_id, :NEW.artist_id,
            :OLD.album_name, :NEW.album_name,
            :OLD.release_date, :NEW.release_date,
            :OLD.total_tracks, :NEW.total_tracks
        );
        DBMS_OUTPUT.PUT_LINE('Album Update: ID=' || :OLD.album_id || 
            ', Old Name=' || :OLD.album_name || 
            ', New Name=' || :NEW.album_name);
    ELSIF DELETING THEN
        INSERT INTO audit_albums (
            audit_id, operation_type, album_id,
            old_artist_id, old_album_name, 
            old_release_date, old_total_tracks
        ) VALUES (
            audit_seq.NEXTVAL, 'DELETE', :OLD.album_id,
            :OLD.artist_id, :OLD.album_name, 
            :OLD.release_date, :OLD.total_tracks
        );
        DBMS_OUTPUT.PUT_LINE('Album Delete: ID=' || :OLD.album_id || ', Name=' || :OLD.album_name);
    END IF;
END;
/