CREATE PROCEDURE my_table_insert(insert_value NUMBER)
IS
BEGIN
    INSERT INTO MyTable (id, val) VALUES (my_table_seq.NEXTVAL, insert_value);
    COMMIT;

EXCEPTION
        
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error occurred during inserting: ' || SQLERRM);
        ROLLBACK;    
END;
    