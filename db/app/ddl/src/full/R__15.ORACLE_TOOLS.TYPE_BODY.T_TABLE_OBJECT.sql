CREATE OR REPLACE TYPE BODY "ORACLE_TOOLS"."T_TABLE_OBJECT" AS

constructor function t_table_object
( self in out nocopy t_table_object
, p_object_schema in varchar2
, p_object_name in varchar2
)
return self as result
is
begin
  -- must use PKG_DDL_UTIL.CREATE_TABLE_OBJECT
  raise_application_error(pkg_ddl_error.c_not_implemented, 'T_TABLE_OBJECT.T_TABLE_OBJECT (1)');
end;

constructor function t_table_object
( self in out nocopy t_table_object
, p_object_schema in varchar2
, p_object_name in varchar2
, p_tablespace_name in varchar2
)
return self as result
is
begin
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 3 $then
  dbug.enter('T_TABLE_OBJECT.T_TABLE_OBJECT (2)');
  dbug.print(dbug."input", 'p_object_schema: %s; p_object_name: %s; p_tablespace_name: %s', p_object_schema, p_object_name, p_tablespace_name);
$end

  self.network_link$ := null;
  self.object_schema$ := p_object_schema;
  self.object_name$ := p_object_name;
  self.tablespace_name$ := p_tablespace_name;

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 3 $then
  dbug.leave;
$end

  return;
end;

member function tablespace_name 
return varchar2
deterministic
is
begin
  return self.tablespace_name$;
end tablespace_name;

member procedure tablespace_name
( self in out nocopy t_table_object
, p_tablespace_name in varchar2
)
is
begin
  self.tablespace_name$ := p_tablespace_name;
end tablespace_name;

overriding member function object_type
return varchar2
deterministic
is
begin
  return 'TABLE';
end object_type;

overriding member procedure chk
( self in t_table_object
, p_schema in varchar2
)
is
begin
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
  dbug.enter('T_TABLE_OBJECT.CHK');
$end

  pkg_ddl_util.chk_schema_object(p_named_object => self, p_schema => p_schema);

  -- tablespace name may or may not be empty

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
  dbug.leave;
$end
end chk;

end;
/

