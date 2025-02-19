CREATE OR REPLACE PROCEDURE compare_schemas(
    dev_schema_name  IN VARCHAR2,
    prod_schema_name IN VARCHAR2
) AUTHID CURRENT_USER AS

    TYPE table_list IS TABLE OF VARCHAR2(128);
    sorted_tables  table_list := table_list();
    missing_tables table_list := table_list();
    tables_with_changes table_list := table_list();

    functions_to_create_or_replace  table_list := table_list();
    procedures_to_create_or_replace  table_list := table_list();
    packages_to_create_or_replace  table_list := table_list();
    indexes_to_create_or_replace  table_list := table_list();

    functions_with_changes  table_list := table_list();
    procedures_with_changes  table_list := table_list();
    packages_with_changes  table_list := table_list();
    indexes_with_changes  table_list := table_list();

    TYPE table_set IS TABLE OF BOOLEAN INDEX BY VARCHAR2(128);
    tables_with_changes_set table_set;
    visited table_set;
    stack table_set;

    TYPE dependency_table_type IS TABLE OF VARCHAR2(128);
    TYPE dependency_list IS TABLE OF dependency_table_type INDEX BY VARCHAR2(128);
    table_dependencies dependency_list;
    
    is_cycle BOOLEAN := FALSE;

    TYPE object_list IS TABLE OF VARCHAR2(128);
    TYPE source_list IS TABLE OF CLOB;

--------------------------------------------------------------------------------------------------------------

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

    CURSOR missing_object_cursor(
        object_type VARCHAR2
    ) IS
        SELECT object_name 
        FROM all_objects 
        WHERE object_type = UPPER(object_type)
            AND owner = UPPER(dev_schema_name)
        MINUS
        SELECT object_name 
        FROM all_objects 
        WHERE object_type = UPPER(object_type)
        AND owner = UPPER(prod_schema_name);

    CURSOR common_object_cursor(
        object_type VARCHAR2
    ) IS
        SELECT object_name 
        FROM all_objects 
        WHERE object_type = UPPER(object_type)
            AND owner = UPPER(dev_schema_name)
        INTERSECT
        SELECT object_name 
        FROM all_objects 
        WHERE object_type = UPPER(object_type)
        AND owner = UPPER(prod_schema_name);

---------------------------------------------------------------------------------------

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

------------

    FUNCTION compare_object_source(
        object_name VARCHAR2, 
        object_type VARCHAR2
    ) RETURN BOOLEAN IS
        dev_source   CLOB;
        prod_source  CLOB;
        
        CURSOR source_cursor(
            schema_name VARCHAR2
        ) IS
            SELECT LISTAGG(text, '') WITHIN GROUP (ORDER BY line) AS full_source
            FROM all_source
            WHERE name = object_name
            AND type = UPPER(object_type)
            AND owner = UPPER(schema_name);
        
    BEGIN

        OPEN source_cursor(dev_schema_name);
            FETCH source_cursor INTO dev_source;
        CLOSE source_cursor;
        
        OPEN source_cursor(prod_schema_name);
            FETCH source_cursor INTO prod_source;
        CLOSE source_cursor;
        
        dev_source  := REGEXP_REPLACE(UPPER(dev_source), '\s+|--.*$', '', 1, 0, 'm');
        prod_source := REGEXP_REPLACE(UPPER(prod_source), '\s+|--.*$', '', 1, 0, 'm');
        
        RETURN dev_source = prod_source;

    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END compare_object_source;    

------------

    PROCEDURE get_missing_objects(
        object_type VARCHAR2,
        collection IN OUT table_list,
        message VARCHAR2
    )
    IS
    BEGIN
        FOR rec IN missing_object_cursor(object_type) LOOP
            DBMS_OUTPUT.PUT_LINE(message || rec.object_name);
            collection.EXTEND;
            collection(collection.LAST) := rec.object_name;
        END LOOP;
    END get_missing_objects;

------------                                                                        

    PROCEDURE get_alter_objects(
        object_type VARCHAR2,
        collection IN OUT table_list,
        message VARCHAR2
    )
    IS
    BEGIN
        FOR rec IN common_object_cursor(object_type) LOOP
            IF NOT compare_object_source(rec.object_name, object_type) THEN
                DBMS_OUTPUT.PUT_LINE(message || rec.object_name);
                collection.EXTEND;
                collection(collection.LAST) := rec.object_name;
            END IF;
        END LOOP;
    END get_alter_objects;


--====================================================================================================        
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

-------------------------------------------------------------------------------    

    get_missing_objects('FUNCTION', functions_to_create_or_replace, 'Отсутствующая в prod функция: ');
    get_missing_objects('PROCEDURE', procedures_to_create_or_replace, 'Отсутствующая в prod процедура: ');
    get_missing_objects('PACKAGE', packages_to_create_or_replace, 'Отсутствующий в prod пакет: ');
    get_missing_objects('INDEX', indexes_to_create_or_replace, 'Отсутствующий в prod индекс: ');

-------------------------------------------------------------------------------

    get_alter_objects('FUNCTION', functions_with_changes, 'Функция с отличной реализацией: ');
    get_alter_objects('PROCEDURE', procedures_with_changes, 'Процедура с отличной реализацией: ');
    get_alter_objects('PACKAGE', packages_with_changes, 'Пакет с отличной реализацией: ');
    get_alter_objects('INDEX', indexes_with_changes, 'Индекс с отличной реализацией: ');

----------------------------------------------------------------------------------------

    DBMS_OUTPUT.PUT_LINE('Топологическая сортировка...');
    FOR i IN 1..missing_tables.COUNT LOOP
        topo_sort(missing_tables(i));
    END LOOP;   

    FOR i IN 1..tables_with_changes.COUNT LOOP
        topo_sort(tables_with_changes(i));
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
