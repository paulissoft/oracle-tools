begin
  execute immediate q'[
create type oracle_tools.t_dependent_or_granted_object authid current_user under oracle_tools.t_schema_object
( base_object$ oracle_tools.t_named_object
, overriding member function base_object_schema return varchar2 deterministic
, overriding member function base_object_type return varchar2 deterministic
, overriding member function base_object_name return varchar2 deterministic
, overriding final member procedure base_object_schema
  ( self in out nocopy oracle_tools.t_dependent_or_granted_object
  , p_base_object_schema in varchar2
  )
, overriding member procedure chk
  ( self in oracle_tools.t_dependent_or_granted_object
  , p_schema in varchar2
  )
, overriding member function base_dict_object_type return varchar2 deterministic
)
not instantiable
not final]';
end;
/
