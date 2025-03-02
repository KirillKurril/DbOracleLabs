INSERT INTO GROUPS (ID, NAME) VALUES (101, 'Group A');
INSERT INTO GROUPS (ID, NAME) VALUES (102, 'Group B');
INSERT INTO GROUPS (ID, NAME) VALUES (103, 'Group C');

SELECT * FROM STUDENTS;

INSERT INTO STUDENTS (ID, NAME, GROUP_ID) VALUES (student_id_seq.NEXTVAL, 'Alice', 101);
INSERT INTO STUDENTS (ID, NAME, GROUP_ID) VALUES (student_id_seq.NEXTVAL, 'Bob', 102);
INSERT INTO STUDENTS (ID, NAME, GROUP_ID) VALUES (student_id_seq.NEXTVAL, 'Charlie', 103);

UPDATE STUDENTS SET NAME = 'Alice Updated', GROUP_ID = 101 WHERE NAME = 'Alice';

DELETE FROM STUDENTS WHERE NAME = 'Charlie';

SELECT * FROM STUDENTS;

DELETE FROM GROUPS WHERE ID = 102;

SELECT * FROM STUDENTS;

EXEC ROLLBACK_IN_SECONDS(5);

SELECT * FROM STUDENTS;