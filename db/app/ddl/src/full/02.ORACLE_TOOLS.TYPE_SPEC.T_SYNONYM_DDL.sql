CREATE TYPE "ORACLE_TOOLS"."T_SYNONYM_DDL" authid current_user under t_schema_ddl
( overriding member procedure uninstall
  ( self in out nocopy t_synonym_ddl
  , p_target in t_schema_ddl
  )
)
final;
/

