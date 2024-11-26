CREATE OR REPLACE FORCE VIEW "ORACLE_TOOLS"."V_DISPLAY_DDL_SQL" BEQUEATH CURRENT_USER AS 
  select  t.*
from    table(oracle_tools.pkg_ddl_util.display_ddl_sql) t;

