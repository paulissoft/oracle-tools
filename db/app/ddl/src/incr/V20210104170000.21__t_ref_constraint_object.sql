begin
  execute immediate q'[
create type oracle_tools.t_ref_constraint_object authid current_user under oracle_tools.t_constraint_object
( ref_object$ oracle_tools.t_named_object -- referenced table
, constructor function t_ref_constraint_object
  ( self in out nocopy oracle_tools.t_ref_constraint_object
  , p_base_object in oracle_tools.t_named_object
  , p_object_schema in varchar2
  , p_object_name in varchar2
  , p_constraint_type in varchar2 default null
  , p_column_names in varchar2 default null
  , p_ref_object in oracle_tools.t_named_object default null
  )
  return self as result
-- begin of getter(s)
, overriding member function object_type return varchar2 deterministic
, member function ref_object_schema return varchar2 deterministic
, member function ref_object_type return varchar2 deterministic
, member function ref_object_name return varchar2 deterministic
-- end of getter(s)
, overriding final map member function signature return varchar2 deterministic
, overriding member procedure chk
  ( self in oracle_tools.t_ref_constraint_object
  , p_schema in varchar2
  )
, final member procedure ref_object_schema
  ( self in out nocopy oracle_tools.t_ref_constraint_object
  , p_ref_object_schema in varchar2
  )
)
final]';
end;
/
