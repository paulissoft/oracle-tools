CREATE OR REPLACE VIEW "ORACLE_TOOLS"."V_MY_SCHEMA_OBJECT_FILTER_RESULTS" ("SCHEMA_OBJECT_FILTER_ID", "SCHEMA_OBJECT_FILTER_JSON", "SCHEMA", "SCHEMA_OBJECT_ID", "SCHEMA_OBJECT", "GENERATE_DDL")  BEQUEATH CURRENT_USER AS 
  select  sofr.schema_object_filter_id
,       vmsof.obj_json as schema_object_filter_json
,       json_value(vmsof.obj_json, '$.SCHEMA$') as schema
,       sofr.schema_object_id
,       so.obj as schema_object
,       sofr.generate_ddl
from    oracle_tools.v_my_schema_object_filter vmsof -- filters on current session id
        inner join oracle_tools.schema_object_filter_results sofr
        on sofr.schema_object_filter_id = vmsof.schema_object_filter_id
        inner join oracle_tools.schema_objects so
        on so.id = sofr.schema_object_id;

