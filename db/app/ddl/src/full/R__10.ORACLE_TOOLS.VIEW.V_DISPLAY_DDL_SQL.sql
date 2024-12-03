CREATE OR REPLACE VIEW "ORACLE_TOOLS"."V_DISPLAY_DDL_SQL" ("SCHEMA_OBJECT_ID", "DDL#", "VERB", "DDL_INFO", "CHUNK#", "CHUNK") BEQUEATH CURRENT_USER AS 
  select  t.schema_object_id
,       t.ddl#
,       t.verb
,       t.ddl_info
,       t.chunk#
,       t.chunk
from    table(oracle_tools.pkg_ddl_util.display_ddl_sql) t;

