CREATE TYPE "ORACLE_TOOLS"."T_SYNONYM_DDL" authid current_user under oracle_tools.t_schema_ddl
( overriding member procedure uninstall
  ( self in out nocopy oracle_tools.t_synonym_ddl
  , p_target in oracle_tools.t_schema_ddl
  )
)
final;
/

