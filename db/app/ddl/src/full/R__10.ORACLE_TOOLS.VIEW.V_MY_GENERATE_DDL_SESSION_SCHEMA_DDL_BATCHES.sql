CREATE OR REPLACE VIEW "ORACLE_TOOLS"."V_MY_GENERATE_DDL_SESSION_SCHEMA_DDL_BATCHES" ("SESSION_ID", "SEQ", "CREATED", "SCHEMA", "TRANSFORM_PARAM_LIST", "OBJECT_SCHEMA", "OBJECT_TYPE", "BASE_OBJECT_SCHEMA", "BASE_OBJECT_TYPE", "OBJECT_NAME_TAB", "BASE_OBJECT_NAME_TAB", "NR_OBJECTS", "DDL_BATCH_GROUP") BEQUEATH CURRENT_USER AS 
  select  gdssdb.session_id
,       gdssdb.seq
,       gdssdb.created
,       gdssdb.schema
,       gdssdb.transform_param_list
,       gdssdb.object_schema
,       gdssdb.object_type
,       gdssdb.base_object_schema
,       gdssdb.base_object_type
,       gdssdb.object_name_tab
,       gdssdb.base_object_name_tab
,       gdssdb.nr_objects
,       trunc
        ( oracle_tools.t_schema_object.ddl_batch_order
          ( p_object_schema => gdssdb.object_schema
          , p_object_type => gdssdb.object_type 
          , p_base_object_schema => gdssdb.base_object_schema 
          , p_base_object_type => gdssdb.base_object_type 
          ) 
        ) as ddl_batch_group
from    oracle_tools.generate_ddl_session_schema_ddl_batches gdssdb
where   gdssdb.session_id = (select oracle_tools.schema_objects_api.get_session_id from dual where rownum = 1) -- old trick
and     gdssdb.object_type <> 'SCHEMA_EXPORT';

