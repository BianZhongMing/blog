SELECT ROUTINE_NAME, ROUTINE_DEFINITION 
FROM INFORMATION_SCHEMA.ROUTINES 
WHERE ROUTINE_DEFINITION LIKE '%text%' 
AND ROUTINE_TYPE='PROCEDURE' --'FUNCTION'
and ROUTINE_NAME='����'