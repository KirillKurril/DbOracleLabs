CREATE OR REPLACE FUNCTION C##DEV.common_function RETURN VARCHAR2 AS
BEGIN
    RETURN 'Common Function';
END;
/

CREATE OR REPLACE FUNCTION C##PROD.common_function RETURN VARCHAR2 AS
BEGIN
    RETURN 'Common Function';
END;
/

-----------

CREATE OR REPLACE FUNCTION C##DEV.get_dev_value(p_id NUMBER) RETURN VARCHAR2 AS
BEGIN
    RETURN 'DEV Value: ' || p_id;
END;
/

--------
CREATE OR REPLACE FUNCTION C##DEV.calculate_bonus(salary NUMBER) RETURN NUMBER AS
BEGIN
    RETURN salary * 0.15;
END;
/

CREATE OR REPLACE FUNCTION C##PROD.calculate_bonus(salary NUMBER) RETURN NUMBER AS
BEGIN
    RETURN salary * 0.10;
END;
/
-------

CREATE OR REPLACE PROCEDURE C##DEV.common_procedure AS
BEGIN
    DBMS_OUTPUT.PUT_LINE('This is the common procedure.');
END;
/

CREATE OR REPLACE PROCEDURE C##PROD.common_procedure AS
BEGIN
    DBMS_OUTPUT.PUT_LINE('This is the common procedure.');
END;
/

CREATE OR REPLACE PROCEDURE C##DEV.update_salary(p_emp_id NUMBER, p_new_salary NUMBER) AS
BEGIN
    UPDATE C##DEV.SALARIES SET salary = p_new_salary WHERE employee_id = p_emp_id;
END;
/

CREATE OR REPLACE PROCEDURE C##DEV.calculate_salary_bonus(p_emp_id NUMBER) AS
    v_salary NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Bonus for DEV employee ' || p_emp_id || ' is: ' || (v_salary * 0.15));
END;
/

CREATE OR REPLACE PROCEDURE C##PROD.calculate_salary_bonus(p_emp_id NUMBER) AS
    v_salary NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Bonus for PROD employee ' || p_emp_id || ' is: ' || (v_salary * 0.10));
END;
/


--------

CREATE OR REPLACE PACKAGE C##DEV.pkg_utils AS
    FUNCTION get_version RETURN VARCHAR2;
END pkg_utils;
/

CREATE OR REPLACE PACKAGE BODY C##DEV.pkg_utils AS
    FUNCTION get_version RETURN VARCHAR2 IS
    BEGIN
        RETURN 'DEV Version 1.0';
    END;
END pkg_utils;
/

CREATE OR REPLACE PACKAGE C##DEV.pkg_operations AS
    FUNCTION calculate_tax(amount NUMBER) RETURN NUMBER;
END pkg_operations;
/

CREATE OR REPLACE PACKAGE BODY C##DEV.pkg_operations AS
    FUNCTION calculate_tax(amount NUMBER) RETURN NUMBER IS
    BEGIN
        RETURN amount * 0.18;
    END;
END pkg_operations;
/

CREATE OR REPLACE PACKAGE C##PROD.pkg_operations AS
    FUNCTION calculate_tax(amount NUMBER) RETURN NUMBER;
END pkg_operations;
/

CREATE OR REPLACE PACKAGE BODY C##PROD.pkg_operations AS
    FUNCTION calculate_tax(amount NUMBER) RETURN NUMBER IS
    BEGIN
        RETURN amount * 0.20;
    END;
END pkg_operations;
/


CREATE OR REPLACE PACKAGE C##DEV.common_package AS
    FUNCTION get_version RETURN VARCHAR2;
    PROCEDURE display_message(p_message VARCHAR2);
END common_package;
/

CREATE OR REPLACE PACKAGE BODY C##DEV.common_package AS
    FUNCTION get_version RETURN VARCHAR2 IS
    BEGIN
        RETURN 'Version 1.0';
    END;

    PROCEDURE display_message(p_message VARCHAR2) IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE('Message: ' || p_message);
    END;
END common_package;
/

CREATE OR REPLACE PACKAGE C##PROD.common_package AS
    FUNCTION get_version RETURN VARCHAR2;
    PROCEDURE display_message(p_message VARCHAR2);
END common_package;
/

CREATE OR REPLACE PACKAGE BODY C##PROD.common_package AS
    FUNCTION get_version RETURN VARCHAR2 IS
    BEGIN
        RETURN 'Version 1.0';
    END;

    PROCEDURE display_message(p_message VARCHAR2) IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE('Message: ' || p_message);
    END;
END common_package;
/

------------

BEGIN
    EXECUTE IMMEDIATE 'DROP INDEX C##DEV.idx_employee_name';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

CREATE INDEX C##DEV.idx_employee_name ON C##DEV.EMPLOYEES (last_name, first_name);

BEGIN
    EXECUTE IMMEDIATE 'DROP INDEX C##DEV.idx_employee_dept';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

CREATE INDEX C##DEV.idx_employee_dept ON C##DEV.EMPLOYEES (department_id);

BEGIN
    EXECUTE IMMEDIATE 'DROP INDEX C##PROD.idx_employee_name';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

CREATE INDEX C##PROD.idx_employee_name ON C##PROD.EMPLOYEES (last_name);
