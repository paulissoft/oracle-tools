begin
  execute immediate 'CREATE TYPE "ORACLE_TOOLS"."T_OBJECT_INFO_REC" AUTHID DEFINER AS OBJECT
(OBJECT_SCHEMA VARCHAR2(128 CHAR),
OBJECT_TYPE VARCHAR2(30 CHAR),
OBJECT_NAME VARCHAR2(1000 CHAR),
BASE_OBJECT_SCHEMA VARCHAR2(128 CHAR),
BASE_OBJECT_TYPE VARCHAR2(30 CHAR),
BASE_OBJECT_NAME VARCHAR2(1000 CHAR),
COLUMN_NAME VARCHAR2(128 CHAR),
GRANTEE VARCHAR2(128 CHAR),
PRIVILEGE VARCHAR2(40 CHAR),
GRANTABLE VARCHAR2(3 CHAR))';
end;
/

