CREATE OR REPLACE VIEW "ORACLE_TOOLS"."V_MY_NAMED_SCHEMA_OBJECTS" OF "ORACLE_TOOLS"."T_NAMED_OBJECT"
  WITH OBJECT IDENTIFIER ("ID") DEFAULT COLLATION "USING_NLS_COMP"  BEQUEATH CURRENT_USER  AS 
  select  treat(so.obj as oracle_tools.t_named_object)
from    oracle_tools.generate_ddl_sessions gds
        inner join oracle_tools.schema_object_filter_results sofr
        on sofr.schema_object_filter_id = gds.schema_object_filter_id
    	inner join oracle_tools.schema_objects so
	    on so.id = sofr.schema_object_id
where   gds.session_id =
        -- use old trick to invoke get_session_id just once
        (select oracle_tools.ddl_crud_api.get_session_id from dual where rownum <= 1)
and     sofr.generate_ddl is not null
and     so.obj is of (oracle_tools.t_named_object)
order by
        -- order of creation
        gds.session_id
,       so.created;

