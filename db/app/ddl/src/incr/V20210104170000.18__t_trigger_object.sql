begin
  execute immediate q'[
create type oracle_tools.t_trigger_object authid current_user under oracle_tools.t_dependent_or_granted_object
( object_name$ varchar2(128 byte)
, constructor function t_trigger_object
  ( self in out nocopy oracle_tools.t_trigger_object
  , p_base_object_id in varchar2
  , p_object_schema in varchar2
  , p_object_name in varchar2
  )
  return self as result
-- begin of getter(s)
, overriding member function object_type return varchar2 deterministic
, overriding member function object_name return varchar2 deterministic
-- end of getter(s)
, overriding member procedure chk
  ( self in oracle_tools.t_trigger_object
  , p_schema in varchar2
  )
)
final]';
end;
/
