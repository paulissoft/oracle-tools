CREATE TYPE "ORACLE_TOOLS"."T_MATERIALIZED_VIEW_LOG_OBJECT" authid current_user under oracle_tools.t_named_object
( constructor function t_materialized_view_log_object
  ( self in out nocopy oracle_tools.t_materialized_view_log_object
  , p_object_schema in varchar2
  , p_object_name in varchar2
  )
  return self as result
, overriding member function object_type return varchar2 deterministic
)
final;
/

