CREATE OR REPLACE VIEW "ORACLE_TOOLS"."V_ALL_SCHEMA_OBJECTS" BEQUEATH CURRENT_USER AS
SELECT  t.*
,       t.obj.id() as obj_id
,       matches_schema_object_fnc(t.schema_object_filter_id, t.obj) as generate_ddl
FROM    all_schema_objects t;
