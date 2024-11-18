CREATE OR REPLACE VIEW "ORACLE_TOOLS"."V_MY_SCHEMA_DDLS" ("SESSION_ID", "SCHEMA_OBJECT_ID", "OBJ", "SCHEMA_DDL") BEQUEATH CURRENT_USER AS 
  select  aso.session_id
,       aso.schema_object_id
,       aso.obj
,       oracle_tools.t_schema_ddl.create_schema_ddl
        ( aso.obj
        , cast
          ( multiset
            ( select  gdssd.ddl
              from    oracle_tools.generate_ddl_session_schema_ddls gdssd
              where   gdssd.session_id = aso.session_id
              and     gdssd.schema_object_id = aso.schema_object_id
              order by
                      gdssd.seq
            ) as oracle_tools.t_ddl_tab
          )  
        ) as schema_ddl
from    oracle_tools.v_all_schema_objects aso
where   aso.session_id =
        -- use old trick to invoke get_session_id just once
        (select oracle_tools.schema_objects_api.get_session_id from dual where rownum <= 1)
and     aso.generate_ddl = 1
and     aso.ddl_generated = 1
order by
        -- unique key
        aso.session_id
,       aso.schema_object_id;

