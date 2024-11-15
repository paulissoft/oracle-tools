CREATE OR REPLACE VIEW "ORACLE_TOOLS"."V_ALL_SCHEMA_OBJECTS" BEQUEATH CURRENT_USER AS
select  gdsso.session_id
,       gdsso.seq
,       gdsso.schema_object_filter_id
,       gdsso.schema_object_id
,       gdsso.created
,       so.obj
,       sofr.generate_ddl
,       case
          when exists
               ( select  1
                 from    oracle_tools.generate_ddl_session_schema_ddls gdssd
                 where   gdssd.session_id = gdsso.session_id
                 and     gdssd.schema_object_id = gdsso.schema_object_id
                 and     gdssd.seq = 1
               )
          then 1
          else 0
        end as ddl_generated
from    oracle_tools.generate_ddl_session_schema_objects gdsso
        inner join oracle_tools.schema_objects so
        on so.id = gdsso.schema_object_id
        inner join oracle_tools.schema_object_filter_results sofr
        on sofr.schema_object_filter_id = gdsso.schema_object_filter_id and sofr.schema_object_id = gdsso.schema_object_id
;
