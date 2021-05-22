CREATE OR REPLACE TYPE BODY "ORACLE_TOOLS"."T_VIEW_OBJECT" AS

constructor function t_view_object
( self in out nocopy t_view_object
, p_object_schema in varchar2
, p_object_name in varchar2
)
return self as result
is
begin
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 3 $then
  dbug.enter('T_VIEW_OBJECT.T_VIEW_OBJECT');
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
  return 'VIEW';
end object_type;

end;
/

