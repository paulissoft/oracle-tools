CREATE OR REPLACE VIEW "ORACLE_TOOLS"."V_MY_GENERATE_DDL_SESSION_BATCHES" ("SESSION_ID", "SEQ", "CREATED", "START_TIME", "END_TIME", "ERROR_MESSAGE", "SCHEMA", "TRANSFORM_PARAM_LIST", "OBJECT_TYPE", "PARAMS", "DDL_BATCH_GROUP") BEQUEATH CURRENT_USER AS 
  select  gdsb.session_id
,       gdsb.seq
,       gdsb.created
,       gdsb.start_time
,       gdsb.end_time
,       gdsb.error_message
,       gdsb.schema
,       gdsb.transform_param_list
,       gdsb.object_type
,       gdsb.params
        -- to know to which USER_PARALLEL_EXECUTE_CHUNKS it belongs
,       to_number
        ( substr
          ( oracle_tools.t_schema_object.ddl_batch_order
            ( p_object_type => gdsb.object_type 
            )
          , 1
          , 1
          )
        ) as ddl_batch_group
from    oracle_tools.generate_ddl_session_batches gdsb
where   gdsb.session_id = (select oracle_tools.ddl_crud_api.get_session_id from dual where rownum = 1) -- old trick
order by
        -- force TABLE to start early (see also t_schema_object.ddl_batch_order)
        ddl_batch_group;

