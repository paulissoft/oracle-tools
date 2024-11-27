CREATE OR REPLACE FORCE VIEW "ORACLE_TOOLS"."V_DISPLAY_DDL_SQL" BEQUEATH CURRENT_USER AS 
  select  t.schema_object_id
,       t.ddl#
,       t.verb
,       t.ddl_info
,       t.chunk#
,       t.chunk
from    table(oracle_tools.pkg_ddl_util.display_ddl_sql) t;
