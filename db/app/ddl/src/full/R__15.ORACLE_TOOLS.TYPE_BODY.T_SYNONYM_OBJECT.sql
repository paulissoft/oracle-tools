CREATE OR REPLACE TYPE BODY "ORACLE_TOOLS"."T_SYNONYM_OBJECT" AS

constructor function t_synonym_object
( self in out nocopy oracle_tools.t_synonym_object
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
  , 'p_base_object.id(): %s; p_object_schema: %s; p_object_name: %s'
  , p_base_object.id()
  , p_object_schema
  , p_object_name
  );
$end

  self.base_object_seq$ := case when p_base_object is not null then schema_objects_api.find_by_object_id(p_base_object.id()).seq end;
  self.network_link$ := null;
  self.object_schema$ := p_object_schema;
  self.object_name$ := p_object_name;

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
  return 'SYNONYM';
end object_type;

overriding member function object_name
return varchar2
deterministic
is
begin
  return self.object_name$;
end object_name;

-- end of getter(s)

overriding member procedure chk
( self in oracle_tools.t_synonym_object
, p_schema in varchar2
)
is
  l_error_message varchar2(2000 char) := null;
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'CHK');
  dbug.print(dbug."input", 'self:');
  self.print();
$end

  -- GPA 2017-01-18
  -- Do not call
  --
  --   oracle_tools.pkg_ddl_util.chk_schema_object(p_dependent_or_granted_object => self, p_schema => p_schema);
  --
  -- for a PUBLIC synonym

  if self.object_schema() in ('PUBLIC', p_schema)
  then
    null; -- ok
  else
    l_error_message := 'Object schema must be PUBLIC or ' || p_schema;
  end if;

  if self.object_schema() = 'PUBLIC'
  then
    if (self.base_object_schema() is null)
    then
      l_error_message := 'Base object schema should not be empty';
    end if;
    if self.base_object_schema() = p_schema
    then
      null; -- ok
    else
      l_error_message := 'Base object schema must be ' || p_schema || ' for a PUBLIC synonym';
    end if;
  else
    if self.object_schema() = p_schema
    then
      null; -- ok
    else
      l_error_message := 'Object schema must be ' || p_schema || ' for a private synonym';
    end if;
  end if;

  if l_error_message is not null
  then
    oracle_tools.pkg_ddl_error.raise_error(oracle_tools.pkg_ddl_error.c_invalid_parameters, l_error_message, self.schema_object_info());
  end if;
  
  if self.object_schema() = 'PUBLIC'
  then
    null;
  else  
    oracle_tools.pkg_ddl_util.chk_schema_object(p_dependent_or_granted_object => self, p_schema => p_schema);
  end if;

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
  dbug.leave;
$end
end chk;

end;
/

