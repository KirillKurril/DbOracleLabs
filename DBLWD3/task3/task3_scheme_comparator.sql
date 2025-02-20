CREATE OR REPLACE FUNCTION compare_schemas(
    dev_schema_name  IN VARCHAR2,
    prod_schema_name IN VARCHAR2
)RETURN CLOB AUTHID CURRENT_USER AS

    TYPE table_list IS TABLE OF VARCHAR2(128);
    sorted_tables  table_list := table_list();
    missing_tables table_list := table_list();
    tables_with_changes table_list := table_list();

    functions_to_add  table_list := table_list();
    procedures_to_add  table_list := table_list();
    packages_to_add  table_list := table_list();
    indexes_to_add  table_list := table_list();

    TYPE table_set IS TABLE OF BOOLEAN INDEX BY VARCHAR2(128);
    tables_with_changes_set table_set;
    visited table_set;
    stack table_set;

    TYPE dependency_table_type IS TABLE OF VARCHAR2(128);
    TYPE dependency_list IS TABLE OF dependency_table_type INDEX BY VARCHAR2(128);
    table_dependencies dependency_list;
    
    is_cycle BOOLEAN := FALSE;

    ddl_output_script CLOB := EMPTY_CLOB();

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
        obj_type VARCHAR2
    ) IS
        SELECT object_name 
        FROM all_objects 
        WHERE object_type = UPPER(obj_type)
            AND owner = UPPER(dev_schema_name)
        MINUS
        SELECT object_name 
        FROM all_objects 
        WHERE object_type = UPPER(obj_type)
        AND owner = UPPER(prod_schema_name);

    CURSOR common_object_cursor(
        obj_type VARCHAR2
    ) IS
        SELECT object_name 
        FROM all_objects 
        WHERE object_type = UPPER(obj_type)
            AND owner = UPPER(dev_schema_name)
        INTERSECT
        SELECT object_name 
        FROM all_objects 
        WHERE object_type = UPPER(obj_type)
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
        obj_name VARCHAR2, 
        obj_type VARCHAR2
    ) RETURN BOOLEAN IS
        dev_source   CLOB;
        prod_source  CLOB;
        
        CURSOR source_cursor(
            schema_name VARCHAR2
        ) IS
            SELECT LISTAGG(text, '') WITHIN GROUP (ORDER BY line) AS full_source
            FROM all_source
            WHERE name = obj_name
            AND type = UPPER(obj_type)
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
        obj_type VARCHAR2,
        collection IN OUT table_list,
        message VARCHAR2
    )
    IS
    BEGIN
        FOR rec IN missing_object_cursor(obj_type) LOOP
            IF UPPER(obj_type) = 'INDEX' AND rec.object_name LIKE 'SYS%' THEN
                CONTINUE;
            END IF;    
            DBMS_OUTPUT.PUT_LINE(message || rec.object_name );
            collection.EXTEND;
            collection(collection.LAST) := rec.object_name;
        END LOOP;
    END get_missing_objects;

------------                                                                        

    PROCEDURE get_alter_objects(
        obj_type VARCHAR2,
        collection IN OUT table_list,
        message VARCHAR2
    )
    IS
    BEGIN
        FOR rec IN common_object_cursor(obj_type) LOOP
            IF NOT compare_object_source(rec.object_name, obj_type) THEN
                DBMS_OUTPUT.PUT_LINE(message || rec.object_name);
                collection.EXTEND;
                collection(collection.LAST) := rec.object_name;
            END IF;
        END LOOP;
    END get_alter_objects;

-----------

    PROCEDURE get_ddl_for_object (
        obj_name     IN VARCHAR2,
        obj_type     IN VARCHAR2
    ) AS
        source_code CLOB:= EMPTY_CLOB();
        ddl_script  CLOB:= EMPTY_CLOB();
        name_entry_position NUMBER;
    BEGIN
        SELECT text
        INTO source_code
        FROM all_source
        WHERE name = UPPER(obj_name) 
            AND type = UPPER(obj_type)
            AND owner = UPPER(dev_schema_name) 
        ORDER BY line;

        name_entry_position := INSTR(source_code, obj_name);

        ddl_script := 'CREATE OR REPLACE ' || obj_type || ' C##PROD.' || obj_name;

        ddl_script := ddl_script || SUBSTR(source_code,name_entry_position + LENGTH(obj_name) + 1) || CHR(13) || CHR(10) || CHR(13) || CHR(10);

        DBMS_OUTPUT.PUT_LINE(ddl_script);

        ddl_output_script := ddl_output_script || ddl_script;

            IF UPPER(obj_type) = 'PACKAGE' THEN
                get_ddl_for_object(obj_name, 'PACKAGE BODY');
            END IF;
        
    END get_ddl_for_object;

-------------------------------------------------------------

PROCEDURE get_ddl_for_index(
    p_index_name IN VARCHAR2
) AS
    v_ddl_script CLOB := '';
    v_table_name VARCHAR2(128);
    v_column_list VARCHAR2(4000);
    v_uniqueness VARCHAR2(10);
    v_index_type VARCHAR2(20);
    v_logging VARCHAR2(10);
    v_compression VARCHAR2(10);
BEGIN

    SELECT 
        table_name, 
        uniqueness,
        index_type,
        logging,
        compression
    INTO 
        v_table_name, 
        v_uniqueness,
        v_index_type,
        v_logging,
        v_compression
    FROM all_indexes
    WHERE index_name = UPPER(p_index_name)
    AND owner = UPPER(dev_schema_name);

    SELECT 
        LISTAGG(column_name || DECODE(descend, 'DESC', ' DESC', ''), ', ')
        WITHIN GROUP (ORDER BY column_position)
    INTO v_column_list
    FROM all_ind_columns
    WHERE index_name = UPPER(p_index_name)
    AND index_owner = UPPER(p_dev_schema);

    v_ddl_script := 'DROP INDEX С##PROD.' || p_index_name || CHR(13) || CHR(10) || CHR(13) || CHR(10);

    v_ddl_script := v_ddl_script || 
        'CREATE ' || 
        CASE v_uniqueness 
            WHEN 'UNIQUE' THEN 'UNIQUE ' 
            ELSE '' 
        END ||
        'INDEX C##PROD.' || p_index_name || 
        ' ON C##PROD.' || v_table_name || 
        ' (' || v_column_list || ')' || CHR(13) || CHR(10);

    IF v_logging = 'NO' THEN
        v_ddl_script := v_ddl_script || 'NOLOGGING ' || CHR(13) || CHR(10);
    END IF;

    IF v_compression = 'ENABLED' THEN
        v_ddl_script := v_ddl_script || 'COMPRESS ' || CHR(13) || CHR(10);
    END IF;

    DBMS_OUTPUT.PUT_LINE(v_ddl_script);
    ddl_output_script := ddl_output_script || v_ddl_script;
END get_ddl_for_index;

-----------------------------------------------------------------------------

PROCEDURE get_alter_table_ddl(
    p_table_name VARCHAR2
) AS
    
    CURSOR column_diff IS
        SELECT 
            d.column_name, 
            d.data_type AS dev_type, 
            d.data_length AS dev_length,
            d.nullable AS dev_nullable,
            p.data_type AS prod_type, 
            p.data_length AS prod_length,
            p.nullable AS prod_nullable
        FROM 
            all_tab_columns d
        FULL OUTER JOIN 
            all_tab_columns p 
            ON (d.column_name = p.column_name 
                AND p.owner = UPPER(prod_schema_name)
                AND p.table_name = UPPER(p_table_name))
        WHERE 
            d.owner = UPPER(dev_schema_name)
            AND d.table_name = UPPER(p_table_name)
            AND (
                p.column_name IS NULL OR 
                d.data_type != p.data_type OR
                d.data_length > p.data_length OR  
                d.nullable != p.nullable  
            );

    v_alter_script CLOB := '';
    v_recreate_needed BOOLEAN := FALSE;
BEGIN
    
    FOR col IN column_diff LOOP
        IF col.prod_type IS NULL THEN
            v_alter_script := v_alter_script || 
                'ALTER TABLE ' || prod_schema_name || '.' || p_table_name || 
                ' ADD (' || col.column_name || ' ' || 
                col.dev_type || 
                CASE WHEN col.dev_length > 0 
                     THEN '(' || col.dev_length || ')' 
                     ELSE '' 
                END ||
                CASE WHEN col.dev_nullable = 'N' 
                     THEN ' NOT NULL' 
                     ELSE ' NULL' 
                END || ');' || CHR(13) || CHR(10);
        
        ELSIF col.dev_type IN ('VARCHAR2', 'CHAR', 'NVARCHAR2') 
              AND col.dev_length >= col.prod_length THEN
            v_alter_script := v_alter_script || 
                'ALTER TABLE ' || prod_schema_name || '.' || p_table_name || 
                ' MODIFY (' || col.column_name || 
                ' ' || col.dev_type || 
                '(' || col.dev_length || '));' || CHR(13) || CHR(10);
        
        ELSIF col.dev_nullable != col.prod_nullable THEN
            v_alter_script := v_alter_script || 
                'ALTER TABLE ' || prod_schema_name || '.' || p_table_name || 
                ' MODIFY (' || col.column_name || 
                CASE WHEN col.dev_nullable = 'N' 
                     THEN ' NOT NULL);' 
                     ELSE ' NULL);' 
                END || CHR(13) || CHR(10);
        
        ELSIF col.dev_type IN ('NUMBER', 'INTEGER', 'DECIMAL')
              AND col.prod_type IN ('NUMBER', 'INTEGER', 'DECIMAL') THEN
            v_alter_script := v_alter_script || 
                'ALTER TABLE ' || prod_schema_name || '.' || p_table_name || 
                ' MODIFY (' || col.column_name || 
                ' ' || col.dev_type || 
                CASE WHEN col.dev_length > 0 
                     THEN '(' || col.dev_length || ')' 
                     ELSE '' 
                END || ');' || CHR(13) || CHR(10);
        
        ELSE
            v_recreate_needed := TRUE;
            EXIT;
        END IF;
    END LOOP;

    IF v_recreate_needed THEN
        get_table_ddl(p_table_name);
    ELSE
        ddl_output_script := ddl_output_script || v_alter_script || CHR(13) || CHR(10);
        DBMS_OUTPUT.PUT_LINE(v_alter_script);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка при изменении таблицы: ' || SQLERRM);
END compare_and_alter_table;

--------------------------------------------------------

PROCEDURE get_table_ddl(
    p_table_name IN VARCHAR2
) AS
    v_ddl CLOB;
BEGIN
    DBMS_METADATA.SET_TRANSFORM_PARAM(
        DBMS_METADATA.SESSION_TRANSFORM, 
        'CONSTRAINTS', 
        TRUE
    );

    v_ddl := 'DROP TABLE ' || prod_schema_name || '.' || p_table_name || ' CASCADE CONSTRAINTS;' || CHR(13) || CHR(10);
    
    v_ddl := v_ddl || REPLACE(
        DBMS_METADATA.GET_DDL('TABLE', p_table_name, dev_schema_name), 
        dev_schema_name, 
        prod_schema_name
    );
    
    DBMS_OUTPUT.PUT_LINE(v_ddl);
    ddl_output_script := ddl_output_script || v_ddl || CHR(13) || CHR(10);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка: ' || p_table_name || ' - ' || SQLERRM);
END;

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

    get_missing_objects('FUNCTION', functions_to_add, 'Отсутствующая в prod функция: ');
    get_missing_objects('PROCEDURE', procedures_to_add, 'Отсутствующая в prod процедура: ');
    get_missing_objects('PACKAGE', packages_to_add, 'Отсутствующий в prod пакет: ');
    get_missing_objects('INDEX', indexes_to_add, 'Отсутствующий в prod индекс: ');

-------------------------------------------------------------------------------

    get_alter_objects('FUNCTION', functions_to_add, 'Функция с отличной реализацией: ');
    get_alter_objects('PROCEDURE', procedures_to_add, 'Процедура с отличной реализацией: ');
    get_alter_objects('PACKAGE', packages_to_add, 'Пакет с отличной реализацией: ');
    get_alter_objects('INDEX', indexes_to_add, 'Индекс с отличной реализацией: ');

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
        RETURN ddl_output_script;
    ELSE
        DBMS_OUTPUT.PUT_LINE('=== Очередность создания таблиц ===');
        FOR i IN 1..sorted_tables.COUNT LOOP
            DBMS_OUTPUT.PUT_LINE(sorted_tables(i));
        END LOOP;
    END IF;

    FOR i IN 1..sorted_tables.COUNT LOOP
        IF sorted_tables(i) MEMBER OF missing_tables THEN
            get_table_ddl(sorted_tables(i));
        ELSE
            get_alter_table_ddl(sorted_tables(i));
        END IF;
    END LOOP;

    FOR i IN 1..indexes_to_add.COUNT LOOP
        get_ddl_for_index(indexes_to_add(i));
    END LOOP;

    FOR i IN 1..functions_to_add.COUNT LOOP
        get_ddl_for_object(functions_to_add(i));
    END LOOP;

    FOR i IN 1..procedures_to_add.COUNT LOOP
        get_ddl_for_object(procedures_to_add(i));
    END LOOP;

    FOR i IN 1..indexes_to_add.COUNT LOOP
        get_ddl_for_object(indexes_to_add(i));
    END LOOP;

    RETURN ddl_output_script;

END compare_schemas;
