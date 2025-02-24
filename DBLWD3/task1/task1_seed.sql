DROP TABLE C##DEV.emp_dept;
DROP TABLE C##DEV.employees;
DROP TABLE C##DEV.departments;
DROP TABLE C##DEV.salaries;

DROP TABLE C##PROD.emp_dept;
DROP TABLE C##PROD.employees;
DROP TABLE C##PROD.departments;


CREATE TABLE C##DEV.departments (
    department_id NUMBER PRIMARY KEY,
    department_name VARCHAR2(200),
    location VARCHAR2(200),
    manager_id NUMBER
);

CREATE TABLE C##DEV.employees (
    employee_id NUMBER PRIMARY KEY,
    first_name VARCHAR2(100),
    last_name VARCHAR2(100),
    hire_date DATE
);

CREATE TABLE C##DEV.emp_dept (
    emp_dept_id NUMBER PRIMARY KEY,
    employee_id NUMBER,
    department_id NUMBER,
    CONSTRAINT fk_emp FOREIGN KEY (employee_id) REFERENCES C##DEV.employees (employee_id),
    CONSTRAINT fk_dept FOREIGN KEY (department_id) REFERENCES C##DEV.departments (department_id)
);


CREATE TABLE C##DEV.salaries (
    employee_id NUMBER PRIMARY KEY,
    salary NUMBER,
    bonus NUMBER
);


CREATE TABLE C##PROD.departments (
    department_id NUMBER PRIMARY KEY,
    department_name VARCHAR2(100),
    location VARCHAR2(100)
);

CREATE TABLE C##PROD.employees (
    employee_id NUMBER PRIMARY KEY,
    first_name VARCHAR2(50),
    last_name VARCHAR2(50),
    hire_date DATE
);

CREATE TABLE C##PROD.emp_dept (
    emp_dept_id NUMBER PRIMARY KEY,
    employee_id NUMBER,
    department_id NUMBER,
    CONSTRAINT fk_emp FOREIGN KEY (employee_id) REFERENCES C##PROD.employees (employee_id),
    CONSTRAINT fk_dept FOREIGN KEY (department_id) REFERENCES C##PROD.departments (department_id)
);

-- INSERT INTO C##DEV.departments VALUES (1, 'HR', 'New York', 1001);
-- INSERT INTO C##DEV.departments VALUES (2, 'Engineering', 'San Francisco', 1002);

-- INSERT INTO C##DEV.employees VALUES (101, 'Alice', 'Smith', TO_DATE('2022-01-01', 'YYYY-MM-DD'), 1);
-- INSERT INTO C##DEV.employees VALUES (102, 'Bob', 'Johnson', TO_DATE('2022-03-01', 'YYYY-MM-DD'), 2);

-- INSERT INTO C##DEV.emp_dept VALUES (1, 101, 1);
-- INSERT INTO C##DEV.emp_dept VALUES (2, 102, 2);

-- INSERT INTO C##DEV.salaries VALUES (101, 50000, 5000);
-- INSERT INTO C##DEV.salaries VALUES (102, 60000, 6000);

-- INSERT INTO C##PROD.departments VALUES (1, 'HR', 'New York');
-- INSERT INTO C##PROD.departments VALUES (2, 'Engineering', 'San Francisco');

-- INSERT INTO C##PROD.employees VALUES (101, 'Alice', 'Smith', TO_DATE('2022-01-01', 'YYYY-MM-DD'), 1);
-- INSERT INTO C##PROD.employees VALUES (102, 'Bob', 'Johnson', TO_DATE('2022-03-01', 'YYYY-MM-DD'), 2);

-- INSERT INTO C##PROD.emp_dept VALUES (1, 101, 1);
-- INSERT INTO C##PROD.emp_dept VALUES (2, 102, 2);


