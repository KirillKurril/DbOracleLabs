SET SERVEROUTPUT ON;

DECLARE
    result CLOB;
BEGIN
    result := compare_schemas('C##DEV', 'C##PROD');
    DBMS_OUTPUT.PUT_LINE(DBMS_LOB.SUBSTR(result, 4000, 1)); 
END;
/
