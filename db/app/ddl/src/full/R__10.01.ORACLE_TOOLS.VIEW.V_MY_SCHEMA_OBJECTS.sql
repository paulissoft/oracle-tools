CREATE OR REPLACE VIEW "ORACLE_TOOLS"."V_MY_SCHEMA_OBJECTS" OF "ORACLE_TOOLS"."T_SCHEMA_OBJECT"
  WITH OBJECT IDENTIFIER ("ID") DEFAULT COLLATION "USING_NLS_COMP"  BEQUEATH CURRENT_USER  AS 
  select  vso.obj
from    oracle_tools.v_schema_objects vso
where   vso.session_id =
        -- use old trick to invoke get_session_id just once
        (select oracle_tools.ddl_crud_api.get_session_id from dual where rownum <= 1)
and     vso.generate_ddl = 1
order by
        -- order of creation
        vso.session_id
,       vso.created;

