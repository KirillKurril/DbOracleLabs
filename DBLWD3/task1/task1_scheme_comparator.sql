CREATE OR REPLACE PROCEDURE compare_schemas(
    dev_schema_name  IN VARCHAR2,
    prod_schema_name IN VARCHAR2
) AUTHID CURRENT_USER AS
    TYPE table_list IS TABLE OF VARCHAR2(128);
    missing_tables table_list := table_list();
    altered_tables table_list := table_list();
    tables_with_changes table_list := table_list(); 

    sorted_tables  table_list := table_list();
    
    CURSOR tbl_cursor IS
        SELECT table_name 
        FROM all_tables 
        WHERE owner = UPPER(dev_schema_name)
        MINUS
        SELECT table_name 
        FROM all_tables 
        WHERE owner = UPPER(prod_schema_name);
        
    CURSOR missing_columns_cursor IS
        SELECT d.table_name, d.column_name, d.data_type, d.data_length
        FROM all_tab_columns d
        WHERE d.owner = UPPER(dev_schema_name)
          AND d.table_name NOT IN (SELECT table_name FROM all_tables WHERE owner = UPPER(dev_schema_name) 
                                   MINUS 
                                   SELECT table_name FROM all_tables WHERE owner = UPPER(prod_schema_name))
        MINUS
        SELECT p.table_name, p.column_name, p.data_type, p.data_length
        FROM all_tab_columns p
        WHERE p.owner = UPPER(prod_schema_name);        
    
    CURSOR altered_cursor IS
        SELECT DISTINCT d.table_name, d.column_name, d.data_type, d.data_length, 
                        p.data_type AS prod_data_type, p.data_length AS prod_data_length
        FROM all_tab_columns d
        JOIN all_tab_columns p
            ON d.table_name = p.table_name
            AND d.column_name = p.column_name
        WHERE d.owner = UPPER(dev_schema_name)
          AND p.owner = UPPER(prod_schema_name)
          AND (d.data_type != p.data_type OR d.data_length != p.data_length);

    CURSOR fk_cursor IS
        SELECT a.table_name, c_pk.table_name AS referenced_table
        FROM all_constraints a
        JOIN all_cons_columns col ON a.constraint_name = col.constraint_name
        JOIN all_constraints c_pk ON a.r_constraint_name = c_pk.constraint_name
        WHERE a.constraint_type = 'R'
          AND a.owner = UPPER(dev_schema_name);
    
    v_table_name VARCHAR2(128);
    v_ref_table  VARCHAR2(128);
    v_column_name VARCHAR2(128);
    v_data_type VARCHAR2(128);
    v_data_length NUMBER;
    v_prod_data_type VARCHAR2(128);
    v_prod_data_length NUMBER;

    TYPE dependency_map IS TABLE OF VARCHAR2(128) INDEX BY VARCHAR2(128);
    table_dependencies dependency_map;
    visited dependency_map;
    is_cycle BOOLEAN := FALSE;

    PROCEDURE topo_sort(tbl_name VARCHAR2) IS
    BEGIN
        IF visited.EXISTS(tbl_name) THEN
            is_cycle := TRUE;
            RETURN;
        END IF;
        visited(tbl_name) := '1';
        IF table_dependencies.EXISTS(tbl_name) THEN
            topo_sort(table_dependencies(tbl_name));
        END IF;
        sorted_tables.EXTEND;
        sorted_tables(sorted_tables.LAST) := tbl_name;
    END topo_sort;
    
BEGIN
    DBMS_OUTPUT.PUT_LINE('Сравнение схем: ' || UPPER(dev_schema_name) || ' vs ' || UPPER(prod_schema_name));

    DBMS_OUTPUT.PUT_LINE('Поиск отсутствующих таблиц...');
    DBMS_OUTPUT.PUT_LINE('Проверка курсора tbl_cursor...' || tbl_cursor );

    FOR rec IN tbl_cursor LOOP
        DBMS_OUTPUT.PUT_LINE('Найдена отсутствующая таблица: ' || rec.table_name);
        missing_tables.EXTEND;
        missing_tables(missing_tables.LAST) := rec.table_name;
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('Поиск таблиц с изменённой структурой...');
    FOR rec IN altered_cursor LOOP
        DBMS_OUTPUT.PUT_LINE('Изменена таблица: ' || rec.table_name || ', колонка: ' || rec.column_name || 
                             ' (' || rec.data_type || '(' || rec.data_length || ') → ' || 
                             rec.prod_data_type || '(' || rec.prod_data_length || '))');
        altered_tables.EXTEND;
        altered_tables(altered_tables.LAST) := rec.table_name;
        tables_with_changes.EXTEND;
        tables_with_changes(tables_with_changes.LAST) := rec.table_name;
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('Поиск отсутствующих колонок...');
    FOR rec IN missing_columns_cursor LOOP
        DBMS_OUTPUT.PUT_LINE('В Prod отсутствует колонка: ' || rec.table_name || '.' || rec.column_name || 
                             ' (' || rec.data_type || '(' || rec.data_length || '))');
        altered_tables.EXTEND;
        altered_tables(altered_tables.LAST) := rec.table_name;
        tables_with_changes.EXTEND;
        tables_with_changes(tables_with_changes.LAST) := rec.table_name;
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('Поиск зависимостей между таблицами...');
    FOR rec IN fk_cursor LOOP
        DBMS_OUTPUT.PUT_LINE('Зависимость: ' || rec.table_name || ' → ' || rec.referenced_table);
        table_dependencies(rec.table_name) := rec.referenced_table;
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('Топологическая сортировка...');
    FOR i IN 1..missing_tables.COUNT LOOP
        topo_sort(missing_tables(i));
    END LOOP;   

    FOR i IN 1..tables_with_changes.COUNT LOOP
        topo_sort(tables_with_changes(i));
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('=== Таблицы, отсутствующие в Prod ===');
    FOR i IN 1..missing_tables.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE(missing_tables(i));
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('=== Таблицы с измененной структурой ===');
    FOR i IN 1..altered_tables.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE(altered_tables(i));
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('=== Таблицы с отсутствующими колонками ===');
    FOR i IN 1..tables_with_changes.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE(tables_with_changes(i));
    END LOOP;

    IF is_cycle THEN
        DBMS_OUTPUT.PUT_LINE('Обнаружены закольцованные связи!');
    ELSE
        DBMS_OUTPUT.PUT_LINE('=== Очередность создания таблиц ===');
        FOR i IN 1..sorted_tables.COUNT LOOP
            DBMS_OUTPUT.PUT_LINE(sorted_tables(i));
        END LOOP;
    END IF;

END compare_schemas;
