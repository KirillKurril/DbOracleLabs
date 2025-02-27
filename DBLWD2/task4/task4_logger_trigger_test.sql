DECLARE
    v_name STUDENTS.NAME%TYPE;
    v_group_id STUDENTS.GROUP_ID%TYPE;
BEGIN
    INSERT INTO STUDENTS (ID, NAME, GROUP_ID) VALUES (1000, 'John Doe', 101);
    INSERT INTO STUDENTS (ID, NAME, GROUP_ID) VALUES (2000, 'Jane Smith', 102);
    UPDATE STUDENTS SET NAME = 'Johnathan Doe', GROUP_ID = 103 WHERE ID = 1000;
    DELETE FROM STUDENTS WHERE ID = 2000;
    DELETE FROM STUDENTS WHERE ID = 1000;

    FOR rec IN (SELECT * FROM STUDENTS_AUDIT) LOOP
        DBMS_OUTPUT.PUT_LINE('Audit ID: ' || rec.AUDIT_ID || ', Action: ' || rec.ACTION_TYPE || ', Student ID: ' || rec.STUDENT_ID);
    END LOOP;

END;
