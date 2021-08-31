CREATE OR REPLACE TYPE BODY "ORACLE_TOOLS"."T_DEPENDENT_OR_GRANTED_OBJECT" IS

overriding member function base_object_schema
return varchar2
deterministic
is
begin
  return base_object$.object_schema();
end base_object_schema;

overriding member function base_object_type
return varchar2
deterministic
is
begin
  return base_object$.object_type();
end base_object_type;

overriding member function base_dict_object_type
return varchar2
deterministic
is
begin
  return base_object$.dict_object_type();
end base_dict_object_type;

overriding member function base_object_name
return varchar2
deterministic
is
begin
  return base_object$.object_name();
end base_object_name;

overriding final member procedure base_object_schema
( p_base_object_schema in varchar2
)
is
begin
  self.base_object$.object_schema(p_base_object_schema);
end base_object_schema;

overriding member procedure chk
( self in t_dependent_or_granted_object
, p_schema in varchar2
)
is
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
  dbug.enter('T_DEPENDENT_OR_GRANTED_OBJECT.CHK');
$end

  oracle_tools.pkg_schema_object.chk_schema_object(p_dependent_or_granted_object => self, p_schema => p_schema);

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
  dbug.leave;
$end
end chk;

end;
/

