CREATE TYPE "ORACLE_TOOLS"."T_COMMENT_DDL" authid current_user under oracle_tools.t_schema_ddl
( overriding member procedure uninstall
  ( self in out nocopy oracle_tools.t_comment_ddl
  , p_target in oracle_tools.t_schema_ddl
  )
)
final;
/

