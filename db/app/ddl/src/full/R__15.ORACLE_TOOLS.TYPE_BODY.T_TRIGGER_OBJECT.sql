CREATE OR REPLACE TYPE BODY "ORACLE_TOOLS"."T_TRIGGER_OBJECT" AS

constructor function t_trigger_object
( self in out nocopy oracle_tools.t_trigger_object
, p_base_object in oracle_tools.t_named_object
, p_object_schema in varchar2
, p_object_name in varchar2
)
return self as result
is
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.CONSTRUCTOR');
  dbug.print
  ( dbug."input"
  , 'p_base_object.id: %s; p_object_schema: %s; p_object_name: %s'
  , p_base_object.id
  , p_object_schema
  , p_object_name
  );
$end

  if p_base_object is null
  then
    self.base_object_id$ := null;
  else
    self.base_object_id$ := p_base_object.id;
  end if;
  self.network_link$ := null;
  self.object_schema$ := p_object_schema;
  self.object_name$ := p_object_name;

  oracle_tools.t_schema_object.set_id(self);

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
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
  return 'TRIGGER';
end;

overriding member function object_name
return varchar2
deterministic
is
begin
  return self.object_name$;
end object_name;

-- end of getter(s)

overriding member procedure chk
( self in oracle_tools.t_trigger_object
, p_schema in varchar2
)
is
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'CHK');
$end

  oracle_tools.pkg_ddl_util.chk_schema_object(p_dependent_or_granted_object => self, p_schema => p_schema);

  if self.object_schema() = p_schema
  then
    null; -- ok
  else
    oracle_tools.pkg_ddl_error.raise_error(oracle_tools.pkg_ddl_error.c_invalid_parameters, 'Object schema (' || self.object_schema() || ') must be ' || p_schema, self.schema_object_info());
  end if;
  if self.base_object_schema() is null
  then
    oracle_tools.pkg_ddl_error.raise_error(oracle_tools.pkg_ddl_error.c_invalid_parameters, 'Base object schema should not be empty.', self.schema_object_info());
  end if;

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
  dbug.leave;
$end
end chk;

overriding member function dict_object_exists
return integer -- 0/1
is
  l_count pls_integer;
  l_object_schema constant all_triggers.owner%type := self.object_schema();
  l_object_name constant all_triggers.trigger_name%type := self.object_name();
  l_base_object_schema constant all_triggers.table_owner%type := self.base_object_schema();
  l_base_object_name constant all_triggers.table_name%type := self.base_object_name();
begin
  select  sign(count(*))
  into    l_count
  from    all_triggers t
  where   t.owner = l_object_schema
  and     t.trigger_name = l_object_name
  and     t.table_owner = l_base_object_schema
  and     t.table_name = l_base_object_name;
  return l_count;
end;

end;
/

