CREATE OR REPLACE FORCE VIEW "ORACLE_TOOLS"."V_MY_SCHEMA_DDLS" ("SESSION_ID", "SCHEMA_OBJECT_ID", "DDL#", "CHUNK#", "OBJ", "VERB", "DDL_INFO", "CHUNK") BEQUEATH CURRENT_USER AS 
  select  aso.session_id -- key #1
,       aso.schema_object_id -- key #2
,       gdssd.ddl# -- key #3
,       gdssdc.chunk# -- key #4
,       aso.obj  
,       gdssd.verb
-- below is output to SQL file
,       '-- ddl info: ' ||
        gdssd.verb || ';' ||
        replace(aso.obj.schema_object_info(), ':', ';') || ';' ||
        gdssd.ddl# || chr(10) as ddl_info
,       gdssdc.chunk
from    oracle_tools.v_all_schema_objects aso
        inner join oracle_tools.generate_ddl_session_schema_ddls gdssd
        on gdssd.session_id = aso.session_id and gdssd.schema_object_id = aso.schema_object_id
        inner join oracle_tools.generate_ddl_session_schema_ddl_chunks gdssdc
        on gdssdc.session_id = gdssd.session_id and gdssdc.schema_object_id = gdssd.schema_object_id and gdssdc.ddl# = gdssd.ddl#
where   aso.session_id = (select oracle_tools.schema_objects_api.get_session_id from dual where rownum = 1)
order by
        -- unique key
        aso.session_id
,       aso.schema_object_id
,       gdssd.ddl#
,       gdssdc.chunk#;

