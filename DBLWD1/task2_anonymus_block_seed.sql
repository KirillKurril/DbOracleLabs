CREATE SEQUENCE my_table_seq
START WITH 1
INCREMENT BY 1
NOCACHE;


DECLARE 
    seed_index NUMBER := 1;
BEGIN
    WHILE seed_index <= 10000 LOOP
        INSERT INTO MyTable (id, val)
        VALUES (my_table_seq.NEXTVAL, TRUNC(DBMS_RANDOM.VALUE(1, 100000))); 
        seed_index := seed_index + 1;
    END LOOP;
    COMMIT;
END;
