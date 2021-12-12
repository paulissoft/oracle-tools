CREATE OR REPLACE TYPE BODY "ORACLE_TOOLS"."T_TYPE_ATTRIBUTE_DDL" AS

constructor function t_type_attribute_ddl
( self in out nocopy oracle_tools.t_type_attribute_ddl
, p_obj in oracle_tools.t_schema_object
)
return self as result
is
  l_type_attribute_object oracle_tools.t_type_attribute_object := treat(p_obj as oracle_tools.t_type_attribute_object);
  l_buffer varchar2(32767 char) := null;
  l_clob clob := null;
  " ADD " constant varchar2(5) := ' ADD ';
  l_data_default t_text_tab;
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT);
$end

  self.obj := p_obj;
  self.ddl_tab := t_ddl_tab();

  /* construct the ALTER TYPE ADD ATTRIBUTE here */ 

  oracle_tools.pkg_str_util.append_text
  ( pi_text => 'ALTER TYPE "' || l_type_attribute_object.base_object_schema() || '"."' || l_type_attribute_object.base_object_name() || '"' ||
               " ADD " || 'ATTRIBUTE "' || l_type_attribute_object.member_name() || '" ' || l_type_attribute_object.data_type()
  , pio_buffer => l_buffer
  , pio_clob => l_clob
  );

  -- append the buffer to l_clob (if that has not already been done)
  oracle_tools.pkg_str_util.append_text
  ( pi_buffer => l_buffer
  , pio_clob => l_clob
  );

  self.add_ddl
  ( p_verb => 'ALTER'
  , p_text => l_clob
  );

  dbms_lob.freetemporary(l_clob);

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
  dbug.leave;
$end

  return;
end;

overriding member procedure migrate
( self in out nocopy oracle_tools.t_type_attribute_ddl
, p_source in oracle_tools.t_schema_ddl
, p_target in oracle_tools.t_schema_ddl
)
is
  l_buffer varchar2(32767 char) := null;
  l_clob clob := null;
  l_source_type_attribute_object oracle_tools.t_type_attribute_object := treat(p_source.obj as oracle_tools.t_type_attribute_object);
  l_target_type_attribute_object oracle_tools.t_type_attribute_object := treat(p_target.obj as oracle_tools.t_type_attribute_object);
  l_changed boolean;
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'MIGRATE');
  dbug.print(dbug."input", 'p_source: %s; p_target: %s', p_source.obj.signature(), p_target.obj.signature());
$end

  -- first the standard things
  oracle_tools.t_schema_ddl.migrate
  ( p_source => p_source
  , p_target => p_target
  , p_schema_ddl => self
  );

  l_changed := false;

  oracle_tools.pkg_str_util.append_text
  ( pi_text => 'ALTER TYPE "' || l_source_type_attribute_object.base_object_schema() || '"."' || l_source_type_attribute_object.base_object_name() || '"' ||
               ' MODIFY "' || l_source_type_attribute_object.member_name() || '" '
  , pio_buffer => l_buffer
  , pio_clob => l_clob
  );

  -- datatype changed?
  if l_source_type_attribute_object.data_type() != l_target_type_attribute_object.data_type()
  then
    oracle_tools.pkg_str_util.append_text
    ( pi_text => l_source_type_attribute_object.data_type()
    , pio_buffer => l_buffer
    , pio_clob => l_clob
    );
    l_changed := true;
  end if;

  if l_changed
  then
    -- append the buffer to l_clob (if that has not already been done)
    oracle_tools.pkg_str_util.append_text
    ( pi_buffer => l_buffer
    , pio_clob => l_clob
    );

    self.add_ddl
    ( p_verb => 'ALTER'
    , p_text => l_clob
    , p_add_sqlterminator => case when oracle_tools.pkg_ddl_util.c_use_sqlterminator then 1 else 0 end
    );
  end if;

  if l_clob is not null
  then
    dbms_lob.freetemporary(l_clob);
  end if;

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
  dbug.leave;
$end
end migrate;

overriding member procedure uninstall
( self in out nocopy oracle_tools.t_type_attribute_ddl
, p_target in oracle_tools.t_schema_ddl
)
is
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'UNINSTALL');
$end

  -- ALTER type "owner"."type" DROP ATTRIBUTE "column"
  self.add_ddl
  ( p_verb => 'ALTER'
  , p_text => 'ALTER ' ||
              p_target.obj.base_object_type() ||
              ' "' ||
              p_target.obj.base_object_schema() ||
              '"."' ||
              p_target.obj.base_object_name() ||
              '"' ||
              ' DROP ATTRIBUTE "' ||
              treat(p_target.obj as oracle_tools.t_type_attribute_object).member_name() ||
              '"'
  , p_add_sqlterminator => case when oracle_tools.pkg_ddl_util.c_use_sqlterminator then 1 else 0 end          
  );

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
  dbug.leave;
$end
end uninstall;

end;
/

