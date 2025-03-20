CREATE TABLE t5 (
    t5_id NUMBER PRIMARY KEY,
    t5_name VARCHAR2(50),
    t5_count NUMBER
);

CREATE TABLE t10 (
    t10_id NUMBER PRIMARY KEY,
    t10_name VARCHAR2(50),
    t5_fk NUMBER REFERENCES t5(t5_id),
    t10_count NUMBER
);

CREATE TABLE e15 (
    e15_id NUMBER PRIMARY KEY,
    e15_name VARCHAR2(50),
    t10_fk NUMBER REFERENCES t10(t10_id),
    e15_count NUMBER
);

INSERT ALL
    INTO t5 (t5_id, t5_name, t5_count) VALUES (1, 'Alpha', 100)
    INTO t5 (t5_id, t5_name, t5_count) VALUES (2, 'Beta', 200)
    INTO t5 (t5_id, t5_name, t5_count) VALUES (3, 'Gamma', 300)
SELECT 1 FROM DUAL;

INSERT ALL
    INTO t10 (t10_id, t10_name, t5_fk, t10_count) VALUES (1, 'Data A', 1, 50)
    INTO t10 (t10_id, t10_name, t5_fk, t10_count) VALUES (2, 'Data B', 1, 75)
    INTO t10 (t10_id, t10_name, t5_fk, t10_count) VALUES (3, 'Data C', 2, 60)
    INTO t10 (t10_id, t10_name, t5_fk, t10_count) VALUES (4, 'Data D', 3, 90)
SELECT 1 FROM DUAL;

INSERT ALL
    INTO e15 (e15_id, e15_name, t10_fk, e15_count) VALUES (1, 'Order 1', 1, 10)
    INTO e15 (e15_id, e15_name, t10_fk, e15_count) VALUES (2, 'Order 2', 2, 15)
    INTO e15 (e15_id, e15_name, t10_fk, e15_count) VALUES (3, 'Order 3', 3, 20)
    INTO e15 (e15_id, e15_name, t10_fk, e15_count) VALUES (4, 'Order 4', 4, 25)
SELECT 1 FROM DUAL;

COMMIT;