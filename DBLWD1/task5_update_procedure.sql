CREATE PROCEDURE my_table_update(update_id NUMBER, update_value NUMBER)
IS
BEGIN
    UPDATE MyTable SET val = update_value WHERE id = update_id;
    
    IF SQL%ROWCOUNT = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Error: No data found to update with id = ' || delete_id);
    ELSE
        DBMS_OUTPUT.PUT_LINE('Successfully updated record with id = ' || delete_id);
    END IF;
    COMMIT;
 
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('No record found with id = ' || update_id);
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error occurred while updating record with id = ' || update_id || ': ' || SQLERRM);
END;