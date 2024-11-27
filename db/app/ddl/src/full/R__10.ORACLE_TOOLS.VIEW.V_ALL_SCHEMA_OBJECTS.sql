CREATE OR REPLACE FORCE VIEW "ORACLE_TOOLS"."V_ALL_SCHEMA_OBJECTS" ("SESSION_ID", "SEQ", "SCHEMA_OBJECT_FILTER_ID", "SCHEMA_OBJECT_ID", "LAST_DDL_TIME", "GENERATE_DDL_PARAMETER_ID", "CREATED", "OBJ", "GENERATE_DDL", "DDL_GENERATED") BEQUEATH CURRENT_USER AS 
  select  gdsso.session_id
,       gdsso.seq
,       gdsso.schema_object_filter_id
,       gdsso.schema_object_id
,       gdsso.last_ddl_time
,       gdsso.generate_ddl_parameter_id
,       gdsso.created
,       so.obj
,       sofr.generate_ddl
,       case when gdsso.last_ddl_time is null then 0 else 1 end as ddl_generated
from    oracle_tools.generate_ddl_session_schema_objects gdsso
        inner join oracle_tools.schema_objects so
        on so.id = gdsso.schema_object_id
        inner join oracle_tools.schema_object_filter_results sofr
        on sofr.schema_object_filter_id = gdsso.schema_object_filter_id and sofr.schema_object_id = gdsso.schema_object_id;

