CREATE FUNCTION calculate_year_salary(monthly_salary NUMBER, bonus_percent NUMBER)
RETURN NUMBER
IS
    year_salary NUMBER;
BEGIN
    IF monthly_salary < 0 OR bonus_percent < 0 THEN
        DBMS_OUTPUT.PUT_LINE('Error: Monthly salary and bonus percentage must be non-negative values.');
        RETURN NULL;
    END IF;
    
    year_salary := (1 + bonus_percent / 100) * 12 * monthly_salary;
    RETURN year_salary;

EXCEPTION
    WHEN VALUE_ERROR THEN
        DBMS_OUTPUT.PUT_LINE('Error: Invalid input data (e.g., non-numeric values).');
        RETURN NULL;
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error occurred: ' || SQLERRM);
        RETURN NULL;
END;
