CREATE OR REPLACE PACKAGE audit_report_pkg AS 
    PROCEDURE generate_dml_report(
        p_start_timestamp IN TIMESTAMP,
        p_directory IN VARCHAR2 DEFAULT 'REPORT_DIR',
        p_filename IN VARCHAR2 DEFAULT NULL
    );
PROCEDURE generate_dml_report(
    p_directory IN VARCHAR2 DEFAULT 'REPORT_DIR',
    p_filename IN VARCHAR2 DEFAULT NULL
);
END audit_report_pkg;
/

CREATE OR REPLACE PACKAGE audit_report_pkg AS
    PROCEDURE generate_dml_report(
        p_start_timestamp IN TIMESTAMP,
        p_directory IN VARCHAR2 DEFAULT 'REPORT_DIR',
        p_filename IN VARCHAR2 DEFAULT NULL
    );

    PROCEDURE generate_dml_report(
        p_directory IN VARCHAR2 DEFAULT 'REPORT_DIR',
        p_filename IN VARCHAR2 DEFAULT NULL
    );
END audit_report_pkg;
/

CREATE OR REPLACE PACKAGE BODY audit_report_pkg AS
    FUNCTION get_last_report_timestamp RETURN TIMESTAMP IS
        v_last_timestamp TIMESTAMP;
    BEGIN
        BEGIN
            SELECT report_timestamp INTO v_last_timestamp
            FROM (
                SELECT report_timestamp 
                FROM report_timestamps 
                ORDER BY report_timestamp DESC
            )
            WHERE ROWNUM = 1;
            
            RETURN v_last_timestamp;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RETURN TIMESTAMP '2025-01-01 00:00:00';
        END;
    END get_last_report_timestamp;

    PROCEDURE write_html_report(
        p_cursor IN SYS_REFCURSOR,
        p_directory IN VARCHAR2,
        p_filename IN VARCHAR2
    ) IS
        v_file UTL_FILE.FILE_TYPE;
        v_filename VARCHAR2(255);
        
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
        
        TYPE operation_counts IS TABLE OF NUMBER INDEX BY VARCHAR2(10);
        v_counts operation_counts;
    BEGIN
        IF p_filename IS NULL THEN
            v_filename := 'dml_report_' || TO_CHAR(SYSTIMESTAMP, 'YYYYMMDD_HH24MISS') || '.html';
        ELSE
            v_filename := p_filename;
        END IF;

        v_file := UTL_FILE.FOPEN(p_directory, v_filename, 'W');

        UTL_FILE.PUTF(v_file, '<!DOCTYPE html>
<html>
<head>
    <title>DML Operations Report</title>
    <style>
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid black; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <h1>DML Operations Report</h1>
    <table>
        <tr>
            <th>Table</th>
            <th>Insert Count</th>
            <th>Update Count</th>
            <th>Delete Count</th>
        </tr>');

        v_counts('INSERT') := 0;
        v_counts('UPDATE') := 0;
        v_counts('DELETE') := 0;

        LOOP
            FETCH v_audit_cursor INTO 
                v_table_name, v_record_id, v_operation_type, v_operation_timestamp,
                v_old_value1, v_new_value1,
                v_old_value2, v_new_value2,
                v_old_value3, v_new_value3,
                v_old_value4, v_new_value4;
            
            EXIT WHEN v_audit_cursor%NOTFOUND;

            v_counts(v_operation_type) := v_counts(v_operation_type) + 1;
        END LOOP;

        UTL_FILE.PUTF(v_file, '
        <tr>
            <td>Artists</td>
            <td>%s</td>
            <td>%s</td>
            <td>%s</td>
        </tr>
        <tr>
            <td>Albums</td>
            <td>%s</td>
            <td>%s</td>
            <td>%s</td>
        </tr>
        <tr>
            <td>Tracks</td>
            <td>%s</td>
            <td>%s</td>
            <td>%s</td>
        </tr>
    </table>
</body>
</html>', 
            v_counts('INSERT'), v_counts('UPDATE'), v_counts('DELETE'),
            v_counts('INSERT'), v_counts('UPDATE'), v_counts('DELETE'),
            v_counts('INSERT'), v_counts('UPDATE'), v_counts('DELETE'));

        UTL_FILE.FCLOSE(v_file);

        INSERT INTO report_timestamps (report_timestamp) VALUES (SYSTIMESTAMP);
        COMMIT;
    END write_html_report;

    PROCEDURE generate_dml_report(
        p_start_timestamp IN TIMESTAMP,
        p_directory IN VARCHAR2 DEFAULT 'REPORT_DIR',
        p_filename IN VARCHAR2 DEFAULT NULL
    ) IS
        v_audit_cursor SYS_REFCURSOR;
    BEGIN
        v_audit_cursor := audit_rollback_pkg.get_sorted_audit_records(p_start_timestamp);
        
        write_html_report(v_audit_cursor, p_directory, p_filename);
    END generate_dml_report;

    PROCEDURE generate_dml_report(
        p_directory IN VARCHAR2 DEFAULT 'REPORT_DIR',
        p_filename IN VARCHAR2 DEFAULT NULL
    ) IS
        v_last_timestamp TIMESTAMP;
        v_audit_cursor SYS_REFCURSOR;
    BEGIN
        v_last_timestamp := get_last_report_timestamp();
        
        v_audit_cursor := audit_rollback_pkg.get_sorted_audit_records(v_last_timestamp);
        
        write_html_report(v_audit_cursor, p_directory, p_filename);
    END generate_dml_report;
END audit_report_pkg;
/