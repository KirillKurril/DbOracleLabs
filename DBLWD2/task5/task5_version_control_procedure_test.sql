SELECT * FROM STUDENTS;

INSERT INTO STUDENTS (ID, NAME, GROUP_ID) VALUES (student_id_seq.NEXTVAL, 'Alice', 101);
INSERT INTO STUDENTS (ID, NAME, GROUP_ID) VALUES (student_id_seq.NEXTVAL, 'Bob', 102);
INSERT INTO STUDENTS (ID, NAME, GROUP_ID) VALUES (student_id_seq.NEXTVAL, 'Charlie', 103);

UPDATE STUDENTS SET NAME = 'Alice Updated', GROUP_ID = 101 WHERE NAME = 'Alice';

DELETE FROM STUDENTS WHERE NAME = 'Charlie';

SELECT * FROM STUDENTS;

EXEC ROLLBACK_IN_SECONDS(5);

SELECT * FROM STUDENTS;
