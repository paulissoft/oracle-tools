CREATE OR REPLACE FORCE VIEW "ORACLE_TOOLS"."V_MY_GENERATE_DDL_SESSION_BATCHES_NO_SCHEMA_EXPORT" ("SESSION_ID", "SEQ", "CREATED", "SCHEMA", "TRANSFORM_PARAM_LIST", "OBJECT_SCHEMA", "OBJECT_TYPE", "BASE_OBJECT_SCHEMA", "BASE_OBJECT_TYPE", "OBJECT_NAME_TAB", "BASE_OBJECT_NAME_TAB", "NR_OBJECTS", "START_TIME", "END_TIME", "DDL_BATCH_GROUP") BEQUEATH CURRENT_USER AS 
  select  gdsb.session_id
,       gdsb.seq
,       gdsb.created
,       gdsb.schema
,       gdsb.transform_param_list
,       gdsb.object_schema
,       gdsb.object_type
,       gdsb.base_object_schema
,       gdsb.base_object_type
,       gdsb.object_name_tab
,       gdsb.base_object_name_tab
,       gdsb.nr_objects
,       gdsb.start_time
,       gdsb.end_time
,       gdsb.ddl_batch_group
from    oracle_tools.v_my_generate_ddl_session_batches gdsb
where   gdsb.object_type <> 'SCHEMA_EXPORT'
order by
        -- force TABLE to start early (see also t_schema_object.ddl_batch_order)
        gdsb.ddl_batch_group;

