-- Создаем пакет для работы с JSON запросами
CREATE OR REPLACE PACKAGE dynamic_sql_pkg AS
  -- Основная функция для обработки JSON-запросов
  FUNCTION process_json_query(p_json_data IN CLOB) 
  RETURN SYS_REFCURSOR;
  
  -- Вспомогательные функции для обработки разных типов запросов
  FUNCTION handle_select_query(p_json IN JSON_OBJECT_T) 
  RETURN VARCHAR2;
  
  FUNCTION build_where_clause(p_conditions IN JSON_ARRAY_T) 
  RETURN VARCHAR2;
  
  FUNCTION handle_dml_query(p_json IN JSON_OBJECT_T) 
  RETURN VARCHAR2;
  
  FUNCTION handle_ddl_query(p_json IN JSON_OBJECT_T) 
  RETURN VARCHAR2;
END dynamic_sql_pkg;
/

CREATE OR REPLACE PACKAGE BODY dynamic_sql_pkg AS
  -- Основная функция обработки JSON
  FUNCTION process_json_query(p_json_data IN CLOB) 
  RETURN SYS_REFCURSOR IS
    v_json          JSON_OBJECT_T;
    v_query_type    VARCHAR2(20);
    v_sql           VARCHAR2(32767);
    v_result_cursor SYS_REFCURSOR;
  BEGIN
    v_json := JSON_OBJECT_T.parse(p_json_data);
    v_query_type := v_json.get_String('queryType');
    
    CASE v_query_type
      WHEN 'SELECT' THEN
        v_sql := handle_select_query(v_json);
        OPEN v_result_cursor FOR v_sql;
        
      WHEN 'INSERT' THEN
        v_sql := handle_dml_query(v_json);
        EXECUTE IMMEDIATE v_sql;
        OPEN v_result_cursor FOR 
          SELECT 'DML query executed successfully' as result FROM dual;
          
      WHEN 'UPDATE' THEN
        v_sql := handle_dml_query(v_json);
        EXECUTE IMMEDIATE v_sql;
        OPEN v_result_cursor FOR 
          SELECT 'DML query executed successfully' as result FROM dual;
          
      WHEN 'DELETE' THEN
        v_sql := handle_dml_query(v_json);
        EXECUTE IMMEDIATE v_sql;
        OPEN v_result_cursor FOR 
          SELECT 'DML query executed successfully' as result FROM dual;
          
      WHEN 'CREATE TABLE' THEN
        v_sql := handle_ddl_query(v_json);
        EXECUTE IMMEDIATE v_sql;
        -- Создаем триггер для автоинкремента, если указан primaryKey
        IF v_json.get_String('primaryKey') IS NOT NULL THEN
          EXECUTE IMMEDIATE 
            'CREATE SEQUENCE seq_' || v_json.get_String('table') || '_' || 
            v_json.get_String('primaryKey') || ' START WITH 1 INCREMENT BY 1';
            
          EXECUTE IMMEDIATE 
            'CREATE OR REPLACE TRIGGER ' || v_json.get_String('table') || '_pk_trigger ' ||
            'BEFORE INSERT ON ' || v_json.get_String('table') || ' ' ||
            'FOR EACH ROW ' ||
            'BEGIN ' ||
            '  :NEW.' || v_json.get_String('primaryKey') || ' := seq_' || 
            v_json.get_String('table') || '_' || v_json.get_String('primaryKey') || '.NEXTVAL; ' ||
            'END;';
        END IF;
        OPEN v_result_cursor FOR 
          SELECT 'DDL query executed successfully' as result FROM dual;
          
      WHEN 'DROP TABLE' THEN
        v_sql := handle_ddl_query(v_json);
        EXECUTE IMMEDIATE v_sql;
        OPEN v_result_cursor FOR 
          SELECT 'DDL query executed successfully' as result FROM dual;
    END CASE;
    
    RETURN v_result_cursor;
  EXCEPTION
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20001, 'Error processing query: ' || SQLERRM);
  END process_json_query;

  -- Функция для обработки SELECT-запросов
  FUNCTION handle_select_query(p_json IN JSON_OBJECT_T) 
  RETURN VARCHAR2 IS
    v_sql VARCHAR2(32767);
    v_columns JSON_ARRAY_T;
    v_tables JSON_ARRAY_T;
    v_joins JSON_ARRAY_T;
    v_where JSON_OBJECT_T;
  BEGIN
    v_columns := p_json.get_Array('columns');
    v_tables := p_json.get_Array('tables');
    v_joins := p_json.get_Array('joins');
    
    -- Формируем SELECT часть
    v_sql := 'SELECT ' || 
             CASE WHEN v_columns IS NULL THEN '*' 
                  ELSE LISTAGG(v_columns.get_String(LEVEL), ', ')
                       WITHIN GROUP (ORDER BY LEVEL)
             END ||
             ' FROM ' || v_tables.get_String(0);
    
    -- Добавляем JOIN условия
    IF v_joins IS NOT NULL THEN
      FOR i IN 0 .. v_joins.get_size - 1 LOOP
        v_sql := v_sql || ' ' || 
                 v_joins.get_Object(i).get_String('type') || ' ' ||
                 v_joins.get_Object(i).get_String('table') || ' ON ' ||
                 v_joins.get_Object(i).get_String('condition');
      END LOOP;
    END IF;
    
    -- Добавляем WHERE условия
    v_where := p_json.get_Object('where');
    IF v_where IS NOT NULL THEN
      v_sql := v_sql || ' WHERE ' || build_where_clause(v_where.get_Array('conditions'));
    END IF;
    
    RETURN v_sql;
  END handle_select_query;

  -- Функция для построения WHERE условий
  FUNCTION build_where_clause(p_conditions IN JSON_ARRAY_T) 
  RETURN VARCHAR2 IS
    v_where VARCHAR2(32767);
    v_condition JSON_OBJECT_T;
    v_operator VARCHAR2(20);
    v_value VARCHAR2(4000);
  BEGIN
    FOR i IN 0 .. p_conditions.get_size - 1 LOOP
      v_condition := p_conditions.get_Object(i);
      
      -- Добавляем логический оператор
      IF i > 0 THEN
        v_where := v_where || ' ' || NVL(v_condition.get_String('logicalOperator'), 'AND') || ' ';
      END IF;
      
      v_operator := v_condition.get_String('operator');
      
      -- Обработка подзапросов
      IF v_operator LIKE '%IN%' THEN
        v_where := v_where || v_condition.get_String('column') || ' ' || 
                  v_operator || ' (' || 
                  handle_select_query(v_condition.get_Object('subquery')) || ')';
      ELSIF v_operator LIKE '%EXIST%' THEN
        v_where := v_where || v_operator || ' (' || 
                  handle_select_query(v_condition.get_Object('subquery')) || ')';
      ELSE
        -- Обработка простых условий
        v_value := v_condition.get_String('value');
        IF v_condition.get_String('type') = 'string' THEN
          v_value := '''' || v_value || '''';
        END IF;
        v_where := v_where || v_condition.get_String('column') || ' ' || 
                  v_operator || ' ' || v_value;
      END IF;
    END LOOP;
    
    RETURN v_where;
  END build_where_clause;

  -- Функция для обработки DML-запросов
  FUNCTION handle_dml_query(p_json IN JSON_OBJECT_T) 
  RETURN VARCHAR2 IS
    v_sql VARCHAR2(32767);
    v_query_type VARCHAR2(20);
    v_table VARCHAR2(128);
    v_columns JSON_ARRAY_T;
    v_values JSON_ARRAY_T;
    v_where JSON_OBJECT_T;
  BEGIN
    v_query_type := p_json.get_String('queryType');
    v_table := p_json.get_String('table');
    
    CASE v_query_type
      WHEN 'INSERT' THEN
        v_columns := p_json.get_Array('columns');
        v_values := p_json.get_Array('values');
        v_sql := 'INSERT INTO ' || v_table || ' (' ||
                 LISTAGG(v_columns.get_String(LEVEL), ', ') WITHIN GROUP (ORDER BY LEVEL) ||
                 ') VALUES (' ||
                 LISTAGG(v_values.get_String(LEVEL), ', ') WITHIN GROUP (ORDER BY LEVEL) || ')';
                 
      WHEN 'UPDATE' THEN
        v_sql := 'UPDATE ' || v_table || ' SET ';
        v_columns := p_json.get_Array('columns');
        v_values := p_json.get_Array('values');
        
        FOR i IN 0 .. v_columns.get_size - 1 LOOP
          IF i > 0 THEN v_sql := v_sql || ', '; END IF;
          v_sql := v_sql || v_columns.get_String(i) || ' = ' || v_values.get_String(i);
        END LOOP;
        
        v_where := p_json.get_Object('where');
        IF v_where IS NOT NULL THEN
          v_sql := v_sql || ' WHERE ' || build_where_clause(v_where.get_Array('conditions'));
        END IF;
        
      WHEN 'DELETE' THEN
        v_sql := 'DELETE FROM ' || v_table;
        v_where := p_json.get_Object('where');
        IF v_where IS NOT NULL THEN
          v_sql := v_sql || ' WHERE ' || build_where_clause(v_where.get_Array('conditions'));
        END IF;
    END CASE;
    
    RETURN v_sql;
  END handle_dml_query;

  -- Функция для обработки DDL-запросов
  FUNCTION handle_ddl_query(p_json IN JSON_OBJECT_T) 
  RETURN VARCHAR2 IS
    v_sql VARCHAR2(32767);
    v_query_type VARCHAR2(20);
    v_table VARCHAR2(128);
    v_columns JSON_ARRAY_T;
    v_column JSON_OBJECT_T;
  BEGIN
    v_query_type := p_json.get_String('queryType');
    v_table := p_json.get_String('table');
    
    IF v_query_type = 'CREATE TABLE' THEN
      v_sql := 'CREATE TABLE ' || v_table || ' (';
      v_columns := p_json.get_Array('columns');
      
      FOR i IN 0 .. v_columns.get_size - 1 LOOP
        v_column := v_columns.get_Object(i);
        IF i > 0 THEN v_sql := v_sql || ', '; END IF;
        
        v_sql := v_sql || v_column.get_String('name') || ' ' || 
                 v_column.get_String('type');
                 
        -- Добавляем ограничения, если есть
        IF v_column.get_Array('constraints') IS NOT NULL THEN
          FOR j IN 0 .. v_column.get_Array('constraints').get_size - 1 LOOP
            v_sql := v_sql || ' ' || v_column.get_Array('constraints').get_String(j);
          END LOOP;
        END IF;
      END LOOP;
      
      -- Добавляем табличные ограничения, если есть
      IF p_json.get_Array('constraints') IS NOT NULL THEN
        FOR i IN 0 .. p_json.get_Array('constraints').get_size - 1 LOOP
          v_sql := v_sql || ', ' || p_json.get_Array('constraints').get_String(i);
        END LOOP;
      END IF;
      
      v_sql := v_sql || ')';
    ELSIF v_query_type = 'DROP TABLE' THEN
      v_sql := 'DROP TABLE ' || v_table;
      IF p_json.get_Boolean('removeConstraints') THEN
        v_sql := v_sql || ' CASCADE CONSTRAINTS';
      END IF;
    END IF;
    
    RETURN v_sql;
  END handle_ddl_query;
END dynamic_sql_pkg;
/