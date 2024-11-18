CREATE TYPE "ORACLE_TOOLS"."T_SCHEMA_OBJECT_FILTER" authid current_user as object
( schema$ varchar2(30 char)
, grantor_is_schema$ integer
, object_tab$ oracle_tools.t_text_tab
, object_cmp_tab$ oracle_tools.t_text_tab
, nr_excluded_objects$ integer
, constructor function t_schema_object_filter
  ( self in out nocopy oracle_tools.t_schema_object_filter
  , p_schema in varchar2 default user
  , p_object_type in varchar2 default null
  , p_object_names in varchar2 default null
  , p_object_names_include in integer default null
  , p_grantor_is_schema in integer default 0
  , p_exclude_objects in clob default null
  , p_include_objects in clob default null
  )
  return self as result
, member function schema return varchar2 deterministic
, member function grantor_is_schema return integer deterministic
, member function matches_schema_object
  ( self in oracle_tools.t_schema_object_filter
  , p_schema_object_id in varchar2
  )
  return integer
  deterministic
, member function serialize return clob deterministic  
, member procedure print
  ( self in oracle_tools.t_schema_object_filter
  )
)
instantiable
final;
/

