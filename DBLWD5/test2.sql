delete from albums;
delete from artists;
delete from tracks;
delete from audit_albums;
delete from audit_artists;
delete from audit_tracks;
delete from report_timestamps;

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

    INSERT INTO artists (artist_name, country, formed_date) 
    VALUES ('Test Rock Band', 'USASUS', DATE '2020-01-01');
    
    v_start_timestamp := SYSTIMESTAMP;

    INSERT INTO artists (artist_name, country, formed_date) 
    VALUES ('Test Rock Band', 'USA', DATE '2020-01-01')
    RETURNING artist_id INTO v_artist_id;
    
    delay(2);
    
    
    INSERT INTO albums (artist_id, album_name, release_date, total_tracks)
    VALUES (v_artist_id, 'First Album', DATE '2021-06-15', 10)
    RETURNING album_id INTO v_album_id;
    
    delay(2);
    
    INSERT INTO tracks (album_id, track_name, duration_seconds)
    VALUES (v_album_id, 'Hit Song 2', 250)
    RETURNING track_id INTO v_track2_id;
    
    DELETE FROM tracks WHERE track_id = v_track2_id;
    
    audit_rollback_pkg.rollback_changes(v_start_timestamp);
    
    DBMS_OUTPUT.PUT_LINE('Artists after rollback');
    FOR r IN (SELECT * FROM artists WHERE artist_id = v_artist_id) LOOP
        DBMS_OUTPUT.PUT_LINE('Artist: ' || r.artist_name || ', Country: ' || r.country);
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('Albums after rollback');
    FOR r IN (SELECT * FROM albums WHERE artist_id = v_artist_id) LOOP
        DBMS_OUTPUT.PUT_LINE('Album: ' || r.album_name || ', Tracks: ' || r.total_tracks);
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('Tracks after rollback');
    FOR r IN (SELECT * FROM tracks WHERE album_id = v_album_id) LOOP
        DBMS_OUTPUT.PUT_LINE('Track: ' || r.track_name || ', Duration: ' || r.duration_seconds);
    END LOOP;
END;
/

