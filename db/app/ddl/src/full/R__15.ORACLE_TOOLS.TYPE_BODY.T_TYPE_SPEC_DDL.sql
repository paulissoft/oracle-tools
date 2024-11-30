CREATE OR REPLACE TYPE BODY "ORACLE_TOOLS"."T_TYPE_SPEC_DDL" IS

overriding member procedure migrate
( self in out nocopy oracle_tools.t_type_spec_ddl
, p_source in oracle_tools.t_schema_ddl
, p_target in oracle_tools.t_schema_ddl
)
is
  l_source_type_spec_object oracle_tools.t_type_spec_object := treat(p_source.obj as oracle_tools.t_type_spec_object);
  l_target_type_spec_object oracle_tools.t_type_spec_object := treat(p_target.obj as oracle_tools.t_type_spec_object);
  l_source_member_ddl_tab oracle_tools.t_schema_ddl_tab;
  l_target_member_ddl_tab oracle_tools.t_schema_ddl_tab;
  l_type_attribute_ddl oracle_tools.t_schema_ddl;
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'MIGRATE');
  dbug.print(dbug."input", 'p_source.obj.id: %s; p_target.obj.id: %s', p_source.obj.id, p_target.obj.id);
$end

  -- first the standard things
  oracle_tools.t_schema_ddl.migrate
  ( p_source => p_source
  , p_target => p_target
  , p_schema_ddl => self
  );

  oracle_tools.pkg_ddl_util.get_member_ddl
  ( p_source
  , l_source_member_ddl_tab
  );
  oracle_tools.pkg_ddl_util.get_member_ddl
  ( p_target
  , l_target_member_ddl_tab
  );

  for r in
  ( select  value(s) as source_schema_ddl
    ,       value(t) as target_schema_ddl
    from    table(l_source_member_ddl_tab) s
            full outer join table(l_target_member_ddl_tab) t
            on t.obj = s.obj -- map function is used
    order by
            treat(s.obj as oracle_tools.t_type_attribute_object).member#() nulls last  -- dropping attributes after adding (since we might drop the last attribute if we reverse it)
  )
  loop
    l_type_attribute_ddl := null;
    if r.source_schema_ddl is null
    then
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
      dbug.print(dbug."info", '*** target column ***');
      r.target_schema_ddl.print();
$end
      oracle_tools.t_schema_ddl.create_schema_ddl
      ( r.target_schema_ddl.obj
      , oracle_tools.t_ddl_tab()
      , l_type_attribute_ddl
      );
      l_type_attribute_ddl.uninstall(r.target_schema_ddl);
    elsif r.target_schema_ddl is null
    then
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
      dbug.print(dbug."info", '*** source column ***');
      r.source_schema_ddl.print();
$end
      oracle_tools.t_schema_ddl.create_schema_ddl
      ( r.source_schema_ddl.obj
      , oracle_tools.t_ddl_tab()
      , l_type_attribute_ddl
      );
      l_type_attribute_ddl.install(r.source_schema_ddl);
    elsif r.source_schema_ddl <> r.target_schema_ddl
    then
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
      dbug.print(dbug."info", '*** source column ***');
      r.source_schema_ddl.print();
      dbug.print(dbug."info", '*** target column ***');
      r.target_schema_ddl.print();
$end
      oracle_tools.t_schema_ddl.create_schema_ddl
      ( r.source_schema_ddl.obj
      , oracle_tools.t_ddl_tab()
      , l_type_attribute_ddl
      );
      l_type_attribute_ddl.migrate
      ( p_source => r.source_schema_ddl
      , p_target => r.target_schema_ddl
      );
    end if;
    if l_type_attribute_ddl is not null and l_type_attribute_ddl.ddl_tab is not null and l_type_attribute_ddl.ddl_tab.count > 0
    then
      for i_idx in l_type_attribute_ddl.ddl_tab.first .. l_type_attribute_ddl.ddl_tab.last
      loop
        self.add_ddl
        ( p_verb => l_type_attribute_ddl.ddl_tab(i_idx).verb()
          -- the schema is
        , p_text_tab => l_type_attribute_ddl.ddl_tab(i_idx).text_tab
        );
      end loop;
    end if;
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
    if l_type_attribute_ddl is not null
    then
      dbug.print(dbug."info", '*** result column ***');
      l_type_attribute_ddl.print();
    end if;
$end
  end loop;

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
  dbug.leave;
$end
end migrate;

overriding member procedure uninstall
( self in out nocopy oracle_tools.t_type_spec_ddl
, p_target in oracle_tools.t_schema_ddl
)
is
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'UNINSTALL');
$end

  self.add_ddl
  ( p_verb => 'DROP'
  , p_text => 'DROP ' || p_target.obj.dict_object_type() || ' ' || p_target.obj.fq_object_name() || ' FORCE'
  , p_add_sqlterminator => case when oracle_tools.pkg_ddl_util.c_use_sqlterminator then 1 else 0 end
  );

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
  dbug.leave;
$end
end uninstall;

end;
/

