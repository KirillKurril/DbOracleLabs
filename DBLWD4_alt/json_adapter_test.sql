DECLARE
  v_json_input CLOB := '{
    "query_type": "SELECT",
    "select_columns": "e.emp_id, e.emp_name, d.dept_name, e.salary",
    "tables": "employees e, departments d",
    "join_conditions": "e.dept_id = d.dept_id",
    "where_conditions": "e.salary > 1000"
  }';

  v_cursor  SYS_REFCURSOR;
  v_rows    NUMBER;
  v_message VARCHAR2(4000);

  v_emp_id    NUMBER;
  v_emp_name  VARCHAR2(100);
  v_dept_name VARCHAR2(100);
  v_salary    NUMBER;

BEGIN
  dynamic_sql_executor(
    p_json    => v_json_input,
    p_cursor  => v_cursor,
    p_rows    => v_rows,
    p_message => v_message
  );

  DBMS_OUTPUT.PUT_LINE('Сообщение: ' || v_message);

  LOOP
    FETCH v_cursor INTO v_emp_id, v_emp_name, v_dept_name, v_salary;
    EXIT WHEN v_cursor%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE('ID: ' || v_emp_id || ', Name: ' || v_emp_name ||
                         ', Dept: ' || v_dept_name || ', Salary: ' || v_salary);
  END LOOP;

  CLOSE v_cursor;
END;
/

--------------------------------------------------

DECLARE
  v_json_input CLOB := '{
    "query_type": "SELECT",
    "select_columns": "e.emp_id, e.emp_name, d.dept_name, e.salary",
    "tables": "employees e, departments d",
    "join_conditions": "e.dept_id = d.dept_id",
    "where_conditions": "e.salary > 1000",
    "subquery_conditions": "e.emp_id IN (SELECT emp_id FROM employees WHERE salary < 1800)"
  }';

  v_cursor  SYS_REFCURSOR;
  v_rows    NUMBER;
  v_message VARCHAR2(4000);

  v_emp_id    NUMBER;
  v_emp_name  VARCHAR2(100);
  v_dept_name VARCHAR2(100);
  v_salary    NUMBER;

BEGIN
  dynamic_sql_executor(
    p_json    => v_json_input,
    p_cursor  => v_cursor,
    p_rows    => v_rows,
    p_message => v_message
  );

  DBMS_OUTPUT.PUT_LINE('Сообщение: ' || v_message);

  LOOP
    FETCH v_cursor INTO v_emp_id, v_emp_name, v_dept_name, v_salary;
    EXIT WHEN v_cursor%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE('ID: ' || v_emp_id || ', Name: ' || v_emp_name ||
                         ', Dept: ' || v_dept_name || ', Salary: ' || v_salary);
  END LOOP;

  CLOSE v_cursor;
END;
/

--------------------------------------------------

DECLARE
  v_json_input CLOB := '{
    "query_type": "INSERT",
    "table": "employees",
    "columns": "emp_id, emp_name, salary, dept_id",
    "values": "5, ''Charlie Black'', 1300, 10"
  }';

  v_cursor  SYS_REFCURSOR;
  v_rows    NUMBER;
  v_message VARCHAR2(4000);

BEGIN
  dynamic_sql_executor(
    p_json    => v_json_input,
    p_cursor  => v_cursor,
    p_rows    => v_rows,
    p_message => v_message
  );

  DBMS_OUTPUT.PUT_LINE('Сообщение: ' || v_message);
  DBMS_OUTPUT.PUT_LINE('Затронуто строк: ' || v_rows);
END;
/

--------------------------------------------------

DECLARE
  v_json_input CLOB := '{
    "query_type": "UPDATE",
    "table": "employees",
    "set_clause": "salary = salary * 1.05",
    "where_conditions": "dept_id = 10",
    "subquery_conditions": "emp_id IN (SELECT emp_id FROM employees WHERE salary < 1500)"
  }';

  v_cursor  SYS_REFCURSOR;
  v_rows    NUMBER;
  v_message VARCHAR2(4000);

BEGIN
  dynamic_sql_executor(
    p_json    => v_json_input,
    p_cursor  => v_cursor,
    p_rows    => v_rows,
    p_message => v_message
  );

  DBMS_OUTPUT.PUT_LINE('Сообщение: ' || v_message);
  DBMS_OUTPUT.PUT_LINE('Затронуто строк: ' || v_rows);
END;
/

--------------------------------------------------

DECLARE
  v_json_input CLOB := '{
    "query_type": "DELETE",
    "table": "employees",
    "where_conditions": "salary < 1000",
    "subquery_conditions": "emp_id IN (SELECT emp_id FROM employees WHERE dept_id = 20)"
  }';

  v_cursor  SYS_REFCURSOR;
  v_rows    NUMBER;
  v_message VARCHAR2(4000);

BEGIN
  dynamic_sql_executor(
    p_json    => v_json_input,
    p_cursor  => v_cursor,
    p_rows    => v_rows,
    p_message => v_message
  );

  DBMS_OUTPUT.PUT_LINE('Сообщение: ' || v_message);
  DBMS_OUTPUT.PUT_LINE('Затронуто строк: ' || v_rows);
END;
/

--------------------------------------------------

DECLARE
  v_json_input CLOB := '{
    "query_type": "DDL",
    "ddl_command": "CREATE TABLE",
    "table": "test_table",
    "fields": "id NUMBER, name VARCHAR2(50)"
  }';

  v_cursor  SYS_REFCURSOR;
  v_rows    NUMBER;
  v_message VARCHAR2(4000);

BEGIN
  dynamic_sql_executor(
    p_json    => v_json_input,
    p_cursor  => v_cursor,
    p_rows    => v_rows,
    p_message => v_message
  );

  DBMS_OUTPUT.PUT_LINE('Сообщение: ' || v_message);
END;
/

--------------------------------------------------

DECLARE
  v_json_input CLOB := '{
    "query_type": "DDL",
    "ddl_command": "DROP TABLE",
    "table": "test_table"
  }';

  v_cursor  SYS_REFCURSOR;
  v_rows    NUMBER;
  v_message VARCHAR2(4000);

BEGIN
  dynamic_sql_executor(
    p_json    => v_json_input,
    p_cursor  => v_cursor,
    p_rows    => v_rows,
    p_message => v_message
  );

  DBMS_OUTPUT.PUT_LINE('Сообщение: ' || v_message);
END;
/

--------------------------------------------------

DECLARE
  v_json_input CLOB := '{
    "query_type": "DDL",
    "ddl_command": "CREATE TABLE",
    "table": "test_table_with_trigger",
    "fields": "id NUMBER, name VARCHAR2(50)",
    "generate_trigger": "true",
    "trigger_name": "test_table_trigger",
    "pk_field": "id",
    "sequence_name": "test_table_seq"
  }';

  v_cursor  SYS_REFCURSOR;
  v_rows    NUMBER;
  v_message VARCHAR2(4000);

BEGIN
  dynamic_sql_executor(
    p_json    => v_json_input,
    p_cursor  => v_cursor,
    p_rows    => v_rows,
    p_message => v_message
  );

  DBMS_OUTPUT.PUT_LINE('Сообщение: ' || v_message);
END;
/

DECLARE
  v_json_input CLOB := '{
    "query_type": "INSERT",
    "table": "test_table_with_trigger",
    "columns": "name",
    "values": "''Test Record''"
  }';

  v_cursor  SYS_REFCURSOR;
  v_rows    NUMBER;
  v_message VARCHAR2(4000);

BEGIN
  dynamic_sql_executor(
    p_json    => v_json_input,
    p_cursor  => v_cursor,
    p_rows    => v_rows,
    p_message => v_message
  );

  DBMS_OUTPUT.PUT_LINE('Сообщение: ' || v_message);
  DBMS_OUTPUT.PUT_LINE('Затронуто строк: ' || v_rows);
END;
/


--------------------------------------------------

DECLARE
  v_json_input CLOB := '{
    "query_type": "SELECT",
    "select_columns": "d.dept_id, d.dept_name, SUM(e.salary) AS total_salary, AVG(e.salary) AS avg_salary",
    "tables": "employees e, departments d",
    "join_conditions": "e.dept_id = d.dept_id",
    "where_conditions": "e.salary > 1000",
    "group_by": "d.dept_id, d.dept_name"
  }';
  v_cursor  SYS_REFCURSOR;
  v_rows    NUMBER;
  v_message VARCHAR2(4000);

  v_dept_id      NUMBER;
  v_dept_name    VARCHAR2(100);
  v_total_salary NUMBER;
  v_avg_salary   NUMBER;
BEGIN
  dynamic_sql_executor(
    p_json    => v_json_input,
    p_cursor  => v_cursor,
    p_rows    => v_rows,
    p_message => v_message
  );

  DBMS_OUTPUT.PUT_LINE('Сообщение: ' || v_message);

  LOOP
    FETCH v_cursor INTO v_dept_id, v_dept_name, v_total_salary, v_avg_salary;
    EXIT WHEN v_cursor%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE('Dept ID: ' || v_dept_id ||
                         ', Dept: ' || v_dept_name ||
                         ', Total Salary: ' || v_total_salary ||
                         ', Avg Salary: ' || v_avg_salary);
  END LOOP;

  CLOSE v_cursor;
END;
/

DECLARE
  v_json_input CLOB := '{
    "query_type": "SELECT",
    "select_columns": "t5.t5_id, t5.t5_name, t10.t10_name, e15.e15_count",
    "tables": "t5, t10, e15",
    "join_conditions": "t5.t5_id = t10.t5_fk AND t10.t10_id = e15.t10_fk",
    "where_conditions": "e15.e15_count > 10",
    "subquery_conditions": " t5.t5_id NOT IN (SELECT t5_fk FROM t10 WHERE t10_count < 60) AND EXISTS (SELECT 1 FROM e15 WHERE e15.t10_fk = t10.t10_id)"
  }';

  v_cursor  SYS_REFCURSOR;
  v_rows    NUMBER;
  v_message VARCHAR2(4000);

  v_t5_id      NUMBER;
  v_t5_name    VARCHAR2(50);
  v_t10_name   VARCHAR2(50);
  v_e15_count  NUMBER;

BEGIN
  dynamic_sql_executor(
    p_json    => v_json_input,
    p_cursor  => v_cursor,
    p_rows    => v_rows,
    p_message => v_message
  );

  DBMS_OUTPUT.PUT_LINE('Сообщение: ' || v_message);

  LOOP
    FETCH v_cursor INTO 
      v_t5_id,
      v_t5_name,
      v_t10_name,
      v_e15_count;
      
    EXIT WHEN v_cursor%NOTFOUND;
    
    DBMS_OUTPUT.PUT_LINE(
      'T5: ' || RPAD(v_t5_id, 3) || ' | ' ||
      RPAD(v_t5_name, 10) || ' | ' ||
      'T10: ' || RPAD(v_t10_name, 10) || ' | ' ||
      'E15 Count: ' || v_e15_count
    );
  END LOOP;

  CLOSE v_cursor;
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Ошибка: ' || SQLERRM);
    IF v_cursor%ISOPEN THEN
      CLOSE v_cursor;
    END IF;
END;
/