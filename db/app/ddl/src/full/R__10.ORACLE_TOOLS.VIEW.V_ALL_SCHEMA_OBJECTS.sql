CREATE OR REPLACE VIEW "ORACLE_TOOLS"."V_ALL_SCHEMA_OBJECTS" BEQUEATH CURRENT_USER AS
select  gdsso.*
,       ( select  value(so)
          from    oracle_tools.schema_objects so
          where   so.id = gdsso.schema_object_id
        ) as obj
,       ( select  oracle_tools.matches_schema_object_fnc
                  ( sofr.schema_object_filter_id
                  , sofr.schema_object_id
                  )
          from    oracle_tools.schema_object_filter_results sofr
          where   sofr.schema_object_filter_id = gdsso.schema_object_filter_id
          and     sofr.schema_object_id = gdsso.schema_object_id
        ) as generate_ddl
,       case when gdsso.ddl is null then 0 else 1 end as ddl_generated
from    oracle_tools.generate_ddl_session_schema_objects gdsso
;
