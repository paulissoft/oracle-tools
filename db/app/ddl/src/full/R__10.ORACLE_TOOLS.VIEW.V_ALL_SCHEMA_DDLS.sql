CREATE OR REPLACE VIEW "ORACLE_TOOLS"."V_ALL_SCHEMA_DDLS" BEQUEATH CURRENT_USER AS
SELECT  t.*
,       t.ddl.obj.id as ddl_obj_id
FROM    oracle_tools.generate_ddl_session_schema_objects t;
