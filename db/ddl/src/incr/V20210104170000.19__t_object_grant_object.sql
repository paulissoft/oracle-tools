begin
  execute immediate q'[
create type t_object_grant_object authid current_user under t_dependent_or_granted_object
( grantee$ varchar2(128 char)
, privilege$ varchar2(40 char)
, grantable$ varchar2(3 char)
, constructor function t_object_grant_object
  ( self in out nocopy t_object_grant_object
  , p_base_object in t_named_object
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
  ( self in t_object_grant_object
  , p_schema in varchar2
  )
)
final]';
end;
/
