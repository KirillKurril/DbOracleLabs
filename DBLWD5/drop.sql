DROP SEQUENCE audit_seq;

DROP TABLE artists CASCADE CONSTRAINTS;
DROP TABLE albums CASCADE CONSTRAINTS;
DROP TABLE tracks CASCADE CONSTRAINTS;
DROP TABLE audit_artists CASCADE CONSTRAINTS;
DROP TABLE audit_albums CASCADE CONSTRAINTS;
DROP TABLE audit_tracks CASCADE CONSTRAINTS;
DROP TABLE report_timestamps CASCADE CONSTRAINTS;

BEGIN
    EXECUTE IMMEDIATE 'DROP PACKAGE audit_rollback_pkg';
    EXECUTE IMMEDIATE 'DROP PACKAGE audit_report_pkg';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -4043 THEN
            RAISE;
        END IF;
END;
/

