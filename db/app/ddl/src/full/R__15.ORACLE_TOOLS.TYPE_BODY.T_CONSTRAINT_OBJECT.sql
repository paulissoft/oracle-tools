CREATE OR REPLACE TYPE BODY "ORACLE_TOOLS"."T_CONSTRAINT_OBJECT" AS

constructor function t_constraint_object
( self in out nocopy oracle_tools.t_constraint_object
, p_base_object in oracle_tools.t_named_object
, p_object_schema in varchar2
, p_object_name in varchar2
, p_constraint_type in varchar2 default null
, p_column_names in varchar2 default null
, p_search_condition in varchar2 default null
)
return self as result
is
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.CONSTRUCTOR');
  p_base_object.print;
  dbug.print(dbug."input", 'p_object_schema: %s; p_object_name: %s', p_object_schema, p_object_name);
  dbug.print(dbug."input", 'p_constraint_type: %s; p_column_names: %s; p_search_condition: %s', p_constraint_type, p_column_names, p_search_condition);
$end

  -- default constructor
  self := oracle_tools.t_constraint_object(null, p_object_schema, p_base_object, p_object_name, p_column_names, p_search_condition, p_constraint_type);

  if p_constraint_type is not null and (p_constraint_type <> 'C' or p_search_condition is not null)
  then
    case
      when p_constraint_type = 'C'
      then null;
      else self.search_condition$ := null;
    end case;
  else
    select  c.search_condition
    ,       c.constraint_type
    into    self.search_condition$
    ,       self.constraint_type$
    from    all_constraints c
    where   c.owner = p_object_schema
    and     c.constraint_name = p_object_name
    ;
  end if;

  case
    when self.constraint_type$ in ('P', 'U')
    then
      if self.column_names$ is null
      then
        self.column_names$ := oracle_tools.t_constraint_object.get_column_names(p_object_schema => p_object_schema, p_object_name => p_object_name, p_table_name => p_base_object.object_name);
      end if;
      self.search_condition$ := null;

    when self.constraint_type$ in ('C')
    then
      -- Since the search_condition may well be beyond 4000 characters, we just use a hash.
      -- When the hash for two search conditions is the same, the search condition will normally be the same too
      self.column_names$ := null;
      self.search_condition$ := dbms_utility.get_hash_value(self.search_condition$, 37, 1073741824);
  end case;

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
  dbug.leave;
$end

  return;

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
exception
  when no_data_found
  then
    oracle_tools.pkg_ddl_error.reraise_error
    ( utl_lms.format_message
      ( 'p_object_schema: %s; p_object_name: %s'
      , p_object_schema
      , p_object_name
      )
    );

  when others
  then
    dbug.leave_on_error;
    raise;
$end
end;

-- begin of getter(s)

overriding member function object_type
return varchar2
deterministic
is
begin
  return 'CONSTRAINT';
end object_type;

overriding final member function object_name
return varchar2
deterministic
is
begin
  return self.object_name$;
end object_name;

final member function column_names
return varchar2
deterministic
is
begin
  return self.column_names$;
end column_names;

final member function search_condition
return varchar2
deterministic
is
begin
  return self.search_condition$;
end search_condition;

final member function constraint_type
return varchar2
deterministic
is
begin
  return self.constraint_type$;
end constraint_type;

-- end of getter(s)

overriding map member function signature
return varchar2
deterministic
is
begin
  return self.object_schema ||
         ':' ||
         self.object_type ||
         ':' ||
         null || -- constraints may be equal between (remote) schemas even though the name is different
         ':' ||
         self.base_object_schema ||
         ':' ||
         self.base_object_type ||
         ':' ||
         self.base_object_name ||
         ':' ||
         self.constraint_type ||
         ':' ||
         self.column_names ||
         ':' ||
         self.search_condition
         ;
end signature;

static function get_column_names
( p_object_schema in varchar2
, p_object_name in varchar2
, p_table_name in varchar2
)
return varchar2
is
  l_column_names varchar2(4000 char) := null;
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'GET_COLUMN_NAMES');
  dbug.print(dbug."input", 'p_object_schema: %s; p_object_name: %s; p_table_name: %s', p_object_schema, p_object_name, p_table_name);
$end

  for r in
  ( select  cc.column_name
    from    all_cons_columns cc
    where   cc.owner = p_object_schema
    and     cc.constraint_name = p_object_name
    and     cc.table_name = p_table_name
    order by
            cc.position asc nulls first -- GPA 2017-02-05 Check constraints have position null
    ,       cc.column_name
  )
  loop
    l_column_names := case when l_column_names is not null then l_column_names || ',' end || '"' || r.column_name || '"'; -- " for oracle_tools.pkg_ddl_util.parse_ddl
  end loop;

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
  dbug.print(dbug."output", 'return: %s', l_column_names);
  dbug.leave;
$end

  return l_column_names;

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end get_column_names;

overriding member procedure chk
( self in oracle_tools.t_constraint_object
, p_schema in varchar2
)
is
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'CHK');
$end

  oracle_tools.pkg_ddl_util.chk_schema_object(p_constraint_object => self, p_schema => p_schema);

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end chk;

final static function deserialize
( p_text_tab in oracle_tools.t_text_tab
)
return oracle_tools.t_constraint_object
deterministic
is
  l_constraint_object oracle_tools.t_constraint_object := null;
begin
  if p_text_tab is not null and p_text_tab.count = 1 + 10
  then    
    -- p_text_tab(1): type name (see serialize() below)
    -- p_text_tab(2): object schema (see t_schema_object.id())
    -- p_text_tab(3): object type (see t_schema_object.id())
    -- p_text_tab(4): object name (see t_schema_object.id())
    -- p_text_tab(5): base object schema (see t_schema_object.id())
    -- p_text_tab(6): base object type (see t_schema_object.id())
    -- p_text_tab(7): base object name (see t_schema_object.id())
    case p_text_tab(1)
      when 'T_CONSTRAINT_OBJECT'
      then
        l_constraint_object :=
          oracle_tools.t_constraint_object
          ( p_base_object =>
              oracle_tools.t_named_object.create_named_object
              ( p_object_type => p_text_tab(6)
              , p_object_schema => p_text_tab(5)
              , p_object_name => p_text_tab(7)
              )
          , p_object_schema => p_text_tab(2)
          , p_object_name => p_text_tab(4)
          , p_constraint_type => null
          , p_column_names => null
          , p_search_condition => null
          );
          
      when 'T_REF_CONSTRAINT_OBJECT'
      then
        l_constraint_object :=
          oracle_tools.t_ref_constraint_object
          ( p_base_object =>
              oracle_tools.t_named_object.create_named_object
              ( p_object_type => p_text_tab(6)
              , p_object_schema => p_text_tab(5)
              , p_object_name => p_text_tab(7)
              )
          , p_object_schema => p_text_tab(2)
          , p_object_name => p_text_tab(4)
          , p_constraint_type => null
          , p_column_names => null
          , p_ref_object => null
          );
    end case;
  end if;
  return l_constraint_object;
end deserialize;

final member function serialize
return oracle_tools.t_text_tab
deterministic
is
  -- start with the type name
  l_text_tab oracle_tools.t_text_tab := oracle_tools.t_text_tab(sys.anydata.gettypename(sys.anydata.convertobject(self)));
  l_part_tab dbms_sql.varchar2a;
begin
  pkg_str_util.split
  ( p_str => id()
  , p_delimiter => ':'
  , p_str_tab => l_part_tab
  );

  if l_part_tab.count > 0
  then
    for i_idx in l_part_tab.first .. l_part_tab.last
    loop
      l_text_tab.extend(1);
      l_text_tab(l_text_tab.last) := l_part_tab(i_idx);
    end loop;
  end if;

  if l_text_tab.count != 1 + 10
  then
    raise program_error;
  end if;
  
  return l_text_tab;
end serialize;

end;
/

