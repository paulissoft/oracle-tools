CREATE OR REPLACE VIEW "ORACLE_TOOLS"."V_MY_SCHEMA_DDLS" ("SESSION_ID", "SCHEMA_OBJECT_ID", "DDL#", "CHUNK#", "OBJ", "LAST_DDL_TIME", "VERB", "DDL_INFO", "CHUNK", "LAST_CHUNK") BEQUEATH CURRENT_USER AS 
  with src as
( select  vso.session_id -- key #1
  ,       vso.schema_object_id -- key #2
  ,       gds.ddl# -- key #3
  ,       gdsc.chunk# -- key #4
  ,       vso.obj
  ,       vso.last_ddl_time
  ,       gds.verb
  -- below is output to SQL file
  ,       oracle_tools.t_ddl.ddl_info(p_schema_object => vso.obj, p_verb => gds.verb, p_ddl# => gds.ddl#) as ddl_info
  ,       gdsc.chunk
  ,       row_number() over (partition by vso.session_id, vso.schema_object_id order by gds.ddl# desc, gdsc.chunk# desc) as seq_per_schema_object_desc
  from    oracle_tools.v_schema_objects vso
          inner join oracle_tools.generated_ddls gd
          on gd.schema_object_id = vso.schema_object_id and gd.last_ddl_time = vso.last_ddl_time and gd.generate_ddl_configuration_id = vso.generate_ddl_configuration_id
          inner join oracle_tools.generated_ddl_statements gds
          on gds.generated_ddl_id = gd.id
          inner join oracle_tools.generated_ddl_statement_chunks gdsc
          on gdsc.generated_ddl_id = gds.generated_ddl_id and gdsc.ddl# = gds.ddl#
  where   vso.session_id = (select oracle_tools.ddl_crud_api.get_session_id from dual where rownum = 1)
)  
select  src.session_id -- key #1
,       src.schema_object_id -- key #2
,       src.ddl# -- key #3
,       src.chunk# -- key #4
,       src.obj
,       src.last_ddl_time
,       src.verb
-- below is used for output to SQL file
,       ddl_info
,       src.chunk
,       case when src.seq_per_schema_object_desc = 1 then 1 else null end last_chunk
from    src
order by
        -- unique key
        session_id
,       schema_object_id
,       ddl#
,       chunk#;

