CREATE TYPE "ORACLE_TOOLS"."T_MATERIALIZED_VIEW_DDL" authid current_user under oracle_tools.t_schema_ddl
( overriding member procedure migrate
  ( self in out nocopy oracle_tools.t_materialized_view_ddl
  , p_source in oracle_tools.t_schema_ddl
  , p_target in oracle_tools.t_schema_ddl
  )
)
final;
/

