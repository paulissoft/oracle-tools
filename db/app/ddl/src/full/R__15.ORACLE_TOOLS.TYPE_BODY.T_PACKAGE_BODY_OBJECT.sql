CREATE OR REPLACE TYPE BODY "ORACLE_TOOLS"."T_PACKAGE_BODY_OBJECT" AS

constructor function t_package_body_object
( self in out nocopy t_package_body_object
, p_object_schema in varchar2
, p_object_name in varchar2
)
return self as result
is
begin
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 3 $then
  dbug.enter('T_PACKAGE_BODY_OBJECT.T_PACKAGE_BODY_OBJECT');
  dbug.print
  ( dbug."input"
  , 'p_object_schema: %s; p_object_name: %s'
  , p_object_schema
  , p_object_name
  );
$end

  self.network_link$ := null;
  self.object_schema$ := p_object_schema;
  self.object_name$ := p_object_name;

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 3 $then
  dbug.leave;
$end

  return;
end;

overriding member function object_type
return varchar2
deterministic
is
begin
  return 'PACKAGE_BODY';
end object_type;

end;
/

