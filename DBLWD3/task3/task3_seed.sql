PROCEDURE compare_and_alter_table(
    dev_schema_name IN VARCHAR2,
    prod_schema_name IN VARCHAR2
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
        get_ddl_for_table(p_table_name, dev_schema_name, prod_schema_name);
    ELSE
        ddl_output_script := ddl_output_script || v_alter_script || CHR(13) || CHR(10);
        DBMS_OUTPUT.PUT_LINE(v_alter_script);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка при изменении таблицы: ' || SQLERRM);
END compare_and_alter_table;