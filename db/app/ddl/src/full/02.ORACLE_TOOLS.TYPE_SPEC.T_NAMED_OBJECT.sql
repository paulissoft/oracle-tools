CREATE TYPE "ORACLE_TOOLS"."T_NAMED_OBJECT" authid current_user under t_schema_object
( object_name$ varchar2(4000 char)
, overriding final member function object_name return varchar2 deterministic
, final static procedure create_named_object
  ( p_object_type in varchar2
  , p_object_schema in varchar2
  , p_object_name in varchar2
  , p_named_object out nocopy t_schema_object
  )
, final static function create_named_object
  ( p_object_type in varchar2
  , p_object_schema in varchar2
  , p_object_name in varchar2
  )
  return t_named_object
, overriding member procedure chk
  ( self in t_named_object
  , p_schema in varchar2
  )
)
not instantiable
not final
 alter type "ORACLE_TOOLS"."T_NAMED_OBJECT" 
add overriding member function get_creation_date return date cascade;
/

