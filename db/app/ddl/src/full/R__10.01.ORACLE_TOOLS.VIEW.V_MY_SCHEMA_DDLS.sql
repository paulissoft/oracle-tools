CREATE OR REPLACE FORCE VIEW "ORACLE_TOOLS"."V_MY_SCHEMA_DDLS" ("SESSION_ID", "SCHEMA_OBJECT_ID", "DDL#", "CHUNK#", "OBJ", "LAST_DDL_TIME", "VERB", "DDL_INFO", "CHUNK")  BEQUEATH CURRENT_USER AS 
  select  aso.session_id -- key #1
,       aso.schema_object_id -- key #2
,       gds.ddl# -- key #3
,       gdsc.chunk# -- key #4
,       aso.obj
,       aso.last_ddl_time
,       gds.verb
-- below is output to SQL file
,       oracle_tools.t_ddl.ddl_info(aso.obj, gds.verb, gds.ddl#) as ddl_info
,       gdsc.chunk
from    oracle_tools.v_all_schema_objects aso
        inner join oracle_tools.generated_ddls gd
        on gd.schema_object_id = aso.schema_object_id and gd.last_ddl_time = aso.last_ddl_time and gd.generate_ddl_configuration_id = aso.generate_ddl_configuration_id
        inner join oracle_tools.generated_ddl_statements gds
        on gds.generated_ddl_id = gd.id
        inner join oracle_tools.generated_ddl_statement_chunks gdsc
        on gdsc.generated_ddl_id = gds.generated_ddl_id and gdsc.ddl# = gds.ddl#
where   aso.session_id = (select oracle_tools.ddl_crud_api.get_session_id from dual where rownum = 1)
order by
        -- unique key
        aso.session_id
,       aso.schema_object_id
,       gds.ddl#
,       gdsc.chunk#;

