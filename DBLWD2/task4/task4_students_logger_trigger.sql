CREATE OR REPLACE TRIGGER students_logger
AFTER INSERT OR UPDATE OR DELETE ON STUDENTS
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        DBMS_OUTPUT.PUT_LINE('INSERT action: Student ID = ' || :NEW.ID || ', Name = ' || :NEW.NAME || ', Group ID = ' || :NEW.GROUP_ID);
        INSERT INTO STUDENTS_AUDIT (
            AUDIT_ID, 
            ACTION_TYPE, 
            ACTION_DATE, 
            STUDENT_ID, 
            STUDENT_NAME, 
            GROUP_ID
        )
        VALUES (
            STUDENTS_AUDIT_SEQ.NEXTVAL, 
            'INSERT',
            SYSTIMESTAMP, 
            :NEW.ID, 
            :NEW.NAME, 
            :NEW.GROUP_ID
        );
    ELSIF UPDATING THEN
        DBMS_OUTPUT.PUT_LINE('UPDATE action: Student ID = ' || :NEW.ID || ', Old Name = ' || :OLD.NAME || ', New Name = ' || :NEW.NAME || ', Old Group ID = ' || :OLD.GROUP_ID || ', New Group ID = ' || :NEW.GROUP_ID);
        INSERT INTO STUDENTS_AUDIT (
            AUDIT_ID, 
            ACTION_TYPE, 
            ACTION_DATE, 
            STUDENT_ID, 
            STUDENT_NAME, 
            GROUP_ID, 
            OLD_STUDENT_NAME, 
            OLD_GROUP_ID
        )
        VALUES (
            STUDENTS_AUDIT_SEQ.NEXTVAL, 
            'UPDATE', 
            SYSTIMESTAMP, 
            :NEW.ID, 
            :NEW.NAME, 
            :NEW.GROUP_ID,
            :OLD.NAME, 
            :OLD.GROUP_ID
        );
    ELSIF DELETING THEN
        DBMS_OUTPUT.PUT_LINE('DELETE action: Student ID = ' || :OLD.ID || ', Name = ' || :OLD.NAME || ', Group ID = ' || :OLD.GROUP_ID);
        INSERT INTO STUDENTS_AUDIT (
            AUDIT_ID, 
            ACTION_TYPE, 
            ACTION_DATE, 
            STUDENT_ID, 
            STUDENT_NAME, 
            GROUP_ID
        )
        VALUES (
            STUDENTS_AUDIT_SEQ.NEXTVAL, 
            'DELETE', 
            SYSTIMESTAMP, 
            :OLD.ID, 
            :OLD.NAME, 
            :OLD.GROUP_ID
        );
    END IF;
END;

