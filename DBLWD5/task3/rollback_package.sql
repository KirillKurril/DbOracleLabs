CREATE OR REPLACE PACKAGE audit_rollback_pkg AS
    PROCEDURE rollback_changes(
        p_timestamp IN TIMESTAMP
    );
    
    PROCEDURE rollback_changes(
        p_milliseconds IN NUMBER
    );
END audit_rollback_pkg;
/

CREATE OR REPLACE PACKAGE BODY audit_rollback_pkg AS

    TYPE audit_record IS RECORD (
        id NUMBER,
        operation_type VARCHAR2(10),
        operation_timestamp TIMESTAMP
    );

    TYPE audit_record_table IS TABLE OF audit_record;

    FUNCTION get_sorted_audit_records(
        p_target_timestamp IN TIMESTAMP
    ) RETURN SYS_REFCURSOR IS
        v_result SYS_REFCURSOR;
    BEGIN
        OPEN v_result FOR
            SELECT 
                'artists' AS table_name, 
                artist_id AS record_id, 
                operation_type, 
                operation_timestamp,
                old_artist_name AS old_value1, 
                new_artist_name AS new_value1,
                old_country AS old_value2, 
                new_country AS new_value2,
                old_formed_date AS old_value3, 
                new_formed_date AS new_value3,
                NULL AS old_value4,
                NULL AS new_value4
            FROM audit_artists
            WHERE operation_timestamp >= p_target_timestamp

            UNION ALL

            SELECT 
                'albums' AS table_name, 
                album_id AS record_id, 
                operation_type, 
                operation_timestamp,
                old_album_name AS old_value1, 
                new_album_name AS new_value1,
                old_artist_id AS old_value2, 
                new_artist_id AS new_value2,
                old_release_date AS old_value3, 
                new_release_date AS new_value3,
                old_total_tracks AS old_value4,
                new_total_tracks AS new_value4
            FROM audit_albums
            WHERE operation_timestamp >= p_target_timestamp

            UNION ALL

            SELECT 
                'tracks' AS table_name, 
                track_id AS record_id, 
                operation_type, 
                operation_timestamp,
                old_track_name AS old_value1, 
                new_track_name AS new_value1,
                old_album_id AS old_value2, 
                new_album_id AS new_value2,
                old_duration_seconds AS old_value3, 
                new_duration_seconds AS new_value3,
                old_track_number AS old_value4,
                new_track_number AS new_value4
            FROM audit_tracks
            WHERE operation_timestamp >= p_target_timestamp
            ORDER BY operation_timestamp;       

        RETURN v_result;
    END get_sorted_audit_records;

    
    PROCEDURE perform_rollback(
        p_target_timestamp IN TIMESTAMP
    ) IS
        v_audit_cursor SYS_REFCURSOR;
        
        v_table_name VARCHAR2(30);
        v_record_id NUMBER;
        v_operation_type VARCHAR2(10);
        v_operation_timestamp TIMESTAMP;
        
        v_old_value1 VARCHAR2(200);
        v_new_value1 VARCHAR2(200);
        v_old_value2 VARCHAR2(200);
        v_new_value2 VARCHAR2(200);
        v_old_value3 DATE;
        v_new_value3 DATE;
        v_old_value4 NUMBER;
        v_new_value4 NUMBER;
    BEGIN
        v_audit_cursor := get_sorted_audit_records(p_target_timestamp);

        LOOP
           FETCH v_audit_cursor INTO 
                v_table_name, v_record_id, v_operation_type, v_operation_timestamp,
                v_old_value1, v_new_value1,
                v_old_value2, v_new_value2,
                v_old_value3, v_new_value3,
                v_old_value4, v_new_value4;
            
            EXIT WHEN v_audit_cursor%NOTFOUND;

            IF v_table_name = 'artists' THEN
                IF v_operation_type = 'INSERT' THEN
                    DELETE FROM artists WHERE artist_id = v_record_id;
                ELSIF v_operation_type = 'UPDATE' THEN
                    UPDATE artists 
                    SET artist_name = v_old_value1, 
                        country = v_old_value2, 
                        formed_date = v_old_value3
                    WHERE artist_id = v_record_id;
                ELSIF v_operation_type = 'DELETE' THEN
                    INSERT INTO artists (artist_id, artist_name, country, formed_date)
                    VALUES (v_record_id, v_old_value1, v_old_value2, v_old_value3);
                END IF;
            
            ELSIF v_table_name = 'albums' THEN
                IF v_operation_type = 'INSERT' THEN
                    DELETE FROM albums WHERE album_id = v_record_id;
                ELSIF v_operation_type = 'UPDATE' THEN
                    UPDATE albums 
                    SET album_name = v_old_value1, 
                        artist_id = v_old_value2, 
                        release_date = v_old_value3,
                        total_tracks = v_old_value4
                    WHERE album_id = v_record_id;
                ELSIF v_operation_type = 'DELETE' THEN
                    INSERT INTO albums (album_id, artist_id, album_name, release_date, total_tracks)
                    VALUES (v_record_id, v_old_value2, v_old_value1, v_old_value3, v_old_value4);
                END IF;
            
            ELSIF v_table_name = 'tracks' THEN
                IF v_operation_type = 'INSERT' THEN
                    DELETE FROM tracks WHERE track_id = v_record_id;
                ELSIF v_operation_type = 'UPDATE' THEN
                    UPDATE tracks 
                    SET track_name = v_old_value1, 
                        album_id = v_old_value2, 
                        duration_seconds = v_old_value3,
                        track_number = v_old_value4
                    WHERE track_id = v_record_id;
                ELSIF v_operation_type = 'DELETE' THEN
                    INSERT INTO tracks (track_id, album_id, track_name, duration_seconds, track_number)
                    VALUES (v_record_id, v_old_value2, v_old_value1, v_old_value3, v_old_value4);
                END IF;
            END IF;
        END LOOP;

        CLOSE v_audit_cursor;
        COMMIT;
    END perform_rollback;

     PROCEDURE rollback_changes(
        p_timestamp IN TIMESTAMP
    ) IS
    BEGIN
        perform_rollback(p_timestamp);
    END rollback_changes;
    
    PROCEDURE rollback_changes(
        p_milliseconds IN NUMBER
    ) IS
        v_target_timestamp TIMESTAMP;
    BEGIN
        v_target_timestamp := SYSTIMESTAMP - INTERVAL '0.001' SECOND * p_milliseconds;
        perform_rollback(v_target_timestamp);
    END rollback_changes;
END audit_rollback_pkg;
/