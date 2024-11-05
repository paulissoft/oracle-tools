CREATE OR REPLACE VIEW "ORACLE_TOOLS"."V_ALL_SCHEMA_DDLS" BEQUEATH CURRENT_USER AS
SELECT  t.*
,       t.ddl.obj.id() as ddl_obj_id
FROM    oracle_tools.all_schema_ddls t;
