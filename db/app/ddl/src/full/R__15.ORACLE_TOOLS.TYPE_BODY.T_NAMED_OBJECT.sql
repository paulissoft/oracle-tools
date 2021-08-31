CREATE OR REPLACE TYPE BODY "ORACLE_TOOLS"."T_NAMED_OBJECT" AS

overriding final member function object_name
return varchar2
deterministic
is
begin
  return self.object_name$;
end object_name;  

final static procedure create_named_object
( p_object_type in varchar2
, p_object_schema in varchar2
, p_object_name in varchar2
, p_named_object out nocopy t_schema_object
)
is
begin
  -- must use PKG_DDL_UTIL.CREATE_NAMED_OBJECT
  raise_application_error(pkg_ddl_error.c_not_implemented, 'T_NAMED_OBJECT.CREATE_NAMED_OBJECT (1)');
end create_named_object;

final static function create_named_object
( p_object_type in varchar2
, p_object_schema in varchar2
, p_object_name in varchar2
)
return t_named_object
is
begin
  -- must use PKG_DDL_UTIL.CREATE_NAMED_OBJECT
  raise_application_error(pkg_ddl_error.c_not_implemented, 'T_NAMED_OBJECT.CREATE_NAMED_OBJECT (2)');
end create_named_object;

overriding member procedure chk
( self in t_named_object
, p_schema in varchar2
)
is
begin
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
  dbug.enter('T_NAMED_OBJECT.CHK');
$end

  pkg_ddl_util.chk_schema_object(p_named_object => self, p_schema => p_schema);

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
  dbug.leave;
$end
end chk;  

end;
/

