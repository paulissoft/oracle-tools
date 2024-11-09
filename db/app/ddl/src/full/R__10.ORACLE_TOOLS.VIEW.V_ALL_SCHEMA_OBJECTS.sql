CREATE OR REPLACE VIEW "ORACLE_TOOLS"."V_ALL_SCHEMA_OBJECTS" BEQUEATH CURRENT_USER AS
select  gdsso.*
,       (select value(so) from oracle_tools.schema_objects so where so.id = gdsso.schema_object_id) as obj
,       oracle_tools.matches_schema_object_fnc(sofr.schema_object_filter_id, sofr.schema_object_id) as generate_ddl
,       (select count(*) /* returns 0 or 1 */ from oracle_tools.v_all_schema_ddls asd where asd.schema_object_filter_id = gdsso.schema_object_filter_id and asd.ddl_obj_id = gdsso.schema_object_id) as ddl_generated
from    oracle_tools.generate_ddl_session_schema_objects gdsso
        inner join schema_object_filter_results sofr
        on sofr.schema_object_filter_id = gdsso.schema_object_filter_id and
           sofr.schema_object_id = gdsso.schema_object_id
;
