CREATE OR REPLACE TYPE BODY "ORACLE_TOOLS"."T_PROCOBJ_OBJECT" AS

constructor function t_procobj_object
( self in out nocopy t_procobj_object
, p_object_schema in varchar2
, p_object_name in varchar2
)
return self as result
is
begin
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 3 $then
  dbug.enter('T_PROCOBJ_OBJECT.T_PROCOBJ_OBJECT');
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

  select  obj.object_type
  into    self.dict_object_type$
  from    all_objects obj
  where   obj.owner = p_object_schema
  and     obj.object_name = p_object_name
  ;

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 3 $then
  dbug.leave;
$end

  return;
end;
  
overriding member function dict_object_type 
return varchar2
deterministic
is
begin
  return self.dict_object_type$;
end dict_object_type;

overriding member function object_type
return varchar2
deterministic
is
begin
  return 'PROCOBJ';
end object_type;

overriding member procedure chk
( self in t_procobj_object
, p_schema in varchar2
)
is
begin
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
  dbug.enter('T_PROCOBJ_OBJECT.CHK');
$end

  pkg_ddl_util.chk_schema_object(p_named_object => self, p_schema => p_schema);

  if self.dict_object_type() is null
  then
    raise_application_error(-20000, 'Dictionary object type should not be null.');
  end if;
  
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
  dbug.leave;
$end
end chk;

end;
/

