begin
  execute immediate q'[
create type oracle_tools.t_constraint_object authid current_user under oracle_tools.t_dependent_or_granted_object
( object_name$ varchar2(128 byte)
, column_names$ varchar2(4000 byte)
, search_condition$ varchar2(4000 byte)
, constraint_type$ varchar2(1 byte)
, constructor function t_constraint_object
  ( self in out nocopy oracle_tools.t_constraint_object
  , p_base_object in oracle_tools.t_named_object
  , p_object_schema in varchar2
  , p_object_name in varchar2
  , p_constraint_type in varchar2 default null
  , p_column_names in varchar2 default null
  , p_search_condition in varchar2 default null
  )
  return self as result
-- begin of getter(s)
, overriding member function object_type return varchar2 deterministic
, overriding final member function object_name return varchar2 deterministic
, final member function column_names return varchar2 deterministic
, final member function search_condition return varchar2 deterministic
, final member function constraint_type return varchar2 deterministic
-- end of getter(s)
, overriding map member function signature return varchar2 deterministic
, static function get_column_names
  ( p_object_schema in varchar2
  , p_object_name in varchar2
  , p_table_name in varchar2
  )
  return varchar2
, overriding member procedure chk
  ( self in oracle_tools.t_constraint_object
  , p_schema in varchar2
  )
, overriding member function dict_last_ddl_time return date
)
not final]';
end;
/
