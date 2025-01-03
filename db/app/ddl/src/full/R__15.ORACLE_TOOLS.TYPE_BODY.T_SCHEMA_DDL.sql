CREATE OR REPLACE TYPE BODY "ORACLE_TOOLS"."T_SCHEMA_DDL" AS

static procedure create_schema_ddl
( p_obj in oracle_tools.t_schema_object
, p_ddl_tab in oracle_tools.t_ddl_tab
, p_schema_ddl out nocopy oracle_tools.t_schema_ddl
)
is
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_defs.c_debugging >= 2 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'CREATE_SCHEMA_DDL (1)');
$end

  case
    /* T_COMMENT_DDL */
    when p_obj is of (oracle_tools.t_comment_object) then p_schema_ddl := oracle_tools.t_comment_ddl(p_obj, p_ddl_tab);
    /* T_CONSTRAINT_DDL */
    when p_obj is of (oracle_tools.t_constraint_object) then p_schema_ddl := oracle_tools.t_constraint_ddl(p_obj, p_ddl_tab);    
    /* T_INDEX_DDL */
    when p_obj is of (oracle_tools.t_index_object) then p_schema_ddl := oracle_tools.t_index_ddl(p_obj, p_ddl_tab);
    /* T_MATERIALIZED_VIEW_DDL */
    when p_obj is of (oracle_tools.t_materialized_view_object) then p_schema_ddl := oracle_tools.t_materialized_view_ddl(p_obj, p_ddl_tab);
    /* T_OBJECT_GRANT_DDL */
    when p_obj is of (oracle_tools.t_object_grant_object) then p_schema_ddl := oracle_tools.t_object_grant_ddl(p_obj, p_ddl_tab);
    /* T_PROCOBJ_DDL */
    when p_obj is of (oracle_tools.t_procobj_object) then p_schema_ddl := oracle_tools.t_procobj_ddl(p_obj, p_ddl_tab);
    /* T_REFRESH_GROUP_DDL */
    when p_obj is of (oracle_tools.t_refresh_group_object) then p_schema_ddl := oracle_tools.t_refresh_group_ddl(p_obj, p_ddl_tab);
    /* T_SEQUENCE_DDL */
    when p_obj is of (oracle_tools.t_sequence_object) then p_schema_ddl := oracle_tools.t_sequence_ddl(p_obj, p_ddl_tab);
    /* T_SYNONYM_DDL */
    when p_obj is of (oracle_tools.t_synonym_object) then p_schema_ddl := oracle_tools.t_synonym_ddl(p_obj, p_ddl_tab);
    -- oracle_tools.t_table_column_object inherits from oracle_tools.t_type_attribute_object
    /* T_TABLE_COLUMN_DDL */
    when p_obj is of (oracle_tools.t_table_column_object) then p_schema_ddl := oracle_tools.t_table_column_ddl(p_obj, p_ddl_tab);
    /* T_TABLE_DDL */
    when p_obj is of (oracle_tools.t_table_object) then p_schema_ddl := oracle_tools.t_table_ddl(p_obj, p_ddl_tab);
    /* T_TRIGGER_DDL */
    when p_obj is of (oracle_tools.t_trigger_object) then p_schema_ddl := oracle_tools.t_trigger_ddl(p_obj, p_ddl_tab);
    /* T_TYPE_ATTRIBUTE_DDL */
    when p_obj is of (oracle_tools.t_type_attribute_object) then p_schema_ddl := oracle_tools.t_type_attribute_ddl(p_obj, p_ddl_tab);
    /* T_TYPE_METHOD_DDL */
    when p_obj is of (oracle_tools.t_type_method_object) then p_schema_ddl := oracle_tools.t_type_method_ddl(p_obj, p_ddl_tab);
    /* T_TYPE_SPEC_DDL */
    when p_obj is of (oracle_tools.t_type_spec_object) then p_schema_ddl := oracle_tools.t_type_spec_ddl(p_obj, p_ddl_tab);
    -- GPA 2017-03-27 #142494703 The DDL generator should remove leading whitespace before WHEN clauses in triggers because that generates differences.
    else p_schema_ddl := oracle_tools.t_schema_ddl(p_obj, p_ddl_tab);
  end case;

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_defs.c_debugging >= 2 $then
  dbug.leave;
$end
end create_schema_ddl;

static function create_schema_ddl
( p_obj in oracle_tools.t_schema_object
, p_ddl_tab in oracle_tools.t_ddl_tab
)
return oracle_tools.t_schema_ddl
is
  l_schema_ddl oracle_tools.t_schema_ddl;
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_defs.c_debugging >= 2 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'CREATE_SCHEMA_DDL (2)');
$end

  oracle_tools.t_schema_ddl.create_schema_ddl
  ( p_obj => p_obj
  , p_ddl_tab => p_ddl_tab
  , p_schema_ddl => l_schema_ddl
  );

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_defs.c_debugging >= 2 $then
  dbug.leave;
$end

  return l_schema_ddl;
end create_schema_ddl;

static function create_schema_ddl
( p_display_ddl_sql_tab in oracle_tools.t_display_ddl_sql_tab
, p_obj in oracle_tools.t_schema_object
)
return oracle_tools.t_schema_ddl
is
  l_schema_ddl oracle_tools.t_schema_ddl := null;
  l_obj oracle_tools.t_schema_object := p_obj;
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_defs.c_debugging >= 2 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'CREATE_SCHEMA_DDL (3)');
$end

  if cardinality(p_display_ddl_sql_tab) > 0
  then
    -- create a schema ddl with an empty ddl table based on the first schema_object_id
    if l_obj is null
    then
      l_obj := oracle_tools.ddl_crud_api.find_schema_object(p_display_ddl_sql_tab(1).schema_object_id);
      if l_obj is null
      then
        raise no_data_found;
      end if;
    end if;

    l_schema_ddl := 
      oracle_tools.t_schema_ddl.create_schema_ddl
      ( p_obj => l_obj
      , p_ddl_tab => oracle_tools.t_ddl_tab()
      );

    -- append to l_schema_ddl.ddl_tab (ddl# is number of items in ddl_tab)
    for i_idx in p_display_ddl_sql_tab.first .. p_display_ddl_sql_tab.last
    loop
      if p_display_ddl_sql_tab(i_idx).ddl# > cardinality(l_schema_ddl.ddl_tab)
      then
        l_schema_ddl.ddl_tab.extend(1);
        l_schema_ddl.ddl_tab(l_schema_ddl.ddl_tab.last) :=
          oracle_tools.t_ddl
          ( p_ddl# => p_display_ddl_sql_tab(i_idx).ddl#
          , p_verb => p_display_ddl_sql_tab(i_idx).verb
          , p_text_tab => oracle_tools.t_text_tab()
          );
      end if;

      if p_display_ddl_sql_tab(i_idx).ddl# = l_schema_ddl.ddl_tab.last
      then
        null; -- OK
      else
        raise program_error;
      end if;

      -- always append to l_schema_ddl.ddl_tab(l_schema_ddl.ddl_tab.last).text_tab
      l_schema_ddl.ddl_tab(l_schema_ddl.ddl_tab.last).text_tab.extend(1);
      l_schema_ddl.ddl_tab(l_schema_ddl.ddl_tab.last).text_tab(l_schema_ddl.ddl_tab(l_schema_ddl.ddl_tab.last).text_tab.last) :=
        p_display_ddl_sql_tab(i_idx).chunk;
        
      if p_display_ddl_sql_tab(i_idx).chunk# = l_schema_ddl.ddl_tab(l_schema_ddl.ddl_tab.last).text_tab.last
      then
        null; -- OK
      else
        raise program_error;
      end if;
    end loop;
  end if;

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_defs.c_debugging >= 2 $then
  dbug.leave;
$end

  return l_schema_ddl;
end create_schema_ddl;

member procedure print
( self in oracle_tools.t_schema_ddl
)
is
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_defs.c_debugging >= 1 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'PRINT');
  self.obj.print();
  dbug.print(dbug."info", 'cardinality(self.ddl_tab): %s', case when self.ddl_tab is not null then self.ddl_tab.count end);
  if self.ddl_tab is not null and self.ddl_tab.count > 0
  then
    for i_idx in self.ddl_tab.first .. self.ddl_tab.last
    loop
      dbug.print(dbug."info", '*** ddl_tab(%s) ***', i_idx);
      self.ddl_tab(i_idx).print();
    end loop;
  end if;
  dbug.leave;
$else
  null;
$end
end print;

member procedure add_ddl
( self in out nocopy oracle_tools.t_schema_ddl
, p_verb in varchar2
, p_text_tab in oracle_tools.t_text_tab
)
is
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_defs.c_debugging >= 2 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'ADD_DDL (1)');
  dbug.print(dbug."input", 'self.obj.id: %s; self.ddl_tab.count: %s; p_text_tab.count: %s', self.obj.id, self.ddl_tab.count, case when p_text_tab is not null then p_text_tab.count end);
$end

  self.ddl_tab.extend(1);
  self.ddl_tab(self.ddl_tab.last) :=
    oracle_tools.t_ddl
    ( p_ddl# => self.ddl_tab.last
    , p_verb => p_verb
    , p_text_tab => p_text_tab
    );
  self.chk(null);

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_defs.c_debugging >= 2 $then
  dbug.leave;
$end
end add_ddl;

member procedure add_ddl
( self in out nocopy oracle_tools.t_schema_ddl
, p_verb in varchar2
, p_text in clob
, p_add_sqlterminator in integer
)
is
  l_text_tab oracle_tools.t_text_tab;
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_defs.c_debugging >= 2 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'ADD_DDL (2)');
  dbug.print
  ( dbug."input"
  , 'p_verb: %s; p_text[1,100]: "%s"; p_add_sqlterminator: %s'
  , p_verb
  , dbms_lob.substr(lob_loc => p_text, amount => 100)
  , p_add_sqlterminator
  );
$end

  l_text_tab := oracle_tools.pkg_str_util.clob2text(p_text, 1); -- text
  -- ORA-20113: Object BC_PORTAL:INDEX:bcp_addresses_l1:BC_PORTAL::BCP_ADDRESSES:::: is not correct.
  if l_text_tab is not null and l_text_tab.count > 0
  then
    if p_add_sqlterminator > 0
    then
      l_text_tab.extend(1);
      l_text_tab(l_text_tab.last) := chr(10) || '/';
    end if;
    self.add_ddl
    ( p_verb => p_verb
    , p_text_tab => l_text_tab
    );
  end if;

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_defs.c_debugging >= 2 $then
  dbug.leave;
$end
end add_ddl;

order member function match( p_schema_ddl in oracle_tools.t_schema_ddl )
return integer
deterministic
is
  l_result integer := 0;
  l_count1 integer;
  l_count2 integer;
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_defs.c_debugging >= 2 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'MATCH');
$end

  case
    when p_schema_ddl is null
    then l_result := null;

    -- use the map function for the object
    when self.obj < p_schema_ddl.obj
    then l_result := -1;
    when self.obj > p_schema_ddl.obj
    then l_result := +1;

    -- objects the same
    else
      l_count1 := self.ddl_tab.count;
      l_count2 := p_schema_ddl.ddl_tab.count;

      case
        when l_count1 < l_count2
        then l_result := -2;
        when l_count1 > l_count2
        then l_result := +2;
        -- number of DDLs equal
        when l_count1 = 0 and l_count2 = 0
        then l_result := 0;
        -- number of DDLs equal and > 0
        else
          l_result := 0;
          for i_idx in self.ddl_tab.first .. self.ddl_tab.last
          loop
            if self.ddl_tab(i_idx) < p_schema_ddl.ddl_tab(i_idx)
            then
              l_result := - ( 3 + (i_idx - self.ddl_tab.first) );
              exit;
            elsif self.ddl_tab(i_idx) > p_schema_ddl.ddl_tab(i_idx)
            then
              l_result := + ( 3 + (i_idx - self.ddl_tab.first) );
              exit;
            end if;
          end loop;
      end case;
  end case;

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_defs.c_debugging >= 2 $then
  dbug.print(dbug."output", 'return: %s', l_result);
  dbug.leave;
$end

  return l_result;
end match;

final member procedure install
( self in out nocopy oracle_tools.t_schema_ddl
, p_source in oracle_tools.t_schema_ddl
)
is
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_defs.c_debugging >= 2 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'INSTALL');
$end

  for i_ddl_idx in p_source.ddl_tab.first .. p_source.ddl_tab.last
  loop
    self.add_ddl
    ( p_verb => p_source.ddl_tab(i_ddl_idx).verb()
    , p_text_tab => p_source.ddl_tab(i_ddl_idx).text_tab
    );
  end loop;

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_defs.c_debugging >= 2 $then
  dbug.leave;
$end
end install;

static procedure migrate
( p_source in oracle_tools.t_schema_ddl
, p_target in oracle_tools.t_schema_ddl
, p_schema_ddl in out nocopy oracle_tools.t_schema_ddl
)
is
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_defs.c_debugging >= 2 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'MIGRATE');
$end

  oracle_tools.pkg_ddl_util.migrate_schema_ddl
  ( p_source => p_source
  , p_target => p_target
  , p_schema_ddl => p_schema_ddl
  );

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_defs.c_debugging >= 2 $then
  dbug.leave;
$end
end migrate;

member procedure migrate
( self in out nocopy oracle_tools.t_schema_ddl
, p_source in oracle_tools.t_schema_ddl
, p_target in oracle_tools.t_schema_ddl
)
is
begin
  oracle_tools.t_schema_ddl.migrate
  ( p_source => p_source
  , p_target => p_target
  , p_schema_ddl => self
  );
end migrate;

member procedure uninstall
( self in out nocopy oracle_tools.t_schema_ddl
, p_target in oracle_tools.t_schema_ddl
)
is
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_defs.c_debugging >= 2 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'UNINSTALL');
$end

  self.add_ddl
  ( p_verb => 'DROP'
  , p_text => 'DROP ' || p_target.obj.dict_object_type() || ' ' || p_target.obj.fq_object_name()
  , p_add_sqlterminator => case when oracle_tools.pkg_ddl_defs.c_use_sqlterminator then 1 else 0 end
  );

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_defs.c_debugging >= 2 $then
  dbug.leave;
$end
end uninstall;

member procedure chk
( self in oracle_tools.t_schema_ddl
, p_schema in varchar2
)
is
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_defs.c_debugging >= 2 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'CHK');
$end

  if p_schema is not null
  then
    self.obj.chk(p_schema);
  end if;

  if self.ddl_tab is null or self.ddl_tab.count = 0
  then
    oracle_tools.pkg_ddl_error.raise_error(oracle_tools.pkg_ddl_error.c_invalid_parameters, 'The number of ddl statements must be at least 1', self.obj.schema_object_info());
  else
    for i_idx in self.ddl_tab.first .. self.ddl_tab.last
    loop
      if self.ddl_tab(i_idx).text_tab is null or self.ddl_tab(i_idx).text_tab.count = 0
      then
        oracle_tools.pkg_ddl_error.raise_error(oracle_tools.pkg_ddl_error.c_invalid_parameters, 'There is no ddl text for ddl statement ' || i_idx, self.obj.schema_object_info());
        self.ddl_tab(i_idx).chk();
      end if;
    end loop;
  end if;

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_defs.c_debugging >= 2 $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end chk;

static procedure execute_ddl(p_id in varchar2, p_text in varchar2)
is
  l_part_tab dbms_sql.varchar2a;
  l_verb_tab dbms_sql.varchar2a;
  l_schema_ddl oracle_tools.t_schema_ddl;
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_defs.c_debugging >= 2 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'EXECUTE_DDL (1)');
$end

  oracle_tools.pkg_str_util.split(p_str => p_id, p_delimiter => ':', p_str_tab => l_part_tab);
  oracle_tools.pkg_str_util.split(p_str => p_text, p_delimiter => ' ', p_str_tab => l_verb_tab);

  l_schema_ddl :=
    oracle_tools.t_schema_ddl.create_schema_ddl
    ( p_obj => oracle_tools.t_schema_object.create_schema_object
               ( p_object_schema => l_part_tab(l_part_tab.first+0)
               , p_object_type => l_part_tab(l_part_tab.first+1)
               , p_object_name => l_part_tab(l_part_tab.first+2)
               , p_base_object_schema => l_part_tab(l_part_tab.first+3)
               , p_base_object_type => l_part_tab(l_part_tab.first+4)
               , p_base_object_name => l_part_tab(l_part_tab.first+5)
               , p_column_name => l_part_tab(l_part_tab.first+6)
               , p_grantee => l_part_tab(l_part_tab.first+7)
               , p_privilege => l_part_tab(l_part_tab.first+8)
               , p_grantable => l_part_tab(l_part_tab.first+9)
               )
    , p_ddl_tab => oracle_tools.t_ddl_tab(oracle_tools.t_ddl(p_ddl# => 1, p_verb => l_verb_tab(l_verb_tab.first+0), p_text_tab => oracle_tools.t_text_tab(p_text)))
    );
  l_schema_ddl.execute_ddl();

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_defs.c_debugging >= 2 $then
  dbug.leave;
$end
exception
  when others
  then
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_defs.c_debugging >= 2 $then
    dbug.leave_on_error;
$end
    oracle_tools.pkg_ddl_error.reraise_error
    ( '# parts: ' || l_part_tab.count ||
      '; part #0: ' || case when l_part_tab.count >= l_part_tab.first+0 then l_part_tab(l_part_tab.first+0) end ||
      '; part #1: ' || case when l_part_tab.count >= l_part_tab.first+1 then l_part_tab(l_part_tab.first+1) end ||
      '; part #2: ' || case when l_part_tab.count >= l_part_tab.first+2 then l_part_tab(l_part_tab.first+2) end ||
      '; part #3: ' || case when l_part_tab.count >= l_part_tab.first+3 then l_part_tab(l_part_tab.first+3) end ||
      '; part #4: ' || case when l_part_tab.count >= l_part_tab.first+4 then l_part_tab(l_part_tab.first+4) end ||
      '; part #5: ' || case when l_part_tab.count >= l_part_tab.first+5 then l_part_tab(l_part_tab.first+5) end ||
      '; part #6: ' || case when l_part_tab.count >= l_part_tab.first+6 then l_part_tab(l_part_tab.first+6) end ||
      '; part #7: ' || case when l_part_tab.count >= l_part_tab.first+7 then l_part_tab(l_part_tab.first+7) end ||
      '; part #8: ' || case when l_part_tab.count >= l_part_tab.first+8 then l_part_tab(l_part_tab.first+8) end ||
      '; part #9: ' || case when l_part_tab.count >= l_part_tab.first+8 then l_part_tab(l_part_tab.first+9) end ||
      '; verb #0: ' || case when l_verb_tab.count >= l_verb_tab.first+0 then l_verb_tab(l_verb_tab.first+0) end
    );
end execute_ddl;

member procedure execute_ddl
( self in oracle_tools.t_schema_ddl
)
is
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_defs.c_debugging >= 2 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'EXECUTE_DDL (2)');
  self.obj.print();
$end

  oracle_tools.t_schema_ddl.execute_ddl(p_schema_ddl => self);

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_defs.c_debugging >= 2 $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
$end
end execute_ddl;

static procedure execute_ddl(p_schema_ddl in oracle_tools.t_schema_ddl)
is
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_defs.c_debugging >= 2 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'EXECUTE_DDL (3)');
$end

  execute immediate p_schema_ddl.ddl_tab(1).text_tab(1);

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_defs.c_debugging >= 2 $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
$end
end execute_ddl;

final member procedure copy
( self in oracle_tools.t_schema_ddl
, p_display_ddl_sql_tab out nocopy oracle_tools.t_display_ddl_sql_tab 
)
is
begin
  p_display_ddl_sql_tab := oracle_tools.t_display_ddl_sql_tab();

  if cardinality(self.ddl_tab) > 0
  then
    for i_ddl_idx in self.ddl_tab.first .. self.ddl_tab.last
    loop
      if cardinality(self.ddl_tab(i_ddl_idx).text_tab) > 0
      then
        for i_text_idx in self.ddl_tab(i_ddl_idx).text_tab.first
                          ..
                          self.ddl_tab(i_ddl_idx).text_tab.last
        loop
          p_display_ddl_sql_tab.extend(1);
          p_display_ddl_sql_tab(p_display_ddl_sql_tab.last) :=
            oracle_tools.t_display_ddl_sql
            ( self.obj.id
            , self.ddl_tab(i_ddl_idx).ddl#
            , self.ddl_tab(i_ddl_idx).verb
            , self.ddl_tab(i_ddl_idx).ddl_info(self.obj)
            , i_text_idx
            , self.ddl_tab(i_ddl_idx).text_tab(i_text_idx)
            , case when i_ddl_idx = self.ddl_tab.last and i_text_idx = self.ddl_tab(i_ddl_idx).text_tab.last then 1 else null end
            , self.obj
            );
        end loop;
      end if;                
    end loop;
  end if;
end copy;

end;
/

