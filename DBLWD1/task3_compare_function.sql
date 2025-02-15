CREATE FUNCTION parity_comparator
RETURN VARCHAR2
IS
    even_count NUMBER :=0 ; 
    odd_count NUMBER :=0 ;  
BEGIN
    SELECT COUNT(*) INTO even_count FROM MyTable WHERE MOD(val, 2) = 0;
    SELECT COUNT(*) INTO odd_count FROM MyTable WHERE MOD(val, 2) <> 0;
    
    IF even_count > odd_count THEN
        RETURN 'TRUE';
    ELSIF even_count < odd_count THEN
        RETURN 'FALSE';
    ELSE
        RETURN 'EQUAL';
    END IF;
END;

--SELECT parity_comparator() FROM dual;