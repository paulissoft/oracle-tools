CREATE OR REPLACE VIEW "ORACLE_TOOLS"."V_MY_SCHEMA_OBJECT_FILTER" ("SESSION_ID", "SCHEMA_OBJECT_FILTER_ID", "OBJ_JSON") BEQUEATH CURRENT_USER AS 
  select  /* V_MY_SCHEMA_OBJECT_FILTER since there is just one current filter */ gds.session_id
,       gds.schema_object_filter_id
,       sof.obj_json
from    oracle_tools.generate_ddl_sessions gds
        inner join oracle_tools.schema_object_filters sof
        on sof.id = gds.schema_object_filter_id
where   gds.session_id = (select oracle_tools.ddl_crud_api.get_session_id from dual where rownum = 1);

