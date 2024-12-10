CREATE OR REPLACE VIEW "ORACLE_TOOLS"."V_MY_NAMED_SCHEMA_OBJECTS" OF "ORACLE_TOOLS"."T_NAMED_OBJECT"
  WITH OBJECT IDENTIFIER ("ID") BEQUEATH CURRENT_USER  AS 
  select  treat(vso.obj as oracle_tools.t_named_object)
from    oracle_tools.v_schema_objects vso
where   vso.session_id =
        -- use old trick to invoke get_session_id just once
        (select oracle_tools.ddl_crud_api.get_session_id from dual where rownum <= 1)
and     vso.generate_ddl is not null
and     vso.obj is of (oracle_tools.t_named_object)
order by
        -- order of creation
        vso.session_id
,       vso.created;

