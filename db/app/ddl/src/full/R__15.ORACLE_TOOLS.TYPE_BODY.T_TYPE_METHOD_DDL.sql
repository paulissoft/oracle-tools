CREATE OR REPLACE TYPE BODY "ORACLE_TOOLS"."T_TYPE_METHOD_DDL" AS

constructor function t_type_method_ddl
( self in out nocopy oracle_tools.t_type_method_ddl
, p_obj in oracle_tools.t_schema_object
)
return self as result
is
  l_type_method_object oracle_tools.t_type_method_object := treat(p_obj as oracle_tools.t_type_method_object);
  l_buffer varchar2(32767 char) := null;
  l_clob clob := null;
  " ADD  " constant varchar2(6) := ' ADD  '; -- so we can replace 'ADD ' by 'DROP'
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_defs.c_debugging >= 3 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.CONSTRUCTOR');
$end

  self.obj := p_obj;
  self.ddl_tab := oracle_tools.t_ddl_tab();

  /* construct the ALTER TYPE ADD METHOD here */
  oracle_tools.pkg_str_util.append_text
  ( pi_text => 'ALTER TYPE "' || l_type_method_object.base_object_schema() || '"."' || l_type_method_object.base_object_name() || '"' || " ADD  " || chr(10)
  , pio_buffer => l_buffer
  , pio_clob => l_clob
  );

  oracle_tools.pkg_str_util.append_text
  ( pi_text => l_type_method_object.signature()
  , pio_buffer => l_buffer
  , pio_clob => l_clob
  );

  oracle_tools.pkg_str_util.append_text
  ( pi_text => chr(10) || 'CASCADE'
  , pio_buffer => l_buffer
  , pio_clob => l_clob
  );

  -- append the buffer to l_clob (if that has not already been done)
  oracle_tools.pkg_str_util.append_text
  ( pi_buffer => l_buffer
  , pio_clob => l_clob
  );

  -- finished
  self.add_ddl(p_verb => 'ALTER', p_text => l_clob);

  dbms_lob.freetemporary(l_clob);

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_defs.c_debugging >= 3 $then
  dbug.leave;
$end

  return;
end;

overriding member procedure migrate
( self in out nocopy oracle_tools.t_type_method_ddl
, p_source in oracle_tools.t_schema_ddl
, p_target in oracle_tools.t_schema_ddl
)
is
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_defs.c_debugging >= 2 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'MIGRATE');
  dbug.print(dbug."input", 'p_source: %s; p_target: %s', p_source.obj.signature(), p_target.obj.signature());
$end

  -- first the standard things
  oracle_tools.t_schema_ddl.migrate
  ( p_source => p_source
  , p_target => p_target
  , p_schema_ddl => self
  );

  self.uninstall(p_target => p_target);
  self.install(p_source => p_source);

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_defs.c_debugging >= 2 $then
  dbug.leave;
$end
end migrate;

overriding member procedure uninstall
( self in out nocopy oracle_tools.t_type_method_ddl
, p_target in oracle_tools.t_schema_ddl
)
is
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_defs.c_debugging >= 2 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'UNINSTALL');
$end

  self.ddl_tab := p_target.ddl_tab;

  self.ddl_tab(1).text_tab(1) := replace(self.ddl_tab(1).text_tab(1), 'ADD ', 'DROP');

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_defs.c_debugging >= 2 $then
  dbug.leave;
$end
end uninstall;

end;
/

