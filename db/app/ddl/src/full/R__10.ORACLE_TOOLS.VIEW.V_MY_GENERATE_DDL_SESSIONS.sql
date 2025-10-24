CREATE OR REPLACE VIEW "ORACLE_TOOLS"."V_MY_GENERATE_DDL_SESSIONS" ("SESSION_ID", "GENERATE_DDL_CONFIGURATION_ID", "SCHEMA_OBJECT_FILTER_ID", "CREATED", "USERNAME", "UPDATED") AS 
  select  gds.session_id
,       gds.generate_ddl_configuration_id
,       gds.schema_object_filter_id
,       gds.created
,       gds.username
,       gds.updated
from    oracle_tools.generate_ddl_sessions gds
where   gds.username = sys_context('USERENV', 'CURRENT_SCHEMA');

