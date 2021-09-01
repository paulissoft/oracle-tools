CREATE TYPE "ORACLE_TOOLS"."T_TYPE_METHOD_DDL" authid current_user under oracle_tools.t_schema_ddl
( constructor function t_type_method_ddl
  ( self in out nocopy oracle_tools.t_type_method_ddl
  , p_obj in oracle_tools.t_schema_object
  )
  return self as result
, overriding member procedure migrate
  ( self in out nocopy oracle_tools.t_type_method_ddl
  , p_source in oracle_tools.t_schema_ddl
  , p_target in oracle_tools.t_schema_ddl
  )
, overriding member procedure uninstall
  ( self in out nocopy oracle_tools.t_type_method_ddl
  , p_target in oracle_tools.t_schema_ddl
  )
)
final;
/

