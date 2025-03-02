BEGIN
    FOR rec IN (SELECT trigger_name FROM all_triggers WHERE owner = 'C##ADMIN_USER') LOOP
        EXECUTE IMMEDIATE 'DROP TRIGGER ' || rec.trigger_name;
    END LOOP;

    FOR rec IN (SELECT sequence_name FROM all_sequences WHERE sequence_owner = 'C##ADMIN_USER') LOOP
        EXECUTE IMMEDIATE 'DROP SEQUENCE ' || rec.sequence_name;
    END LOOP;

    FOR rec IN (SELECT table_name FROM all_tables WHERE owner = 'C##ADMIN_USER') LOOP
        EXECUTE IMMEDIATE 'DROP TABLE ' || rec.table_name || ' CASCADE CONSTRAINTS';
    END LOOP;

    EXECUTE IMMEDIATE 'DROP PROCEDURE ROLLBACK_IN_SECONDS';
END;
/

drop SEQUENCE student_id_seq;
drop SEQUENCE group_id_seq;
drop SEQUENCE students_audit_seq;
drop SEQUENCE groupd_audit_seq;

DROP PROCEDURE ROLLBACK_IN_SECONDS;