CREATE OR REPLACE FORCE VIEW "ORACLE_TOOLS"."V_MY_GENERATE_DDL_SESSION_SCHEMA_DDL_BATCHES" ("SESSION_ID", "SEQ", "CREATED", "SCHEMA", "TRANSFORM_PARAM_LIST", "OBJECT_SCHEMA", "OBJECT_TYPE", "BASE_OBJECT_SCHEMA", "BASE_OBJECT_TYPE", "OBJECT_NAME_TAB", "BASE_OBJECT_NAME_TAB", "NR_OBJECTS", "DDL_BATCH_GROUP") BEQUEATH CURRENT_USER AS 
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
,       to_number
        ( substr
          ( oracle_tools.t_schema_object.ddl_batch_order
            ( p_object_schema => gdsb.object_schema
            , p_object_type => gdsb.object_type 
            , p_base_object_schema => gdsb.base_object_schema 
            , p_base_object_type => gdsb.base_object_type 
            )
          , 1
          , 1
          )
        ) as ddl_batch_group
from    oracle_tools.generate_ddl_session_batches gdsb
where   gdsb.session_id = (select oracle_tools.schema_objects_api.get_session_id from dual where rownum = 1) -- old trick
and     gdsb.object_type <> 'SCHEMA_EXPORT';

