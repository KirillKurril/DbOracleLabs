-- Ensure DBMS_SESSION is available
BEGIN
    EXECUTE IMMEDIATE 'CREATE OR REPLACE PROCEDURE delay(p_seconds NUMBER) IS 
    BEGIN 
        DBMS_SESSION.SLEEP(p_seconds); 
    END;';
END;
/

SET SERVEROUTPUT ON;

DECLARE
    v_start_timestamp TIMESTAMP;
    v_artist_id NUMBER;
    v_album_id NUMBER;
    v_track1_id NUMBER;
    v_track2_id NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Inserting initial artist');
    INSERT INTO artists (artist_name, country, formed_date) 
    VALUES ('Test Rock Band', 'USA', DATE '2020-01-01')
    RETURNING artist_id INTO v_artist_id;
    
    v_start_timestamp := SYSTIMESTAMP;
    
    delay(2);
    
    DBMS_OUTPUT.PUT_LINE('Updating artist country');
    UPDATE artists SET country = 'Canada' WHERE artist_id = v_artist_id;
    
    delay(2);
    
    DBMS_OUTPUT.PUT_LINE('Inserting album');
    INSERT INTO albums (artist_id, album_name, release_date, total_tracks)
    VALUES (v_artist_id, 'First Album', DATE '2021-06-15', 10)
    RETURNING album_id INTO v_album_id;
    
    delay(2);
    
    DBMS_OUTPUT.PUT_LINE('Inserting tracks');
    INSERT INTO tracks (album_id, track_name, duration_seconds)
    VALUES (v_album_id, 'Hit Song 1', 240)
    RETURNING track_id INTO v_track1_id;
    
    INSERT INTO tracks (album_id, track_name, duration_seconds)
    VALUES (v_album_id, 'Hit Song 2', 250)
    RETURNING track_id INTO v_track2_id;
    
    delay(2);
    
    DBMS_OUTPUT.PUT_LINE('Updating track duration');
    UPDATE tracks SET duration_seconds = 260 WHERE track_id = v_track1_id;
    
    delay(2);
    
    DBMS_OUTPUT.PUT_LINE('Deleting a track');
    DELETE FROM tracks WHERE track_id = v_track2_id;
    
    DBMS_OUTPUT.PUT_LINE('Generating initial report');
    BEGIN
        audit_report_pkg.generate_dml_report(
            p_start_timestamp => v_start_timestamp,
            p_directory => 'REPORT_DIR',
            p_filename => 'initial_changes_report.html'
        );
    END;
    
    DBMS_OUTPUT.PUT_LINE('Performing rollback');
    BEGIN
        audit_rollback_pkg.rollback_changes(
            p_timestamp => v_start_timestamp + INTERVAL '1' SECOND
        );
    END;
    
    DBMS_OUTPUT.PUT_LINE('Generating rollback report');
    BEGIN
        audit_report_pkg.generate_dml_report(
            p_directory => 'REPORT_DIR', 
            p_filename => 'rollback_report.html'
        );
    END;
    
    DBMS_OUTPUT.PUT_LINE('Verifying artists after rollback');
    FOR r IN (SELECT * FROM artists WHERE artist_id = v_artist_id) LOOP
        DBMS_OUTPUT.PUT_LINE('Artist: ' || r.artist_name || ', Country: ' || r.country);
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('Verifying albums after rollback');
    FOR r IN (SELECT * FROM albums WHERE artist_id = v_artist_id) LOOP
        DBMS_OUTPUT.PUT_LINE('Album: ' || r.album_name || ', Tracks: ' || r.total_tracks);
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('Verifying tracks after rollback');
    FOR r IN (SELECT * FROM tracks WHERE album_id = v_album_id) LOOP
        DBMS_OUTPUT.PUT_LINE('Track: ' || r.track_name || ', Duration: ' || r.duration_seconds);
    END LOOP;
END;
/

-- Audit record queries
SELECT * FROM audit_artists WHERE artist_id = (SELECT MAX(artist_id) FROM artists) ORDER BY operation_timestamp;
SELECT * FROM audit_albums WHERE album_id = (SELECT MAX(album_id) FROM albums) ORDER BY operation_timestamp;
SELECT * FROM audit_tracks WHERE track_id IN (SELECT track_id FROM tracks WHERE album_id = (SELECT MAX(album_id) FROM albums)) ORDER BY operation_timestamp;