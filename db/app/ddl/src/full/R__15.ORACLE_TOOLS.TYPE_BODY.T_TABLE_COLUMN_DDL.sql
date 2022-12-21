CREATE OR REPLACE TYPE BODY "ORACLE_TOOLS"."T_TABLE_COLUMN_DDL" AS

constructor function t_table_column_ddl
( self in out nocopy oracle_tools.t_table_column_ddl
, p_obj in oracle_tools.t_schema_object
)
return self as result
is
  l_table_column_object oracle_tools.t_table_column_object := treat(p_obj as oracle_tools.t_table_column_object);
  l_buffer varchar2(32767 char) := null;
  l_clob clob := null;
  "ADD" constant varchar2(5) := ' ADD ';
  l_data_default t_text_tab;
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT);
$end

  self.obj := p_obj;
  self.ddl_tab := t_ddl_tab();

  /* construct the ALTER TABLE ADD COLUMN here */

  oracle_tools.pkg_str_util.append_text
  ( pi_text => 'ALTER TABLE "' || l_table_column_object.base_object_schema() || '"."' || l_table_column_object.base_object_name() || '"' ||
               "ADD" || '"' || l_table_column_object.column_name() || '" '
  , pio_buffer => l_buffer
  , pio_clob => l_clob
  );

  -- datatype
  oracle_tools.pkg_str_util.append_text
  ( pi_text => l_table_column_object.data_type()
  , pio_buffer => l_buffer
  , pio_clob => l_clob
  );

  -- default?
  if l_table_column_object.default_length() > 0 and l_table_column_object.data_default() is not null
  then
    oracle_tools.pkg_str_util.append_text
    ( pi_text => ' DEFAULT '
    , pio_buffer => l_buffer
    , pio_clob => l_clob
    );
    l_data_default := l_table_column_object.data_default();
    for i_idx in l_data_default.first .. l_data_default.last
    loop
      oracle_tools.pkg_str_util.append_text
      ( pi_text => l_data_default(i_idx)
      , pio_buffer => l_buffer
      , pio_clob => l_clob
      );
    end loop;
  end if;

  if l_table_column_object.nullable() = 'N'
  then
    oracle_tools.pkg_str_util.append_text
    ( pi_text => ' NOT NULL'
    , pio_buffer => l_buffer
    , pio_clob => l_clob
    );
  end if;

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

  dbms_lob.freetemporary(l_clob);

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
  dbug.leave;
$end

  return;
end;

overriding member procedure migrate
( self in out nocopy oracle_tools.t_table_column_ddl
, p_source in oracle_tools.t_schema_ddl
, p_target in oracle_tools.t_schema_ddl
)
is
  l_buffer varchar2(32767 char) := null;
  l_clob clob := null;
  l_source_table_column_object oracle_tools.t_table_column_object := treat(p_source.obj as oracle_tools.t_table_column_object);
  l_target_table_column_object oracle_tools.t_table_column_object := treat(p_target.obj as oracle_tools.t_table_column_object);
  l_data_default t_text_tab;
  l_changed boolean;
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'MIGRATE');
  dbug.print(dbug."input", 'p_source: %s; p_target: %s', p_source.obj.signature(), p_target.obj.signature());
$end

  -- invoke the super method
  oracle_tools.t_schema_ddl.migrate
  ( p_source => p_source
  , p_target => p_target
  , p_schema_ddl => self
  );

  for i_ddl_idx in 1..3
  loop
    l_clob := null;
    l_buffer := null;
    l_changed := false;

    oracle_tools.pkg_str_util.append_text
    ( pi_text => 'ALTER TABLE "' || l_source_table_column_object.base_object_schema() || '"."' || l_source_table_column_object.base_object_name() || '"' ||
                 ' MODIFY "' || l_source_table_column_object.member_name() || '" '
    , pio_buffer => l_buffer
    , pio_clob => l_clob
    );

    case i_ddl_idx
      when 1
      then
        -- datatype changed?
        if l_source_table_column_object.data_type() != l_target_table_column_object.data_type()
        then
          oracle_tools.pkg_str_util.append_text
          ( pi_text => l_source_table_column_object.data_type()
          , pio_buffer => l_buffer
          , pio_clob => l_clob
          );
          l_changed := true;
        end if;

      when 2
      then
        -- default changed?
        if l_source_table_column_object.data_default() != l_target_table_column_object.data_default()
        then
          oracle_tools.pkg_str_util.append_text
          ( pi_text => 'DEFAULT '
          , pio_buffer => l_buffer
          , pio_clob => l_clob
          );
          l_data_default := l_source_table_column_object.data_default();
          if cardinality(l_data_default) > 0
          then
            for i_idx in l_data_default.first .. l_data_default.last
            loop
              oracle_tools.pkg_str_util.append_text
              ( pi_text => l_data_default(i_idx)
              , pio_buffer => l_buffer
              , pio_clob => l_clob
              );
            end loop;
          else
            oracle_tools.pkg_str_util.append_text
            ( pi_text => 'NULL'
            , pio_buffer => l_buffer
            , pio_clob => l_clob
            );
          end if;
          l_changed := true;
        end if;

      when 3
      then
        if l_source_table_column_object.nullable() != l_target_table_column_object.nullable()
        then
          oracle_tools.pkg_str_util.append_text
          ( pi_text => case l_source_table_column_object.nullable() when 'N' then 'NOT NULL' else 'NULL' end
          , pio_buffer => l_buffer
          , pio_clob => l_clob
          );
          l_changed := true;
        end if;
    end case;

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
  end loop;

  if l_clob is not null
  then
    dbms_lob.freetemporary(l_clob);
  end if;

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
  dbug.leave;
$end
end migrate;

overriding member procedure uninstall
( self in out nocopy oracle_tools.t_table_column_ddl
, p_target in oracle_tools.t_schema_ddl
)
is
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'UNINSTALL');
$end

  -- ALTER TABLE "owner"."table" DROP COLUMN "column"
  self.add_ddl
  ( p_verb => 'ALTER'
  , p_text => 'ALTER ' ||
              p_target.obj.base_object_type() ||
              ' "' ||
              p_target.obj.base_object_schema() ||
              '"."' ||
              p_target.obj.base_object_name() ||
              '"' ||
              ' DROP COLUMN "' ||
              treat(p_target.obj as oracle_tools.t_table_column_object).member_name() ||
              '"'
  , p_add_sqlterminator => case when oracle_tools.pkg_ddl_util.c_use_sqlterminator then 1 else 0 end
  );

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
  dbug.leave;
$end
end uninstall;

end;
/

