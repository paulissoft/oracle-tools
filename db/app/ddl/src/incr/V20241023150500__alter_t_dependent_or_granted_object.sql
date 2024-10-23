begin
  for r in
  ( select  'drop type ' || object_name as cmd
    from    user_objects
    where   object_type = 'TYPE'
    and     object_name = 'T_DEPENDENT_OR_GRANTED_OBJECT'
  )
  loop
    execute immediate r.cmd;
  end loop;

  execute immediate q'[
create type oracle_tools.t_dependent_or_granted_object authid current_user under oracle_tools.t_schema_object
( base_object$ ref oracle_tools.t_named_object
, final member function base_object return oracle_tools.t_named_object deterministic
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

  execute immediate 'GRANT EXECUTE ON T_DEPENDENT_OR_GRANTED_OBJECT TO PUBLIC';
end;
/
