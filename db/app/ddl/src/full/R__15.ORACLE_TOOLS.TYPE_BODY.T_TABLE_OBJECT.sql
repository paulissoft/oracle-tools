CREATE OR REPLACE TYPE BODY "ORACLE_TOOLS"."T_TABLE_OBJECT" AS

constructor function t_table_object
( self in out nocopy oracle_tools.t_table_object
, p_object_schema in varchar2
, p_object_name in varchar2
)
return self as result
is
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_defs.c_debugging >= 3 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.CONSTRUCTOR' || ' (1)');
  dbug.print
  ( dbug."input"
  , 'p_object_schema: %s; p_object_name: %s'
  , p_object_schema
  , p_object_name
  );
$end

 -- non default constructor
  self := oracle_tools.t_table_object(p_object_schema, p_object_name, null);

  if self.tablespace_name$ is null
  then
    begin
      -- standard table?
      select  t.tablespace_name
      into    self.tablespace_name$
      from    all_tables t
      where   t.owner = p_object_schema
      and     t.table_name = p_object_name
      ;
    exception
      when no_data_found
      then
        -- maybe a temporary table
        self.tablespace_name$ := null;
    end;
  end if;

  oracle_tools.t_schema_object.normalize(self);

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_defs.c_debugging >= 3 $then
  dbug.print(dbug."info", 'self.tablespace_name$: %s', self.tablespace_name$);
  dbug.leave;
$end

  return;
end;

constructor function t_table_object
( self in out nocopy oracle_tools.t_table_object
, p_object_schema in varchar2
, p_object_name in varchar2
, p_tablespace_name in varchar2
)
return self as result
is
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_defs.c_debugging >= 3 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.CONSTRUCTOR' || ' (2)');
  dbug.print(dbug."input", 'p_object_schema: %s; p_object_name: %s; p_tablespace_name: %s', p_object_schema, p_object_name, p_tablespace_name);
$end

  self.network_link$ := null;
  self.object_schema$ := p_object_schema;
  self.object_name$ := p_object_name;
  self.tablespace_name$ := p_tablespace_name;

  oracle_tools.t_schema_object.normalize(self);

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_defs.c_debugging >= 3 $then
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
( self in out nocopy oracle_tools.t_table_object
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
( self in oracle_tools.t_table_object
, p_schema in varchar2
)
is
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_defs.c_debugging >= 3 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'CHK');
$end

  oracle_tools.pkg_ddl_util.chk_schema_object(p_named_object => self, p_schema => p_schema);

  -- tablespace name may or may not be empty

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_defs.c_debugging >= 3 $then
  dbug.leave;
$end
end chk;

end;
/

