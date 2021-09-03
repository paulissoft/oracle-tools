CREATE OR REPLACE TYPE BODY "ORACLE_TOOLS"."T_JAVA_SOURCE_OBJECT" AS

constructor function t_java_source_object
( self in out nocopy oracle_tools.t_java_source_object
, p_object_schema in varchar2
, p_object_name in varchar2
)
return self as result
is
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT);
$end

  self.network_link$ := null;
  self.object_schema$ := p_object_schema;
  self.object_name$ := p_object_name;

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
  dbug.leave;
$end

  return;
end;

overriding member function object_type
return varchar2
deterministic
is
begin
  return 'JAVA_SOURCE';
end object_type;

end;
/

