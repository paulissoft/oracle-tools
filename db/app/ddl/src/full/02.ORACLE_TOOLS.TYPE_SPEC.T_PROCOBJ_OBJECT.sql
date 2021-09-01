CREATE TYPE "ORACLE_TOOLS"."T_PROCOBJ_OBJECT" authid current_user under oracle_tools.t_named_object
( dict_object_type$ varchar2(19 char)
, constructor function t_procobj_object
  ( self in out nocopy oracle_tools.t_procobj_object
  , p_object_schema in varchar2
  , p_object_name in varchar2
  )
  return self as result
  -- begin of getter(s)
, overriding member function dict_object_type return varchar2 deterministic
, overriding member function object_type return varchar2 deterministic
  -- end of getter(s)
, overriding member procedure chk
  ( self in oracle_tools.t_procobj_object
  , p_schema in varchar2
  )
)
final;
/

