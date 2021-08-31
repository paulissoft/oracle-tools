CREATE OR REPLACE PACKAGE BODY "ORACLE_TOOLS"."PKG_SCHEMA_OBJECT" IS

g_package_prefix constant varchar2(100) := $$PLSQL_UNIT || '.';

procedure create_schema_object
( p_owner in varchar2 -- GJP 2021-08-31 Necessary in case of a remap
, p_object_schema in varchar2
, p_object_type in varchar2
, p_object_name in varchar2 default null
, p_base_object_schema in varchar2 default null
, p_base_object_type in varchar2 default null
, p_base_object_name in varchar2 default null
, p_column_name in varchar2 default null
, p_grantee in varchar2 default null
, p_privilege in varchar2 default null
, p_grantable in varchar2 default null
, p_schema_object out nocopy t_schema_object
)
is
  l_base_object_schema all_objects.owner%type := p_base_object_schema;
  l_base_object_name all_objects.object_name%type := p_base_object_name;
begin
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
  dbug.enter(g_package_prefix || 'CREATE_SCHEMA_OBJECT (1)');
  dbug.print
  ( dbug."input"
  , 'p_owner: %s; p_object_schema: %s; p_object_type: %s; p_object_name: %s'
  , p_owner
  , p_object_schema
  , p_object_type
  , p_object_name
  );
  if p_base_object_schema is not null or p_base_object_type is not null or p_base_object_name is not null
  then
    dbug.print
    ( dbug."input"
    , 'p_base_object_schema: %s; p_base_object_type: %s; p_base_object_name: %s'
    , p_base_object_schema
    , p_base_object_type
    , p_base_object_name
    );
  end if;
  if p_column_name is not null or p_grantee is not null or p_privilege is not null or p_grantable is not null
  then
    dbug.print
    ( dbug."input"
    , 'p_column_name: %s; p_grantee: %s; p_privilege: %s; p_grantable: %s'
    , p_column_name
    , p_grantee
    , p_privilege
    , p_grantable
    );
  end if;
$end

  case p_object_type
    when 'INDEX' -- a named object with a base named object
    then
      -- base_object_type is corrected in create_named_object()
      if l_base_object_schema is null or l_base_object_name is null
      then
        select  i.table_owner
        ,       i.table_name
        into    l_base_object_schema
        ,       l_base_object_name
        from    all_indexes i
        where   i.owner = p_owner /* p_object_schema */ -- GJP 2021-08-31 Necessary in case of a remap
        and     i.index_name = p_object_name
        and     ( l_base_object_schema is null or i.table_owner = p_owner /* l_base_object_schema */ ) -- GJP 2021-08-31 Necessary in case of a remap
        and     ( l_base_object_name is null or i.table_name = l_base_object_name )
        ;
      end if;
      
      p_schema_object :=
        create_index_object
        ( p_owner => p_owner
        , p_base_object =>
            create_named_object
            ( p_owner => p_owner
            , p_object_schema => l_base_object_schema
            , p_object_type => p_base_object_type
            , p_object_name => l_base_object_name
            )
        , p_object_schema => p_object_schema
        , p_object_name => p_object_name
        , p_tablespace_name => null
        );

    when 'TRIGGER' -- a named object with a base named object
    then
      -- base_object_type is corrected in create_named_object()
      if l_base_object_schema is null or l_base_object_name is null
      then
        select  t.table_owner
        ,       t.table_name
        into    l_base_object_schema
        ,       l_base_object_name
        from    all_triggers t
        where   t.owner = p_owner /* p_object_schema */ -- GJP 2021-08-31 Necessary in case of a remap
        and     t.trigger_name = p_object_name
        and     ( l_base_object_schema is null or t.table_owner = p_owner /* l_base_object_schema */ ) -- GJP 2021-08-31 Necessary in case of a remap
        and     ( l_base_object_name is null or t.table_name = l_base_object_name )
        ;
      end if;
      
      p_schema_object :=
        t_trigger_object
        ( p_base_object =>
            create_named_object
            ( p_owner => p_owner
            , p_object_schema => l_base_object_schema
            , p_object_type => p_base_object_type
            , p_object_name => l_base_object_name
            )
        , p_object_schema => p_object_schema
        , p_object_name => p_object_name
        );

    when 'OBJECT_GRANT'
    then
      p_schema_object :=
        t_object_grant_object
        ( p_base_object =>
            create_named_object
            ( p_owner => p_owner
            , p_object_schema => p_base_object_schema
            , p_object_type => p_base_object_type
            , p_object_name => p_base_object_name
            )
        , p_object_schema => p_object_schema
        , p_grantee => p_grantee
        , p_privilege => p_privilege
        , p_grantable => p_grantable
        );

    when 'CONSTRAINT'
    then
      p_schema_object :=
        create_constraint_object
        ( p_owner => p_owner
        , p_base_object =>
            create_named_object
            ( p_owner => p_owner
            , p_object_schema => p_base_object_schema
            , p_object_type => p_base_object_type
            , p_object_name => p_base_object_name
            )
        , p_object_schema => p_object_schema
        , p_object_name => p_object_name
        );

    when 'REF_CONSTRAINT'
    then
      p_schema_object :=
        create_ref_constraint_object
        ( p_owner => p_owner
        , p_base_object =>
            create_named_object
            ( p_owner => p_owner
            , p_object_schema => p_base_object_schema
            , p_object_type => p_base_object_type
            , p_object_name => p_base_object_name
            )
        , p_object_schema => p_object_schema
        , p_object_name => p_object_name
        );

    when 'SYNONYM' -- a named object with a base named object
    then
      -- base_object_type is corrected in create_named_object()
      if l_base_object_schema is null or l_base_object_name is null
      then
        select  s.table_owner
        ,       s.table_name
        into    l_base_object_schema
        ,       l_base_object_name
        from    all_synonyms s
        where   s.owner = p_owner /* p_object_schema */ -- GJP 2021-08-31 Necessary in case of a remap
        and     s.synonym_name = p_object_name
        and     ( l_base_object_schema is null or s.table_owner = p_owner /* l_base_object_schema */ ) -- GJP 2021-08-31 Necessary in case of a remap
        and     ( l_base_object_name is null or s.table_name = l_base_object_name )
        ;
      end if;
      
      p_schema_object :=
        t_synonym_object
        ( p_base_object =>
            create_named_object
            ( p_owner => p_owner
            , p_object_schema => l_base_object_schema
            , p_object_type => p_base_object_type
            , p_object_name => l_base_object_name
            )
        , p_object_schema => p_object_schema
        , p_object_name => p_object_name
        );

    when 'COMMENT'
    then
      p_schema_object :=
        t_comment_object
        ( p_base_object =>
            create_named_object
            ( p_owner => p_owner
            , p_object_schema => p_base_object_schema
            , p_object_type => p_base_object_type
            , p_object_name => p_base_object_name
            )
        , p_object_schema => p_object_schema
        , p_column_name => p_column_name
        );

    else
-- when 'SEQUENCE'
-- when 'TYPE_SPEC'
-- when 'CLUSTER'
-- when 'AQ_QUEUE_TABLE'
-- when 'AQ_QUEUE'
-- when 'TABLE'
-- when 'DB_LINK'
-- when 'FUNCTION'
-- when 'PACKAGE_SPEC'
-- when 'VIEW'
-- when 'PROCEDURE'
-- when 'MATERIALIZED_VIEW'
-- when 'MATERIALIZED_VIEW_LOG'
-- when 'PACKAGE_BODY'
-- when 'TYPE_BODY'
-- when 'DIMENSION'
-- when 'INDEXTYPE'
-- when 'JAVA_SOURCE'
-- when 'LIBRARY'
-- when 'OPERATOR'
-- when 'REFRESH_GROUP'
-- when 'XMLSCHEMA'
-- when 'PROCOBJ'
      create_named_object
      ( p_owner => p_owner
      , p_object_schema => p_object_schema
      , p_object_type => p_object_type
      , p_object_name => p_object_name
      , p_named_object => p_schema_object
      );
  end case;

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end create_schema_object;

function create_schema_object
( p_owner in varchar2
, p_object_schema in varchar2
, p_object_type in varchar2
, p_object_name in varchar2 default null
, p_base_object_schema in varchar2 default null
, p_base_object_type in varchar2 default null
, p_base_object_name in varchar2 default null
, p_column_name in varchar2 default null
, p_grantee in varchar2 default null
, p_privilege in varchar2 default null
, p_grantable in varchar2 default null
)
return t_schema_object
is
  l_schema_object t_schema_object;
begin
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
  dbug.enter(g_package_prefix || 'CREATE_SCHEMA_OBJECT (2)');
$end

  create_schema_object
  ( p_owner => p_owner
  , p_object_schema => p_object_schema
  , p_object_type => p_object_type
  , p_object_name => p_object_name
  , p_base_object_schema => p_base_object_schema
  , p_base_object_type => p_base_object_type
  , p_base_object_name => p_base_object_name
  , p_column_name => p_column_name
  , p_grantee => p_grantee
  , p_privilege => p_privilege
  , p_grantable => p_grantable
  , p_schema_object => l_schema_object
  );

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
  dbug.leave;
$end

  return l_schema_object;

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end create_schema_object;

procedure create_named_object
( p_owner in varchar2 -- GJP 2021-08-31 Necessary in case of a remap
, p_object_type in varchar2
, p_object_schema in varchar2
, p_object_name in varchar2
, p_named_object out nocopy t_schema_object
)
is
  l_object_type oracle_tools.pkg_ddl_util.t_metadata_object_type := p_object_type;
begin
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
  dbug.enter(g_package_prefix || 'CREATE_NAMED_OBJECT (1)');
  dbug.print
  ( dbug."input"
  , 'p_object_type: %s; p_object_schema: %s; p_object_name: %s'
  , p_object_type
  , p_object_schema
  , p_object_name
  );
$end

  if l_object_type is null
  then
    select  distinct
            o.object_type
    into    l_object_type
    from    all_objects o
    where   o.owner = p_owner /* p_object_schema */ -- GJP 2021-08-31 Necessary in case of a remap
    and     o.object_name = p_object_name
    and     o.object_type not in ('INDEX', 'TRIGGER', 'PACKAGE BODY', 'TYPE BODY', 'MATERIALIZED VIEW') -- only primary objects
    ;

    l_object_type := oracle_tools.t_schema_object.dict2metadata_object_type(l_object_type);
  end if;

  case l_object_type
    when 'SEQUENCE'              then p_named_object := t_sequence_object(p_object_schema, p_object_name);
    when 'TYPE_SPEC'             then p_named_object := t_type_spec_object(p_object_schema, p_object_name);
    when 'CLUSTER'               then p_named_object := t_cluster_object(p_object_schema, p_object_name);
    when 'TABLE'                 then p_named_object := create_table_object(p_owner, p_object_schema, p_object_name);
    when 'FUNCTION'              then p_named_object := t_function_object(p_object_schema, p_object_name);
    when 'PACKAGE_SPEC'          then p_named_object := t_package_spec_object(p_object_schema, p_object_name);
    when 'VIEW'                  then p_named_object := t_view_object(p_object_schema, p_object_name);
    when 'PROCEDURE'             then p_named_object := t_procedure_object(p_object_schema, p_object_name);
    when 'MATERIALIZED_VIEW'     then p_named_object := t_materialized_view_object(p_object_schema, p_object_name);
    when 'MATERIALIZED_VIEW_LOG' then p_named_object := t_materialized_view_log_object(p_object_schema, p_object_name);
    when 'PACKAGE_BODY'          then p_named_object := t_package_body_object(p_object_schema, p_object_name);
    when 'TYPE_BODY'             then p_named_object := t_type_body_object(p_object_schema, p_object_name);
    when 'JAVA_SOURCE'           then p_named_object := t_java_source_object(p_object_schema, p_object_name);
    when 'REFRESH_GROUP'         then p_named_object := t_refresh_group_object(p_object_schema, p_object_name);
    when 'PROCOBJ'               then p_named_object := create_procobj_object(p_owner, p_object_schema, p_object_name);
    else raise_application_error(pkg_ddl_error.c_invalid_parameters, 'Object type "' || l_object_type || '" is not listed here.');
  end case;

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end create_named_object;

function create_named_object
( p_owner in varchar2
, p_object_type in varchar2
, p_object_schema in varchar2
, p_object_name in varchar2
)
return t_named_object
is
  l_named_object t_schema_object;
begin
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
  dbug.enter(g_package_prefix || 'CREATE_NAMED_OBJECT (2)');
$end

  create_named_object
  ( p_owner => p_owner
  , p_object_type => p_object_type
  , p_object_schema => p_object_schema
  , p_object_name => p_object_name
  , p_named_object => l_named_object
  );

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
  dbug.leave;
$end

  return treat(l_named_object as t_named_object);

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end create_named_object;

procedure create_constraint_object
( p_owner in varchar2
, p_base_object in t_named_object
, p_object_schema in varchar2
, p_object_name in varchar2
, p_constraint_type in varchar2 default null
, p_column_names in varchar2 default null
, p_search_condition in varchar2 default null
, p_obj out nocopy t_constraint_object
)
is
begin
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
  dbug.enter(g_package_prefix || 'CREATE_CONSTRAINT_OBJECT (1)');
  p_base_object.print;
  dbug.print(dbug."input", 'p_object_schema: %s; p_object_name: %s', p_object_schema, p_object_name);
  dbug.print(dbug."input", 'p_constraint_type: %s; p_column_names: %s; p_search_condition: %s', p_constraint_type, p_column_names, p_search_condition);
$end

  -- default constructor
  p_obj := t_constraint_object(null, p_object_schema, p_base_object, p_object_name, p_column_names, p_search_condition, p_constraint_type);

  if p_constraint_type is not null and (p_constraint_type <> 'C' or p_search_condition is not null)
  then
    case
      when p_constraint_type = 'C'
      then null;
      else p_obj.search_condition$ := null;
    end case;
  else
    select  c.search_condition
    ,       c.constraint_type
    into    p_obj.search_condition$
    ,       p_obj.constraint_type$
    from    all_constraints c
    where   c.owner = p_owner -- use p_owner in case of a remap
    and     c.constraint_name = p_object_name
    ;
  end if;

  case 
    when p_obj.constraint_type$ in ('P', 'U')
    then
      if p_obj.column_names$ is null
      then
        p_obj.column_names$ := get_column_names(p_owner => p_owner, p_constraint_name => p_object_name, p_table_name => p_base_object.object_name);
      end if;
      p_obj.search_condition$ := null;

    when p_obj.constraint_type$ in ('C')
    then
      -- Since the search_condition may well be beyond 4000 characters, we just use a hash.
      -- When the hash for two search conditions is the same, the search condition will normally be the same too
      p_obj.column_names$ := null;
      p_obj.search_condition$ := dbms_utility.get_hash_value(p_search_condition, 37, 1073741824);
  end case;

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
exception
  when no_data_found
  then
    raise_application_error
    ( pkg_ddl_error.c_reraise_with_backtrace
    , utl_lms.format_message
      ( 'p_object_schema: %s; p_object_name: %s'
      , p_object_schema
      , p_object_name
      )
    , true
    );

  when others
  then
    dbug.leave_on_error;
    raise;
$end
end create_constraint_object;

function create_constraint_object
( p_owner in varchar2
, p_base_object in t_named_object
, p_object_schema in varchar2
, p_object_name in varchar2
, p_constraint_type in varchar2 default null
, p_column_names in varchar2 default null
, p_search_condition in varchar2 default null
)
return t_constraint_object
is
  l_obj t_constraint_object;
begin
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
  dbug.enter(g_package_prefix || 'CREATE_CONSTRAINT_OBJECT (2)');
$end

  create_constraint_object
  ( p_owner => p_owner
  , p_base_object => p_base_object
  , p_object_schema => p_object_schema
  , p_object_name => p_object_name
  , p_constraint_type => p_constraint_type
  , p_column_names => p_column_names
  , p_search_condition => p_search_condition
  , p_obj => l_obj
  );

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
$end

  return l_obj;

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end create_constraint_object;

function create_index_object
( p_owner in varchar2
, p_base_object in t_named_object
, p_object_schema in varchar2
, p_object_name in varchar2
, p_tablespace_name in varchar2 default null
)
return t_index_object
is
  l_obj t_index_object;
begin
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 3 $then
  dbug.enter(g_package_prefix || 'CREATE_INDEX_OBJECT');
  dbug.print
  ( dbug."input"
  , 'p_owner: %s; p_base_object.id: %s; p_object_schema: %s; p_object_name: %s; p_tablespace_name: %s'
  , p_owner
  , p_base_object.id()
  , p_object_schema
  , p_object_name
  , p_tablespace_name
  );
$end

  -- default constructor
  l_obj := t_index_object(null, p_object_schema, p_base_object, p_object_name, null, p_tablespace_name);

  l_obj.column_names$ := get_column_names(p_owner => p_owner, p_index_name => p_object_name);

  if l_obj.tablespace_name$ is null
  then
    select  ind.tablespace_name
    into    l_obj.tablespace_name$
    from    all_indexes ind
    where   ind.owner = p_owner /* p_object_schema */ -- GJP 2021-08-31 Necessary in case of a remap
    and     ind.index_name = p_object_name;
  end if;

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 3 $then
  dbug.leave;
$end

  return l_obj;
end create_index_object;

function create_procobj_object
( p_owner in varchar2
, p_object_schema in varchar2
, p_object_name in varchar2
)
return t_procobj_object
is
  l_obj t_procobj_object;
begin
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 3 $then
  dbug.enter(g_package_prefix || 'T_PROCOBJ_OBJECT');
  dbug.print
  ( dbug."input"
  , 'p_owner: %s; p_object_schema: %s; p_object_name: %s'
  , p_owner
  , p_object_schema
  , p_object_name
  );
$end

  l_obj := t_procobj_object(null, p_object_schema, p_object_name, null);

  select  obj.object_type
  into    l_obj.dict_object_type$
  from    all_objects obj
  where   obj.owner = p_owner /* p_object_schema */ -- GJP 2021-08-31 Necessary in case of a remap
  and     obj.object_name = p_object_name
  ;

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 3 $then
  dbug.leave;
$end

  return l_obj;
end create_procobj_object;

procedure create_ref_constraint_object
( p_owner in varchar2
, p_base_object in t_named_object
, p_object_schema in varchar2
, p_object_name in varchar2
, p_constraint_type in varchar2 default null
, p_column_names in varchar2 default null
, p_ref_object in t_named_object default null
, p_obj out nocopy t_ref_constraint_object
)
is
  l_owner all_objects.owner%type;
  l_table_name all_objects.object_name%type;
  l_tablespace_name all_tables.tablespace_name%type;

  cursor c_con(b_owner in varchar2, b_constraint_name in varchar2, b_table_name in varchar2)
  is
    select  con.owner
    ,       con.constraint_type
    ,       con.table_name
    ,       con.r_owner
    ,       con.r_constraint_name
    from    all_constraints con
    where   con.owner = b_owner
    and     con.constraint_name = b_constraint_name
    and     (b_table_name is null or con.table_name = b_table_name)
    ;

  r_con c_con%rowtype;
begin
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 3 $then
  dbug.enter(g_package_prefix || 'CREATE_REF_CONSTRAINT_OBJECT (1)');
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
  p_obj := t_ref_constraint_object
           ( null
           , p_object_schema
           , p_base_object
           , p_object_name
           , nvl(p_column_names, get_column_names(p_owner => p_owner, p_constraint_name => p_object_name, p_table_name => p_base_object.object_name()))
           , null -- search condition
           , p_constraint_type
           , p_ref_object
           );

  -- GPA 2017-01-18
  -- one combined query (twice all_constraints and once all_objects) was too slow.
  if p_constraint_type is not null and p_ref_object is not null
  then
    null;
  else
    begin
      p_obj.constraint_type$ := null; -- to begin with

      open c_con(p_owner /* object_schema */, p_object_name, p_base_object.object_name());
      fetch c_con into r_con;
      if c_con%found
      then
        close c_con; -- closed cursor indicates success

        p_obj.constraint_type$ := r_con.constraint_type;

        -- get the referenced table/view
        open c_con(r_con.r_owner, r_con.r_constraint_name, null);
        fetch c_con into r_con;
        if c_con%found
        then
          close c_con; -- closed cursor indicates success

          begin
            select  t.owner
            ,       t.table_name as table_name
            ,       t.tablespace_name as tablespace_name
            into    l_owner
            ,       l_table_name
            ,       l_tablespace_name
            from    all_tables t
            where   t.owner = r_con.owner
            and     t.table_name = r_con.table_name
            ;
            p_obj.ref_object$ := create_table_object(p_owner => l_owner, p_object_schema => r_con.owner, p_object_name => r_con.table_name, p_tablespace_name => l_tablespace_name);
          exception
            when no_data_found
            then
              -- reference constraints to views are possible too...
              select  v.owner
              ,       v.view_name as table_name
              into    l_owner
              ,       l_table_name
              from    all_views v
              where   v.owner = r_con.owner
              and     v.view_name = r_con.table_name
              ;
              p_obj.ref_object$ := t_view_object(l_owner, l_table_name);
          end;
        end if;
      end if;

      -- closed cursor indicates success
      if c_con%isopen
      then
        close c_con;
        raise no_data_found;
      end if;

    exception
      when others
      then
        p_obj.ref_object$ := null;
        -- chk() will signal this later on
    end;
  end if;

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 3 $then
  dbug.leave;
$end
end create_ref_constraint_object;

function create_ref_constraint_object
( p_owner in varchar2
, p_base_object in t_named_object
, p_object_schema in varchar2
, p_object_name in varchar2
, p_constraint_type in varchar2 default null
, p_column_names in varchar2 default null
, p_ref_object in t_named_object default null
)
return t_ref_constraint_object
is
  l_obj t_ref_constraint_object;
begin
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 3 $then
  dbug.enter(g_package_prefix || 'CREATE_REF_CONSTRAINT_OBJECT (2)');
$end

  create_ref_constraint_object
  ( p_owner => p_owner
  , p_base_object => p_base_object
  , p_object_schema => p_object_schema
  , p_object_name => p_object_name
  , p_constraint_type => p_constraint_type
  , p_column_names => p_column_names
  , p_ref_object => p_ref_object
  , p_obj => l_obj
  );

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 3 $then
  dbug.leave;
$end

  return l_obj;
end create_ref_constraint_object;

function create_table_object
( p_owner in varchar2
, p_object_schema in varchar2
, p_object_name in varchar2
, p_tablespace_name in varchar2 default null
)
return t_table_object
is
  l_obj t_table_object;
begin
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 3 $then
  dbug.enter(g_package_prefix || 'T_TABLE_OBJECT');
  dbug.print
  ( dbug."input"
  , 'p_owner: %s; p_object_schema: %s; p_object_name: %s'
  , p_owner
  , p_object_schema
  , p_object_name
  , p_tablespace_name
  );
$end

 -- non default constructor
  l_obj := t_table_object(p_object_schema, p_object_name, p_tablespace_name);

  if l_obj.tablespace_name$ is null
  then
    begin
      -- standard table?
      select  t.tablespace_name
      into    l_obj.tablespace_name$
      from    all_tables t
      where   t.owner = p_owner /* p_object_schema */ -- GJP 2021-08-31 Necessary in case of a remap
      and     t.table_name = p_object_name
      ;
    exception
      when no_data_found
      then
        -- maybe a temporary table
        l_obj.tablespace_name$ := null;
    end;
  end if;

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 3 $then
  dbug.print(dbug."info", 'l_obj.tablespace_name$: %s', l_obj.tablespace_name$);
  dbug.leave;
$end

  return l_obj;
end create_table_object;

function get_column_names
( p_owner in varchar2
, p_constraint_name in varchar2
, p_table_name in varchar2
)
return varchar2
is
  l_column_names varchar2(4000 char) := null;
begin
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
  dbug.enter(g_package_prefix || 'GET_COLUMN_NAMES (1)');
  dbug.print(dbug."input", 'p_owner: %s; p_constraint_name: %s; p_table_name: %s', p_owner, p_constraint_name, p_table_name);
$end

  for r in
  ( select  cc.column_name
    from    all_cons_columns cc
    where   cc.owner = p_owner
    and     cc.constraint_name = p_constraint_name
    and     cc.table_name = p_table_name
    order by
            cc.position asc nulls first -- GPA 2017-02-05 Check constraints have position null
    ,       cc.column_name
  )
  loop
    l_column_names := case when l_column_names is not null then l_column_names || ',' end || '"' || r.column_name || '"'; -- " for pkg_ddl_util.parse_ddl
  end loop;

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
  dbug.print(dbug."output", 'return: %s', l_column_names);
  dbug.leave;
$end

  return l_column_names;

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end    
end get_column_names;

function get_column_names
( p_owner in varchar2
, p_index_name in varchar2
)
return varchar2
is
  l_column_names varchar2(4000 char) := null;
begin
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
  dbug.enter(g_package_prefix || 'GET_COLUMN_NAMES (2)');
  dbug.print(dbug."input", 'p_owner: %s; p_index_name: %s', p_owner, p_index_name);
$end

  for r in
  ( select  ic.column_name
$if pkg_ddl_util.c_#138550749 $then
    ,       ie.column_expression
$end
    from    all_ind_columns ic
$if pkg_ddl_util.c_#138550749 $then
            left join all_ind_expressions ie
            on ie.index_owner = ic.index_owner and ie.index_name = ic.index_name and ie.column_position = ic.column_position
$end    
    where   ic.index_owner = p_owner /* p_object_schema */ -- GJP 2021-08-31 Necessary in case of a remap
    and     ic.index_name = p_index_name
    order by
            ic.column_position asc nulls first
    ,       ic.column_name
  )
  loop
    l_column_names :=
      case when l_column_names is not null then l_column_names || ',' end ||
$if pkg_ddl_util.c_#138550749 $then
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

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
  dbug.print(dbug."output", 'return: %s', l_column_names);
  dbug.leave;
$end

  return l_column_names;
end get_column_names;

end pkg_schema_object;
/

