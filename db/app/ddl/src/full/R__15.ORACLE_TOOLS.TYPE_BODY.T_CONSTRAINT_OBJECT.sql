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
  self := oracle_tools.t_constraint_object
          ( null -- id
          , null
          , p_object_schema
          , case when p_base_object is not null then p_base_object.id end
          , p_object_name
          , p_column_names
          , p_search_condition
          , p_constraint_type
          );

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

  oracle_tools.t_schema_object.set_id(self);

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

overriding member function last_ddl_time
return date
is
  l_last_ddl_time all_objects.last_ddl_time%type;
  l_object_schema constant all_objects.owner%type := self.object_schema();
  l_object_type constant all_objects.object_type%type := self.dict_object_type();
  l_constraint_name constant all_objects.object_name%type := self.object_name();
  l_table_name constant all_objects.object_name%type := self.base_object_name();
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'LAST_DDL_TIME');
  dbug.print
  ( dbug."input"
  , 'l_object_schema: %s; l_object_type: %s; l_constraint_name: %s; l_table_name: %s'
  , l_object_schema
  , l_object_type
  , l_constraint_name
  , l_table_name
  );
$end

  begin
    select  c.last_change
    into    l_last_ddl_time
    from    all_constraints c /* this is where we are interested in */
    where   l_object_type in ('TABLE', 'VIEW')
    and     c.owner = l_object_schema
    and     c.constraint_name = l_constraint_name
    and     c.table_name = l_table_name;
  exception
    when others
    then
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
      dbug.on_error;
$end
      -- get last_ddl_time from base object
      select  o.last_ddl_time
      into    l_last_ddl_time
      from    all_objects o
      where   o.owner = l_object_schema
      and     o.object_type = l_object_type
      and     o.object_name = l_table_name;    
  end;  

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
  dbug.print(dbug."output", 'return: %s', l_last_ddl_time);
  dbug.leave;
$end

  return l_last_ddl_time;
exception
  when others
  then
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
    dbug.print(dbug."output", 'return: %s', to_date(null));
    dbug.leave_on_error;
$end
    return null;
end last_ddl_time;

end;
/

