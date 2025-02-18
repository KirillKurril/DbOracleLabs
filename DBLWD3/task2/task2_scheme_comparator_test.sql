CREATE OR REPLACE PROCEDURE compare_schemas(
    dev_schema_name  IN VARCHAR2,
    prod_schema_name IN VARCHAR2
) AUTHID CURRENT_USER AS

    TYPE table_list IS TABLE OF VARCHAR2(128);
    sorted_tables  table_list := table_list();
    missing_tables table_list := table_list();
    tables_with_changes table_list := table_list();

    TYPE table_set IS TABLE OF BOOLEAN INDEX BY VARCHAR2(128);
    tables_with_changes_set table_set;
    visited table_set;
    stack table_set;

    TYPE dependency_table_type IS TABLE OF VARCHAR2(128);
    TYPE dependency_list IS TABLE OF dependency_table_type INDEX BY VARCHAR2(128);
    table_dependencies dependency_list;
    
    is_cycle BOOLEAN := FALSE;

    -- Коллекции для списков объектов
    TYPE object_list IS TABLE OF VARCHAR2(128);
    TYPE source_list IS TABLE OF CLOB;

    -- Списки для функций
    dev_functions  object_list := object_list();
    prod_functions object_list := object_list();
    missing_functions object_list := object_list();
    changed_functions object_list := object_list();
    
    -- Списки для процедур
    dev_procedures  object_list := object_list();
    prod_procedures object_list := object_list();
    missing_procedures object_list := object_list();
    changed_procedures object_list := object_list();
    
    -- Списки для пакетов
    dev_packages  object_list := object_list();
    prod_packages object_list := object_list();
    missing_packages object_list := object_list();
    changed_packages object_list := object_list();
    
    -- Списки для индексов
    dev_indexes  object_list := object_list();
    prod_indexes object_list := object_list();
    missing_indexes object_list := object_list();
    changed_indexes object_list := object_list();

    -- Коллекции для хранения исходного кода
    dev_function_sources  source_list := source_list();
    prod_function_sources source_list := source_list();
    dev_procedure_sources source_list := source_list();
    prod_procedure_sources source_list := source_list();
    dev_package_sources   source_list := source_list();
    prod_package_sources  source_list := source_list();

    CURSOR tbl_cursor IS
        SELECT table_name 
        FROM all_tables 
        WHERE owner = UPPER(dev_schema_name)
        MINUS
        SELECT table_name 
        FROM all_tables 
        WHERE owner = UPPER(prod_schema_name);
        
    CURSOR altered_cursor IS
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
    
    CURSOR fk_cursor IS
        SELECT DISTINCT a.table_name, c_pk.table_name AS referenced_table
        FROM all_constraints a
        JOIN all_cons_columns col ON a.constraint_name = col.constraint_name 
                                  AND col.owner = UPPER(dev_schema_name)
        JOIN all_constraints c_pk ON a.r_constraint_name = c_pk.constraint_name 
                                  AND c_pk.owner = UPPER(dev_schema_name)
        WHERE a.constraint_type = 'R'
          AND a.owner = UPPER(dev_schema_name)
          AND a.table_name != c_pk.table_name  
    ORDER BY a.table_name, referenced_table;

    -- Курсоры для функций
    CURSOR function_cursor IS
        SELECT object_name 
        FROM all_objects 
        WHERE object_type = 'FUNCTION'
          AND owner = UPPER(dev_schema_name)
        MINUS
        SELECT object_name 
        FROM all_objects 
        WHERE object_type = 'FUNCTION'
          AND owner = UPPER(prod_schema_name);

    CURSOR function_source_cursor IS
        SELECT name, text
        FROM all_source
        WHERE type = 'FUNCTION'
          AND owner = UPPER(dev_schema_name)
        ORDER BY line;

    -- Курсоры для процедур
    CURSOR procedure_cursor IS
        SELECT object_name 
        FROM all_procedures 
        WHERE owner = UPPER(dev_schema_name)
        MINUS
        SELECT object_name 
        FROM all_procedures 
        WHERE owner = UPPER(prod_schema_name);

    CURSOR procedure_source_cursor IS
        SELECT name, text
        FROM all_source
        WHERE type = 'PROCEDURE'
          AND owner = UPPER(dev_schema_name)
        ORDER BY line;

    -- Курсоры для пакетов
    CURSOR package_cursor IS
        SELECT object_name 
        FROM all_objects 
        WHERE object_type = 'PACKAGE'
          AND owner = UPPER(dev_schema_name)
        MINUS
        SELECT object_name 
        FROM all_objects 
        WHERE object_type = 'PACKAGE'
          AND owner = UPPER(prod_schema_name);

    CURSOR package_source_cursor IS
        SELECT name, text
        FROM all_source
        WHERE type IN ('PACKAGE', 'PACKAGE BODY')
          AND owner = UPPER(dev_schema_name)
        ORDER BY name, type, line;

    -- Курсоры для индексов
    CURSOR index_cursor IS
        SELECT index_name, table_name, index_type
        FROM all_indexes 
        WHERE owner = UPPER(dev_schema_name)
        MINUS
        SELECT index_name, table_name, index_type
        FROM all_indexes 
        WHERE owner = UPPER(prod_schema_name);

    PROCEDURE topo_sort(tbl_name VARCHAR2) IS
        dep_table VARCHAR2(128);
    BEGIN
        IF visited.EXISTS(tbl_name) THEN
            RETURN;
        END IF;

        IF stack.EXISTS(tbl_name) THEN
            is_cycle := TRUE;
            RETURN;
        END IF;

        stack(tbl_name) := TRUE;

        IF table_dependencies.EXISTS(tbl_name) THEN
            FOR i IN 1..table_dependencies(tbl_name).COUNT LOOP
                dep_table := table_dependencies(tbl_name)(i);
                topo_sort(dep_table);
            END LOOP;
        END IF;

        stack.DELETE(tbl_name);
        visited(tbl_name) := TRUE;
        sorted_tables.EXTEND;
        sorted_tables(sorted_tables.LAST) := tbl_name;
    END topo_sort;
    
BEGIN
    DBMS_OUTPUT.PUT_LINE('Сравнение схем: ' || UPPER(dev_schema_name) || ' vs ' || UPPER(prod_schema_name));

    FOR rec IN tbl_cursor LOOP
        DBMS_OUTPUT.PUT_LINE('Найдена отсутствующая таблица: ' || rec.table_name);
        
        missing_tables.EXTEND;
        missing_tables(missing_tables.LAST) := rec.table_name;

    END LOOP;

    FOR rec IN altered_cursor LOOP
        DBMS_OUTPUT.PUT_LINE('Отсутствует в PROD или были изменена : ' || rec.table_name || '.' || rec.column_name || 
                             ' (' || rec.data_type || '(' || rec.data_length || '))');
        
        IF NOT tables_with_changes_set.EXISTS(rec.table_name) THEN
            tables_with_changes_set(rec.table_name) := TRUE; 
            tables_with_changes.EXTEND;
            tables_with_changes(tables_with_changes.LAST) := rec.table_name;
        END IF;

    END LOOP;

  DBMS_OUTPUT.PUT_LINE('Поиск зависимостей между таблицами...');
    FOR rec IN fk_cursor LOOP
        DBMS_OUTPUT.PUT_LINE('Зависимость: ' || rec.table_name || ' → ' || rec.referenced_table);
        
        IF NOT table_dependencies.EXISTS(rec.table_name) THEN
            table_dependencies(rec.table_name) := dependency_table_type();
        END IF;
        
        DECLARE
            dependency_exists BOOLEAN := FALSE;
        BEGIN
            FOR i IN 1..table_dependencies(rec.table_name).COUNT LOOP
                IF table_dependencies(rec.table_name)(i) = rec.referenced_table THEN
                    dependency_exists := TRUE;
                    EXIT;
                END IF;
            END LOOP;
            
            IF NOT dependency_exists THEN
                table_dependencies(rec.table_name).EXTEND;
                table_dependencies(rec.table_name)(table_dependencies(rec.table_name).LAST) := rec.referenced_table;
            END IF;
        END;
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('Топологическая сортировка...');
    FOR i IN 1..missing_tables.COUNT LOOP
        topo_sort(missing_tables(i));
    END LOOP;   

    FOR i IN 1..tables_with_changes.COUNT LOOP
        topo_sort(tables_with_changes(i));
    END LOOP;

    -- Сравнение функций
    FOR rec IN function_cursor LOOP
        DBMS_OUTPUT.PUT_LINE('Найдена отсутствующая функция: ' || rec.object_name);
        
        missing_functions.EXTEND;
        missing_functions(missing_functions.LAST) := rec.object_name;

    END LOOP;

    -- Сравнение процедур
    FOR rec IN procedure_cursor LOOP
        DBMS_OUTPUT.PUT_LINE('Найдена отсутствующая процедура: ' || rec.object_name);
        
        missing_procedures.EXTEND;
        missing_procedures(missing_procedures.LAST) := rec.object_name;

    END LOOP;

    -- Сравнение пакетов
    FOR rec IN package_cursor LOOP
        DBMS_OUTPUT.PUT_LINE('Найден отсутствующий пакет: ' || rec.object_name);
        
        missing_packages.EXTEND;
        missing_packages(missing_packages.LAST) := rec.object_name;

    END LOOP;

    -- Сравнение индексов
    FOR rec IN index_cursor LOOP
        DBMS_OUTPUT.PUT_LINE('Найден отсутствующий индекс: ' || rec.index_name);
        
        missing_indexes.EXTEND;
        missing_indexes(missing_indexes.LAST) := rec.index_name;

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
