CREATE OR REPLACE TYPE BODY "ORACLE_TOOLS"."T_REF_CONSTRAINT_OBJECT" AS

constructor function t_ref_constraint_object
( self in out nocopy oracle_tools.t_ref_constraint_object
, p_base_object in oracle_tools.t_named_object
, p_object_schema in varchar2
, p_object_name in varchar2
, p_constraint_type in varchar2 default null
, p_column_names in varchar2 default null
  /*
   * GJP 2022-07-17
   *
   * BUG: the referential constraints are not created in the correct order in the install.sql file (https://github.com/paulissoft/oracle-tools/issues/35).
   *
   * The solution is to have a better dependency sort order and thus let the referential constraint depends on the primary / unique key and not on the base table / view.
   */
, p_ref_object in oracle_tools.t_constraint_object default null
)
return self as result
is
  l_base_object oracle_tools.t_named_object;
  l_constraint_object oracle_tools.t_constraint_object;
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.CONSTRUCTOR');
  dbug.print
  ( dbug."input"
  , 'p_base_object.id(): %s; p_object_schema: %s; p_object_name: %s; p_constraint_type: %s; p_column_names: %s'
  , p_base_object.id()
  , p_object_schema
  , p_object_name
  , p_constraint_type
  , p_column_names
  );
  if p_ref_object is not null
  then
    p_ref_object.print();
  end if;
$end

  -- default constructor
  self := oracle_tools.t_ref_constraint_object
          ( null
          , p_object_schema
          , case when p_base_object is not null then schema_objects_api.find_by_object_id(p_base_object.id()).seq end          
          , p_object_name
          , nvl
            ( p_column_names
            , oracle_tools.t_constraint_object.get_column_names
              ( p_object_schema => p_object_schema
              , p_object_name => p_object_name
              , p_table_name => p_base_object.object_name()
              )
            )
          , null -- search condition
          , nvl(p_constraint_type, 'R')
          , case when p_ref_object is not null then schema_objects_api.find_by_object_id(p_ref_object.id()).seq end          
          );

  if self.ref_object_seq$ is null
  then
    -- find referenced primary / unique key and its base table / view
    <<find_loop>>
    for r in
    ( select  r.owner as r_owner
      ,       r.constraint_name as r_constraint_name
      ,       r.table_name as r_table_name
      ,       r.constraint_type as r_constraint_type
      ,       ( select  o.object_type
                from    all_objects o
                where   o.owner = r.owner
                and     o.object_type <> 'MATERIALIZED VIEW'
                and     o.object_name = r.table_name ) as r_object_type
      from    all_constraints t -- this object (constraint)
              inner join all_constraints r -- remote object (constraint)
              on r.owner = t.r_owner and r.constraint_name = t.r_constraint_name
      where   t.owner = self.object_schema$
      and     t.constraint_name = self.object_name$
      and     t.constraint_type = self.constraint_type$
      and     r.constraint_type in ('P', 'U')
    )
    loop
      l_base_object :=
        oracle_tools.t_named_object.create_named_object
        ( p_object_schema => r.r_owner
        , p_object_type => r.r_object_type
        , p_object_name => r.r_table_name
        );
      l_constraint_object :=
        oracle_tools.t_constraint_object
        ( p_base_object => l_base_object
        , p_object_schema => r.r_owner
        , p_object_name => r.r_constraint_name
        , p_constraint_type => r.r_constraint_type
        , p_search_condition => null
        );
      schema_objects_api.add
      ( p_schema_object => l_base_object
      , p_must_exist => null
      );
      schema_objects_api.add
      ( p_schema_object => l_constraint_object          
      , p_must_exist => null
      );
      self.ref_object_seq$ := schema_objects_api.find_by_object_id(l_constraint_object.id()).seq;
      
      exit find_loop;
    end loop find_loop;
  end if;

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
  return 'REF_CONSTRAINT';
end object_type;

member function ref_object_schema
return varchar2
deterministic
is
begin
  return case when self.ref_object_seq$ is not null then self.ref_object().object_schema() end;
end ref_object_schema;

member function ref_object_type
return varchar2
deterministic
is
begin
  return case when self.ref_object_seq$ is not null then self.ref_object().object_type() end;
end ref_object_type;

member function ref_object_name
return varchar2
deterministic
is
begin
  return case when self.ref_object_seq$ is not null then self.ref_object().object_name() end;
end ref_object_name;

member function ref_base_object_schema
return varchar2
deterministic
is
begin
  return case when self.ref_object_seq$ is not null then self.ref_object().base_object_schema() end;
end ref_base_object_schema;

member function ref_base_object_type
return varchar2
deterministic
is
begin
  return case when self.ref_object_seq$ is not null then self.ref_object().base_object_type() end;
end ref_base_object_type;

member function ref_base_object_name
return varchar2
deterministic
is
begin
  return case when self.ref_object_seq$ is not null then self.ref_object().base_object_name() end;
end ref_base_object_name;

-- end of getter(s)

overriding final map member function signature
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
         self.ref_object_schema ||
         ':' ||
         self.ref_object_type ||
         ':' ||
         self.ref_object_name;
end signature;

overriding member procedure chk
( self in oracle_tools.t_ref_constraint_object
, p_schema in varchar2
)
is
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'CHK');
$end

  oracle_tools.pkg_ddl_util.chk_schema_object(p_constraint_object => self, p_schema => p_schema);

  if self.constraint_type$ is null
  then
    oracle_tools.pkg_ddl_error.raise_error(oracle_tools.pkg_ddl_error.c_invalid_parameters, 'Constraint type should not be empty.', self.schema_object_info());
  end if;

  if self.ref_object_seq$ is null
  then
    oracle_tools.pkg_ddl_error.raise_error(oracle_tools.pkg_ddl_error.c_invalid_parameters, 'Reference object should not be empty.', self.schema_object_info());
  end if;

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
  dbug.leave;
$end
end chk;

final member procedure ref_object_schema
( self in out nocopy oracle_tools.t_ref_constraint_object
, p_ref_object_schema in varchar2
)
is
  l_base_object oracle_tools.t_named_object := self.base_object();
  l_ref_object oracle_tools.t_constraint_object := self.ref_object();
begin
  if l_ref_object.object_schema() = p_ref_object_schema
  then
    null; -- no change
  else
    -- change and add again (must exist)
    l_ref_object.object_schema(p_ref_object_schema);
    schema_objects_api.add(p_schema_object => l_ref_object, p_must_exist => true);
  end if;  

  if l_base_object.object_schema() = p_ref_object_schema
  then
    null; -- no change
  else
    -- change and add again (must exist)
    l_base_object.object_schema(p_ref_object_schema);
    schema_objects_api.add(p_schema_object => l_base_object, p_must_exist => true);
  end if;  
end ref_object_schema;

static function get_ref_constraint -- get referenced primary / unique key constraint whose base object is the referencing table / view with those columns
( p_ref_base_object_schema in varchar2
, p_ref_base_object_name in varchar2
, p_ref_column_names in varchar2
)
return oracle_tools.t_constraint_object
is
  l_tablespace_name all_tables.tablespace_name%type := null;
  l_ref_base_object_type oracle_tools.pkg_ddl_util.t_metadata_object_type;
  l_ref_base_object oracle_tools.t_named_object := null;
  l_ref_object oracle_tools.t_constraint_object := null;
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT);
  dbug.print
  ( dbug."input"
  , 'p_ref_base_object_schema: %s; p_ref_base_object_name: %s; p_ref_column_names: %s'
  , p_ref_base_object_schema
  , p_ref_base_object_name
  , p_ref_column_names
  );
$end

  -- GJP 2022-07-15
  -- We now loop through the primary/unique constraints to see whether their column name list matches the one found.
  -- If so, we have found the reference constraint
  <<ref_column_names_loop>>
  for r in
  ( select  con.constraint_name
    ,       con.constraint_type
    from    all_constraints con
    where   con.owner = p_ref_base_object_schema
    and     con.table_name = p_ref_base_object_name
    and     con.constraint_type in ('P', 'U') -- primary / unique key
  )
  loop
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
    dbug.print
    ( dbug."info"
    , 'r.constraint_name: %s; r.constraint_type: %s'
    , r.constraint_name
    , r.constraint_type
    );
$end
    if oracle_tools.t_constraint_object.get_column_names
       ( p_object_schema => p_ref_base_object_schema
       , p_object_name => r.constraint_name
       , p_table_name => p_ref_base_object_name
       ) = p_ref_column_names
    then
      begin
        select  t.tablespace_name as tablespace_name
        ,       'TABLE' as object_type -- already meta
        into    l_tablespace_name
        ,       l_ref_base_object_type
        from    all_tables t
        where   t.owner = p_ref_base_object_schema
        and     t.table_name = p_ref_base_object_name
        ;
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
        dbug.print(dbug."debug", 'l_tablespace_name: %s', l_tablespace_name);
$end
        l_ref_base_object := oracle_tools.t_table_object
                             ( p_object_schema => p_ref_base_object_schema
                             , p_object_name => p_ref_base_object_name
                             , p_tablespace_name => l_tablespace_name
                             );
      exception
        when no_data_found
        then
          -- reference constraints to views are possible too...
          select  'VIEW' as object_type -- already meta
          into    l_ref_base_object_type
          from    all_views v
          where   v.owner = p_ref_base_object_schema
          and     v.view_name = p_ref_base_object_name
          ;
          l_ref_base_object := oracle_tools.t_view_object
                               ( p_object_schema => p_ref_base_object_schema
                               , p_object_name => p_ref_base_object_name
                               );
      end;

      l_ref_object := oracle_tools.t_constraint_object
                      ( p_base_object => l_ref_base_object
                      , p_object_schema => p_ref_base_object_schema
                      , p_object_name => r.constraint_name
                      , p_constraint_type => r.constraint_type
                      , p_column_names => p_ref_column_names
                      , p_search_condition => null
                      );

      exit ref_column_names_loop; -- found so done
    end if;
  end loop ref_column_names_loop;

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
  if l_ref_object is not null
  then
    l_ref_object.print();
  end if;
  dbug.leave;
$end

  return l_ref_object;
end get_ref_constraint;

member function ref_object
return oracle_tools.t_constraint_object
deterministic
is
  l_ref_object oracle_tools.t_named_object := null;
begin
  return case when self.ref_object_seq$ is not null then treat(schema_objects_api.find_by_seq(self.ref_object_seq$).obj as oracle_tools.t_constraint_object) end;
end ref_object;

end;
/

