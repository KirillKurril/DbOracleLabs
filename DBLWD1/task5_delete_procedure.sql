CREATE PROCEDURE my_table_delete(delete_id NUMBER)
IS
BEGIN
    DELETE FROM MyTable WHERE id = delete_id;
  
    IF SQL%ROWCOUNT = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Error: No data found to delete with id = ' || delete_id);
    ELSE
        DBMS_OUTPUT.PUT_LINE('Successfully deleted record with id = ' || delete_id);
    END IF;

    COMMIT;
    
EXCEPTION
        
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error occurred during deletion: ' || SQLERRM);
        ROLLBACK;
END;
    

