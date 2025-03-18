CREATE OR REPLACE FUNCTION Parse(source_path IN VARCHAR2) RETURN VARCHAR2 IS
    v_source CLOB;
    v_json CLOB;
    v_query_type VARCHAR2(50);
    v_response VARCHAR2(4000);
BEGIN
    v_source := ReadFile(source_path);
    v_json := ParseJson(v_source);
    
    v_query_type := JsonGetValue(v_json, 'queryType');
    
    CASE v_query_type 
        WHEN 'SELECT' THEN
            v_response := ExecuteSelectQuery(CreateSelectQuery(v_json));
        
        WHEN 'CREATE TABLE' THEN
            v_response := ExecuteDdlQuery(CreateCreateTableQuery(v_json));
        
        WHEN 'DROP TABLE' THEN
            v_response := ExecuteDdlQuery(CreateDropTableQuery(v_json));
        
        WHEN 'INSERT' THEN
            v_response := ExecuteDmlQuery(CreateInsertQuery(v_json));
        
        WHEN 'UPDATE' THEN
            v_response := ExecuteDmlQuery(CreateUpdateQuery(v_json));
        
        WHEN 'DELETE' THEN
            v_response := ExecuteDmlQuery(CreateDeleteQuery(v_json));
        
        ELSE
            v_response := 'Wrong prompt file format!';
    END CASE;
    
    RETURN v_response;
END Parse;

CREATE OR REPLACE PROCEDURE ExecuteSelectQuery(p_query IN VARCHAR2, p_result OUT CLOB) AS
    v_cursor SYS_REFCURSOR;
    v_row VARCHAR2(4000);
    v_results CLOB;
BEGIN
    DBMS_OUTPUT.PUT_LINE(p_query);
    OPEN v_cursor FOR p_query;
    
    v_results := '';
    
    LOOP
        FETCH v_cursor INTO v_row;
        EXIT WHEN v_cursor%NOTFOUND;
        v_results := v_results || v_row || CHR(10);
    END LOOP;
    
    CLOSE v_cursor;
    p_result := v_results;
EXCEPTION
    WHEN OTHERS THEN
        p_result := 'Select query error: ' || SQLERRM;
        IF v_cursor%ISOPEN THEN
            CLOSE v_cursor;
        END IF;
END ExecuteSelectQuery;

CREATE OR REPLACE PROCEDURE ExecuteDdlQuery(p_queries IN SYS.ODCIVARCHAR2LIST, p_result OUT VARCHAR2) AS
BEGIN
    FOR i IN 1 .. p_queries.COUNT LOOP
        BEGIN
            EXECUTE IMMEDIATE p_queries(i);
            DBMS_OUTPUT.PUT_LINE(p_queries(i));
        EXCEPTION
            WHEN OTHERS THEN
                p_result := 'DDL error: ' || SQLERRM;
                RETURN;
        END;
    END LOOP;
    p_result := 'DDL query executed successfully';
EXCEPTION
    WHEN OTHERS THEN
        p_result := 'DDL query execution error: ' || SQLERRM;
END ExecuteDdlQuery;

CREATE OR REPLACE PROCEDURE ExecuteDmlQuery(p_query IN VARCHAR2, p_result OUT VARCHAR2) AS
    v_affected_rows NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE(p_query);
    EXECUTE IMMEDIATE p_query;
    v_affected_rows := SQL%ROWCOUNT;
    p_result := 'DML query executed successfully\n ' || v_affected_rows || ' lines affected';
EXCEPTION
    WHEN OTHERS THEN
        p_result := 'DML query execution error: ' || SQLERRM;
END ExecuteDmlQuery;


