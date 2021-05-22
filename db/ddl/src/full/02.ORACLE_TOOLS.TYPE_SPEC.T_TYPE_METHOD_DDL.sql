CREATE TYPE "ORACLE_TOOLS"."T_TYPE_METHOD_DDL" authid current_user under t_schema_ddl
( constructor function t_type_method_ddl
  ( self in out nocopy t_type_method_ddl
  , p_obj in t_schema_object
  )
  return self as result
, overriding member procedure migrate
  ( self in out nocopy t_type_method_ddl
  , p_source in t_schema_ddl
  , p_target in t_schema_ddl
  )
, overriding member procedure uninstall
  ( self in out nocopy t_type_method_ddl
  , p_target in t_schema_ddl
  )
)
final;
/

