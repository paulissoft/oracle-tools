CREATE TYPE "ORACLE_TOOLS"."T_REFRESH_GROUP_OBJECT" authid current_user under oracle_tools.t_named_object
( constructor function t_refresh_group_object
  ( self in out nocopy oracle_tools.t_refresh_group_object
  , p_object_schema in varchar2
  , p_object_name in varchar2
  )
  return self as result
, overriding member function object_type return varchar2 deterministic
, overriding member function dict_object_exists return integer -- 0/1
)
final;
/

