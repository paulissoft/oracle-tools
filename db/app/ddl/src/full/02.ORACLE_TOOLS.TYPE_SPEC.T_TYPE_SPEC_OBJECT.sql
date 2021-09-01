CREATE TYPE "ORACLE_TOOLS"."T_TYPE_SPEC_OBJECT" authid current_user under oracle_tools.t_named_object
( constructor function t_type_spec_object
  ( self in out nocopy oracle_tools.t_type_spec_object
  , p_object_schema in varchar2
  , p_object_name in varchar2
  )
  return self as result
, overriding member function object_type return varchar2 deterministic
)
final;
/

