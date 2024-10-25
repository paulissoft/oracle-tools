begin
  execute immediate q'[
create type oracle_tools.t_named_object authid current_user under oracle_tools.t_schema_object
( object_name$ varchar2(128 byte)
, overriding final member function object_name return varchar2 deterministic
, overriding member function object_type return varchar2 deterministic -- needed to create an object view on this object type
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
)
instantiable -- needed to create an object view on this object type
not final]';
end;
/


