drop table C##DEV.EMP_DEPT;
drop table C##DEV.EMPLOYEES;
drop table C##DEV.DEPARTMENTS;
drop table C##DEV.SALARIES;

drop index C##DEV.IDX_EMPLOYEE_DEPT;
drop index C##DEV.IDX_EMPLOYEE_NAME;

drop package C##DEV.COMMON_PACKAGE;
drop package C##DEV.PKG_OPERATIONS;
drop package C##DEV.PKG_UTILS;

drop procedure C##DEV.CALCULATE_SALARY_BONUS;
drop procedure C##DEV.COMMON_PROCEDURE;
drop procedure C##DEV.UPDATE_SALARY;

drop function C##DEV.CALCULATE_BONUS;
drop function C##DEV.COMMON_FUNCTION;
drop function C##DEV.GET_DEV_VALUE;

drop table C##PROD.EMP_DEPT;
drop table C##PROD.EMPLOYEES;
drop table C##PROD.DEPARTMENTS;
drop table C##PROD.SALARIES;
drop table C##PROD.UNNEEDED;

drop index C##PROD.IDX_EMPLOYEE_NAME;
drop index C##PROD.IDX_EMPLOYEE_DEPT;

drop package C##PROD.COMMON_PACKAGE;
drop package C##PROD.PKG_OPERATIONS;
drop package C##PROD.PKG_UTILS;

drop procedure C##PROD.CALCULATE_SALARY_BONUS;
drop procedure C##PROD.COMMON_PROCEDURE;
drop procedure C##PROD.UPDATE_SALARY;

drop function C##PROD.CALCULATE_BONUS;
drop function C##PROD.COMMON_FUNCTION;
drop function C##PROD.GET_DEV_VALUE;

