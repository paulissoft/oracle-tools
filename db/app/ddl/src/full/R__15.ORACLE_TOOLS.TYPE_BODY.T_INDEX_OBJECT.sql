CREATE OR REPLACE TYPE BODY "ORACLE_TOOLS"."T_INDEX_OBJECT" AS

constructor function t_index_object
( self in out nocopy oracle_tools.t_index_object
, p_base_object in oracle_tools.t_named_object
, p_object_schema in varchar2
, p_object_name in varchar2
)
return self as result
is
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.CONSTRUCTOR' || ' (1)');
  dbug.print
  ( dbug."input"
  , 'p_base_object.id: %s; p_object_schema: %s; p_object_name: %s'
  , p_base_object.id()
  , p_object_schema
  , p_object_name
  );
$end

  -- default constructor
  self := oracle_tools.t_index_object
          ( null -- id
          , null
          , p_object_schema
          , case when p_base_object is not null then p_base_object.id end
          , p_object_name
          , null
          , null
          );

  self.column_names$ := oracle_tools.t_index_object.get_column_names(p_object_schema => p_object_schema, p_object_name => p_object_name);

  if self.tablespace_name$ is null
  then
    select  ind.tablespace_name
    into    self.tablespace_name$
    from    all_indexes ind
    where   ind.owner = p_object_schema
    and     ind.index_name = p_object_name;
  end if;

  oracle_tools.t_schema_object.set_id(self);

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
  dbug.leave;
$end

  return;
end;

constructor function t_index_object
( self in out nocopy oracle_tools.t_index_object
, p_base_object in oracle_tools.t_named_object
, p_object_schema in varchar2
, p_object_name in varchar2
, p_tablespace_name in varchar2
)
return self as result
is
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.CONSTRUCTOR' || ' (2)');
  dbug.print
  ( dbug."input"
  , 'p_base_object.id: %s; p_object_schema: %s; p_object_name: %s; p_tablespace_name: %s'
  , p_base_object.id()
  , p_object_schema
  , p_object_name
  , p_tablespace_name
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
  self.column_names$ := oracle_tools.t_index_object.get_column_names(p_object_schema, p_object_name);
  self.tablespace_name$ := p_tablespace_name;

  oracle_tools.t_schema_object.set_id(self);

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
  dbug.leave;
$end

  return;
end;

-- begin of getter(s)
member function tablespace_name
return varchar2
deterministic
is
begin
  return self.tablespace_name$;
end tablespace_name;

member procedure tablespace_name
( self in out nocopy oracle_tools.t_index_object
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
  return 'INDEX';
end object_type;

overriding member function object_name
return varchar2
deterministic
is
begin
  return self.object_name$;
end object_name;

member function column_names
return varchar2
deterministic
is
begin
  return self.column_names$;
end column_names;

-- end of getter(s)

overriding final map member function signature
return varchar2
deterministic
is
begin
  -- GPA 20170126 This generated SQL statement is totally wrong:
  -- /* SQL statement 7 (ALTER;<owner>;INDEX;ORDER_PK;<owner>;TABLE;ORDERHEADER;;;;;3) */
  -- ALTER INDEX "<owner>"."MAINTENANCE_PK" RENAME TO "ORDER_PK";

  -- select * from all_ind_columns where index_name IN ('MAINTENANCE_PK','ORDER_PK');
  --
  -- INDEX_OWNER  INDEX_NAME  TABLE_OWNER TABLE_NAME  COLUMN_NAME COLUMN_POSITION
  -- -----------        ----------      -----------     ----------      -----------     ---------------
  -- <owner>  MAINTENANCE_PK  <owner> MAINTENANCE SEQ         1
  -- <owner>  ORDER_PK  <owner> ORDERHEADER SEQ         1

  -- GPA 20170126
  -- The problem was that oracle_tools.t_schema_object.id ignored base info for an INDEX

  return self.object_schema ||
         ':' ||
         self.object_type ||
         ':' ||
         null || -- indexes may have different names but can be equal between (remote) schemas
         ':' ||
         self.base_object_schema ||
         ':' ||
         self.base_object_type ||
         ':' ||
         self.base_object_name || -- but the table names should be the same
         ':' ||
         self.column_names;
end signature;

static function get_column_names
( p_object_schema in varchar2
, p_object_name in varchar2
)
return varchar2
is
  l_column_names varchar2(4000 char) := null;
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'GET_COLUMN_NAMES');
  dbug.print(dbug."input", 'p_object_schema: %s; p_object_name: %s', p_object_schema, p_object_name);
$end

  for r in
  ( select  ic.column_name
$if oracle_tools.pkg_ddl_util.c_#138550749 $then
    ,       ie.column_expression
$end
    from    all_ind_columns ic
$if oracle_tools.pkg_ddl_util.c_#138550749 $then
            left join all_ind_expressions ie
            on ie.index_owner = ic.index_owner and ie.index_name = ic.index_name and ie.column_position = ic.column_position
$end
    where   ic.index_owner = p_object_schema
    and     ic.index_name = p_object_name
    order by
            ic.column_position asc nulls first
    ,       ic.column_name
  )
  loop
    l_column_names :=
      case when l_column_names is not null then l_column_names || ',' end ||
$if oracle_tools.pkg_ddl_util.c_#138550749 $then
      case
        when r.column_expression is not null
        then to_char(dbms_utility.get_hash_value(r.column_expression, 37, 1073741824))
        else r.column_name
      end
$else
      r.column_name
$end
    ;
  end loop;

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
  dbug.print(dbug."output", 'return: %s', l_column_names);
  dbug.leave;
$end

  return l_column_names;
end get_column_names;

overriding member procedure chk
( self in oracle_tools.t_index_object
, p_schema in varchar2
)
is
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'CHK');
$end

  oracle_tools.pkg_ddl_util.chk_schema_object(p_dependent_or_granted_object => self, p_schema => p_schema);

  if self.object_name() is null
  then
    oracle_tools.pkg_ddl_error.raise_error
    ( oracle_tools.pkg_ddl_error.c_invalid_parameters
    , 'Object name should not be empty'
    , self.schema_object_info()
    );
  end if;
  if self.column_names() is null
  then
    oracle_tools.pkg_ddl_error.raise_error
    ( oracle_tools.pkg_ddl_error.c_invalid_parameters
    , 'Column names should not be empty'
    , self.schema_object_info()
    );
  end if;

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
  dbug.leave;
$end
end chk;

overriding member function dict_object_exists
return integer -- 0/1
is
  l_count pls_integer;
  l_object_schema constant all_objects.owner%type := self.object_schema();
  l_object_name constant all_objects.object_name%type := self.object_name();
  l_base_object_schema constant all_objects.owner%type := self.base_object_schema();
  l_base_object_type constant all_objects.object_type%type := self.base_dict_object_type();
  l_base_object_name constant all_objects.object_name%type := self.base_object_name();
begin
  select  sign(count(*))
  into    l_count
  from    all_indexes i
  where   i.owner = l_object_schema
  and     i.index_name = l_object_name
  and     i.table_owner = l_base_object_schema
  and     i.table_type = l_base_object_type
  and     i.table_name = l_base_object_name;
  return l_count;
end;

end;
/

