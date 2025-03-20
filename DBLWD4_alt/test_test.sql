DECLARE
  v_json_input CLOB := '{
    "query_type": "INSERT",
    "table": "t1",
    "columns": "t1_id, t1_name, t1_fk, t1_c",
    "values": "5, ''t1_name'', 55, 10"
  }';

  v_cursor  SYS_REFCURSOR;
  v_rows    NUMBER;
  v_message VARCHAR2(4000);
  
  v_t1_id    NUMBER;
  v_t1_name  VARCHAR2(100);
  v_t1_fk NUMBER;
  v_t1_c    NUMBER;  

BEGIN
  dynamic_sql_executor(
    p_json    => v_json_input,
    p_cursor  => v_cursor,
    p_rows    => v_rows,
    p_message => v_message
  );

  DBMS_OUTPUT.PUT_LINE('Message: ' || v_message);
  DBMS_OUTPUT.PUT_LINE(v_rows || ' lines affected');
  
END;
/

DECLARE
  v_json_input CLOB := '{
    "query_type": "UPDATE",
    "table": "t1",
    "set_clause": "t1_c = t1_c * 1.05",
    "where_conditions": "t1_id = 5"
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

  DBMS_OUTPUT.PUT_LINE('Message: ' || v_message);
  DBMS_OUTPUT.PUT_LINE(v_rows || ' lines affected');
END;
/

DECLARE
  v_json_input CLOB := '{
    "query_type": "DELETE",
    "table": "t1",
    "where_conditions": "t1_fk > 50",
    "subquery_conditions": "t1_c IN (SELECT t1_c FROM t1 WHERE t1_c < 11)"
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

  DBMS_OUTPUT.PUT_LINE('Message: ' || v_message);
  DBMS_OUTPUT.PUT_LINE('Lines affected: ' || v_rows);
END;
/

DECLARE
  v_json_input CLOB := '{
    "query_type": "DDL",
    "ddl_command": "CREATE TABLE",
    "table": "t2",
    "fields": "t2_id NUMBER, t2_name VARCHAR2(50), t2_fk NUMBER, t2_c NUMBER"
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

  DBMS_OUTPUT.PUT_LINE('Message: ' || v_message);
END;
/

DECLARE
  v_json_input CLOB := '{
    "query_type": "DDL",
    "ddl_command": "DROP TABLE",
    "table": "t2"
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

  DBMS_OUTPUT.PUT_LINE('Message: ' || v_message);
END;
/

DECLARE
  v_json_input CLOB := '{
    "query_type": "DDL",
    "ddl_command": "CREATE TABLE",
    "table": "t99",
    "fields": "t99_id NUMBER, t99_name VARCHAR2(50), t99_fk NUMBER, t99_c NUMBER",
    "generate_trigger": "true",
    "trigger_name": "t99_tg",
    "pk_field": "t99_id",
    "sequence_name": "t99_seq"
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

  DBMS_OUTPUT.PUT_LINE('Message: ' || v_message);
END;
/

DECLARE
  v_json_input CLOB := '{
    "query_type": "INSERT",
    "table": "t99",
    "columns": "t99_name, t99_fk, t99_c",
    "values": "''t1_name'', 55, 10"
  }';

  v_cursor  SYS_REFCURSOR;
  v_rows    NUMBER;
  v_message VARCHAR2(4000);
  
  v_t1_id    NUMBER;
  v_t1_name  VARCHAR2(100);
  v_t1_fk NUMBER;
  v_t1_c    NUMBER;  

BEGIN
  dynamic_sql_executor(
    p_json    => v_json_input,
    p_cursor  => v_cursor,
    p_rows    => v_rows,
    p_message => v_message
  );

  DBMS_OUTPUT.PUT_LINE('Message: ' || v_message);
  DBMS_OUTPUT.PUT_LINE(v_rows || ' lines affected');
  
END;
/

DECLARE
  v_json_input CLOB := '{
    "query_type": "SELECT",
    "select_columns": "t5.t5_id, t5.t5_name, t10.t10_name, e15.e15_name, e15.e15_count",
    "tables": "t5, t10, e15",
    "join_conditions": "t5.t5_id = t10.t5_fk AND t10.t10_id = e15.t10_fk",
    "where_conditions": "e15.e15_count > 15"
  }';

  v_cursor  SYS_REFCURSOR;
  v_rows    NUMBER;
  v_message VARCHAR2(4000);

  v_t5_id      NUMBER;
  v_t5_name    VARCHAR2(50);
  v_t10_name   VARCHAR2(50);
  v_e15_name   VARCHAR2(50);
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
      v_e15_name,
      v_e15_count;
      
    EXIT WHEN v_cursor%NOTFOUND;
    
    DBMS_OUTPUT.PUT_LINE(
      'T5: ' || RPAD(v_t5_id, 3) || ' | ' ||
      RPAD(v_t5_name, 10) || ' | ' ||
      'T10: ' || RPAD(v_t10_name, 10) || ' | ' ||
      'E15: ' || RPAD(v_e15_name, 10) || ' | ' ||
      'Count: ' || v_e15_count
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

