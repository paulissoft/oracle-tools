CREATE TYPE "ORACLE_TOOLS"."T_TABLE_COLUMN_DDL" authid current_user under t_type_attribute_ddl
( constructor function t_table_column_ddl
  ( self in out nocopy t_table_column_ddl
  , p_obj in t_schema_object
  )
  return self as result
, overriding member procedure migrate
  ( self in out nocopy t_table_column_ddl
  , p_source in t_schema_ddl
  , p_target in t_schema_ddl
  )
, overriding member procedure uninstall
  ( self in out nocopy t_table_column_ddl
  , p_target in t_schema_ddl
  )
)
not final;
/

