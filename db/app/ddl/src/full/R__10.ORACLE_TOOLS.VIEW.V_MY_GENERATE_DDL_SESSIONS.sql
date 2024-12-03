create or replace view v_my_generate_ddl_sessions as
select  gds.session_id
,       gds.generate_ddl_configuration_id
,       gds.schema_object_filter_id
,       gds.created
,       gds.username
,       gds.updated
from    oracle_tools.generate_ddl_sessions gds
where   gds.username = user;
