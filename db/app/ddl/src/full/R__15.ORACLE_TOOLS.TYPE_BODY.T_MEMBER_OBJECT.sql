CREATE OR REPLACE TYPE BODY "ORACLE_TOOLS"."T_MEMBER_OBJECT" IS

constructor function t_member_object
( self in out nocopy oracle_tools.t_member_object
, network_link$ in varchar2
, object_schema$ in varchar2
, base_object_id$ in varchar2
, member#$ integer
, member_name$ varchar2
)
return self as result
is
begin
  self.network_link$ := network_link$;
  self.object_schema$ := object_schema$;
  self.base_object_id$ := base_object_id$;
  self.member#$ := member#$;
  self.member_name$ := member_name$;
  
  self.id := member_name$;
  
  return;
end;
  
member function member#
return integer
deterministic
is
begin
  return member#$;
end member#;

member function member_name
return varchar2
deterministic
is
begin
  return member_name$;
end member_name;

overriding member function is_a_repeatable
return integer
deterministic
is
begin
  return 0;
end is_a_repeatable;

end;
/

