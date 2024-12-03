CREATE OR REPLACE VIEW "ORACLE_TOOLS"."V_MY_SCHEMA_OBJECTS" OF "ORACLE_TOOLS"."T_SCHEMA_OBJECT"
  WITH OBJECT IDENTIFIER ("ID") BEQUEATH CURRENT_USER  AS 
  select  aso.obj
from    oracle_tools.v_all_schema_objects aso
where   aso.session_id =
        -- use old trick to invoke get_session_id just once
        (select oracle_tools.ddl_crud_api.get_session_id from dual where rownum <= 1)
and     aso.generate_ddl = 1
order by
        -- order of creation
        aso.session_id
,       aso.created;

