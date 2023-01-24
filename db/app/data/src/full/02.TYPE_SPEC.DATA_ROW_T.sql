CREATE TYPE "DATA_ROW_T" AS OBJECT (
  table_owner varchar2(128 char)
, table_name varchar2(128 char)
, key anydata
, scn number -- DBMS_FLASHBACK.GET_SYSTEM_CHANGE_NUMBER
)
not instantiable
not final;
/

