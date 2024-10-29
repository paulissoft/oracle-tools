CREATE OR REPLACE TYPE BODY "ORACLE_TOOLS"."T_DEPENDENT_OR_GRANTED_OBJECT" IS

overriding member function base_object_schema
return varchar2
deterministic
is
begin
  return base_object().object_schema();
end base_object_schema;

overriding member function base_object_type
return varchar2
deterministic
is
begin
  return base_object().object_type();
end base_object_type;

overriding member function base_dict_object_type
return varchar2
deterministic
is
begin
  return base_object().dict_object_type();
end base_dict_object_type;

overriding member function base_object_name
return varchar2
deterministic
is
begin
  return base_object().object_name();
end base_object_name;

overriding final member procedure base_object_schema
( self in out nocopy oracle_tools.t_dependent_or_granted_object
, p_base_object_schema in varchar2
)
is
  l_base_object oracle_tools.t_named_object := self.base_object();
begin
  if l_base_object.object_schema() = p_base_object_schema
  then
    null; -- no change
  else
    -- change and add again (must exist)
    l_base_object.object_schema(p_base_object_schema);
    all_schema_objects_api.add(p_schema_object => l_base_object, p_must_exist => true);
  end if;  
end base_object_schema;

overriding member procedure chk
( self in oracle_tools.t_dependent_or_granted_object
, p_schema in varchar2
)
is
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'CHK');
$end

  oracle_tools.pkg_ddl_util.chk_schema_object(p_dependent_or_granted_object => self, p_schema => p_schema);

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
  dbug.leave;
$end
end chk;

member function base_object
return oracle_tools.t_named_object
deterministic
is
  l_base_object oracle_tools.t_named_object := null;
begin
  return case when self.base_object_seq$ is not null then treat(all_schema_objects_api.find_by_seq(self.base_object_seq$).obj as oracle_tools.t_named_object) end;
end base_object;

end;
/

