CREATE TABLE "GROUPS" (
    ID NUMBER,    
    NAME VARCHAR2(100),       
    C_VAL NUMBER              
);

CREATE TABLE STUDENTS (
    ID NUMBER,    
    NAME VARCHAR2(100),       
    GROUP_ID NUMBER
);

CREATE TABLE UNIFIED_AUDIT (
    AUDIT_ID NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ENTITY_TYPE VARCHAR2(10) NOT NULL, 
    ENTITY_ID NUMBER NOT NULL,
    ENTITY_NAME VARCHAR2(100) NOT NULL,
    GROUP_ID NUMBER,
    С_VAL NUMBER,
    ACTION_TYPE VARCHAR2(10) NOT NULL,
    ACTION_DATE TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    OLD_ENTITY_NAME VARCHAR2(100),
    OLD_GROUP_ID NUMBER,
    OLD_C_VAL NUMBER 
);

CREATE SEQUENCE student_id_seq
START WITH 1          
INCREMENT BY 1        
NOCACHE;

CREATE SEQUENCE group_id_seq
START WITH 1          
INCREMENT BY 1        
NOCACHE;


CREATE OR REPLACE PACKAGE trigger_state AS
    cascade_delete_students_is_active BOOLEAN := FALSE;
END;