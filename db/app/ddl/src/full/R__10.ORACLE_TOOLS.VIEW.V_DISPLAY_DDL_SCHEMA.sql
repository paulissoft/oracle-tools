CREATE OR REPLACE FORCE VIEW "ORACLE_TOOLS"."V_DISPLAY_DDL_SCHEMA" ("SCHEMA_DDL")  BEQUEATH CURRENT_USER AS 
  select  value(t) as schema_ddl
from    table(oracle_tools.pkg_ddl_util.display_ddl_schema) t;

