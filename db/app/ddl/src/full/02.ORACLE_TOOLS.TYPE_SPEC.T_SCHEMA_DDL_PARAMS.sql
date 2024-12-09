CREATE TYPE "ORACLE_TOOLS"."T_SCHEMA_DDL_PARAMS" AUTHID CURRENT_USER UNDER "ORACLE_TOOLS"."T_OBJECT_JSON"
( object_schema varchar2(128 byte)
, base_object_schema varchar2(128 byte)
, base_object_type varchar2(30 byte)
, object_name_tab oracle_tools.t_text_tab
, base_object_name_tab oracle_tools.t_text_tab
, nr_objects integer
, overriding
  member procedure serialize
  ( self in oracle_tools.t_schema_ddl_params
  , p_json_object in out nocopy json_object_t
  )
)
instantiable
final;
/

