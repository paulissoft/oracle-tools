CREATE OR REPLACE TYPE BODY "ORACLE_TOOLS"."T_COMMENT_OBJECT" AS

constructor function t_comment_object
( self in out nocopy t_comment_object
, p_base_object in t_named_object
, p_object_schema in varchar2
, p_column_name in varchar2
)
return self as result
is
begin
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
  dbug.enter('T_COMMENT_OBJECT.T_COMMENT_OBJECT');
  dbug.print
  ( dbug."input"
  , 'p_base_object.id(): %s; p_object_schema: %s; p_column_name: %s'
  , p_base_object.id()
  , p_object_schema
  , p_column_name
  );
$end

  self.base_object$ := p_base_object;
  self.network_link$ := null;
  self.object_schema$ := p_object_schema;
  self.column_name$ := p_column_name;

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
  dbug.leave;
$end

  return;
end;  

-- begin of getter(s)

overriding member function object_type
return varchar2
deterministic
is
begin
  return 'COMMENT';
end object_type;

overriding member function column_name
return varchar2
deterministic
is
begin
  return self.column_name$;
end column_name;

-- end of getter(s)

overriding member procedure chk
( self in t_comment_object
, p_schema in varchar2
)
is
begin
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
  dbug.enter('T_COMMENT_OBJECT.CHK');
$end

  pkg_ddl_util.chk_schema_object(p_dependent_or_granted_object => self, p_schema => p_schema);

  if self.object_schema() is not null
  then
    raise_application_error(-20000, 'Object schema should be empty.');
  end if;
  if self.object_name() is not null
  then
    raise_application_error(-20000, 'Object name should be empty.');
  end if;

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
  dbug.leave;
$end  
end chk;

end;
/

