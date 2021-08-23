CREATE TYPE "ORACLE_TOOLS"."T_SYNONYM_OBJECT" authid current_user under t_dependent_or_granted_object
( object_name$ varchar2(4000 char)
, constructor function t_synonym_object
  ( self in out nocopy t_synonym_object
  , p_base_object in t_named_object
  , p_object_schema in varchar2
  , p_object_name in varchar2
  )
  return self as result
-- begin of getter(s)
, overriding member function object_type return varchar2 deterministic
, overriding member function object_name return varchar2 deterministic
-- end of getter(s)
, overriding member procedure chk
  ( self in t_synonym_object
  , p_schema in varchar2
  )
)
final
 alter type "ORACLE_TOOLS"."T_SYNONYM_OBJECT" 
add overriding member function get_creation_date return date cascade;
/

