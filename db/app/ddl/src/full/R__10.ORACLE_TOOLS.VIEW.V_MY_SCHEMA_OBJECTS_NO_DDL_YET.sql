CREATE OR REPLACE VIEW "ORACLE_TOOLS"."V_MY_SCHEMA_OBJECTS_NO_DDL_YET" BEQUEATH CURRENT_USER AS
select  t.obj
from    v_all_schema_objects t
where   t.schema_object_filter_id =
        (select oracle_tools.schema_objects_api.get_last_schema_object_filter_id from dual where rownum <= 1)
and     t.generate_ddl = 1
and     t.ddl_generated = 0
order by
        -- primary key
        t.schema_object_filter_id
,       t.seq;

