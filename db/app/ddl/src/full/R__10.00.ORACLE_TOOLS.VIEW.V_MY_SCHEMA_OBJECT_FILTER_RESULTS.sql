CREATE OR REPLACE VIEW "ORACLE_TOOLS"."V_MY_SCHEMA_OBJECT_FILTER_RESULTS" ("SCHEMA_OBJECT_FILTER_ID", "SCHEMA_OBJECT_FILTER_JSON", "SCHEMA_OBJECT_ID", "SCHEMA_OBJECT", "GENERATE_DDL") BEQUEATH CURRENT_USER AS 
  select  sofr.schema_object_filter_id
,       sof.obj_json as schema_object_filter_json
--,       treat(oracle_tools.t_object_json.deserialize('ORACLE_TOOLS.T_SCHEMA_OBJECT_FILTER', sof.obj) as oracle_tools.t_schema_object_filter) as schema_object_filter
,       sofr.schema_object_id
,       so.obj as schema_object
,       sofr.generate_ddl
from    oracle_tools.generate_ddl_sessions gds
        inner join oracle_tools.schema_object_filter_results sofr
        on sofr.schema_object_filter_id = gds.schema_object_filter_id
        inner join oracle_tools.schema_object_filters sof
        on sof.id = sofr.schema_object_filter_id
        inner join oracle_tools.schema_objects so
        on so.id = sofr.schema_object_id
where   gds.session_id =
        -- old trick to invoke function just once
        (select oracle_tools.ddl_crud_api.get_session_id from dual);

