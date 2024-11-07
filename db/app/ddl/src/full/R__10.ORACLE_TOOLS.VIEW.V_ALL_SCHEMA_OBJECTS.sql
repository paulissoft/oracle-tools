CREATE OR REPLACE VIEW "ORACLE_TOOLS"."V_ALL_SCHEMA_OBJECTS" BEQUEATH CURRENT_USER AS
SELECT  t.*
,       t.obj.id() as obj_id
,       oracle_tools.matches_schema_object_fnc(t.schema_object_filter_id, t.obj) as generate_ddl
,       (select count(*) /* returns 0 or 1 */ from oracle_tools.v_all_schema_ddls d where d.schema_object_filter_id = t.schema_object_filter_id and d.ddl_obj_id = t.obj.id()) as ddl_generated
FROM    oracle_tools.all_schema_objects t;
