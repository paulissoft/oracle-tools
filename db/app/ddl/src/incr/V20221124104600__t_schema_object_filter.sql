begin
  execute immediate q'[
CREATE TYPE "ORACLE_TOOLS"."T_SCHEMA_OBJECT_FILTER" authid current_user as object
( schema$ varchar2(30 char)
, grantor_is_schema$ integer
, objects_tab$ oracle_tools.t_text_tab
, objects_include$ integer
, objects_cmp_tab$ oracle_tools.t_text_tab
, match_partial_eq_complete integer
, match_count integer
, match_count_ok integer
, constructor function t_schema_object_filter
  ( self in out nocopy oracle_tools.t_schema_object_filter
  , p_schema in varchar2 default user
  , p_object_type in varchar2 default null
  , p_object_names in varchar2 default null
  , p_object_names_include in integer default null
  , p_grantor_is_schema in integer default 0
  , p_objects in clob default null
  , p_objects_include in integer default null
  )
  return self as result
, member function schema return varchar2 deterministic
, member function grantor_is_schema return integer deterministic
, member function match_perc return integer deterministic
, member procedure print
  ( self in oracle_tools.t_schema_object_filter
  )
, member function matches_schema_object
  ( self in out nocopy oracle_tools.t_schema_object_filter
  , p_metadata_object_type in varchar2
  , p_object_name in varchar2
  , p_metadata_base_object_type in varchar2 default null
  , p_base_object_name in varchar2 default null
  )
  return integer
  deterministic
, member function matches_schema_object
  ( self in oracle_tools.t_schema_object_filter
  , p_schema_object_id in varchar2
  )
  return integer
  deterministic
, member procedure combine_named_dependent_objects
  ( self in oracle_tools.t_schema_object_filter
  , p_named_object_tab in oracle_tools.t_schema_object_tab
  , p_dependent_object_tab in oracle_tools.t_schema_object_tab
  , p_schema_object_tab out nocopy oracle_tools.t_schema_object_tab
  )
)
instantiable
final]';
end;
/
