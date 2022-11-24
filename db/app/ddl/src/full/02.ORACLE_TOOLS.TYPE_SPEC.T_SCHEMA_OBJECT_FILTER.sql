CREATE TYPE "ORACLE_TOOLS"."T_SCHEMA_OBJECT_FILTER" authid current_user as object
( schema$ varchar2(30 char)
, object_type$ varchar2(30 char)
, object_names$ varchar2(4000 char)
, object_names_include$ integer
, grantor_is_schema$ integer
-- set in constructor
, object_name_tab$ oracle_tools.t_text_tab
, schema_object_info_tab$ oracle_tools.t_text_tab
, constructor function t_schema_object_filter
  ( self in out nocopy oracle_tools.t_schema_object_filter
  , p_schema in varchar2 default user
  , p_object_type in varchar2 default null
  , p_object_names in varchar2 default null
  , p_object_names_include in integer default null
  , p_grantor_is_schema in integer default 0
  )
  return self as result
, member function schema return varchar2 deterministic
, member function object_type return varchar2 deterministic
, member function object_names return varchar2 deterministic
, member function object_names_include return integer deterministic
, member function grantor_is_schema return integer deterministic
, member function object_name_tab return oracle_tools.t_text_tab deterministic
, member function schema_object_info_tab return oracle_tools.t_text_tab deterministic
, member procedure print
  ( self in oracle_tools.t_schema_object_filter
  )
)
instantiable
final;
/

