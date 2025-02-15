CREATE FUNCTION generate_insert(record_id NUMBER)
RETURN VARCHAR2
IS
    record_val NUMBER;
    insert_query VARCHAR2(4000);
BEGIN
    SELECT val INTO record_val FROM MyTable WHERE id = record_id;

    insert_query := 'INSERT INTO MyTable (id, val) VALUES (' || record_id || ', ' || record_val || ');';

    RETURN insert_query;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'No data found for ID ' || record_id;
END;

--SELECT generate_insert(2) FROM dual;