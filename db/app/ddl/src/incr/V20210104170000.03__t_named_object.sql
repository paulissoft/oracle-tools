begin
  execute immediate q'[
create type oracle_tools.t_named_object authid current_user under oracle_tools.t_schema_object
( object_name$ varchar2(128 byte)
  -- other methods
, overriding final member function object_name return varchar2 deterministic
, final static procedure create_named_object
  ( p_object_type in varchar2
  , p_object_schema in varchar2
  , p_object_name in varchar2
  , p_named_object out nocopy oracle_tools.t_schema_object
  )
, final static function create_named_object
  ( p_object_type in varchar2
  , p_object_schema in varchar2
  , p_object_name in varchar2
  )
  return oracle_tools.t_named_object
, overriding member procedure chk
  ( self in oracle_tools.t_named_object
  , p_schema in varchar2
  )
, overriding member function dict_object_exists return integer -- 0/1
)
not instantiable
not final]';
end;
/


