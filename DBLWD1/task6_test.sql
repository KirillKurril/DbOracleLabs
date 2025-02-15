DECLARE
    v_reward NUMBER;
BEGIN
    v_reward := calculate_year_salary(-1000, 10);  
    DBMS_OUTPUT.PUT_LINE('Calculated Reward: ' || v_reward);
    
     v_reward := calculate_year_salary(5000, 120); 
    DBMS_OUTPUT.PUT_LINE('Calculated Reward: ' || v_reward);
    
     v_reward := calculate_year_salary(5000, 10);  
    DBMS_OUTPUT.PUT_LINE('Calculated Reward: ' || v_reward);
    
    v_reward := calculate_year_salary('five thousand', 10);  
    DBMS_OUTPUT.PUT_LINE('Calculated Reward: ' || v_reward);
    
END;
