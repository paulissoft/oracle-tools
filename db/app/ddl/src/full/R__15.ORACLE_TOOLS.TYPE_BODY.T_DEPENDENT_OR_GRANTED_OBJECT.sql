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
  l_base_object oracle_tools.t_named_object;
begin
  select  deref(self.base_object$)
  into    l_base_object
  from    dual;

  if l_base_object.object_schema() = p_base_object_schema
  then
    null; -- no change
  else
    -- remove from all_schema_objects and then insert the new
    delete
    from    all_schema_objects t
    where   t.obj.id() = l_base_object.id();
    
    l_base_object.object_schema(p_base_object_schema);

    insert into all_schema_objects(obj) values (l_base_object);
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
  if base_object$ is not null
  then
    select  deref(base_object$)
    into    l_base_object
    from    dual;
  end if;
  return l_base_object;
end;

end;
/

