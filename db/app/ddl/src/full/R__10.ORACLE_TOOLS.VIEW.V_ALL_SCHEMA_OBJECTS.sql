CREATE OR REPLACE VIEW "ORACLE_TOOLS"."V_ALL_SCHEMA_OBJECTS" BEQUEATH CURRENT_USER AS
select  gdsso.*
,       so.obj
,       sofr.generate_ddl
,       case when gdsso.ddl is null then 0 else 1 end as ddl_generated
from    oracle_tools.generate_ddl_session_schema_objects gdsso
        inner join oracle_tools.schema_objects so
        on so.id = gdsso.schema_object_id
        inner join oracle_tools.schema_object_filter_results sofr
        on sofr.schema_object_filter_id = gdsso.schema_object_filter_id and sofr.schema_object_id = gdsso.schema_object_id
;
