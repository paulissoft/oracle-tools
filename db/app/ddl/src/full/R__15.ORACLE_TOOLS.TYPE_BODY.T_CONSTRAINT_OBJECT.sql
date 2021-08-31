CREATE OR REPLACE TYPE BODY "ORACLE_TOOLS"."T_CONSTRAINT_OBJECT" AS

constructor function t_constraint_object
( self in out nocopy t_constraint_object
, p_base_object in t_named_object
, p_object_schema in varchar2
, p_object_name in varchar2
, p_constraint_type in varchar2 default null
, p_column_names in varchar2 default null
, p_search_condition in varchar2 default null
)
return self as result
is
begin
  -- must use PKG_DDL_UTIL.T_CONSTRAINT_OBJECT
  raise_application_error(pkg_ddl_error.c_not_implemented, 'T_CONSTRAINT_OBJECT.T_CONSTRAINT_OBJECT');
end;

-- begin of getter(s)

overriding member function object_type
return varchar2
deterministic
is
begin
  return 'CONSTRAINT';
end object_type;

overriding final member function object_name
return varchar2
deterministic
is
begin
  return self.object_name$;
end object_name;

final member function column_names
return varchar2
deterministic
is
begin
  return self.column_names$;
end column_names;

final member function search_condition
return varchar2
deterministic
is
begin
  return self.search_condition$;
end search_condition;

final member function constraint_type 
return varchar2
deterministic
is
begin
  return self.constraint_type$;
end constraint_type;

-- end of getter(s)

overriding map member function signature
return varchar2
deterministic
is
begin
  return self.object_schema ||
         ':' ||
         self.object_type ||
         ':' ||
         null || -- constraints may be equal between (remote) schemas even though the name is different
         ':' || 
         self.base_object_schema ||
         ':' ||
         self.base_object_type ||
         ':' ||
         self.base_object_name ||
         ':' ||
         self.constraint_type ||
         ':' ||
         self.column_names ||
         ':' ||
         self.search_condition
         ;
end signature;

static function get_column_names
( p_object_schema in varchar2
, p_object_name in varchar2
, p_table_name in varchar2
)
return varchar2
is
begin
  -- must use PKG_DDL_UTIL.GET_COLUMN_NAMES
  raise_application_error(pkg_ddl_error.c_not_implemented, 'T_CONSTRAINT_OBJECT.GET_COLUMN_NAMES');
end get_column_names;

overriding member procedure chk
( self in t_constraint_object
, p_schema in varchar2
)
is
begin
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
  dbug.enter('T_CONSTRAINT_OBJECT.CHK');
$end

  pkg_ddl_util.chk_schema_object(p_constraint_object => self, p_schema => p_schema);

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end chk;

end;
/

