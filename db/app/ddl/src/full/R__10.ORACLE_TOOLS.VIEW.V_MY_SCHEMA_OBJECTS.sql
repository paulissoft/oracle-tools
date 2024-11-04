CREATE OR REPLACE VIEW "ORACLE_TOOLS"."V_MY_SCHEMA_OBJECTS" BEQUEATH CURRENT_USER AS
select  t.obj
from    v_all_schema_objects t
where   t.schema_object_filter_id =
        (select max(f.id) from oracle_tools.schema_object_filters f where f.session_id = sys_context('USERENV', 'SESSION_ID'))
and     t.generate_ddl = 1;

