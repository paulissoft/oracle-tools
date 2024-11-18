CREATE OR REPLACE VIEW V_MY_GENERATE_DDL_SESSION_SCHEMA_DDL_BATCHES BEQUEATH CURRENT_USER AS 
select  gdssdb.*
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
