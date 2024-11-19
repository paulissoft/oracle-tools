CREATE OR REPLACE VIEW "ORACLE_TOOLS"."V_MY_SCHEMA_OBJECT_FILTER" ("SESSION_ID", "SCHEMA_OBJECT_FILTER_ID", "OBJ", "SCHEMA", "GRANTOR_IS_SCHEMA") BEQUEATH CURRENT_USER AS 
  select  gds.session_id
,       gds.schema_object_filter_id
,       sof.obj as obj
,       sof.obj.schema$ as schema
,       sof.obj.grantor_is_schema$ as grantor_is_schema
from    oracle_tools.generate_ddl_sessions gds
        inner join oracle_tools.schema_object_filters sof
        on sof.id = gds.schema_object_filter_id
where   gds.session_id = (select oracle_tools.schema_objects_api.get_session_id from dual where rownum = 1);

