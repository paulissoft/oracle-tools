CREATE TYPE "ORACLE_TOOLS"."T_MATERIALIZED_VIEW_DDL" authid current_user under t_schema_ddl
( overriding member procedure migrate
  ( self in out nocopy t_materialized_view_ddl
  , p_source in t_schema_ddl
  , p_target in t_schema_ddl
  )
)
final;
/

