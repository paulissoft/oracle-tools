begin
  execute immediate q'[
create type oracle_tools.t_member_object authid current_user under oracle_tools.t_dependent_or_granted_object
( member#$ integer
, member_name$ varchar2(128 byte)
-- constructors
, constructor function t_member_object
  ( self in out nocopy oracle_tools.t_member_object
  , network_link$ in varchar2
  , object_schema$ in varchar2
  , base_object_id$ in varchar2
  , member#$ integer
  , member_name$ varchar2
  )
  return self as result
-- begin of getter(s)/setter(s)
, member function member# return integer deterministic
, member function member_name return varchar2 deterministic
-- end of getter(s)/setter(s)
, overriding member function is_a_repeatable return integer deterministic
)
not final
not instantiable]';
end;
/


