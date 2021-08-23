CREATE TYPE "ORACLE_TOOLS"."T_INDEX_OBJECT" authid current_user under t_dependent_or_granted_object
( object_name$ varchar2(4000 char)
, column_names$ varchar2(4000 char)
, tablespace_name$ varchar2(30 char)
, constructor function t_index_object
  ( self in out nocopy t_index_object
  , p_base_object in t_named_object
  , p_object_schema in varchar2
  , p_object_name in varchar2
  )
  return self as result
, constructor function t_index_object
  ( self in out nocopy t_index_object
  , p_base_object in t_named_object
  , p_object_schema in varchar2
  , p_object_name in varchar2
  , p_tablespace_name in varchar2
  )
  return self as result
-- begin of getter(s)/setter(s)
, overriding member function object_type return varchar2 deterministic
, overriding member function object_name return varchar2 deterministic
, member function column_names return varchar2 deterministic
, member function tablespace_name return varchar2 deterministic
, member procedure tablespace_name
  ( self in out nocopy t_index_object
  , p_tablespace_name in varchar2
  )
-- end of getter(s)/setter(s)
, overriding final map member function signature return varchar2 deterministic
, static function get_column_names
  ( p_object_schema in varchar2
  , p_object_name in varchar2
  )
  return varchar2
, overriding member procedure chk
  ( self in t_index_object
  , p_schema in varchar2
  )
)
final
 alter type "ORACLE_TOOLS"."T_INDEX_OBJECT" 
add overriding member function get_creation_date return date cascade;
/

