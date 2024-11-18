CREATE TYPE "ORACLE_TOOLS"."T_OBJECT_GRANT_OBJECT" authid current_user under oracle_tools.t_dependent_or_granted_object
( grantee$ varchar2(128 byte)
, privilege$ varchar2(40 byte)
, grantable$ varchar2(3 byte)
, constructor function t_object_grant_object
  ( self in out nocopy oracle_tools.t_object_grant_object
  , p_base_object in oracle_tools.t_named_object
  , p_object_schema in varchar2
  , p_grantee in varchar2
  , p_privilege in varchar2
  , p_grantable in varchar2
  )
  return self as result
-- begin of getter(s)
, overriding member function object_type return varchar2 deterministic
, overriding member function grantee return varchar2 deterministic
, overriding member function privilege return varchar2 deterministic
, overriding member function grantable return varchar2 deterministic
-- end of getter(s)
, overriding member procedure chk
  ( self in oracle_tools.t_object_grant_object
  , p_schema in varchar2
  )
, overriding member function dict_object_exists return integer -- 0/1
)
final;
/

