CREATE OR REPLACE VIEW "ORACLE_TOOLS"."V_MY_SCHEMA_OBJECT_FILTER" ("SESSION_ID", "SCHEMA_OBJECT_FILTER_ID", "OBJ_JSON", "SCHEMA", "GRANTOR_IS_SCHEMA") BEQUEATH CURRENT_USER AS 
  with sof as
( select  sof.id
  ,       sof.obj_json
  ,       treat(oracle_tools.t_object_json.deserialize('ORACLE_TOOLS.T_SCHEMA_OBJECT_FILTER', sof.obj_json) as oracle_tools.t_schema_object_filter) as obj
  from    oracle_tools.schema_object_filters sof
)
select  /* V_MY_SCHEMA_OBJECT_FILTER since there is just one current filter */ gds.session_id
,       gds.schema_object_filter_id
,       sof.obj_json
,       sof.obj.schema$ as schema
,       sof.obj.grantor_is_schema$ as grantor_is_schema
from    oracle_tools.generate_ddl_sessions gds
        inner join sof
        on sof.id = gds.schema_object_filter_id
where   gds.session_id = (select oracle_tools.ddl_crud_api.get_session_id from dual where rownum = 1);

