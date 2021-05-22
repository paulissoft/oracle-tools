CREATE TYPE "ORACLE_TOOLS"."T_PROCEDURE_OBJECT" authid current_user under t_named_object
( constructor function t_procedure_object
  ( self in out nocopy t_procedure_object
  , p_object_schema in varchar2
  , p_object_name in varchar2
  )
  return self as result
, overriding member function object_type return varchar2 deterministic
)
final;
/

