CREATE OR REPLACE TYPE BODY "ORACLE_TOOLS"."T_DEPENDENT_OR_GRANTED_OBJECT" IS

overriding member function base_object_schema
return varchar2
deterministic
is
begin
  return oracle_tools.t_schema_object.split_id(self.base_object_id$)(4);
end base_object_schema;

overriding member function base_object_type
return varchar2
deterministic
is
begin
  return oracle_tools.t_schema_object.split_id(self.base_object_id$)(5);
end base_object_type;

overriding member function base_dict_object_type
return varchar2
deterministic
is
begin
  return oracle_tools.t_schema_object.dict_object_type(self.base_object_type());
end base_dict_object_type;

overriding member function base_object_name
return varchar2
deterministic
is
begin
  return self.base_object_name$;
end base_object_name;

overriding final member procedure base_object_schema
( self in out nocopy oracle_tools.t_dependent_or_granted_object
, p_base_object_schema in varchar2
)
is
  l_id_parts oracle_tools.t_text_tab := oracle_tools.t_schema_object.split_id(self.base_object_id$);
begin
  l_id_parts(4) := p_base_object_schema;
  self.base_object_id$ := oracle_tools.t_schema_object.join_id(l_id_parts);
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

member function base_object_id
return varchar2
deterministic
is
begin
  return oracle_tools.t_schema_object.id
         ( p_object_schema => self.base_object_schema$
         , p_object_type => self.base_object_type$
         , p_object_name => self.base_object_name$
         );
end base_object_id;

end;
/

