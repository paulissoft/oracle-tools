CREATE OR REPLACE PACKAGE BODY "ORACLE_TOOLS"."PKG_DDL_UTIL" IS /* -*-coding: utf-8-*- */

  /* TYPES */

  type t_db_link_tab is table of all_db_links.db_link%type index by all_db_links.db_link%type;

  type t_object_natural_tab is table of natural /* >= 0 */
  index by t_object;

  type t_object_dependency_tab is table of t_object_natural_tab index by t_object;

  type t_object_lookup_rec is record
  ( count t_numeric_boolean default 0
  , schema_ddl oracle_tools.t_schema_ddl
  , ready boolean default false -- pipe row has been issued
  );

  type t_object_lookup_tab is table of t_object_lookup_rec index by t_object;

  -- key is oracle_tools.t_schema_object.signature(), value is oracle_tools.t_schema_object.id()
  type t_constraint_lookup_tab is table of t_object index by t_object; -- for parse_ddl

  -- just to make the usage of VIEW oracle_tools.v_display_ddl_schema in dynamic SQL explicit
  subtype t_stm_v_display_ddl_schema is oracle_tools.v_display_ddl_schema%rowtype;

  subtype t_graph is t_object_dependency_tab;
  /*
  -- l_object_dependency_tab t_graph;
  -- l_object_dependency_tab(l_object_dependency)(l_object) := null;
  */
  -- This means l_object depends on l_object_dependency

  type t_object_exclude_name_expr_tab is table of oracle_tools.t_text_tab index by t_metadata_object_type;

  subtype t_module is varchar2(100);

  subtype t_longops_rec is oracle_tools.api_longops_pkg.t_longops_rec;

  type t_transform_param_tab is table of boolean index by varchar2(4000 char);

  /* CONSTANTS/VARIABLES */

  -- a simple check to ensure the euro sign gets not scrambled, i.e. whether generate_ddl.pl can write down unicode characters
  c_euro_sign constant varchar2(1 char) := '€';

  c_dbms_metadata_set_count_small_ddl constant pls_integer := 100;
  c_dbms_metadata_set_count_large_ddl constant pls_integer := 10;

  -- ORA-01795: maximum number of expressions in a list is 1000
  c_max_object_name_tab_count constant integer := 1000;

  c_fetch_limit constant pls_integer := 100;

  g_dbname global_name.global_name%type := null;

  g_package constant t_module := $$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT;

  g_package_prefix constant t_module := g_package || '.';

  g_max_fetch constant simple_integer := 100;

  function get_object_no_dependencies_tab
  return t_object_natural_tab;

  c_object_no_dependencies_tab constant t_object_natural_tab := get_object_no_dependencies_tab; -- initialisation

  "schema_version" constant user_objects.object_name%type := 'schema_version';

  "flyway_schema_history" constant user_objects.object_name%type := 'flyway_schema_history';

  "CREATE$JAVA$LOB$TABLE" constant user_objects.object_name%type := 'CREATE$JAVA$LOB$TABLE';

  c_object_to_ignore_tab constant oracle_tools.t_text_tab := oracle_tools.t_text_tab("schema_version", "flyway_schema_history", "CREATE$JAVA$LOB$TABLE");

$if oracle_tools.cfg_pkg.c_testing $then

  "EMPTY"                    constant all_objects.owner%type := 'EMPTY';

  g_owner constant all_objects.owner%type := $$PLSQL_UNIT_OWNER;

  g_owner_utplsql all_objects.owner%type; -- not a real constant but set only once

  g_empty constant all_objects.owner%type := "EMPTY";

  g_raise_exc constant boolean := true;

  g_loopback constant varchar2(10 char) := 'LOOPBACK';

  c_transform_param_list_testing constant varchar2(4000 char) :=
    -- c_transform_param_list = 'CONSTRAINTS,CONSTRAINTS_AS_ALTER,FORCE,PRETTY,REF_CONSTRAINTS,SEGMENT_ATTRIBUTES,TABLESPACE'
    '-CONSTRAINTS_AS_ALTER,-SEGMENT_ATTRIBUTES';


$end -- $if oracle_tools.cfg_pkg.c_testing $then

  /* EXCEPTIONS */

  -- ORA-31603: object ... of type MATERIALIZED_VIEW not found in schema ...
  -- GJP 2022-09-05 Not used here anymore
  /*
  -- e_object_not_found exception;
  -- pragma exception_init(e_object_not_found, -31603);
  */

  -- ORA-31623: a job is not attached to this session via the specified handle
  e_job_is_not_attached exception;
  pragma exception_init(e_job_is_not_attached, -31623);

--  -- ORA-31604: invalid transform NAME parameter "MODIFY" for object type ON_USER_GRANT in function ADD_TRANSFORM
--  e_invalid_transform_parameter exception;
--  pragma exception_init(e_invalid_transform_parameter, -31604);

  -- ORA-31602: parameter OBJECT_TYPE value "XMLSCHEMA" in function ADD_TRANSFORM inconsistent with HANDLE
  e_wrong_transform_object_type exception;
  pragma exception_init(e_wrong_transform_object_type, -31602);

  -- ORA-44003: invalid SQL name
  e_invalid_sql_name exception;
  pragma exception_init(e_invalid_sql_name, -44003);

  -- ORA-31600: invalid input value OID for parameter NAME in function SET_TRANSFORM_PARAM
  e_invalid_transform_param exception;
  pragma exception_init(e_invalid_transform_param, -31600);

/* VARIABLES */

  g_object_exclude_name_expr_tab t_object_exclude_name_expr_tab;  

  g_db_link_tab t_db_link_tab;

  /*
  -- GPA 2017-01-20
  --
  -- How do we get the DDL via a database link using the correct
  -- authentication?
  --
  -- Well, we need to use a view since a pipelined function with a database
  -- link does not work.  But then, if we use a view (which actually uses
  -- AUTHID DEFINER) the AUTHID for oracle_tools.pkg_ddl_util will be the same,
  -- i.e. ORACLE_TOOLS. That means that objects not granted directly to
  -- ORACLE_TOOLS on the remote database will not be retrieved by
  -- DBMS_METADATA.
  --
  -- The solution is to get (a cursor to) the data already in
  -- set_display_ddl_schema_args() which is called before the view which calls
  -- get_display_ddl_schema(). Now the correct authentication is used.
  --
  -- So:
  -- a) for Oracle 11g and above open a ref cursor in
  --    set_display_ddl_schema_args() and since ref cursors can not be used as
  --    a package variable, convert it to a DBMS_SQL cursor package variable
  --    (just an integer) and use it later on in get_display_ddl_schema().
  -- b) for Oracle 10g and below just get all the data in
  --    set_display_ddl_schema_args() and use it later on in
  --    get_display_ddl_schema()
  */


$if dbms_db_version.ver_le_10 $then

  $error 'Oracle 10 and below not supported.' $end

$else
  -- PLS-00994: Cursor Variables cannot be declared as part of a package
  -- So store a dbms_sql cursor (integer) and convert to sys_refcursor whenever necessary.
  -- Only available in Oracle 11g and above.
  g_cursor integer := null;

  -- to be used to transfer CLOBs via remote link
  g_exclude_objects dbms_sql.varchar2a;
  g_include_objects dbms_sql.varchar2a;

$end

  g_clob clob := null;

  -- DBMS_METADATA object types voor DBA gerelateerde taken (DBA rol)
  g_dba_md_object_type_tab constant oracle_tools.t_text_tab := oracle_tools.t_text_tab( 'CONTEXT'
                                                            /*, 'DEFAULT_ROLE'*/
                                                            , 'DIRECTORY'
                                                            /*, 'FGA_POLICY'*/
                                                            /*, 'ROLE'*/
                                                            /*, 'ROLE_GRANT'*/
                                                            /*, 'ROLLBACK_SEGMENT'*/
                                                            , 'SYSTEM_GRANT'
                                                            /*, 'TABLESPACE'*/
                                                            /*, 'TABLESPACE_QUOTA'*/
                                                            /*, 'TRUSTED_DB_LINK'*/
                                                            /*, 'USER'*/
                                                            );

  -- DBMS_METADATA object types voor de PUBLIC rol
  g_public_md_object_type_tab constant oracle_tools.t_text_tab := oracle_tools.t_text_tab('DB_LINK');

  -- DBMS_METADATA object types ordered by least dependencies (see also sort_objects_by_deps)
  g_schema_md_object_type_tab constant oracle_tools.t_text_tab :=
    oracle_tools.t_text_tab
    ( 'SEQUENCE'
    , 'TYPE_SPEC'
    , 'CLUSTER'
$if oracle_tools.pkg_ddl_util.c_get_queue_ddl $then
    , 'AQ_QUEUE_TABLE'
    , 'AQ_QUEUE'
$else
    /* ORA-00904: "KU$"."SCHEMA_OBJ"."TYPE": invalid identifier */
    /* voorlopig nog geen queues i.v.m. voorgaand probleem */
$end
    , 'TABLE'
    , 'COMMENT'
    -- een (package) functie kan door een constraint, index of view worden gebruikt
    , 'FUNCTION'
    , 'PACKAGE_SPEC'
    , 'VIEW'
    , 'PROCEDURE'
    , 'MATERIALIZED_VIEW'
    , 'MATERIALIZED_VIEW_LOG'
    , 'PACKAGE_BODY'
    , 'TYPE_BODY'
    -- als de index is gebaseerd op een package functie dan moet ook de body al aangemaakt zijn tijdens aanmaken index
    , 'INDEX'
    , 'TRIGGER'
    , 'OBJECT_GRANT'
    /* zit al bij TABLE */ --,'CONSTRAINT'
    /* zit al bij TABLE */ --,'REF_CONSTRAINT'
    , 'SYNONYM' -- zo laat mogelijk i.v.m. verwijderen publieke synoniemen in synchronize()
    -- vanaf hier is beste volgorde niet bekend
$if oracle_tools.pkg_ddl_util.c_get_db_link_ddl $then
    , 'DB_LINK'
$end                                                                                   
$if oracle_tools.pkg_ddl_util.c_get_dimension_ddl $then
    , 'DIMENSION'
$end                                                                                   
$if oracle_tools.pkg_ddl_util.c_get_indextype_ddl $then
    , 'INDEXTYPE'
$end                                                                                   
    , 'JAVA_SOURCE'
$if oracle_tools.pkg_ddl_util.c_get_library_ddl $then
    , 'LIBRARY'
$end                                                                                   
$if oracle_tools.pkg_ddl_util.c_get_operator_ddl $then
    , 'OPERATOR'
$end                                                                                   
    , 'REFRESH_GROUP'
$if oracle_tools.pkg_ddl_util.c_get_xmlschema_ddl $then
    , 'XMLSCHEMA'
$end 
    , 'PROCOBJ'
    );

  g_dependent_md_object_type_tab constant oracle_tools.t_text_tab :=
    oracle_tools.t_text_tab
    ( 'OBJECT_GRANT'   -- Part of g_schema_md_object_type_tab
    , 'SYNONYM'        -- Part of g_schema_md_object_type_tab
    , 'COMMENT'        -- Part of g_schema_md_object_type_tab
    , 'CONSTRAINT'     -- NOT part of g_schema_md_object_type_tab
    , 'REF_CONSTRAINT' -- NOT part of g_schema_md_object_type_tab
    , 'INDEX'          -- Part of g_schema_md_object_type_tab
    , 'TRIGGER'        -- Part of g_schema_md_object_type_tab
    );

  g_chk_tab t_object_natural_tab;

  -- forward declaration to be able to use it in a constant assignment
  function default_transform_param_tab
  return t_transform_param_tab;

  c_transform_param_tab constant t_transform_param_tab := default_transform_param_tab;

  g_ddl_tab sys.ku$_ddls; -- should be package global for better performance

  /* PRIVATE ROUTINES */

  function default_transform_param_tab
  return t_transform_param_tab
  is
    l_transform_param_tab t_transform_param_tab;
  begin
    l_transform_param_tab('CONSTRAINTS_AS_ALTER') := false;
    l_transform_param_tab('CONSTRAINTS') := false;
    l_transform_param_tab('FORCE') := false;
    l_transform_param_tab('OID') := false;
    l_transform_param_tab('PRETTY') := false;
    l_transform_param_tab('REF_CONSTRAINTS') := false;
    l_transform_param_tab('SEGMENT_ATTRIBUTES') := false;
    l_transform_param_tab('SIZE_BYTE_KEYWORD') := false;
    l_transform_param_tab('STORAGE') := false;
    l_transform_param_tab('TABLESPACE') := false;

    return l_transform_param_tab;
  end default_transform_param_tab;

  function get_db_link
  ( p_network_link in t_network_link
  )
  return varchar2
  is
    l_db_link all_db_links.db_link%type;
    l_cursor sys_refcursor;
  begin
    if not(g_db_link_tab.exists(upper(p_network_link)))
    then
      begin
        -- GPA 2016-12-12 #135952639 When a database link is defined as private and public the private must be chosen during DDL generation.
        select  oracle_tools.data_api_pkg.dbms_assert$enquote_name(t.db_link, 'database link')
        into    l_db_link
        from    all_db_links t
        where   t.db_link = upper(p_network_link)
        and     rownum = 1; -- GPA 2016-12-15 #135952639 get only one if both a private and a public db link exist
      exception
        when no_data_found
        then
          -- GPA 15-09-2015
          -- p_network_link is not a private/public database link but
          -- maybe a global database link (not created by "create database link" statement but just a TNS entry).
          -- In the latter case the user must exist with the same password (or an OPS$ user) on the remote database.
          open l_cursor for 'select dbms_assert.enquote_name(global_name) from global_name@' || upper(p_network_link);
          fetch l_cursor into l_db_link;
          close l_cursor;
      end;

      g_db_link_tab(upper(p_network_link)) := l_db_link;
    else
      l_db_link := g_db_link_tab(upper(p_network_link));
    end if;

    return l_db_link;
  exception
    when others then
      return null;
  end get_db_link;

  procedure check_network_link
  ( p_network_link in t_network_link
  , p_description in varchar2 default 'Database link'
  )
  is
  begin
    if p_network_link is not null and
       get_db_link(p_network_link) is null
    then
      raise_application_error(oracle_tools.pkg_ddl_error.c_database_link_does_not_exist, p_description || ' "' || p_network_link || '" unknown.');
    end if;  
  end check_network_link;

  procedure check_source_target
  ( p_schema_source in t_schema
  , p_schema_target in t_schema
  , p_network_link_source in t_network_link
  , p_network_link_target in t_network_link
  )
  is
  begin
    if ((p_network_link_source is null and p_network_link_target is null) or
        (p_network_link_source = p_network_link_target)) and
       (p_schema_source = p_schema_target)
    then
      -- source and target equal
      raise_application_error(oracle_tools.pkg_ddl_error.c_source_and_target_equal, 'Source and target may not be equal.');
    end if;
  end check_source_target;

$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then

  procedure print
  ( p_line_tab in dbms_sql.varchar2a
  , p_first in pls_integer
  , p_last in pls_integer
  , p_print_enter_leave in boolean default true
  )
  is
    l_idx pls_integer := p_first;
  begin
    if p_print_enter_leave
    then
      dbug.enter(g_package_prefix || 'PRINT (1)');
      dbug.print(dbug."input", 'p_line_tab.count: %s; p_first: %s; p_last: %s', p_line_tab.count, p_first, p_last);
    end if;

    <<line_loop>>
    while l_idx <= p_last
    loop
      dbug.print(dbug."info", 'p_line_tab(%s): "%s"', l_idx, case when p_line_tab.exists(l_idx) then p_line_tab(l_idx) else '<DOES NOT EXIST>' end);
      l_idx := l_idx + 1;
    end loop line_loop;

    if p_print_enter_leave
    then
      dbug.leave;
    end if;
  exception
    when others
    then
      if p_print_enter_leave
      then
        dbug.leave_on_error;
      end if;
      raise;
  end print;

  procedure print
  ( p_description in varchar2
  , p_line_tab in dbms_sql.varchar2a
  , p_first in pls_integer default null
  , p_last in pls_integer default null
  )
  is
  begin
    dbug.enter(g_package_prefix || 'PRINT (2)');
    dbug.print(dbug."info", p_description);
    print(p_line_tab, nvl(p_first, p_line_tab.first), nvl(p_last, p_line_tab.last), false);
    dbug.leave;
  end print;

  procedure print
  ( p_description in varchar2
  , p_text_tab in oracle_tools.t_text_tab
  )
  is
    l_str varchar2(32767 char);
    l_line_tab dbms_sql.varchar2a;
  begin
    if p_text_tab is not null and p_text_tab.count > 0
    then
      l_str := p_text_tab(p_text_tab.first); -- to prevent a VALUE_ERROR (?!)
      oracle_tools.pkg_str_util.split(p_str => l_str, p_delimiter => chr(10), p_str_tab => l_line_tab);
    end if;
    print(p_description, l_line_tab, l_line_tab.first, least(l_line_tab.last, 10));
  exception
    when others
    then
      dbug.on_error;
      raise;
  end print;

$end

  /*
  -- see depth-first search algorithm in https://en.wikipedia.org/wiki/Topological_sorting
  --
  -- code                                                       | marker
  -- ====                                                       | ======
  -- function visit(node n)                                     |
  --    if n has a temporary mark then stop (not a DAG)         | A
  --    if n is not marked (i.e. has not been visited yet) then | B
  --        mark n temporarily                                  | C
  --        for each node m with an graph from n to m do        | D
  --            visit(m)                                        | E
  --        mark n permanently                                  | F
  --        unmark n temporarily                                | G
  --        add n to head of L                                  | H
  */
  procedure visit
  ( p_graph in t_graph
  , p_n in t_object
  , p_unmarked_nodes in out nocopy t_object_natural_tab
  , p_marked_nodes in out nocopy t_object_natural_tab
  , p_result in out nocopy dbms_sql.varchar2_table
  , p_error_n out nocopy t_object
  )
  is
    l_m t_object;
  begin
    p_error_n := null;

    if p_marked_nodes.exists(p_n)
    then
      if p_marked_nodes(p_n) = 1 /* A */
      then
        -- node has been visited before
        p_error_n := p_n;
        return;
      end if;
    else
      if not p_unmarked_nodes.exists(p_n)
      then
        raise program_error;
      end if;

      /* B */
      p_marked_nodes(p_n) := 1; -- /* C */

      /* D */
      if p_graph.exists(p_n)
      then
        l_m := p_graph(p_n).first;
        while l_m is not null
        loop
          visit
          ( p_graph => p_graph
          , p_n => l_m
          , p_unmarked_nodes => p_unmarked_nodes
          , p_marked_nodes => p_marked_nodes
          , p_result => p_result
          , p_error_n => p_error_n
          ); /* E */
          if p_error_n is not null
          then
            return;
          end if;
          l_m := p_graph(p_n).next(l_m);
        end loop;
      end if;

      p_marked_nodes(p_n) := 2; -- /* F */
      p_unmarked_nodes.delete(p_n); -- /* G */
      p_result(-p_result.count) := p_n; /* H */
    end if;
  end visit;

  procedure tsort
  ( p_graph in t_graph
  , p_result out nocopy dbms_sql.varchar2_table /* I */
  , p_error_n out nocopy t_object
  )
  is
    l_unmarked_nodes t_object_natural_tab;
    l_marked_nodes t_object_natural_tab; -- l_marked_nodes(n) = 1 (temporarily marked) or 2 (permanently marked)
    l_n t_object;
    l_m t_object;
  begin
$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
    dbug.enter(g_package_prefix || 'TSORT');
$end

    /*
    -- see depth-first search algorithm in https://en.wikipedia.org/wiki/Topological_sorting
    --
    -- code                                               | marker
    -- ====                                               | ======
    -- L := Empty list that will contain the sorted nodes | I
    -- while there are unmarked nodes do                  | J
    --    select an unmarked node n                       | K
    --    visit(n)                                        | L
    */

    /* I */
    if p_result.count <> 0
    then
      raise program_error;
    end if;

    /* determine unmarked nodes: all node graphs */
    l_n := p_graph.first;
    while l_n is not null
    loop
      l_unmarked_nodes(l_n) := 0; -- n not marked
      l_m := p_graph(l_n).first;
      while l_m is not null
      loop
        l_unmarked_nodes(l_m) := 0; -- m not marked
        l_m := p_graph(l_n).next(l_m);
      end loop;
      l_n := p_graph.next(l_n);
    end loop;
    /* all nodes are unmarked */

    while l_unmarked_nodes.count > 0 /* J */
    loop
      /* L */
      visit
      ( p_graph => p_graph
      , p_n => l_unmarked_nodes.first /* K */
      , p_unmarked_nodes => l_unmarked_nodes
      , p_marked_nodes => l_marked_nodes
      , p_result => p_result
      , p_error_n => p_error_n
      );
      exit when p_error_n is not null;
    end loop;

$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
    dbug.print(dbug."output", 'p_error_n: %s', p_error_n);
    dbug.leave;
  exception
    when others
    then
      dbug.leave_on_error;
      raise;
$end
  end tsort;

  procedure dsort
  ( p_graph in out nocopy t_graph
  , p_result out nocopy dbms_sql.varchar2_table /* I */
  )
  is
    l_error_n t_object;
  begin
$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
    dbug.enter(g_package_prefix || 'DSORT');
$end

    while true
    loop
      tsort(p_graph, p_result, l_error_n);

      exit when l_error_n is null; -- successful: stop

      if p_graph(l_error_n).count = 0
      then
        raise program_error;
      end if;

      p_graph(l_error_n) := c_object_no_dependencies_tab;

      if p_graph(l_error_n).count != 0
      then
        raise program_error;
      end if;
    end loop;

$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
    dbug.leave;
  exception
    when others
    then
      dbug.leave_on_error;
      raise;
$end
  end dsort;

  function get_host(p_network_link in varchar2)
  return varchar2
  is
    l_host all_db_links.host%type;
  begin
$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
    dbug.enter(g_package_prefix || 'GET_HOST');
    dbug.print(dbug."input", 'p_network_link: %s', p_network_link);
$end

    if p_network_link is null
    then
      select oracle_tools.data_api_pkg.dbms_assert$enquote_name(t.global_name, 'database') into l_host from global_name t;
    else
      select oracle_tools.data_api_pkg.dbms_assert$enquote_name(t.host, 'host') into l_host from all_db_links t where t.db_link = upper(p_network_link);
    end if;

$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
    dbug.print(dbug."output", 'return: %s', l_host);
    dbug.leave;
$end

    return l_host;
  exception
    when others then
$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
      dbug.print(dbug."output", 'return: %s', to_char(null));
      dbug.leave;
$end
      return null;
  end get_host;

  procedure parse_ddl
  ( p_ddl in sys.ku$_ddl
  , p_schema in varchar2 -- necessary when there is a remap going on
  , p_object_lookup_tab in t_object_lookup_tab
  , p_constraint_lookup_tab in t_constraint_lookup_tab
  , p_verb out nocopy varchar2
  , p_object_name out nocopy varchar2
  , p_object_type out nocopy varchar2
  , p_object_schema out nocopy varchar2
  , p_base_object_name out nocopy varchar2
  , p_base_object_type out nocopy varchar2
  , p_base_object_schema out nocopy varchar2
  , p_column_name out nocopy varchar2
  , p_grantee out nocopy varchar2
  , p_privilege out nocopy varchar2
  , p_grantable out nocopy varchar2
  )
  is
    l_ddl_text varchar2(100 char) := null;

    procedure nullify_output_parameters
    is
    begin
      -- nullify all output parameters
      p_verb := null;
      p_object_name := null;
      p_object_type := null;
      p_object_schema := null;
      p_base_object_name := null;
      p_base_object_type := null;
      p_base_object_schema := null;
      p_column_name := null;
      p_grantee := null;
      p_privilege := null;
      p_grantable := null;
    end nullify_output_parameters;

    procedure parse_alter
    is
      l_constraint varchar2(32767 char) := oracle_tools.pkg_str_util.dbms_lob_substr(p_clob => p_ddl.ddlText, p_amount => 32767);
      l_constraint_expr_tab constant oracle_tools.t_text_tab :=
        oracle_tools.t_text_tab
        ( -- 1) ALTER TABLE "<owner>"."<table>" ADD CONSTRAINT "<pk>" PRIMARY KEY (...)
          --    ALTER TABLE "<owner>"."<table>" ADD CONSTRAINT "<fk>" FOREIGN KEY (...)
          --    ALTER TABLE "<owner>"."<table>" ADD CONSTRAINT "<ck>" CHECK (...)
          'ALTER % "%"."%" ADD CONSTRAINT "%" %' -- named constraint
        , -- 2) ALTER TABLE "<owner>"."<table>" ADD PRIMARY KEY ("SEQ")
          'ALTER % "%"."%" ADD PRIMARY KEY %' -- system generated constraint
        , -- 3) ALTER TABLE "<owner>"."<table>" ADD UNIQUE ("SYS_NC_OID$") ENABLE;
          'ALTER % "%"."%" ADD UNIQUE %' -- system generated unique constraint
        , -- 4) ALTER TABLE "<owner>"."<table>" ADD FOREIGN KEY ("CMMSEQ") REFERENCES "<owner>"."<rtable>" ("SEQ")
          'ALTER % "%"."%" ADD FOREIGN KEY %' -- system generated constraint
        , -- 5) ALTER TABLE "<owner>"."<table>" ADD CHECK ( ... )
          'ALTER % "%"."%" ADD CHECK (%)%' -- system generated constraint
        , -- 6) ALTER TABLE "<owner>"."APEX$_ACL" MODIFY ("CREATED_BY" NOT NULL ENABLE);
          --    ALTER TABLE "BC_PORTAL"."BCP_IMAGES" MODIFY ("ID" CONSTRAINT "NNC_IMG_ID" NOT NULL ENABLE)
          'ALTER % "%"."%" MODIFY ("%" NOT NULL ENABLE)%' -- system generated not null constraint
        , -- 7) ALTER TABLE "BATCHPRICEAGREEMENTS" MODIFY ("SEQ" GENERATED BY DEFAULT AS IDENTITY MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH  LIMIT VALUE  NOCACHE  ORDER  NOCYCLE );
          'ALTER % "%"."%" MODIFY ("%" GENERATED %)%' -- identity management
        );
      l_constraint_expr_idx pls_integer;
      l_pos1 pls_integer := null;
      l_pos2 pls_integer := null;
      l_column_names varchar2(32767 char);
      l_search_condition varchar2(32767 char);

      /*
       * GJP 2022-07-17
       * 
       * BUG: the referential constraints are not created in the correct order in the install.sql file (https://github.com/paulissoft/oracle-tools/issues/35).
       *
       * The solution is to have a better dependency sort order and thus let the referential constraint depends on the primary / unique key and not on the base table / view.
       */ 
      l_base_object oracle_tools.t_named_object;
      l_ref_column_names varchar2(32767 char);
      l_ref_object oracle_tools.t_constraint_object := null;
      l_ref_base_object_schema t_schema;
      l_ref_base_object_name t_object;
      l_constraint_object oracle_tools.t_constraint_object := null;

      cursor c_con(b_schema in t_schema_nn, b_table_name in varchar2) is
        select  c.constraint_name
        ,       c.search_condition
        from    all_constraints c
        where   c.owner = b_schema
        and     c.constraint_type in ('C')
        and     c.table_name = b_table_name
        order by
                c.constraint_name
      ;

      type t_con is record (
        constraint_name user_constraints.constraint_name%type
      , search_condition varchar2(32767 char) -- database column is a LONG
      );

      r_con t_con;
      
      procedure add_user_constraint
      is
      begin
        /*
        -- l_constraint_expr_idx = 1
        */
        l_pos1 := instr(l_constraint, '"', 1, 5);
        l_pos2 := instr(l_constraint, '"', 1, 6);
        p_object_name := substr(l_constraint, l_pos1+1, l_pos2 - (l_pos1+1));
$if oracle_tools.pkg_ddl_util.c_debugging_parse_ddl $then
        dbug.print
        ( dbug."info"
        , 'l_pos1: %s; l_pos2: %s; p_object_name: %s'
        , l_pos1
        , l_pos2
        , p_object_name
        );
$end
      end add_user_constraint;

      procedure add_system_constraint
      is
      begin
        /*
        -- l_constraint_expr_idx between 2 and 4  
        */
        -- get the column names (without spaces)
        l_pos1 := instr(l_constraint, '(');
        l_pos2 := instr(l_constraint, ')');
        if l_pos1 > 0 and l_pos2 > l_pos1
        then
          l_column_names := replace(substr(l_constraint, l_pos1+1, l_pos2 - (l_pos1+1)), ' ');

$if oracle_tools.pkg_ddl_util.c_debugging_parse_ddl $then
          dbug.print
          ( dbug."info"
          , 'l_pos1: %s; l_pos2: %s; l_column_names: %s'
          , l_pos1
          , l_pos2
          , l_column_names
          );
$end

          l_base_object :=
            oracle_tools.t_named_object.create_named_object
            ( p_object_type => p_base_object_type
            , p_object_schema => p_base_object_schema
            , p_object_name => p_base_object_name
            );

          case
            when l_constraint_expr_idx = 2 -- primary key
            then l_constraint_object := oracle_tools.t_constraint_object
                                        ( p_base_object => l_base_object
                                        , p_object_schema => p_base_object_schema
                                        , p_object_name => null -- constraint name is not known
                                        , p_constraint_type => 'P'
                                        , p_column_names => l_column_names
                                        );
            when l_constraint_expr_idx = 3 -- unique key
            then l_constraint_object := oracle_tools.t_constraint_object
                                        ( p_base_object => l_base_object
                                        , p_object_schema => p_base_object_schema
                                        , p_object_name => null -- constraint name is not known
                                        , p_constraint_type => 'U'
                                        , p_column_names => l_column_names
                                        );
            when l_constraint_expr_idx = 4 -- foreign key
            then
              -- ALTER TABLE "<owner>"."<table>" ADD FOREIGN KEY ("CMMSEQ") REFERENCES "<owner>"."<rtable>" ("<ref_column_name1>"[,"<ref_column_nameN>"])

              -- get the reference object schema, since l_pos2 is the position of the first ')'
              l_pos1 := instr(l_constraint, '"', l_pos2+1);
              l_pos2 := instr(l_constraint, '"', l_pos1+1);
              l_ref_base_object_schema := substr(l_constraint, l_pos1+1, l_pos2 - (l_pos1+1));

              l_pos1 := instr(l_constraint, '"', l_pos2+1);
              l_pos2 := instr(l_constraint, '"', l_pos1+1);
              l_ref_base_object_name := substr(l_constraint, l_pos1+1, l_pos2 - (l_pos1+1));

              -- GJP 2022-07-15 We now have the reference base object but not yet the reference object (the constraint)
              l_pos1 := instr(l_constraint, '(', l_pos2+1); -- l_pos2 points to last '"' before '('
              l_pos2 := instr(l_constraint, ')', l_pos1+1); -- l_pos1 points to last '('
              if l_pos1 > 0 and l_pos2 > l_pos1
              then
                l_ref_column_names := replace(substr(l_constraint, l_pos1+1, l_pos2 - (l_pos1+1)), ' '); -- assumes a column name does not have a space inside

$if oracle_tools.pkg_ddl_util.c_debugging_parse_ddl $then
                dbug.print
                ( dbug."info"
                , 'l_pos1: %s; l_pos2: %s; l_ref_column_names: %s'
                , l_pos1
                , l_pos2
                , l_ref_column_names
                );
$end

                l_ref_object := oracle_tools.t_ref_constraint_object.get_ref_constraint
                                ( p_ref_base_object_schema => l_ref_base_object_schema
                                , p_ref_base_object_name => l_ref_base_object_name
                                , p_ref_column_names => l_ref_column_names
                                );
              end if;

$if oracle_tools.pkg_ddl_util.c_debugging_parse_ddl $then
              l_ref_object.print();
$end

              l_constraint_object := oracle_tools.t_ref_constraint_object
                                     ( p_base_object => l_base_object
                                     , p_object_schema => p_base_object_schema
                                     , p_object_name => null -- constraint name unknown
                                     , p_constraint_type => 'R'
                                     , p_column_names => l_column_names
                                     , p_ref_object => l_ref_object
                                     );
          end case;

$if oracle_tools.pkg_ddl_util.c_debugging_parse_ddl $then
          l_constraint_object.print();
$end

          begin
            p_object_name := p_object_lookup_tab(p_constraint_lookup_tab(l_constraint_object.signature())).schema_ddl.obj.object_name();
$if oracle_tools.pkg_ddl_util.c_debugging_parse_ddl $then
            dbug.print( dbug."info", 'p_object_name (%s) determined by lookup', p_object_name);
$end
          exception
            when others
            then
$if oracle_tools.pkg_ddl_util.c_debugging_parse_ddl $then
              dbug.print
              ( dbug."warning"
              , 'constraint signature: %s; constraint looked up: %s; p_object_name could not be determined by lookup: %s'
              , l_constraint_object.signature()
              , case when p_constraint_lookup_tab.exists(l_constraint_object.signature()) then p_constraint_lookup_tab(l_constraint_object.signature()) end
              , sqlerrm
              );
$end
              for r_cc in
              ( select  c.constraint_name
                ,       oracle_tools.t_constraint_object.get_column_names
                        ( p_object_schema => c.owner
                        , p_object_name => c.constraint_name
                        , p_table_name => c.table_name
                        ) as column_names
                from    all_constraints c
                where   c.owner = p_schema
                and     c.table_name = p_base_object_name
                        -- GJP 2023-01-16 We know the constraint type so use it.
                and     c.constraint_type = case l_constraint_expr_idx when 2 then 'P' when 3 then 'U' when 4 then 'R' end
              )
              loop
$if oracle_tools.pkg_ddl_util.c_debugging_parse_ddl $then
                dbug.print
                ( dbug."info"
                , 'r_cc.constraint_name: %s; r_cc.column_names: %s'
                , r_cc.constraint_name
                , r_cc.column_names
                );
$end
                if replace(r_cc.column_names, ' ') = replace(l_column_names, ' ')
                then
                  p_object_name := r_cc.constraint_name;
$if oracle_tools.pkg_ddl_util.c_debugging_parse_ddl $then
                  dbug.print( dbug."info", 'p_object_name (%s) determined by dictionary search', p_object_name);
$end
                  exit;
                end if;
              end loop;
          end;
        end if; -- if l_pos1 > 0 and l_pos2 > l_pos1
      end add_system_constraint;

      procedure check_constraint
      is
      begin
        /*
        -- l_constraint_expr_idx in (5, 6)
        */

        p_object_name := null; -- the constraint name
        
        l_pos1 := instr(l_constraint, '(');
        l_pos2 := instr(l_constraint, ')', -1); -- get the last parenthesis
        if l_pos1 > 0 and l_pos2 > l_pos1
        then
          l_search_condition := substr(l_constraint, l_pos1+1, l_pos2 - (l_pos1+1));

$if oracle_tools.pkg_ddl_util.c_debugging_parse_ddl $then
          dbug.print(dbug."info", 'l_search_condition: %s', l_search_condition);
$end

          if l_constraint_expr_idx = 6
          then
            if l_search_condition like '"%" CONSTRAINT "%"%'
            then
              -- we can retrieve the constraint name
              l_pos1 := instr(l_search_condition, '"', 1, 3);
              l_pos2 := instr(l_search_condition, '"', 1, 4);
              p_object_name := substr(l_search_condition, l_pos1+1, l_pos2 - (l_pos1+1));              
$if oracle_tools.pkg_ddl_util.c_debugging_parse_ddl $then
              dbug.print(dbug."info", 'named constraint: %s', p_object_name);
$end
            end if;
            l_search_condition := replace(l_search_condition, ' NOT NULL ENABLE', ' IS NOT NULL');
          end if;

          l_base_object :=
            oracle_tools.t_named_object.create_named_object
            ( p_object_type => p_base_object_type
            , p_object_schema => p_base_object_schema
            , p_object_name => p_base_object_name
            );

          l_constraint_object := oracle_tools.t_constraint_object
                                 ( p_base_object => l_base_object
                                 , p_object_schema => p_base_object_schema
                                 , p_object_name => p_object_name -- may be known
                                 , p_constraint_type => 'C'
                                 , p_search_condition => l_search_condition
                                 );

$if oracle_tools.pkg_ddl_util.c_debugging_parse_ddl $then
          l_constraint_object.print();
$end

          if p_object_name is null
          then
            begin
              p_object_name := p_object_lookup_tab(p_constraint_lookup_tab(l_constraint_object.signature())).schema_ddl.obj.object_name();
$if oracle_tools.pkg_ddl_util.c_debugging_parse_ddl $then
              dbug.print( dbug."info", 'p_object_name (%s) determined by lookup', p_object_name);
$end
            exception
              when others
              then
$if oracle_tools.pkg_ddl_util.c_debugging_parse_ddl $then
                dbug.print( dbug."warning", 'p_object_name could not be determined by lookup: %s', sqlerrm);
$end
                open c_con(b_schema => p_schema, b_table_name => p_base_object_name);
                <<fetch_loop>>
                loop
                  fetch c_con into r_con;

                  exit fetch_loop when c_con%notfound;

$if oracle_tools.pkg_ddl_util.c_debugging_parse_ddl $then
                  dbug.print
                  ( dbug."info"
                  , 'r_con.constraint_name: %s; r_con.search_condition: %s'
                  , r_con.constraint_name
                  , r_con.search_condition
                  );
$end

                  if r_con.search_condition = l_search_condition
                  then
                    p_object_name := r_con.constraint_name;
$if oracle_tools.pkg_ddl_util.c_debugging_parse_ddl $then
                    dbug.print( dbug."info", 'p_object_name (%s) determined by dictionary search', p_object_name);
$end
                    exit fetch_loop;
                  end if;
                end loop fetch_loop;
                close c_con;
            end;
          end if; -- if p_object_name is null
        end if; -- if l_pos1 > 0 and l_pos2 > l_pos1
      end check_constraint;
    begin
      -- skip whitespace at the beginning
      l_pos1 := 1;
      l_pos2 := length(l_constraint);
      while l_pos1 <= l_pos2 and substr(l_constraint, l_pos1, 1) in (chr(9), chr(10), chr(13), chr(32))
      loop
        l_pos1 := l_pos1 + 1;
      end loop;
      l_constraint := substr(l_constraint, l_pos1);

      l_constraint_expr_idx := 1;
      while l_constraint_expr_idx <= l_constraint_expr_tab.count and
            not(l_constraint like l_constraint_expr_tab(l_constraint_expr_idx))
      loop
        l_constraint_expr_idx := l_constraint_expr_idx + 1;
      end loop;

$if oracle_tools.pkg_ddl_util.c_debugging_parse_ddl $then
      dbug.print(dbug."info", 'l_constraint_expr_idx: %s; l_constraint: "%s"', l_constraint_expr_idx, l_constraint);
$end

      if l_constraint_expr_idx between 1 and 6
      then
        -- determine base info (TABLE/VIEW)
        if p_base_object_schema is null
        then
          l_pos1 := instr(l_constraint, '"', 1, 1);
          l_pos2 := instr(l_constraint, '"', 1, 2);
          p_base_object_schema := substr(l_constraint, l_pos1+1, l_pos2 - (l_pos1+1));
        end if;

        if p_base_object_type is null
        then
          p_base_object_type :=
            case
              when l_constraint like 'ALTER TABLE %' then 'TABLE'
              when l_constraint like 'ALTER VIEW %' then 'VIEW'
            end;
        end if;

        if p_base_object_name is null
        then
          l_pos1 := instr(l_constraint, '"', 1, 3);
          l_pos2 := instr(l_constraint, '"', 1, 4);
          p_base_object_name := substr(l_constraint, l_pos1+1, l_pos2 - (l_pos1+1));
        end if;

        -- now object info (CONSTRAINT/REF_CONSTRAINT)
        if p_object_schema is null
        then
          p_object_schema := p_base_object_schema;
        end if;

$if oracle_tools.pkg_ddl_util.c_debugging_parse_ddl $then
        dbug.print
        ( dbug."info"
        , 'p_object_type: %s; named constraint?: %s'
        , p_object_type
        , dbug.cast_to_varchar2(l_constraint_expr_idx = 1)
        );
$end
        -- NAMED CONSTRAINT?
        -- GPA 2016-11-24
        -- When object type is TABLE/VIEW, the object name is the name of the TABLE/VIEW and not the name of the constraint.
        if p_object_type in ('TABLE', 'VIEW') and
           l_constraint_expr_idx = 1
        then
          add_user_constraint;
        -- SYSTEM NON CHECK CONSTRAINT?
        elsif p_object_type in ('TABLE', 'VIEW') and
              l_constraint_expr_idx between 2 and 4
        then
          add_system_constraint;
        -- CHECK CONSTRAINT?
        elsif p_object_type in ('TABLE', 'VIEW') and
              l_constraint_expr_idx between 5 and 6
        then
          check_constraint;
        end if; -- if p_object_type in ('TABLE', 'VIEW') and

        -- Oracle DBMS_METADATA bug?
        -- <owner>:CONSTRAINT:UN_DG_LIST_UN_DG_CLASSIFI_FK1::::
        -- =>
        -- <owner>:REF_CONSTRAINT:UN_DG_LIST_UN_DG_CLASSIFI_FK1::::

        p_object_type := case when instr(l_constraint, ' FOREIGN KEY ') > 0 then 'REF_CONSTRAINT' else 'CONSTRAINT' end;
      elsif l_constraint_expr_idx = 7
      then
        null;
      elsif trim(replace(replace(l_constraint, chr(13)), chr(10))) is null
      then
        nullify_output_parameters;
      else        
        raise_application_error(oracle_tools.pkg_ddl_error.c_could_not_parse, 'Could not parse ALTER DDL "' || l_constraint || '"');
      end if;
    end parse_alter;

    procedure parse_comment
    is
    -- COMMENT ON TABLE "schema"."object" IS
    -- COMMENT ON VIEW "schema"."object" IS
    -- COMMENT ON MATERIALIZED VIEW "<owner>"."<mview>"
    -- COMMENT ON COLUMN "schema"."object"."column" IS
      l_pos1 pls_integer := dbms_lob.instr(lob_loc => p_ddl.ddlText, pattern => ' IS ');
      l_pos2 pls_integer;
      l_comment constant all_tab_comments.comments%type := oracle_tools.pkg_str_util.dbms_lob_substr(p_clob => p_ddl.ddlText, p_amount => case when l_pos1 > 0 then l_pos1 else 2000 end);
    begin
$if oracle_tools.pkg_ddl_util.c_debugging_parse_ddl $then
      dbug.print(dbug."info", 'l_comment: "%s"', l_comment);
$end

      if p_base_object_schema is null
      then
        l_pos1 := instr(l_comment, '"', 1, 1);
        l_pos2 := instr(l_comment, '"', 1, 2);
        p_base_object_schema := substr(l_comment, l_pos1+1, l_pos2 - (l_pos1+1));
      end if;
      if p_base_object_name is null
      then
        l_pos1 := instr(l_comment, '"', 1, 3);
        l_pos2 := instr(l_comment, '"', 1, 4);
        p_base_object_name := substr(l_comment, l_pos1+1, l_pos2 - (l_pos1+1));
      end if;
      if p_column_name is null and l_comment like '% ON COLUMN %'
      then
        l_pos1 := instr(l_comment, '"', 1, 5);
        l_pos2 := instr(l_comment, '"', 1, 6);
        p_column_name := substr(l_comment, l_pos1+1, l_pos2 - (l_pos1+1));
      end if;

      if p_base_object_type is null
      then
        case
          when l_comment like '% ON TABLE %' or
               l_comment like '% ON VIEW %'
          then
            -- Oracle returns COMMENT ON TABLE for a VIEW, :(
            select  min(obj.object_type)
            into    p_base_object_type
            from    all_objects obj
            where   obj.owner = p_schema
            and     obj.object_name = p_base_object_name
            and     obj.object_type in ( 'TABLE', 'VIEW' )
$if oracle_tools.pkg_ddl_util.c_exclude_system_objects $then
            and     obj.generated = 'N' -- GPA 2016-12-19 #136334705
$end            
            ;

          when l_comment like '% ON MATERIALIZED VIEW %'
          then
            p_base_object_type := 'MATERIALIZED_VIEW';

          when l_comment like '% ON COLUMN %'
          then
            select  min(obj.object_type)
            into    p_base_object_type
            from    all_objects obj
            where   obj.owner = p_schema
            and     obj.object_name = p_base_object_name
            and     obj.object_type in ( 'TABLE', 'MATERIALIZED VIEW', 'VIEW' )
$if oracle_tools.pkg_ddl_util.c_exclude_system_objects $then
            and     obj.generated = 'N' -- GPA 2016-12-19 #136334705
$end            
            ;

          when trim(replace(replace(l_comment, chr(13)), chr(10))) is null
          then
            nullify_output_parameters;

          else
            raise_application_error(oracle_tools.pkg_ddl_error.c_could_not_parse, 'Could not parse COMMENT DDL "' || l_comment || '"');
        end case;
      end if;
    exception
      when others
      then
        raise_application_error
        ( oracle_tools.pkg_ddl_error.c_could_not_parse
        , 'Comment: ' || l_comment ||
          '; p_schema: ' || p_schema ||
          '; p_base_object_name: ' || p_base_object_name
        , true
        );
    end parse_comment;

    procedure parse_procobj
    is
      l_plsql_block varchar2(4000 char) := oracle_tools.pkg_str_util.dbms_lob_substr(p_clob => p_ddl.ddlText, p_amount => 4000);
      l_pos1 pls_integer := null;
      l_pos2 pls_integer := null;
    begin
$if oracle_tools.pkg_ddl_util.c_debugging_parse_ddl $then
      dbug.print(dbug."info", 'l_plsql_block: "%s"', l_plsql_block);
$end
      if upper(l_plsql_block) like q'[%DBMS_SCHEDULER.CREATE_%('"%"'%]'
      then
        l_pos1 := instr(l_plsql_block, '"', 1, 1);
        l_pos2 := instr(l_plsql_block, '"', 1, 2);
        p_object_name := substr(l_plsql_block, l_pos1+1, l_pos2 - (l_pos1+1));
      elsif trim(replace(replace(l_plsql_block, chr(13)), chr(10))) is null
      then
        nullify_output_parameters;
      else
        raise_application_error(oracle_tools.pkg_ddl_error.c_could_not_parse, 'Could not parse PROCOBJ DDL "' || l_plsql_block || '"');
      end if;
    end parse_procobj;

    procedure parse_index
    is
      l_index varchar2(4000 char) := oracle_tools.pkg_str_util.dbms_lob_substr(p_clob => p_ddl.ddlText, p_amount => 4000);
      l_pos1 pls_integer := null;
      l_pos2 pls_integer := null;
    begin
$if oracle_tools.pkg_ddl_util.c_debugging_parse_ddl $then
      dbug.print(dbug."info", 'l_index: "%s"', l_index);
$end
      if l_index like 'CREATE INDEX %' or
         l_index like 'CREATE UNIQUE INDEX %' or
         l_index like 'CREATE BITMAP INDEX %'
      then
        -- CREATE INDEX "<owner>"."schema_version_s_idx" ON "<owner>"."schema_version"
        if p_base_object_schema is null
        then
          -- CREATE INDEX "<owner>"."schema_version_s_idx" ON "<owner>"."schema_version"
          if p_base_object_schema is null
          then
            l_pos1 := instr(l_index, '"', 1, 5);
            l_pos2 := instr(l_index, '"', 1, 6);
            p_base_object_schema := substr(l_index, l_pos1+1, l_pos2 - (l_pos1+1));
          end if;
          if p_base_object_name is null
          then
            l_pos1 := instr(l_index, '"', 1, 7);
            l_pos2 := instr(l_index, '"', 1, 8);
            p_base_object_name := substr(l_index, l_pos1+1, l_pos2 - (l_pos1+1));
          end if;
        end if;
      elsif trim(replace(replace(l_index, chr(13)), chr(10))) is null
      then
        nullify_output_parameters;
      else
        raise_application_error(oracle_tools.pkg_ddl_error.c_could_not_parse, 'Could not parse INDEX DDL "' || l_index || '"');
      end if;
    end parse_index;

    procedure parse_object_grant
    is
      l_object_grant varchar2(4000 char) := oracle_tools.pkg_str_util.dbms_lob_substr(p_clob => p_ddl.ddlText, p_amount => 4000);
      l_pos1 pls_integer := null;
      l_pos2 pls_integer := null;
    begin
$if oracle_tools.pkg_ddl_util.c_debugging_parse_ddl $then
      dbug.print(dbug."info", 'l_object_grant: "%s"', l_object_grant);
$end
      if l_object_grant like 'GRANT %'
      then
        -- GRANT SELECT ON "<owner>"."<table>" TO "<owner>";
        -- or
        -- GRANT SELECT ON "<owner>"."<table>" TO "<owner>" WITH GRANT OPTION;
        p_grantable := case when l_object_grant like '% WITH GRANT OPTION%' then 'YES' else 'NO' end;
        l_pos1 := instr(l_object_grant, 'GRANT ') + length('GRANT ');
        l_pos2 := instr(l_object_grant, ' ON "');
        p_privilege := substr(l_object_grant, l_pos1, l_pos2 - l_pos1);
      elsif trim(replace(replace(l_object_grant, chr(13)), chr(10))) is null
      then
        nullify_output_parameters;
      else
        raise_application_error(oracle_tools.pkg_ddl_error.c_could_not_parse, 'Could not parse OBJECT_GRANT DDL "' || l_object_grant || '"');
      end if;
    end parse_object_grant;

  begin
$if oracle_tools.pkg_ddl_util.c_debugging_parse_ddl $then
    dbug.enter(g_package_prefix || 'PARSE_DDL');
    dbug.print(dbug."input", 'p_schema: %s', p_schema);
$end

    if p_ddl.parseditems is not null and
       p_ddl.parseditems.count > 0
    then
      <<parse_item_loop>>
      for i_parsed_item_idx in p_ddl.parseditems.first .. p_ddl.parseditems.last
      loop
$if oracle_tools.pkg_ddl_util.c_debugging_parse_ddl $then
        dbug.print(dbug."info"
                   ,'p_ddl.parseditems(%s).item: %s; value: %s'
                   ,i_parsed_item_idx
                   ,p_ddl.parseditems(i_parsed_item_idx).item
                   ,p_ddl.parseditems(i_parsed_item_idx).value);
$end

        case p_ddl.parseditems(i_parsed_item_idx).item
          when 'VERB' then
            p_verb := p_ddl.parseditems(i_parsed_item_idx).value;
          when 'NAME' then
            p_object_name := p_ddl.parseditems(i_parsed_item_idx).value;
          when 'OBJECT_TYPE' then
            p_object_type := oracle_tools.t_schema_object.dict2metadata_object_type(p_ddl.parseditems(i_parsed_item_idx).value);
          when 'SCHEMA' then
            p_object_schema := p_ddl.parseditems(i_parsed_item_idx).value;
          when 'BASE_OBJECT_NAME' then
            p_base_object_name := p_ddl.parseditems(i_parsed_item_idx).value;
          when 'BASE_OBJECT_TYPE' then
            p_base_object_type := oracle_tools.t_schema_object.dict2metadata_object_type(p_ddl.parseditems(i_parsed_item_idx).value);
          when 'BASE_OBJECT_SCHEMA' then
            p_base_object_schema := p_ddl.parseditems(i_parsed_item_idx).value;
          when 'GRANTEE' then
            p_grantee := p_ddl.parseditems(i_parsed_item_idx).value;
        end case;
      end loop parse_item_loop;

$if oracle_tools.pkg_ddl_util.c_debugging_parse_ddl $then
      dbug.print
      ( dbug."info"
      , 'p_verb: %s; p_object_name; %s; p_object_type: %s; p_object_schema: %s'
      , p_verb
      , p_object_name
      , p_object_type
      , p_object_schema
      );
      dbug.print
      ( dbug."info"
      , 'p_base_object_name: %s; p_base_object_type: %s; p_base_object_schema: %s; p_grantable: %s'
      , p_base_object_name
      , p_base_object_type
      , p_base_object_schema
      , p_grantable
      );
$end

      -- TABLE/VIEW for Oracle 10g
      if p_verb = 'ALTER' and p_object_type in ('TABLE', 'VIEW', 'CONSTRAINT', 'REF_CONSTRAINT')
      then
        parse_alter;
      elsif p_verb = 'COMMENT' and
            (p_base_object_name is null or p_base_object_schema is null or p_base_object_type is null)
      then
        parse_comment;
      elsif p_object_type = 'PROCOBJ'
      then
        parse_procobj;
      elsif p_object_type = 'INDEX'
      then
        parse_index;
      elsif p_object_type = 'OBJECT_GRANT' -- GPA 2016-11-28 #135018217
      then
        parse_object_grant;
      elsif p_verb in ('DBMS_JAVA.START_IMPORT', 'DBMS_JAVA.IMPORT_TEXT_CHUNK', 'DBMS_JAVA.IMPORT_RAW_CHUNK', 'DBMS_JAVA.END_IMPORT') or
            p_object_type in ('PROCACT_SCHEMA', 'PROCACT_SYSTEM', 'JAVA_CLASS')                 
      then
        l_ddl_text := oracle_tools.pkg_str_util.dbms_lob_substr(p_clob => p_ddl.ddlText, p_amount => 100);
        raise_application_error
        ( oracle_tools.pkg_ddl_error.c_object_not_correct
        , utl_lms.format_message
          ( 'Verb "%s" and/or object type "%s" not correct for ddl "%s"'
          , p_verb
          , p_object_type
          , l_ddl_text
          )
        , true
        );
        nullify_output_parameters;        
      end if;
    end if;

$if oracle_tools.pkg_ddl_util.c_debugging_parse_ddl $then
    dbug.print
    ( dbug."output"
    , 'p_verb: %s; p_object_name; %s; p_object_type: %s; p_object_schema: %s'
    , p_verb
    , p_object_name
    , p_object_type
    , p_object_schema
    );
    dbug.print
    ( dbug."output"
    , 'p_base_object_name: %s; p_base_object_type: %s; p_base_object_schema: %s; p_column_name: %s'
    , p_base_object_name
    , p_base_object_type
    , p_base_object_schema
    , p_column_name
    );
    dbug.print
    ( dbug."output"
    , 'p_grantee: %s; p_privilege: %s; p_grantable: %s'
    , p_grantee
    , p_privilege
    , p_grantable
    );
    dbug.leave;
$end
  exception
    when others then
$if oracle_tools.pkg_ddl_util.c_debugging_parse_ddl $then
      dbug.leave_on_error;
$end      
      raise;
  end parse_ddl;

  procedure i_object_exclude_name_expr_tab
  is
    procedure add(p_object_type in varchar2, p_exclude_name_expr in varchar2)
    is
    begin
      if not(g_object_exclude_name_expr_tab.exists(p_object_type))
      then
        g_object_exclude_name_expr_tab(p_object_type) := oracle_tools.t_text_tab();
      end if;

      g_object_exclude_name_expr_tab(p_object_type).extend(1);
      g_object_exclude_name_expr_tab(p_object_type)(g_object_exclude_name_expr_tab(p_object_type).last) := p_exclude_name_expr;
    end add;

    procedure add(p_object_type_tab in oracle_tools.t_text_tab, p_exclude_name_expr in varchar2)
    is
    begin
      for i_idx in p_object_type_tab.first .. p_object_type_tab.last
      loop
        add(p_object_type_tab(i_idx), p_exclude_name_expr);
      end loop;
    end add;
  begin
    -- no dropped tables
    add(oracle_tools.t_text_tab('TABLE', 'INDEX', 'TRIGGER', 'OBJECT_GRANT'), 'BIN$%');

    -- no AQ indexes/views
    add(oracle_tools.t_text_tab('INDEX', 'VIEW', 'OBJECT_GRANT'), 'AQ$%');

    -- no Flashback archive tables/indexes
    add(oracle_tools.t_text_tab('TABLE', 'INDEX'), 'SYS\_FBA\_%');

    -- no system generated indexes
    add('INDEX', 'SYS\_C%');

    -- no generated types by declaring pl/sql table types in package specifications
    add(oracle_tools.t_text_tab('SYNONYM', 'TYPE_SPEC', 'TYPE_BODY', 'OBJECT_GRANT'), 'SYS\_PLSQL\_%');

    -- see http://orasql.org/2012/04/28/a-funny-fact-about-collect/
    add(oracle_tools.t_text_tab('SYNONYM', 'TYPE_SPEC', 'TYPE_BODY', 'OBJECT_GRANT'), 'SYSTP%');

    -- no datapump tables
    add(oracle_tools.t_text_tab('TABLE', 'OBJECT_GRANT'), 'SYS\_SQL\_FILE\_SCHEMA%');
    add(oracle_tools.t_text_tab('TABLE', 'OBJECT_GRANT'), user || '\_DDL');
    add(oracle_tools.t_text_tab('TABLE', 'OBJECT_GRANT'), user || '\_DML');
    -- no Oracle generated datapump tables
    add(oracle_tools.t_text_tab('TABLE', 'OBJECT_GRANT'), 'SYS\_EXPORT\_FULL\_%');

    -- no Flyway stuff and other Oracle things
    for i_idx in c_object_to_ignore_tab.first .. c_object_to_ignore_tab.last
    loop
      add(oracle_tools.t_text_tab('TABLE', 'OBJECT_GRANT', 'INDEX', 'CONSTRAINT', 'REF_CONSTRAINT'), c_object_to_ignore_tab(i_idx) || '%');
    end loop;

    -- no identity column sequences
    add(oracle_tools.t_text_tab('SEQUENCE', 'OBJECT_GRANT'), 'ISEQ$$%');
  end i_object_exclude_name_expr_tab;

  procedure get_transform_param_tab
  ( p_transform_param_list in varchar2
  , p_transform_param_tab out nocopy t_transform_param_tab
  )
  is
    l_line_tab dbms_sql.varchar2a;
    "+-" boolean := null;

    procedure set_transform_param
    ( p_transform_param in varchar2
    , p_value in boolean
    )
    is
    begin
      if p_transform_param is not null and p_transform_param_tab.exists(p_transform_param)
      then
        p_transform_param_tab(p_transform_param) := p_value;
      end if;
    end set_transform_param;
  begin
    p_transform_param_tab := c_transform_param_tab;

    if p_transform_param_list is not null
    then
      oracle_tools.pkg_str_util.split(p_str => p_transform_param_list, p_delimiter => ',', p_str_tab => l_line_tab);
      if l_line_tab.count > 0
      then
        for i_idx in l_line_tab.first .. l_line_tab.last
        loop
          l_line_tab(i_idx) := upper(trim(l_line_tab(i_idx)));
          
          continue when l_line_tab(i_idx) is null;

          if "+-" is null
          then
            "+-" := substr(l_line_tab(i_idx), 1, 1) in ('+', '-');
            if "+-"
            then
              -- Apply the default c_transform_param_list first.
              -- There will be no recursion since the default list does not contain +/-.
              get_transform_param_tab
              ( p_transform_param_list => c_transform_param_list
              , p_transform_param_tab => p_transform_param_tab
              );
            end if;
          elsif "+-" != (substr(l_line_tab(i_idx), 1, 1) in ('+', '-'))
          then
            -- either all entries start with a +/- or none
            oracle_tools.pkg_ddl_error.raise_error
            ( p_error_number => oracle_tools.pkg_ddl_error.c_transform_parameter_wrong
            , p_error_message => 'Either every transform parameter starts with a +/- or none'
            , p_context_info => p_transform_param_list
            , p_context_label => 'transform parameter list'
            );
          end if;

          case substr(l_line_tab(i_idx), 1, 1)
            when '+'
            then set_transform_param(ltrim(substr(l_line_tab(i_idx), 2)), true);
            when '-'
            then set_transform_param(ltrim(substr(l_line_tab(i_idx), 2)), false);
            else set_transform_param(l_line_tab(i_idx), true);
          end case;
        end loop;
      end if;
    end if;
  end get_transform_param_tab;

  procedure dbms_metadata$set_transform_param
  ( transform_handle   in number
  , name               in varchar2
  , value              in varchar2
  , object_type        in varchar2 default null
  )
  is
  begin
$if oracle_tools.pkg_ddl_util.c_debugging_dbms_metadata $then
    dbug.print
    ( dbug."info"
    , 'dbms_metadata.set_transform_param(%s, %s, %s, %s) (1)'
    , transform_handle
    , name
    , value
    , object_type
    );
$end      
    dbms_metadata.set_transform_param
    ( transform_handle
    , name
    , value
    , object_type
    );
  exception
    when e_invalid_transform_param
    then
$if oracle_tools.pkg_ddl_util.c_debugging_dbms_metadata $then
      dbug.on_error;
$end
      null;
  end dbms_metadata$set_transform_param;

  procedure dbms_metadata$set_transform_param
  ( transform_handle   in number
  , name               in varchar2
  , value              in boolean default true
  , object_type        in varchar2 default null
  )
  is
  begin
$if oracle_tools.pkg_ddl_util.c_debugging_dbms_metadata $then
    dbug.print
    ( dbug."info"
    , 'dbms_metadata.set_transform_param(%s, %s, %s, %s) (2)'
    , transform_handle
    , name
    , dbug.cast_to_varchar2(value)
    , object_type
    );
$end      
    dbms_metadata.set_transform_param
    ( transform_handle
    , name
    , value
    , object_type
    );
  exception
    when e_invalid_transform_param
    then
$if oracle_tools.pkg_ddl_util.c_debugging_dbms_metadata $then
      dbug.on_error;
$end
      null;
  end dbms_metadata$set_transform_param;

  procedure dbms_metadata$set_transform_param
  ( transform_handle   in number
  , name               in varchar2
  , value              in number
  , object_type        in varchar2 default null
  )
  is
  begin
$if oracle_tools.pkg_ddl_util.c_debugging_dbms_metadata $then
    dbug.print
    ( dbug."info"
    , 'dbms_metadata.set_transform_param(%s, %s, %s, %s) (3)'
    , transform_handle
    , name
    , value
    , object_type
    );
$end      
    dbms_metadata.set_transform_param
    ( transform_handle
    , name
    , value
    , object_type
    );
  exception
    when e_invalid_transform_param
    then
$if oracle_tools.pkg_ddl_util.c_debugging_dbms_metadata $then
      dbug.on_error;
$end
      null;
  end dbms_metadata$set_transform_param;
    
  procedure dbms_metadata$set_filter(handle in number, name in varchar2, value in varchar2)
  is
  begin
$if oracle_tools.pkg_ddl_util.c_debugging_dbms_metadata $then
    dbug.print(dbug."info", 'dbms_metadata.set_filter(%s, %s, %s)', handle, name, value);
$end
    dbms_metadata.set_filter(handle, name, value);
  end dbms_metadata$set_filter;

  procedure dbms_metadata$set_filter(handle in number, name in varchar2, value in boolean default true)
  is
  begin
$if oracle_tools.pkg_ddl_util.c_debugging_dbms_metadata $then
    dbug.print(dbug."info", 'dbms_metadata.set_filter(%s, %s, %s)', handle, name, dbug.cast_to_varchar2(value));
$end
    dbms_metadata.set_filter(handle, name, value);
  end dbms_metadata$set_filter;

  procedure dbms_metadata$set_filter(handle in number, name in varchar2, value in number)
  is
  begin
$if oracle_tools.pkg_ddl_util.c_debugging_dbms_metadata $then
    dbug.print(dbug."info", 'dbms_metadata.set_filter(%s, %s, %s)', handle, name, value);
$end
    dbms_metadata.set_filter(handle, name, value);
  end dbms_metadata$set_filter;

  procedure md_set_transform_param
  ( p_transform_handle in number default dbms_metadata.session_transform
  , p_object_type_tab in oracle_tools.t_text_tab default oracle_tools.t_text_tab('INDEX', 'TABLE', 'CLUSTER', 'CONSTRAINT', 'VIEW', 'TYPE_SPEC')
  , p_use_object_type_param in boolean default false
  , p_transform_param_tab in t_transform_param_tab default c_transform_param_tab
  )
  is
    procedure set_transform_param
    ( transform_handle   in number
    , name               in varchar2
    , object_type        in varchar2 default null
    )
    is
    begin
      dbms_metadata$set_transform_param
      ( transform_handle 
      , name
      , p_transform_param_tab(name)
      , object_type
      );
    end set_transform_param;
  begin
$if oracle_tools.pkg_ddl_util.c_debugging_dbms_metadata $then
    dbug.enter($$PLSQL_UNIT_OWNER||'.'||$$PLSQL_UNIT||'.MD_SET_TRANSFORM_PARAM');
    dbug.print(dbug."input", 'p_use_object_type_param: %s', p_use_object_type_param);
$end

    set_transform_param(p_transform_handle, 'PRETTY');
    -- this one is fixed
    dbms_metadata$set_transform_param(p_transform_handle, 'SQLTERMINATOR', c_use_sqlterminator);

    for i_idx in p_object_type_tab.first .. p_object_type_tab.last
    loop
$if oracle_tools.pkg_ddl_util.c_debugging_dbms_metadata $then
      dbug.print(dbug."info", 'p_object_type_tab(%s): %s', i_idx, p_object_type_tab(i_idx));
$end
      if p_object_type_tab(i_idx) in ('TABLE', 'INDEX', 'CLUSTER', 'CONSTRAINT', 'ROLLBACK_SEGMENT', 'TABLESPACE')
      then
        set_transform_param(p_transform_handle, 'SEGMENT_ATTRIBUTES'  , case when p_use_object_type_param then p_object_type_tab(i_idx) end);
        set_transform_param(p_transform_handle, 'STORAGE'             , case when p_use_object_type_param then p_object_type_tab(i_idx) end);
        set_transform_param(p_transform_handle, 'TABLESPACE'          , case when p_use_object_type_param then p_object_type_tab(i_idx) end);
      end if;
      -- GJP 2022-12-15 Maybe setting CONSTRAINTS before CONSTRAINTS_AS_ALTER may generate this command:
      -- ALTER TABLE "BC_BO"."BC_CONSUMPTION_PREDICTIONS" MODIFY ("GRD_ID" CONSTRAINT "NNC_CPN_GRD_ID" NOT NULL ENABLE)
      if p_object_type_tab(i_idx) in ('TABLE', 'VIEW')
      then
        set_transform_param(p_transform_handle, 'CONSTRAINTS'         , case when p_use_object_type_param then p_object_type_tab(i_idx) end);
      end if;
      if p_object_type_tab(i_idx) = 'TABLE'
      then
        set_transform_param(p_transform_handle, 'REF_CONSTRAINTS'     , case when p_use_object_type_param then p_object_type_tab(i_idx) end);
        set_transform_param(p_transform_handle, 'CONSTRAINTS_AS_ALTER', case when p_use_object_type_param then p_object_type_tab(i_idx) end);
      end if;
      if p_object_type_tab(i_idx) = 'VIEW'
      then
        -- GPA 2016-12-01 The FORCE keyword may be removed by the generate_ddl.pl script, depending on an option.
        set_transform_param(p_transform_handle, 'FORCE'               , case when p_use_object_type_param then p_object_type_tab(i_idx) end);
      end if;
      if p_object_type_tab(i_idx) = 'TYPE_SPEC'
      then
        set_transform_param(p_transform_handle, 'OID'                 , case when p_use_object_type_param then p_object_type_tab(i_idx) end);
      end if;
    end loop;

$if oracle_tools.pkg_ddl_util.c_debugging_dbms_metadata $then
    dbug.leave;
$end
  end md_set_transform_param;

  procedure md_set_filter
  ( p_object_type in varchar2
  , p_object_schema in varchar2
  , p_object_name_tab in oracle_tools.t_text_tab
  , p_base_object_schema in varchar2
  , p_base_object_name_tab in oracle_tools.t_text_tab
  , p_handle in number
  )
  is
    function in_list_expr(p_object_name_tab in oracle_tools.t_text_tab)
    return varchar2
    is
      l_in_list varchar2(32767 char) := 'IN (';
      l_object_name user_objects.object_name%type := null;
    begin
      if p_object_name_tab is not null and p_object_name_tab.count > 0
      then
        for i_idx in p_object_name_tab.first .. p_object_name_tab.last
        loop
          -- trim tab, linefeed, carriage return and space from the input
          l_object_name := trim(chr(9) from trim(chr(10) from trim(chr(13) from trim(' ' from p_object_name_tab(i_idx)))));
          -- GJP 2021-08-27 Do not check for valid SQL names.
          l_in_list := l_in_list || '''' || l_object_name || ''',';
        end loop;
        l_in_list := rtrim(l_in_list, ',');
      end if;
      l_in_list := l_in_list || ')';

      return l_in_list;
    end in_list_expr;

    procedure set_exclude_name_expr(p_object_type in t_metadata_object_type, p_name in varchar2)
    is
      l_exclude_name_expr_tab oracle_tools.t_text_tab;
    begin
      get_exclude_name_expr_tab(p_object_type => p_object_type, p_exclude_name_expr_tab => l_exclude_name_expr_tab);
      if l_exclude_name_expr_tab.count > 0
      then
        for i_idx in l_exclude_name_expr_tab.first .. l_exclude_name_expr_tab.last
        loop
          dbms_metadata$set_filter(handle => p_handle, name => p_name, value => q'[LIKE ']' || l_exclude_name_expr_tab(i_idx) || q'[' ESCAPE '\']');
        end loop;
      end if;
    end set_exclude_name_expr;
  begin
$if oracle_tools.pkg_ddl_util.c_debugging_dbms_metadata $then
    dbug.enter(g_package_prefix || 'MD_SET_FILTER');
    dbug.print(dbug."input"
               ,'p_object_type: %s; p_object_schema: %s; p_base_object_schema: %s'
               ,p_object_type
               ,p_object_schema
               ,p_base_object_schema);
$end

    if p_object_type = 'SCHEMA_EXPORT'
    then
      -- Use filters to specify the schema. See SCHEMA_EXPORT_OBJECTS for a complete overview.
      dbms_metadata$set_filter(handle => p_handle, name => 'SCHEMA', value => p_object_schema);
      -- dbms_metadata$set_filter(handle => p_handle, name => 'INCLUDE_USER', value => true);
      dbms_metadata$set_filter
      ( handle => p_handle
      , name =>  'EXCLUDE_PATH_EXPR'
      , value => 'in ('   ||
                 '''AUDIT_OBJ''          ,' ||
                  /*
                  -- GJP 2016-07-12
                  --
                  -- Skip DDL like this:
                  --
                  -- ALTER PACKAGE "<owner>"."<package>"
                  --  COMPILE SPECIFICATION
                  --    PLSQL_OPTIMIZE_LEVEL=  2
                  --    PLSQL_CODE_TYPE=  INTERPRETED
                  --    PLSQL_DEBUG=  FALSE    PLSCOPE_SETTINGS=  'IDENTIFIERS:ALL'
                  --
                  -- REUSE SETTINGS TIMESTAMP '2016-07-12 09:53:26'
                  --
                  */
                 '''ALTER_FUNCTION''     ,' ||
                 '''ALTER_PACKAGE_SPEC'' ,' ||
                 '''ALTER_PROCEDURE''    ,' ||
                 '''DEFAULT_ROLE''       ,' ||
$if not(oracle_tools.pkg_ddl_util.c_get_db_link_ddl) $then
                 '''DB_LINK''            ,' ||
$end                 
                 '''ON_USER_GRANT''      ,' ||
                 '''PASSWORD_HISTORY''   ,' ||
                 /*
                 -- GJP 2016-07-12 To prevent the following error we must not exclude PROCACT_SCHEMA:
                 --
                 -- ORA-31642: the following SQL statement fails:
                 -- BEGIN "SYS"."DBMS_SCHED_EXPORT_CALLOUTS".SCHEMA_CALLOUT(:1,1,1,'11.02.00.00.00'); END;
                 */
                 --'''PROCACT_SCHEMA''     ,' ||
                 '''ROLE_GRANT''         ,' ||
                 '''STATISTICS''         ,' ||
                 '''SYSTEM_GRANT''       ,' || -- a bit strange
                 '''TABLESPACE_QUOTA''   ,' ||
                 '''TABLE_DATA''         ,' ||
                 '''USER''               ,' ||
                 'NULL                    ' || -- just for the comma on the line before
                 ')'
      );
    else
      if nvl(is_dependent_object_type(p_object_type => p_object_type), 1) = 1
      then
        if p_object_type in ('INDEX', 'TRIGGER')
        then
          if is_dependent_object_type(p_object_type => p_object_type) is null
          then
            null; -- OK
          else
            raise program_error;
          end if;

          dbms_metadata$set_filter(handle => p_handle, name => 'SYSTEM_GENERATED', value => false);
          dbms_metadata$set_filter(handle => p_handle, name => 'SCHEMA', value => p_object_schema);

          if p_object_name_tab is not null and
             p_object_name_tab.count between 1 and c_max_object_name_tab_count
          then
            dbms_metadata$set_filter
            ( handle => p_handle
            , name => 'NAME_EXPR'
            , value => in_list_expr(p_object_name_tab)
            );
          end if;

          if p_base_object_name_tab is not null and
             p_base_object_name_tab.count between 1 and c_max_object_name_tab_count
          then
            dbms_metadata$set_filter
            ( handle => p_handle
            , name => 'BASE_OBJECT_NAME_EXPR'
            , value => in_list_expr(p_base_object_name_tab)
            );
          end if;

          dbms_metadata$set_filter
          ( handle => p_handle
          , name => 'EXCLUDE_BASE_OBJECT_NAME_EXPR'
          , value => in_list_expr(c_object_to_ignore_tab)
          );
        else
          if is_dependent_object_type(p_object_type => p_object_type) = 1
          then
            null; -- OK
          else
            raise program_error;
          end if;

          dbms_metadata$set_filter(handle => p_handle, name => 'BASE_OBJECT_SCHEMA', value => p_base_object_schema);

          if p_base_object_name_tab is not null and
             p_base_object_name_tab.count between 1 and c_max_object_name_tab_count
          then
            dbms_metadata$set_filter
            ( handle => p_handle
            , name => 'BASE_OBJECT_NAME_EXPR'
            , value => in_list_expr(p_base_object_name_tab)
            );
          end if;

          dbms_metadata$set_filter
          ( handle => p_handle
          , name => 'EXCLUDE_BASE_OBJECT_NAME_EXPR'
          , value => in_list_expr(c_object_to_ignore_tab)
          );

          if p_object_type = 'OBJECT_GRANT'
          then
            set_exclude_name_expr(p_object_type => 'TYPE_SPEC', p_name => 'EXCLUDE_BASE_OBJECT_NAME_EXPR');
          end if;
        end if;
      elsif p_object_type = 'SYNONYM'
      then
        dbms_metadata$set_filter(handle => p_handle, name => 'SCHEMA', value => p_object_schema);

        -- Voor synoniemen moet gelden:
        -- 1a) lange naam van synonym moet gelijk zijn aan korte naam EN
        -- 1b) schema van synoniem is niet PUBLIC of object waar naar verwezen wordt zit in base object schema
        if p_object_schema != 'PUBLIC'
        then
          -- simple custom filter: always allowed
          dbms_metadata$set_filter
          ( handle => p_handle
          , name => 'CUSTOM_FILTER'
          , value => '/* 1a */ KU$.SYN_LONG_NAME = KU$.SCHEMA_OBJ.NAME'
          );
        else
          -- simple custom filter: always allowed
          dbms_metadata$set_filter
          ( handle => p_handle
          , name => 'CUSTOM_FILTER'
          , value => q'[/* 1a */ KU$.SYN_LONG_NAME = KU$.SCHEMA_OBJ.NAME AND /* 1b */ KU$.OWNER_NAME = ']' ||
                     oracle_tools.data_api_pkg.dbms_assert$schema_name(p_base_object_schema, 'schema') || q'[']'
          );
        end if;

        if p_object_name_tab is not null and
           p_object_name_tab.count between 1 and c_max_object_name_tab_count
        then
          dbms_metadata$set_filter
          ( handle => p_handle
          , name => 'NAME_EXPR'
          , value => in_list_expr(p_object_name_tab)
          );
        end if;
      else
        if p_object_schema != 'DBA'
        then
          dbms_metadata$set_filter(handle => p_handle, name => 'SCHEMA', value => p_object_schema);
        end if;

        if p_object_type not in ('DEFAULT_ROLE', 'FGA_POLICY', 'ROLE_GRANT')
        then
          if p_object_name_tab is not null and
             p_object_name_tab.count between 1 and c_max_object_name_tab_count
          then
            dbms_metadata$set_filter
            ( handle => p_handle
            , name => 'NAME_EXPR'
            , value => in_list_expr(p_object_name_tab)
            );
          end if;

          dbms_metadata$set_filter
          ( handle => p_handle
          , name => 'EXCLUDE_NAME_EXPR'
          , value => in_list_expr(c_object_to_ignore_tab)
          );
        end if;

        if p_object_type = 'TABLE'
        then
          dbms_metadata$set_filter(handle => p_handle, name => 'SECONDARY', value => false);
        end if;
      end if;

      if p_object_type <> 'OBJECT_GRANT'
      then
        set_exclude_name_expr(p_object_type => p_object_type, p_name => 'EXCLUDE_NAME_EXPR');
      end if;
    end if; -- if p_object_type = 'SCHEMA_EXPORT'

$if oracle_tools.pkg_ddl_util.c_debugging_dbms_metadata $then
    dbug.leave;
  exception
    when others
    then
      dbug.leave_on_error;
      raise;
$end
  end md_set_filter;

  procedure md_open
  ( p_object_type in t_metadata_object_type
  , p_object_schema in varchar2
  , p_object_name_tab in oracle_tools.t_text_tab
  , p_base_object_schema in varchar2
  , p_base_object_name_tab in oracle_tools.t_text_tab
  , p_transform_param_tab in t_transform_param_tab
  , p_handle out number
  )
  is
    l_found pls_integer := null;
  begin
$if oracle_tools.pkg_ddl_util.c_debugging_dbms_metadata $then
    dbug.enter(g_package_prefix || 'MD_OPEN');
    dbug.print(dbug."input"
               ,'p_object_type: %s; p_object_schema: %s; p_base_object_schema: %s'
               ,p_object_type
               ,p_object_schema
               ,p_base_object_schema);
$end

    /*

    1. Open the object type using the DBMS_METADATA.OPEN() procedure.
       Object types that you can open include, but are not limited to, tables, indexes, types, packages, and synonyms.
    2. Specify which objects to retrieve using the DBMS_METADATA.SET_FILTER() procedure.
    3. Specify what transforms are to be invoked on the output.
       Use the DBMS_METADATA.ADD_TRANSFORM() procedure to add a transform. The last transform added must be the "DDL" transform.
    4. Use the DBMS_METADATA.SET_TRANSFORM_PARAM() procedure to customize the DDL.
       For example, you could use it to exclude storage clauses on table definitions. Transform parameters are specific to the object type chosen.
    5. Fetch the DDL using the DBMS_METADATA.FETCH_DDL() procedure.
       An example of the DDL processing is re-creating objects in another schema or database.
    6. If the result of this operation is NULL, then call the DBMS_METADATA.CLOSE() procedure.

    */
    case is_dependent_object_type(p_object_type => p_object_type)
      when 1
      then
        if p_base_object_schema is not null and p_object_schema is null
        then
          null; -- OK
        else
          raise_application_error
          ( oracle_tools.pkg_ddl_error.c_invalid_parameters
          , 'p_object_schema ('
            ||p_object_schema
            ||') should be empty, '
            ||'base object schema ('
            ||p_base_object_schema
            ||') should not be empty.'
          );
        end if;

      when 0
      then
        if p_object_schema = 'PUBLIC' and
           p_object_type = 'SYNONYM'
        then
          if p_base_object_schema is not null
          then
            null; -- OK
          else
            raise_application_error
            ( oracle_tools.pkg_ddl_error.c_invalid_parameters
            , 'Base object schema ('
              ||p_base_object_schema
              ||') should not be empty.'
            );
          end if;
        elsif p_object_schema is not null and p_base_object_schema is null
        then
          null; -- ok
        else
          raise_application_error
          ( oracle_tools.pkg_ddl_error.c_invalid_parameters
          , 'Object schema ('
            ||p_object_schema
            ||') should not be empty, '
            ||' base object schema ('
            ||p_base_object_schema
            ||') should be empty.'
          );
        end if;

      else
        -- INDEX, TRIGGER
        if p_object_schema is not null and p_base_object_schema is null
        then
          null; -- OK
        else
          raise_application_error
          ( oracle_tools.pkg_ddl_error.c_invalid_parameters
          , 'Object schema ('
            ||p_object_schema
            ||') should not be empty, '
            ||'p_base_object_schema ('
            ||p_base_object_schema
            ||') should be empty.'
          );
        end if;
    end case;

    if nvl(p_object_schema, p_base_object_schema) in (user, 'PUBLIC')
    then
      null; -- we have all the privileges to lookup objects
    elsif user <> 'SYS' -- SYS has access to all
    then
      -- GPA 2017-03-09 #141388347 In order too see grants from another grantor you do not need the role SELECT_CATALOG_ROLE.
      if p_object_type <> 'OBJECT_GRANT'
      then
        -- GPA 2016-12-12 #135951281 The increment DDL generator does not work when you use a public database link.
        -- Must have session role SELECT_CATALOG_ROLE to lookup objects.
        begin
          select  1
          into    l_found
          from    session_roles
          where   session_roles.role = 'SELECT_CATALOG_ROLE';
        exception
          when no_data_found
          then
            raise_application_error
            ( oracle_tools.pkg_ddl_error.c_missing_session_role
            , 'User "' || 
              user || 
              '" must have session role SELECT_CATALOG_ROLE to view objects of type "' || p_object_type || '" for "' ||
              nvl(p_object_schema, p_base_object_schema) ||
              '".'
            );
        end;
      end if;

      if p_object_type like '%\_BODY' escape '\'
      then
        -- must have CREATE ANY PROCEDURE privilege to lookup bodies
        begin
          select  1
          into    l_found
          from    session_privs
          where   session_privs.privilege = 'CREATE ANY PROCEDURE';
        exception
          when no_data_found
          then
            raise_application_error
            ( oracle_tools.pkg_ddl_error.c_missing_session_privilege
            , 'User "' || 
              user || 
              '" must have session privilege CREATE ANY PROCEDURE to view package or type bodies for "' ||
              nvl(p_object_schema, p_base_object_schema) ||
              '".'
            );
        end;
      end if;
    end if;

    p_handle := dbms_metadata.open(object_type => p_object_type);

    -- GPA 2016-11-24  set_remap_param first before converting to ddl
    --
    -- Otherwise you may get:
    --
    -- ORA-06502: PL/SQL: numeric or value error
    -- LPX-00210: expected '<' instead of '\'

    if p_object_type = 'SCHEMA_EXPORT'
    then
      md_set_transform_param
      ( p_transform_handle => dbms_metadata.add_transform(handle => p_handle, name => 'DDL')
      , p_use_object_type_param => true
      , p_transform_param_tab => p_transform_param_tab
      );
    else
      md_set_transform_param
      ( p_transform_handle => dbms_metadata.add_transform(handle => p_handle, name => 'DDL')
      , p_object_type_tab => oracle_tools.t_text_tab(p_object_type)
      , p_transform_param_tab => p_transform_param_tab
      );
    end if;
    md_set_filter
    ( p_object_type => p_object_type
    , p_object_schema => p_object_schema
    , p_object_name_tab => p_object_name_tab
    , p_base_object_schema => p_base_object_schema
    , p_base_object_name_tab => p_base_object_name_tab
    , p_handle => p_handle
    );

    dbms_metadata.set_parse_item(handle => p_handle, name => 'VERB');
    dbms_metadata.set_parse_item(handle => p_handle, name => 'NAME');
    dbms_metadata.set_parse_item(handle => p_handle, name => 'OBJECT_TYPE');
    dbms_metadata.set_parse_item(handle => p_handle, name => 'SCHEMA');
    dbms_metadata.set_parse_item(handle => p_handle, name => 'BASE_OBJECT_NAME');
    dbms_metadata.set_parse_item(handle => p_handle, name => 'BASE_OBJECT_TYPE');
    dbms_metadata.set_parse_item(handle => p_handle, name => 'BASE_OBJECT_SCHEMA');
    dbms_metadata.set_parse_item(handle => p_handle, name => 'GRANTEE');

    dbms_metadata.set_count
    ( handle => p_handle
    , value => case
                 when p_object_type in ('PROCEDURE', 'FUNCTION', 'VIEW', 'PACKAGE_SPEC', 'PACKAGE_BODY', 'TYPE_SPEC', 'TYPE_BODY', 'MATERIALIZED_VIEW')
                 then c_dbms_metadata_set_count_large_ddl
                 else c_dbms_metadata_set_count_small_ddl
               end);

$if oracle_tools.pkg_ddl_util.c_debugging_dbms_metadata $then
    dbug.leave;
  exception
    when others then
      dbug.leave_on_error;
      oracle_tools.pkg_ddl_error.reraise_error
      ( p_object_type||';'||p_object_schema||';'||p_base_object_schema
      );
$end
  end md_open;

  procedure md_fetch_ddl
  ( p_handle in number
  , p_split_grant_statement in boolean
  )
  is
    l_line_tab dbms_sql.varchar2a;
    l_statement varchar2(4000 char);
    l_privileges varchar2(4000 char);
    l_pos1 pls_integer;
    l_pos2 pls_integer;
    l_ddl_tab_last pls_integer;
  begin
$if oracle_tools.pkg_ddl_util.c_debugging_dbms_metadata $then
    dbug.enter(g_package_prefix || 'MD_FETCH_DDL');
$end

    begin
      g_ddl_tab := dbms_metadata.fetch_ddl(handle => p_handle);

      if g_ddl_tab is not null and g_ddl_tab.count > 0
      then
        -- GRANT DELETE, INSERT, SELECT, UPDATE, REFERENCES, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ...
        l_ddl_tab_last := g_ddl_tab.last; -- the collection may expand so just store the last entry
$if oracle_tools.pkg_ddl_util.c_debugging_dbms_metadata $then
        dbug.print(dbug."info", 'g_ddl_tab.first: %s; l_ddl_tab_last: %s', g_ddl_tab.first, l_ddl_tab_last);
$end
        for i_ku$ddls_idx in g_ddl_tab.first .. l_ddl_tab_last
        loop
          l_statement := oracle_tools.pkg_str_util.dbms_lob_substr(p_clob => g_ddl_tab(i_ku$ddls_idx).ddlText, p_offset => 1, p_amount => 4000);
$if oracle_tools.pkg_ddl_util.c_debugging_dbms_metadata $then
          dbug.print
          ( dbug."info"
          , 'i_ku$ddls_idx: %s; length(ltrim(l_statement)): %s; ltrim(l_statement): %s'
          , i_ku$ddls_idx
          , length(ltrim(l_statement))
          , ltrim(l_statement)
          );
$end
          if p_split_grant_statement and ltrim(l_statement) like 'GRANT %, % ON "%'
          then
            l_pos1 := instr(l_statement, 'GRANT ') + length('GRANT ');
            l_pos2 := instr(l_statement, ' ON "');
            l_privileges := substr(l_statement, l_pos1, l_pos2 - l_pos1);

$if oracle_tools.pkg_ddl_util.c_debugging_dbms_metadata $then
            dbug.print(dbug."info", 'l_privileges: %s', l_privileges);
$end

            oracle_tools.pkg_str_util.split
            ( p_str => l_privileges
            , p_delimiter => ', '
            , p_str_tab => l_line_tab
            );
            if l_line_tab.count > 0
            then
              -- free and nullify the ddlText so a copy will not create a new temporary on the fly
              dbms_lob.freetemporary(g_ddl_tab(i_ku$ddls_idx).ddlText);
              g_ddl_tab(i_ku$ddls_idx).ddlText := null;

              for i_idx in l_line_tab.first .. l_line_tab.last
              loop
$if oracle_tools.pkg_ddl_util.c_debugging_dbms_metadata $then
                dbug.print
                ( dbug."info"
                , 'replace(l_statement, l_privileges, l_line_tab(%s)): %s'
                , i_idx
                , replace(l_statement, l_privileges, l_line_tab(i_idx))
                );
$end
                if i_idx = l_line_tab.first
                then
                  -- replace i_ku$ddls_idx
                  dbms_lob.createtemporary(g_ddl_tab(i_ku$ddls_idx).ddlText, true);
                  oracle_tools.pkg_str_util.append_text
                  ( pi_buffer => replace(l_statement, l_privileges, l_line_tab(i_idx))
                  , pio_clob => g_ddl_tab(i_ku$ddls_idx).ddlText
                  );
                else
                  -- extend the table
                  g_ddl_tab.extend(1);
                  -- copy everything (including the null ddlText)
                  g_ddl_tab(g_ddl_tab.last) := g_ddl_tab(i_ku$ddls_idx);
                  -- create a new clob
                  dbms_lob.createtemporary(g_ddl_tab(g_ddl_tab.last).ddlText, true);
                  oracle_tools.pkg_str_util.append_text
                  ( pi_buffer => replace(l_statement, l_privileges, l_line_tab(i_idx))
                  , pio_clob => g_ddl_tab(g_ddl_tab.last).ddlText
                  );
                end if;
              end loop;
            end if;
          end if;
        end loop;
      end if;

    exception
      when e_job_is_not_attached
      then
$if oracle_tools.pkg_ddl_util.c_debugging_dbms_metadata $then
        dbug.on_error;
$end
        g_ddl_tab := null;
    end;

$if oracle_tools.pkg_ddl_util.c_debugging_dbms_metadata $then
    dbug.print(dbug."output", 'g_ddl_tab.count: %s', case when g_ddl_tab is not null then g_ddl_tab.count end);
    dbug.leave;
  exception
    when others
    then
      dbug.leave_on_error;
      raise;
$end
  end md_fetch_ddl;

  procedure parse_object
  ( p_schema_object_filter in oracle_tools.t_schema_object_filter
  , p_constraint_lookup_tab in t_constraint_lookup_tab
  , p_object_lookup_tab in out nocopy t_object_lookup_tab
  , p_ku$_ddl in out nocopy sys.ku$_ddl
  , p_object_key out nocopy varchar2 -- error if null
  )
  is
    l_verb varchar2(4000 char) := null;
    l_object_name t_object_name := null;
    l_object_type varchar2(4000 char) := null;
    l_object_schema varchar2(4000 char) := null;
    l_base_object_name t_object_name := null;
    l_base_object_type varchar2(4000 char) := null;
    l_base_object_schema varchar2(4000 char) := null;
    l_column_name varchar2(4000 char) := null;
    l_grantee varchar2(4000 char) := null;
    l_privilege varchar2(4000 char) := null;
    l_grantable varchar2(4000 char) := null;
    l_ddl_text varchar2(32767 char) := null;
    l_exclude_name_expr_tab oracle_tools.t_text_tab;
    l_schema_object oracle_tools.t_schema_object;

    procedure cleanup
    is
    begin
      if p_ku$_ddl.ddlText is not null
      then
        dbms_lob.freetemporary(p_ku$_ddl.ddlText);
        p_ku$_ddl.ddlText := null;
      end if;
    end cleanup;
  begin
$if oracle_tools.pkg_ddl_util.c_debugging_parse_ddl $then
    dbug.enter(g_package_prefix || 'PARSE_OBJECT');
$end

    p_object_key := null;

    parse_ddl
    ( p_ku$_ddl
    , p_schema_object_filter.schema()
    , p_object_lookup_tab
    , p_constraint_lookup_tab
    , l_verb
    , l_object_name
    , l_object_type
    , l_object_schema
    , l_base_object_name
    , l_base_object_type
    , l_base_object_schema
    , l_column_name
    , l_grantee
    , l_privilege
    , l_grantable
    );

    if l_verb is null and
       ( l_object_name is null and l_object_type is null and l_object_schema is null ) and
       ( l_base_object_name is null and l_base_object_type is null and l_base_object_schema is null )
    then
      cleanup;
    else
      l_object_type := oracle_tools.t_schema_object.dict2metadata_object_type(l_object_type);
      l_base_object_type := oracle_tools.t_schema_object.dict2metadata_object_type(l_base_object_type);

      l_schema_object :=
        oracle_tools.t_schema_object.create_schema_object
        ( p_object_schema => l_object_schema
        , p_object_type => l_object_type
        , p_object_name => l_object_name
        , p_base_object_schema => l_base_object_schema
        , p_base_object_type => l_base_object_type
        , p_base_object_name => l_base_object_name
        , p_column_name => l_column_name
        , p_grantee => l_grantee
        , p_privilege => l_privilege
        , p_grantable => l_grantable
        );

      -- check the object type (base object set if necessary and so on)
      l_schema_object.chk(p_schema_object_filter.schema());

      p_object_key := l_schema_object.id();

      begin
        if not(p_object_lookup_tab(p_object_key).ready)
        then
          p_object_lookup_tab(p_object_key).schema_ddl.add_ddl
          ( p_verb => l_verb
          , p_text => p_ku$_ddl.ddlText
          );

          begin
            p_object_lookup_tab(p_object_key).schema_ddl.chk(p_schema_object_filter.schema());
          exception
            when others
            then
$if oracle_tools.pkg_ddl_util.c_debugging_parse_ddl $then
              p_object_lookup_tab(p_object_key).schema_ddl.print();
$end            
              raise_application_error
              ( oracle_tools.pkg_ddl_error.c_object_not_correct
              , 'Object ' || p_object_lookup_tab(p_object_key).schema_ddl.obj.id() || ' is not correct.'
              , true
              );
          end;

          -- the normal stuff
          p_object_lookup_tab(p_object_key).count := p_object_lookup_tab(p_object_key).count + 1;
        end if; -- if not(p_object_lookup_tab(p_object_key).ready)
      exception
        when no_data_found
        then
          case
            when p_schema_object_filter.matches_schema_object
                 ( p_schema_object_id => p_object_key
                 ) = 0 -- object not but on purpose
            then
              p_object_key := null;

            when l_verb in ('DBMS_JAVA.START_IMPORT', 'DBMS_JAVA.IMPORT_TEXT_CHUNK', 'DBMS_JAVA.IMPORT_RAW_CHUNK', 'DBMS_JAVA.END_IMPORT') or
                 l_object_type in ('PROCACT_SCHEMA', 'PROCACT_SYSTEM', 'JAVA_CLASS')                 
            then
              p_object_key := null;

            -- GPA 2017-02-05 Ignore the old job package DBMS_JOB
            when l_object_type = 'PROCOBJ' and l_verb = 'DBMS_JOB.SUBMIT'
            then
              p_object_key := null;

            else
              -- GJP 2021-08-27 Ignore this only when the DDL is whitespace only.
              if p_ku$_ddl.ddlText is not null
              then
                l_ddl_text := trim(replace(replace(oracle_tools.pkg_str_util.dbms_lob_substr(p_ku$_ddl.ddlText, 32767), chr(10), ' '), chr(13), ' '));
                if l_ddl_text is not null
                then
                  raise_application_error
                  ( oracle_tools.pkg_ddl_error.c_object_not_found
                  , utl_lms.format_message
                    ( 'object "%s" not found in allowed objects; ddl: "%s"'
                    , p_object_key
                    , substr(l_ddl_text, 1, 2000)
                    )
                  );
                end if;
              end if;
          end case;
      end;
    end if; -- if l_verb is not null

    cleanup;

$if oracle_tools.pkg_ddl_util.c_debugging_parse_ddl $then
    dbug.print(dbug."output", 'p_object_key: %s', p_object_key);
    dbug.leave;
$end
  exception
    -- GJP 2021-08-30 Ignore this always.
    when oracle_tools.pkg_ddl_error.e_object_not_correct or
         oracle_tools.pkg_ddl_error.e_object_not_found or
         oracle_tools.pkg_ddl_error.e_could_not_parse or
         -- GJP 2023-01-06 An error occurred for object with object type/schema/name: POST_TABLE_ACTION//
         oracle_tools.pkg_ddl_error.e_object_type_wrong or
         -- ORA-20110: Object name should not be empty. An error occurred for object with object schema info: :MATERIALIZED_VIEW_LOG::::::::
         oracle_tools.pkg_ddl_error.e_object_not_valid
    then
      p_object_key := null;
      cleanup;
$if oracle_tools.pkg_ddl_util.c_debugging_parse_ddl $then
      dbug.leave_on_error;
$end

    when others
    then
      p_object_key := null;
      cleanup;
$if oracle_tools.pkg_ddl_util.c_debugging_parse_ddl $then
      dbug.leave_on_error;
$end
      raise;
  end parse_object;

  procedure md_close
  ( p_handle in out number
  )
  is
  begin
    -- reset to the default
    if p_handle is not null
    then
      dbms_metadata.close(p_handle);
      p_handle := null;
    end if;
  end md_close;

  procedure remove_ddl
  ( p_object_schema in varchar2
  , p_object_type in varchar2
  , p_filter in varchar2
  , p_schema_ddl_tab in out nocopy oracle_tools.t_schema_ddl_tab
  )
  is
    l_idx pls_integer := p_schema_ddl_tab.last;
  begin
$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
    dbug.enter(g_package || '.REMOVE_DDL');
    dbug.print(dbug."input", 'p_object_schema: %s; p_object_type: %s; p_filter: %s; p_schema_ddl_tab.count: %s', p_object_schema, p_object_type, p_filter, p_schema_ddl_tab.count);
$end

    loop
      exit when l_idx is null;

$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
      dbug.print
      ( dbug."info"
      , '[%s] object_schema: %s; object_type: %s; text: %s'
      , l_idx
      , p_schema_ddl_tab(l_idx).obj.object_schema()
      , p_schema_ddl_tab(l_idx).obj.object_type()
      , p_schema_ddl_tab(l_idx).ddl_tab(1).text(1)
      );
$end

      if ( ( p_schema_ddl_tab(l_idx).obj.object_schema() is null and p_object_schema is null ) or
           p_schema_ddl_tab(l_idx).obj.object_schema() = p_object_schema ) and
         p_schema_ddl_tab(l_idx).obj.object_type() = p_object_type and
         p_schema_ddl_tab(l_idx).ddl_tab(1).text(1) like p_filter escape '\'
      then
        for i_idx in l_idx + 1 .. p_schema_ddl_tab.last
        loop
          p_schema_ddl_tab(i_idx - 1) := p_schema_ddl_tab(i_idx);
        end loop;

        l_idx := p_schema_ddl_tab.prior(l_idx);
        p_schema_ddl_tab.delete(p_schema_ddl_tab.last); -- laatste kan weg
      else
        l_idx := p_schema_ddl_tab.prior(l_idx);
      end if;
    end loop;

$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
    dbug.print(dbug."output", 'p_schema_ddl_tab.count: %s', p_schema_ddl_tab.count);
    dbug.leave;
$end
  end remove_ddl;

  procedure remove_public_synonyms(p_schema_ddl_tab in out nocopy oracle_tools.t_schema_ddl_tab) is
  begin
    remove_ddl(p_object_schema => 'PUBLIC'
              ,p_object_type => 'SYNONYM'
              ,p_filter => '% PUBLIC SYNONYM %'
              ,p_schema_ddl_tab => p_schema_ddl_tab);
  end remove_public_synonyms;

  procedure remove_object_grants(p_schema_ddl_tab in out nocopy oracle_tools.t_schema_ddl_tab)
  is
  begin
    remove_ddl(p_object_schema => null
              ,p_object_type => 'OBJECT_GRANT'
              ,p_filter => '%'
              ,p_schema_ddl_tab => p_schema_ddl_tab);
  end remove_object_grants;

  function get_object
  (
    p_owner in varchar2
   ,p_type in varchar2 default null
   ,p_name in varchar2
--   ,p_grantee in varchar2 default null
  ) return t_object is
    function get_object_part(p_object_part in varchar2) return varchar2 is
    begin
      return case when upper(p_object_part) != p_object_part then '"' || p_object_part || '"' else p_object_part end;
    end get_object_part;
  begin
    return get_object_part(p_owner)
           || '.'
           || case when p_type is not null then p_type || '.' end
           || get_object_part(p_name)
           -- || case when p_grantee is not null then '.' || get_object_part(p_grantee) end
           ;
  end get_object;

  procedure add2text
  ( p_str in varchar2
  , p_text_tab in out nocopy oracle_tools.t_text_tab
  )
  is
  begin
    for i_chunk in 1 .. ceil(length(p_str) / 4000)
    loop
      p_text_tab.extend(1);
      p_text_tab(p_text_tab.last) := substr(p_str, 1 + (i_chunk-1) * 4000, 4000);
    end loop;
  end add2text;

  function lines2text
  ( p_line_tab in dbms_sql.varchar2a
  )
  return oracle_tools.t_text_tab
  is
    l_text_tab oracle_tools.t_text_tab := oracle_tools.t_text_tab();
  begin
    for i_idx in p_line_tab.first .. p_line_tab.last
    loop
      add2text(p_line_tab(i_idx) || chr(10), l_text_tab);
    end loop;
    return l_text_tab;
  end lines2text;

  function get_object_no_dependencies_tab
  return t_object_natural_tab
  is
    l_object_no_dependencies_tab t_object_natural_tab; -- initialisation
  begin
    return l_object_no_dependencies_tab;
  end get_object_no_dependencies_tab;

  function modify_ddl_text
  ( p_ddl_text in varchar2
  , p_schema in t_schema_nn
  , p_new_schema in t_schema
  )
  return varchar2
  is
    l_ddl_text varchar2(32767 char) := p_ddl_text;
    l_schema varchar2(32767 char);
    l_new_schema varchar2(32767 char);
    l_match_mode varchar2(2);
    "([^_a-zA-Z0-9$#])" constant varchar2(100) := '([^_a-zA-Z0-9$#])';
  begin
    if p_schema <> p_new_schema and l_ddl_text is not null
    then
      /*
         ON "<owner>"."<table>" must be replaced by ON "EMPTY"."<table>"

         CREATE OR REPLACE EDITIONABLE TRIGGER "EMPTY"."<trigger>"
         BEFORE INSERT OR DELETE OR UPDATE ON "<owner>"."<table>"
         REFERENCING FOR EACH ROW
      */

      -- replace p_schema

      -- A) CASE SENSITIVE, between " and "
      l_ddl_text :=
        replace(l_ddl_text, '"' || p_schema || '"', '"' || p_new_schema || '"');

      -- B) (NOT CASE SENSITIVE)
      --    1) at the start of a line or after a non Oracle identifier character (extra $ and #)
      --    2) before a non Oracle identifier character or the end of a line
      for i_case_idx in 1..2
      loop
        l_schema := case i_case_idx when 1 then lower(p_schema) else p_schema end;
        l_new_schema := case i_case_idx when 1 then lower(p_new_schema) else p_new_schema end;
        l_match_mode := case i_case_idx when 1 then 'c' else 'i' end || -- case sensitive for 1, case insensitive for 2
                        'm'; -- multi line mode

        for i_repl_idx in 1 .. 4
        loop
        l_ddl_text :=
          case i_repl_idx
            when 1 then regexp_replace(l_ddl_text, '^' || l_schema || '$'                                , l_new_schema                , 1, 0, l_match_mode)
            when 2 then regexp_replace(l_ddl_text, "([^_a-zA-Z0-9$#])" || l_schema || '$'                , '\1' || l_new_schema        , 1, 0, l_match_mode)
            when 3 then regexp_replace(l_ddl_text, '^' || l_schema || "([^_a-zA-Z0-9$#])"                , l_new_schema || '\1'        , 1, 0, l_match_mode)
            when 4 then regexp_replace(l_ddl_text, "([^_a-zA-Z0-9$#])" || l_schema || "([^_a-zA-Z0-9$#])", '\1' || l_new_schema || '\2', 1, 0, l_match_mode)
          end;
        end loop;
      end loop;

$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
      if p_ddl_text != l_ddl_text
      then
        dbug.print(dbug."info", 'old ddl text: %s', substr(p_ddl_text, 1, 255));
        dbug.print(dbug."info", 'new ddl text: %s', substr(l_ddl_text, 1, 255));
      end if;
$end
    end if;

    return l_ddl_text;
  end modify_ddl_text;

  procedure remap_schema
  ( p_schema in t_schema_nn
  , p_new_schema in t_schema_nn
  , p_schema_object in out nocopy oracle_tools.t_schema_object
  )
  is
    l_ref_constraint_object oracle_tools.t_ref_constraint_object;
  begin
$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
    dbug.enter(g_package_prefix || 'REMAP_SCHEMA (1)');
    p_schema_object.print;
$end

    if p_schema != p_new_schema -- implies both not null
    then
      -- If we are going to move to another schema, adjust all schema attributes because the DDL generated
      -- will also be changed due to dbms_metadata.set_remap_param() being called.
      if p_schema_object.object_schema() = p_schema
      then
        p_schema_object.object_schema(p_new_schema);
      end if;
      if p_schema_object.base_object_schema() = p_schema
      then
        p_schema_object.base_object_schema(p_new_schema);
      end if;
      if p_schema_object is of (oracle_tools.t_ref_constraint_object)
      then
        l_ref_constraint_object := treat(p_schema_object as oracle_tools.t_ref_constraint_object);
        if l_ref_constraint_object.ref_object_schema() = p_schema
        then
          l_ref_constraint_object.ref_object_schema(p_new_schema);
          p_schema_object := l_ref_constraint_object;
        end if;
      end if;
    end if;

$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
    p_schema_object.print;
    dbug.leave;
  exception
    when others
    then
      dbug.leave_on_error;
      raise;
$end
  end remap_schema;

  procedure remap_schema
  ( p_schema in t_schema_nn
  , p_new_schema in t_schema_nn
  , p_ddl in out nocopy oracle_tools.t_ddl
  )
  is
    l_str_tab dbms_sql.varchar2a;

    procedure append_clob
    ( p_clob in out nocopy clob
    , p_buffer in varchar2
    , p_append in varchar2
    ) is
    begin
      dbms_lob.writeappend(lob_loc => p_clob, amount => length(p_buffer || p_append), buffer => p_buffer || p_append);
    end append_clob;
  begin
$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
    dbug.enter(g_package_prefix || 'REMAP_SCHEMA (2)');
$end

    if p_ddl.text is not null and p_ddl.text.count > 0 
    then
      if length(p_schema) = length(p_new_schema)
      then
        -- GJP 2021-09-02
        -- The replacement will not change the length: do not change p_ddl.text itself just its elements
        for i_idx in p_ddl.text.first .. p_ddl.text.last
        loop
          p_ddl.text(i_idx) := modify_ddl_text(p_ddl_text => p_ddl.text(i_idx), p_schema => p_schema, p_new_schema => p_new_schema);
        end loop;
      else
        -- GJP 2021-09-02
        -- The replacement will change the length and it may either become too big or too small
        -- (remainder empty which will cause compare problems).

        -- GJP 2021-09-03
        -- It is not sufficient to replace the individual chunks from p_ddl.text since
        -- those are not lines, but just chunks. This will give a problem if the old schema starts at index i and ends at index i+1.
        -- In that case it will not be replaced.
        --
        -- The solution:
        -- A) concatenate all the chunks from the text array to a CLOB (initially trimmed)
        -- B) split them into lines using the linefeed character
        -- C) trim the CLOB
        -- D) modify each line and append it to the CLOB (add a new line except for the last line)
        -- E) convert the CLOB to the text array element

        -- See A
        oracle_tools.pkg_str_util.text2clob
        ( pi_text_tab => p_ddl.text
        , pio_clob => g_clob
        , pi_append => false -- trim g_clob first
        );

        -- See B
        oracle_tools.pkg_str_util.split
        ( p_str => g_clob
        , p_delimiter => chr(10)
        , p_str_tab  => l_str_tab
        );

        -- See C
        dbms_lob.trim(g_clob, 0);

        -- See D
        if l_str_tab.count > 0
        then
          for i_idx in l_str_tab.first .. l_str_tab.last
          loop
            append_clob
            ( p_clob => g_clob
            , p_buffer => modify_ddl_text(p_ddl_text => l_str_tab(i_idx), p_schema => p_schema, p_new_schema => p_new_schema)
            , p_append => case when i_idx < l_str_tab.last then chr(10) end -- add a new line but NOT for the last line
            );
          end loop;
        end if;

        -- See E
        p_ddl.text :=
          oracle_tools.pkg_str_util.clob2text
          ( pi_clob => g_clob
          , pi_trim => 0
          );
      end if;
    end if;

$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
    dbug.leave;
  exception
    when others
    then
      dbug.leave_on_error;
      raise;
$end
  end remap_schema;

  procedure remap_schema
  ( p_schema in t_schema_nn
  , p_new_schema in t_schema_nn
  , p_ddl_tab in out nocopy oracle_tools.t_ddl_tab
  )
  is
  begin
$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
    dbug.enter(g_package_prefix || 'REMAP_SCHEMA (3)');
$end

    if p_ddl_tab is not null and p_ddl_tab.count > 0
    then
      for i_idx in p_ddl_tab.first .. p_ddl_tab.last
      loop
        remap_schema
        ( p_schema => p_schema
        , p_new_schema => p_new_schema
        , p_ddl => p_ddl_tab(i_idx)
        );
      end loop;
    end if;

$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
    dbug.leave;
  exception
    when others
    then
      dbug.leave_on_error;
      raise;
$end
  end remap_schema;

  procedure remap_schema
  ( p_schema in t_schema_nn
  , p_new_schema in t_schema_nn
  , p_schema_ddl in out nocopy oracle_tools.t_schema_ddl
  )
  is
  begin
$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
    dbug.enter(g_package_prefix || 'REMAP_SCHEMA (4)');
$end

    if p_schema = p_new_schema
    then
      raise program_error;
    end if;

    remap_schema
    ( p_schema => p_schema
    , p_new_schema => p_new_schema
    , p_schema_object => p_schema_ddl.obj
    );
    remap_schema
    ( p_schema => p_schema
    , p_new_schema => p_new_schema
    , p_ddl_tab => p_schema_ddl.ddl_tab
    );

$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
    dbug.leave;
  exception
    when others
    then
      dbug.leave_on_error;
      raise;
$end
  end remap_schema;

  /* PUBLIC ROUTINES */

  function display_ddl_schema
  ( p_schema in t_schema_nn
  , p_new_schema in t_schema
  , p_sort_objects_by_deps in t_numeric_boolean_nn
  , p_object_type in t_metadata_object_type
  , p_object_names in t_object_names
  , p_object_names_include in t_numeric_boolean
  , p_network_link in t_network_link
  , p_grantor_is_schema in t_numeric_boolean_nn
  , p_transform_param_list in varchar2
  , p_exclude_objects in t_objects
  , p_include_objects in t_objects
  )
  return oracle_tools.t_schema_ddl_tab
  pipelined
  is
    l_schema_object_filter oracle_tools.t_schema_object_filter :=
      oracle_tools.t_schema_object_filter
      ( p_schema => p_schema
      , p_object_type => p_object_type
      , p_object_names => p_object_names
      , p_object_names_include => p_object_names_include
      , p_grantor_is_schema => 0
      , p_exclude_objects => p_exclude_objects
      , p_include_objects => p_include_objects
      );
    l_network_link all_db_links.db_link%type := null;
    l_cursor sys_refcursor;
    l_schema_object_tab oracle_tools.t_schema_object_tab;
    -- GJP 2022-12-31 Not used
    -- l_transform_param_tab t_transform_param_tab;
    l_line_tab dbms_sql.varchar2a;
    l_schema_ddl_tab oracle_tools.t_schema_ddl_tab;
    l_program constant t_module := 'DISPLAY_DDL_SCHEMA'; -- geen schema omdat l_program in dbms_application_info wordt gebruikt

    -- dbms_application_info stuff
    l_longops_rec t_longops_rec :=
      oracle_tools.api_longops_pkg.longops_init
      ( p_target_desc => l_program
      , p_op_name => 'fetch'
      , p_units => 'objects'
      );
  begin
$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
    dbug.enter(g_package_prefix || 'DISPLAY_DDL_SCHEMA');
    dbug.print(dbug."input"
               ,'p_schema: %s; p_new_schema: %s; p_sort_objects_by_deps: %s; p_object_type: %s; p_object_names: %s'
               ,p_schema
               ,p_new_schema
               ,p_sort_objects_by_deps
               ,p_object_type
               ,p_object_names);
    dbug.print(dbug."input"
               ,'p_object_names_include: %s; p_network_link: %s; p_grantor_is_schema: %s; p_transform_param_list: %s'
               ,p_object_names_include
               ,p_network_link
               ,p_grantor_is_schema
               ,p_transform_param_list
               );
    dbug.print(dbug."input"
               ,'p_exclude_objects length: %s; p_include_objects length: %s'
               ,dbms_lob.getlength(p_exclude_objects)
               ,dbms_lob.getlength(p_include_objects)
               );
$end

    -- input checks
    check_schema(p_schema => p_schema, p_network_link => p_network_link);
    -- no checks for new schema: it may be null or any name
    check_numeric_boolean(p_numeric_boolean => p_sort_objects_by_deps, p_description => 'sort objects by deps');
    check_numeric_boolean(p_numeric_boolean => p_object_names_include, p_description => 'object names include'); -- duplicate but for unit testing
    check_network_link(p_network_link => p_network_link);
    check_numeric_boolean(p_numeric_boolean => p_grantor_is_schema, p_description => 'grantor is schema'); -- duplicate but for unit testing

    -- GJP 2022-12-31 Not used
    -- get_transform_param_tab(p_transform_param_list, l_transform_param_tab);

    if p_network_link is not null
    then
      l_network_link := get_db_link(p_network_link);

      if l_network_link is null
      then
        raise program_error;
      end if;

      oracle_tools.pkg_ddl_util.set_display_ddl_schema_args
      ( p_schema => p_schema
      , p_new_schema => p_new_schema
      , p_sort_objects_by_deps => p_sort_objects_by_deps
      , p_object_type => p_object_type
      , p_object_names => p_object_names
      , p_object_names_include => p_object_names_include
      , p_network_link => p_network_link
      , p_grantor_is_schema => p_grantor_is_schema
      , p_transform_param_list => p_transform_param_list
      , p_exclude_objects => p_exclude_objects
      , p_include_objects => p_include_objects
      );

      open l_cursor for 'select t.schema_ddl from oracle_tools.v_display_ddl_schema@' || l_network_link || ' t';
    else -- local
      /* GPA 27-10-2016
         The queries below may invoke the objects clause twice.
         Now if it that means invoking get_schema_ddl() twice that may be costly.
         The solution is to retrieve all the object ddl info once and use it twice.
      */
      oracle_tools.pkg_schema_object_filter.get_schema_objects
      ( p_schema_object_filter => l_schema_object_filter
      , p_schema_object_tab => l_schema_object_tab
      );

      if nvl(p_sort_objects_by_deps, 0) != 0
      then
        open l_cursor for
          select  s.schema_ddl
          from    ( select  value(s) as schema_ddl
                    from    table
                            ( oracle_tools.pkg_ddl_util.get_schema_ddl
                              ( p_schema_object_filter => l_schema_object_filter
                              , p_schema_object_tab => l_schema_object_tab
                              , p_transform_param_list => p_transform_param_list
                              )
                            ) s
                  ) s
                  -- GPA 27-10-2016 We should not forget objects so use left outer join
                  inner join
                  ( select  value(d) as obj
                    ,       rownum as nr
                    from    table
                            ( oracle_tools.pkg_ddl_util.sort_objects_by_deps
                              ( l_schema_object_tab
                              , p_schema
                              )
                            ) d
                  ) d
                  on d.obj = s.schema_ddl.obj
          order by
                  d.nr
          ;
      else
        -- normal stuff: no network link, no dependency sorting
        open l_cursor for
          select  value(s) as schema_ddl
          from    table
                  ( oracle_tools.pkg_ddl_util.get_schema_ddl
                    ( p_schema_object_filter => l_schema_object_filter
                    , p_schema_object_tab => l_schema_object_tab
                    , p_transform_param_list => p_transform_param_list
                    )
                  ) s
          order by
                  s.obj.object_type_order() nulls last
          ,       s.obj.object_schema()
          ,       s.obj.object_type()
          ,       s.obj.object_name()
          ,       s.obj.base_object_schema()
          ,       s.obj.base_object_type()
          ,       s.obj.base_object_name()
          ,       s.obj.column_name()
          ,       s.obj.grantee()
          ,       s.obj.privilege()
          ,       s.obj.grantable()
        ;
      end if;
    end if;

    <<fetch_loop>>
    loop
      fetch l_cursor bulk collect into l_schema_ddl_tab limit c_fetch_limit;    

      if l_schema_ddl_tab.count > 0
      then
        for i_idx in l_schema_ddl_tab.first .. l_schema_ddl_tab.last
        loop
          if p_network_link is not null
          then
            l_schema_ddl_tab(i_idx).obj.network_link(p_network_link);
          end if;

          if p_schema != p_new_schema
          then
            remap_schema
            ( p_schema => p_schema
            , p_new_schema => p_new_schema
            , p_schema_ddl => l_schema_ddl_tab(i_idx)
            );
          end if;

          pipe row(l_schema_ddl_tab(i_idx));

          oracle_tools.api_longops_pkg.longops_show(l_longops_rec);
        end loop;
      end if;
      exit fetch_loop when l_schema_ddl_tab.count < c_fetch_limit;
    end loop fetch_loop;
    close l_cursor;

    oracle_tools.api_longops_pkg.longops_done(l_longops_rec);

$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
    dbug.leave;
$end

    return;

  exception
    when no_data_needed
    then
$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
      dbug.leave;
$end
      null; -- not a real error, just a way to some cleanup

    when no_data_found -- disappears otherwise (GJP 2022-12-29 as it should)
    then
$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
      dbug.leave_on_error;
$end
      -- GJP 2022-12-29
$if oracle_tools.pkg_ddl_util.c_err_pipelined_no_data_found $then
      oracle_tools.pkg_ddl_error.reraise_error(l_program);
$else      
      null;
$end      

$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
    when others
    then
      dbug.leave_on_error;
      raise;
$end
  end display_ddl_schema;

  procedure create_schema_ddl
  ( p_source_schema_ddl in oracle_tools.t_schema_ddl
  , p_target_schema_ddl in oracle_tools.t_schema_ddl
  , p_skip_repeatables in t_numeric_boolean
  , p_schema_ddl out nocopy oracle_tools.t_schema_ddl
  )
  is
    "nothing" constant varchar2(100) := 'nothing';
    "uninstall" constant varchar2(100) := 'uninstall';
    "install" constant varchar2(100) := 'install';
    "diff" constant varchar2(100) := 'diff';
    "dbms_metadata_diff" constant varchar2(100) := 'dbms_metadata_diff';

    l_action varchar2(100) := "nothing";
    l_comment varchar2(4000 char) := 'there are no changes';
  begin
$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
    dbug.enter(g_package_prefix || 'CREATE_SCHEMA_DDL');
    dbug.print(dbug."input", 'p_source_schema_ddl.obj:');
    if p_source_schema_ddl is not null then p_source_schema_ddl.obj.print(); end if;
    dbug.print(dbug."input", 'p_target_schema_ddl.obj:');
    if p_target_schema_ddl is not null then p_target_schema_ddl.obj.print(); end if;
    dbug.print
    ( dbug."input"
    , 'p_skip_repeatables: %s'
    , p_skip_repeatables
    );
$end

    -- determine action and comment

$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
    dbug.print
    ( dbug."info"
    , '(p_target_schema_ddl is null): %s; (p_source_schema_ddl is null): %s; (p_target_schema_ddl = p_source_schema_ddl): %s'
    , dbug.cast_to_varchar2(p_target_schema_ddl is null)
    , dbug.cast_to_varchar2(p_source_schema_ddl is null)
    , dbug.cast_to_varchar2(p_target_schema_ddl is not null and p_source_schema_ddl is not null and p_target_schema_ddl = p_source_schema_ddl)
    );
    dbug.print
    ( dbug."info"
    , 'p_source_schema_ddl.is_a_repeatable(): %s'
    , case when p_source_schema_ddl is not null then p_source_schema_ddl.obj.is_a_repeatable() end
    );
$end

    if ( p_target_schema_ddl is not null or p_source_schema_ddl is not null ) -- both empty: what do we do here?
       and
       ( p_target_schema_ddl is null or -- source objects are new
         p_source_schema_ddl is null or -- target objects are obsolete
         p_target_schema_ddl != p_source_schema_ddl -- target and source not equal
       )
       and
       ( p_source_schema_ddl is null or -- objects to be dropped
         p_skip_repeatables = 0 or -- any object type must be compared
         p_source_schema_ddl.obj.is_a_repeatable() = 0 -- only non-repeatable object types
       )
    then
      if p_target_schema_ddl is not null and p_source_schema_ddl is null
      then
        l_comment := 'object does not exist in the source schema';
        l_action := "uninstall";
      else
        if p_source_schema_ddl is null
        then
          raise program_error;
        end if;

        /*
        -- Show original DDL if:
        -- a) it is an object type that can be replaced AND
        --    1) the object in target schema does not exist OR
        --    2) there is a difference
        -- b) it is an object type that can NOT be replaced AND
        --    the object does not exist in the target schema
        --
        -- Else:
        -- c1) show an invalid ALTER statement if DBMS_METADATA_DIFF is not licensed and there is a difference
        -- c2) show the by DBMS_METADATA_DIFF calculated DDL if this is the first occurrence of the object
        */

        if p_source_schema_ddl.obj.is_a_repeatable() = 1
        then
          if p_target_schema_ddl is null
          then
            /* variant a1 */
            l_comment := 'repeatable object does not exist in the target schema';
            l_action := "install";
          elsif p_source_schema_ddl is not null
          then
            /* variant a2 */
            l_comment := 'repeatable source and target object are not the same';
            l_action := "install";
          end if;
        elsif p_target_schema_ddl is null
        then
          /* variant b */
          l_comment := 'non repeatable object does not exist in the target schema';
          l_action := "install";
        else
          /* variant c1 */
          l_comment := 'non repeatable source and target object are not the same';
          l_action := "diff";
        end if;
      end if;
    end if;

$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
    dbug.print(dbug."info", 'l_action: %s; l_comment: %s', l_action, l_comment);
$end

    -- create with an empty ddl list
    oracle_tools.t_schema_ddl.create_schema_ddl
    ( case
        when p_source_schema_ddl is not null
        then p_source_schema_ddl.obj
        else p_target_schema_ddl.obj
      end
    , oracle_tools.t_ddl_tab()
    , p_schema_ddl
    );

    -- add action and comment
    p_schema_ddl.add_ddl
    ( p_verb => '--'
    , p_text => '-- action: ' || l_action || ' (' || l_comment || ')'
    );

    case l_action
      when "nothing"
      then
        null;

      when "uninstall"
      then
        /*
        -- DROP van objecten in target schema die niet in source schema zitten,
        -- maar wel in omgekeerde volgorde.
        */
        p_schema_ddl.uninstall(p_target => p_target_schema_ddl);

      when "install"
      then
        p_schema_ddl.install
        ( p_source => p_source_schema_ddl
        );

      else
        p_schema_ddl.migrate
        ( p_source => p_source_schema_ddl
        , p_target => p_target_schema_ddl
        );
    end case;

$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
    dbug.leave;
$end
  exception
    when others
    then
$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
      dbug.leave_on_error;
$end
      raise;
  end create_schema_ddl;

  function display_ddl_schema_diff
  ( p_object_type in t_metadata_object_type
  , p_object_names in t_object_names
  , p_object_names_include in t_numeric_boolean
  , p_schema_source in t_schema
  , p_schema_target in t_schema_nn
  , p_network_link_source in t_network_link
  , p_network_link_target in t_network_link
  , p_skip_repeatables in t_numeric_boolean_nn
  , p_transform_param_list in varchar2
  , p_exclude_objects in t_objects
  , p_include_objects in t_objects
  )
  return oracle_tools.t_schema_ddl_tab
  pipelined
  is
    l_schema_ddl oracle_tools.t_schema_ddl;
    l_source_schema_ddl_tab oracle_tools.t_schema_ddl_tab;
    l_target_schema_ddl_tab oracle_tools.t_schema_ddl_tab;

    l_object t_object;
    l_text_tab dbms_sql.varchar2a;
    l_program constant t_module := 'DISPLAY_DDL_SCHEMA_DIFF';

    -- dbms_application_info stuff
    l_longops_rec t_longops_rec :=
      oracle_tools.api_longops_pkg.longops_init
      ( p_op_name => 'fetch'
      , p_units => 'objects'
      , p_target_desc => l_program
      );

    procedure free_memory
    ( p_schema_ddl_tab in out nocopy oracle_tools.t_schema_ddl_tab
    )
    is
    begin
      /* GPA 2017-04-12 #142504743 The DDL incremental generator fails on the Oracle XE database with an ORA-22813 error.

         In spite of the remark below (#141477987 ) we have to free up memory if and only if:
         - parameter p_skip_repeatables != 0 AND
         - the object are repeatable objects (excluding oracle_tools.t_type_method_ddl because it uses ddl_tab(1))
      */
      if p_skip_repeatables != 0 and cardinality(p_schema_ddl_tab) > 0
      then
        for i_idx in p_schema_ddl_tab.first .. p_schema_ddl_tab.last
        loop
          if p_schema_ddl_tab(i_idx).obj.is_a_repeatable() != 0 and
             not(p_schema_ddl_tab(i_idx) is of (oracle_tools.t_type_method_ddl))
          then
            p_schema_ddl_tab(i_idx).ddl_tab := oracle_tools.t_ddl_tab();
          end if;
        end loop;
      end if;
    end free_memory;
  begin
$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
    dbug.enter(g_package_prefix || l_program);
    dbug.print(dbug."input"
               ,'p_object_type: %s; p_object_names: %s; p_object_names_include: %s; p_schema_source: %s; p_schema_target: %s'
               ,p_object_type
               ,p_object_names
               ,p_object_names_include
               ,p_schema_source
               ,p_schema_target);
    dbug.print(dbug."input"
               ,'p_network_link_source: %s; p_network_link_target: %s; p_skip_repeatables: %s; p_transform_param_list: %s'
               ,p_network_link_source
               ,p_network_link_target
               ,p_skip_repeatables
               ,p_transform_param_list);
    dbug.print(dbug."input"
               ,'p_exclude_objects length: %s; p_include_objects length: %s'
               ,dbms_lob.getlength(p_exclude_objects)
               ,dbms_lob.getlength(p_include_objects)
               );
$end

    -- input checks
    -- by display_ddl_schema: check_numeric_boolean(p_numeric_boolean => p_object_names_include, p_description => 'Object names include');
    check_schema(p_schema => p_schema_source, p_network_link => p_network_link_source, p_description => 'Source schema');
    check_schema(p_schema => p_schema_target, p_network_link => p_network_link_target, p_description => 'Target schema');
    check_source_target
    ( p_schema_source => p_schema_source
    , p_schema_target => p_schema_target
    , p_network_link_source => p_network_link_source
    , p_network_link_target => p_network_link_target
    );
    check_network_link(p_network_link => p_network_link_source, p_description => 'Source database link');
    check_network_link(p_network_link => p_network_link_target, p_description => 'Target database link');
    check_numeric_boolean(p_numeric_boolean => p_skip_repeatables, p_description => 'Skip repeatables');

    if p_schema_source is null
    then
      l_source_schema_ddl_tab := oracle_tools.t_schema_ddl_tab();
    else
      select  value(s)
      bulk collect
      into    l_source_schema_ddl_tab
      from    table
              ( oracle_tools.pkg_ddl_util.display_ddl_schema
                ( p_schema => p_schema_source
                , p_new_schema => p_schema_target
                , p_sort_objects_by_deps => 1 -- sort for create
                , p_object_type => p_object_type
                , p_object_names => p_object_names
                , p_object_names_include => p_object_names_include
                , p_network_link => p_network_link_source
                , p_grantor_is_schema => 0 -- any grantor
                , p_transform_param_list => p_transform_param_list
                , p_exclude_objects => p_exclude_objects
                , p_include_objects => p_include_objects
                )
              ) s
      ;
      free_memory(l_source_schema_ddl_tab);
    end if;

$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
    dbug.print(dbug."info", 'cardinality(l_source_schema_ddl_tab): %s', cardinality(l_source_schema_ddl_tab));
$end

    if p_schema_target is null
    then
      l_target_schema_ddl_tab := oracle_tools.t_schema_ddl_tab();
    else
      /* GPA 2017-03-10 #141477987 
         Do not try to optimise retrieving DDL when there is only an uninstall
         because the revoke statement needs the actual DDL.
      */
      select  value(t)
      bulk collect
      into    l_target_schema_ddl_tab
      from    table
              ( oracle_tools.pkg_ddl_util.display_ddl_schema
                ( p_schema => p_schema_target
                , p_new_schema => null
                , p_sort_objects_by_deps => 1 -- sort for drop
                , p_object_type => p_object_type
                  /*
                  -- GPA 2017-01-12
                  -- When the source objects are named, we also just compare
                  -- those target objects.  However if all source objects
                  -- are taken or some excluded, we suppose that those
                  -- excluded objects are temporary objects. So now if we
                  -- just retrieve all target objects, those target objects
                  -- that are not in the source schema will be uninstalled.
                  --
                  -- So we get rid of obsolete target objects if the objects
                  -- are not named explicitly (i.e. p_object_names_include != 1).
                  */
                , p_object_names => case when p_object_names_include = 1 then p_object_names end 
                , p_object_names_include => case when p_object_names_include = 1 then p_object_names_include end
                , p_network_link => p_network_link_target
                , p_grantor_is_schema => 1 -- only grantor equal to p_schema_target so we can revoke the grant if necessary
                , p_transform_param_list => p_transform_param_list
                , p_exclude_objects => p_exclude_objects
                , p_include_objects => p_include_objects
                )
              ) t
      ;
      free_memory(l_target_schema_ddl_tab);
    end if;

$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
    dbug.print(dbug."info", 'cardinality(l_target_schema_ddl_tab): %s', cardinality(l_target_schema_ddl_tab));
$end

    for r_schema_ddl in
    ( with source as
      ( select  value(source) as schema_ddl
        ,       rownum as dependency_order
        from    table(l_source_schema_ddl_tab) source
      ), target as
      ( select  value(target) as schema_ddl
        ,       rownum as dependency_order
        from    table(l_target_schema_ddl_tab) target
      )
      -- GPA 2017-03-24 #142307767 The incremental DDL generator handles changed check constraints incorrectly.
      --
      -- Since the map function is used (which uses signature()) some objects may have the same id but not
      -- the same signature.
      --
      -- For example if a check constraint has the same name but a different check condition
      -- they will not be "equal" so this query will return two rows and the new object first
      -- and the dropped object last.
      -- So the WRONG outcome is that the constraint will be added and then dropped.
      -- So we have to adjust for objects not being "equal" but having the same id.
      , eq as
      (
        select  s.schema_ddl as source_schema_ddl
        ,       s.dependency_order as source_dependency_order
        ,       t.schema_ddl as target_schema_ddl
        ,       t.dependency_order as target_dependency_order
        ,       count(*) over (partition by case when s.schema_ddl is not null then s.schema_ddl.obj.id() else t.schema_ddl.obj.id() end) as nr_objects_with_same_id
        from    source s
                full outer join target t
                on t.schema_ddl.obj = s.schema_ddl.obj -- map function is used
      )
      select    eq.source_schema_ddl
      ,         eq.target_schema_ddl
      from      eq
      order by
                case
                  when eq.nr_objects_with_same_id = 1 or (eq.source_schema_ddl is not null and eq.target_schema_ddl is not null) -- old behaviour
                  then eq.source_dependency_order
                  else null
                end asc nulls last -- new or changed objects first
      ,         case
                  when eq.nr_objects_with_same_id = 1 or (eq.source_schema_ddl is not null and eq.target_schema_ddl is not null) -- old behaviour
                  then eq.target_dependency_order
                  else null
                end desc nulls last -- to be dropped objects last in reversed order of creation
      ,         case
                  when not(eq.nr_objects_with_same_id = 1 or (eq.source_schema_ddl is not null and eq.target_schema_ddl is not null)) -- #142307767
                  then eq.target_dependency_order
                  else null
                end desc nulls last -- drop first for object with same id
      ,         case
                  when not(eq.nr_objects_with_same_id = 1 or (eq.source_schema_ddl is not null and eq.target_schema_ddl is not null)) -- #142307767
                  then eq.source_dependency_order
                  else null
                end asc nulls last -- create next
    )
    loop
$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
      dbug.print
      ( dbug."debug"
      , 'sofar: %s; source signature: %s; target signature: %s; id different: %s'
      , to_char(l_longops_rec.sofar + 1)
      , case when r_schema_ddl.source_schema_ddl is not null then r_schema_ddl.source_schema_ddl.obj.signature() end
      , case when r_schema_ddl.target_schema_ddl is not null then r_schema_ddl.target_schema_ddl.obj.signature() end
      , dbug.cast_to_varchar2
        ( case
            when r_schema_ddl.source_schema_ddl is not null and
                 r_schema_ddl.target_schema_ddl is not null
            then r_schema_ddl.source_schema_ddl.obj.id() != r_schema_ddl.target_schema_ddl.obj.id()
          end
        )
      );
$end
      create_schema_ddl
      ( p_source_schema_ddl => r_schema_ddl.source_schema_ddl
      , p_target_schema_ddl => r_schema_ddl.target_schema_ddl
      , p_skip_repeatables => p_skip_repeatables
      , p_schema_ddl => l_schema_ddl
      );

      pipe row(l_schema_ddl);

      oracle_tools.api_longops_pkg.longops_show(l_longops_rec);
    end loop schema_source_loop;

    oracle_tools.api_longops_pkg.longops_done(l_longops_rec);

$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
    dbug.leave;
$end

    return; -- essential for a pipelined function

  exception
    when no_data_needed
    then
$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
      dbug.leave;
$end
      null; -- not a real error, just a way to some cleanup

    when no_data_found -- will otherwise get lost due to pipelined function (GJP 2022-12-29 as it should)
    then
$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
      dbug.leave_on_error;
$end
      -- GJP 2022-12-29
$if oracle_tools.pkg_ddl_util.c_err_pipelined_no_data_found $then
      oracle_tools.pkg_ddl_error.reraise_error(l_program);
$else      
      null;
$end      

    when others
    then
$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
      dbug.leave_on_error;
$end
      raise;
  end display_ddl_schema_diff;

  procedure execute_ddl
  ( p_id in varchar2
  , p_text in varchar2
  )
  is
  begin
$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
    dbug.enter(g_package_prefix || 'EXECUTE_DDL (1)');
    dbug.print(dbug."input", 'p_id: %s; p_text[:255]: %s', p_id, substr(p_text, 1, 255));
$end

    oracle_tools.t_schema_ddl.execute_ddl(p_id => p_id, p_text => p_text);

$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
    dbug.leave;
  exception
    when others
    then
      dbug.leave_on_error;
      raise;
$end
  end execute_ddl;

  procedure execute_ddl
  ( p_ddl_text_tab in oracle_tools.t_text_tab
  , p_network_link in varchar2 default null
  )
  is
    l_statement varchar2(32767) := null;
    l_network_link all_db_links.db_link%type := null;
  begin
$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
    dbug.enter(g_package_prefix || 'EXECUTE_DDL (2)');
    dbug.print(dbug."input", 'p_network_link: %s; p_ddl_text_tab(1)[:255]: %s', p_network_link, substr(p_ddl_text_tab(1), 1, 255));
$end

    if p_network_link is not null
    then
      check_network_link(p_network_link);

      l_network_link := get_db_link(p_network_link);

      if l_network_link is null
      then
        raise program_error;
      end if;

      l_network_link := '@' || l_network_link;
    end if;

    l_statement :=
      utl_lms.format_message
      ( q'[
declare
  l_ddl_text_tab constant oracle_tools.t_text_tab := :b1;
  l_ddl_tab dbms_sql.varchar2a%s;
begin
  -- copy to (remote) array
  if l_ddl_text_tab.count > 0
  then
    for i_idx in l_ddl_text_tab.first .. l_ddl_text_tab.last
    loop
      l_ddl_tab(i_idx) := l_ddl_text_tab(i_idx);
    end loop;
  end if;
  --
  oracle_tools.pkg_ddl_util.execute_ddl%s(l_ddl_tab);
end;]', l_network_link -- no need to use dbms_assert since it may empty or @<network link>
      , l_network_link
      );

    begin
      if l_network_link is null
      then
        execute immediate l_statement using p_ddl_text_tab;
      else
        oracle_tools.api_pkg.dbms_output_enable(substr(l_network_link, 2));
        oracle_tools.api_pkg.dbms_output_clear(substr(l_network_link, 2));

        execute immediate l_statement using p_ddl_text_tab;

        oracle_tools.api_pkg.dbms_output_flush(substr(l_network_link, 2));
      end if;
    exception
      when others
      then
        if l_network_link is not null
        then
          oracle_tools.api_pkg.dbms_output_flush(substr(l_network_link, 2));
        end if;
        raise;
    end;

$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
    dbug.leave;
  exception
    when others
    then
      dbug.leave_on_error;
      raise;
$end
  end execute_ddl;

  procedure execute_ddl
  ( p_ddl_tab in dbms_sql.varchar2a
  )
  is
    l_cursor integer;
    l_last_error_position integer := null;

    -- ORA-24344: success with compilation error -- due to missing privileges
    e_s6_with_compilation_error exception;
    pragma exception_init(e_s6_with_compilation_error, -24344);
    -- ORA-04063: view "EMPTY.V_DISPLAY_DDL_SCHEMA" has errors
    e_view_has_errors exception;
    pragma exception_init(e_view_has_errors, -4063);
    -- ORA-01720: grant option does not exist for <owner>.PARTY
    e_grant_option_does_not_exist exception;
    pragma exception_init(e_grant_option_does_not_exist, -1720);
    -- ORA-01927: cannot REVOKE privileges you did not grant
    e_cannot_revoke exception;
    pragma exception_init(e_cannot_revoke, -1927);
    -- ORA-04045: errors during recompilation/revalidation of EMPTY.T_TRIGGER_DDL
    e_errors_during_recompilation exception;
    pragma exception_init(e_errors_during_recompilation, -4045);
    -- ORA-01442: column to be modified to NOT NULL is already NOT NULL
    e_column_already_null exception;
    pragma exception_init(e_column_already_null, -1442);
  begin
$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
    dbug.enter(g_package_prefix || 'EXECUTE_DDL (3)');
    dbug.print(dbug."input", 'p_ddl_tab.count: %s', p_ddl_tab.count);
$end

    l_cursor := dbms_sql.open_cursor;
    --
    dbms_sql.parse
    ( c => l_cursor
    , statement => p_ddl_tab
    , lb => p_ddl_tab.first
    , ub => p_ddl_tab.last
    , lfflg => false
    , language_flag => dbms_sql.native
    );
    --
    dbms_sql.close_cursor(l_cursor);

$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
    dbug.leave;
$end
  exception
    when e_s6_with_compilation_error or
         e_view_has_errors or
         e_grant_option_does_not_exist or
         e_cannot_revoke or
         e_errors_during_recompilation or
         e_column_already_null
    then 
      dbms_sql.close_cursor(l_cursor);
$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
      dbug.leave_on_error;
$end
      null; -- no reraise

    when others
    then
      /* DBMS_SQL.LAST_ERROR_POSITION 
         This function returns the byte offset in the SQL statement text where the error occurred. 
         The first character in the SQL statement is at position 0. 
      */
      l_last_error_position := 1 + nvl(dbms_sql.last_error_position, 0);
      dbms_sql.close_cursor(l_cursor);
$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
      dbug.leave_on_error;
$end
      raise_application_error
      ( oracle_tools.pkg_ddl_error.c_execute_via_db_link
      , 'Error at position ' || l_last_error_position || '; ddl:' || chr(10) || substr(p_ddl_tab(p_ddl_tab.first), 1, 255)
      , true
      );
  end execute_ddl;

  procedure execute_ddl
  ( p_schema_ddl_tab in oracle_tools.t_schema_ddl_tab
  , p_network_link in varchar2 default null
  )
  is
  begin
$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
    dbug.enter(g_package_prefix || 'EXECUTE_DDL (4)');
    dbug.print(dbug."input"
               ,'p_schema_ddl_tab.count: %s; p_network_link: %s'
               ,case when p_schema_ddl_tab is not null then p_schema_ddl_tab.count end
               ,p_network_link);
$end

    if p_schema_ddl_tab is not null and
       p_schema_ddl_tab.count > 0
    then
      for i_idx in p_schema_ddl_tab.first .. p_schema_ddl_tab.last
      loop
        if cardinality(p_schema_ddl_tab(i_idx).ddl_tab) > 0
        then
          for i_ddl_idx in p_schema_ddl_tab(i_idx).ddl_tab.first .. p_schema_ddl_tab(i_idx).ddl_tab.last
          loop
$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
            p_schema_ddl_tab(i_idx).ddl_tab(i_ddl_idx).print();
$end          
            if p_schema_ddl_tab(i_idx).ddl_tab(i_ddl_idx).verb() = '--' 
            then
              -- this is a comment
              null;
            else
              execute_ddl(p_schema_ddl_tab(i_idx).ddl_tab(i_ddl_idx).text, p_network_link);
            end if;
          end loop;
        end if; -- if cardinality(p_schema_ddl_tab(i_idx).ddl_tab) > 0
      end loop;
    end if;

$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
    dbug.leave;
  exception
    when others
    then
      dbug.leave_on_error;
      raise;
$end
  end execute_ddl;

  procedure synchronize
  ( p_object_type in t_metadata_object_type
  , p_object_names in t_object_names
  , p_object_names_include in t_numeric_boolean
  , p_schema_source in t_schema
  , p_schema_target in t_schema_nn
  , p_network_link_source in t_network_link
  , p_network_link_target in t_network_link
  , p_exclude_objects in t_objects
  , p_include_objects in t_objects
  )
  is
    l_diff_schema_ddl_tab oracle_tools.t_schema_ddl_tab;

$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
    l_program constant t_module := g_package_prefix || 'SYNCHRONIZE';
$end
  begin
$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
    dbug.enter(l_program);
$end

    -- Bereken de verschillen, i.e. de CREATE statements.
    -- Gebruik database links om aan te loggen met de juiste gebruiker.
    select value(t)
    bulk collect
    into   l_diff_schema_ddl_tab
    from   table
           ( oracle_tools.pkg_ddl_util.display_ddl_schema_diff
             ( p_object_type => p_object_type
             , p_object_names => p_object_names
             , p_object_names_include => p_object_names_include
             , p_schema_source => p_schema_source
             , p_schema_target => p_schema_target
             , p_network_link_source => p_network_link_source
             , p_network_link_target => p_network_link_target
             , p_skip_repeatables => 0
             , p_exclude_objects => p_exclude_objects
             , p_include_objects => p_include_objects
             )
           ) t
    ;

    -- Skip public synonyms on the same database
    if get_host(p_network_link_source) = get_host(p_network_link_target)
    then
      remove_public_synonyms(l_diff_schema_ddl_tab);
    end if;

    execute_ddl(l_diff_schema_ddl_tab, p_network_link_target);

$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
    dbug.leave;
  exception
    when others
    then
      dbug.leave_on_error;
      raise;
$end
  end synchronize;

  procedure uninstall
  ( p_object_type in t_metadata_object_type
  , p_object_names in t_object_names
  , p_object_names_include in t_numeric_boolean
  , p_schema_target in t_schema_nn
  , p_network_link_target in t_network_link
  , p_exclude_objects in t_objects
  , p_include_objects in t_objects
  )
  is
    l_drop_schema_ddl_tab oracle_tools.t_schema_ddl_tab;

$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
    l_program constant t_module := g_package_prefix || 'UNINSTALL';
$end
  begin
$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
    dbug.enter(l_program);
$end

    synchronize
    ( p_object_type => p_object_type
    , p_object_names => p_object_names
    , p_object_names_include => p_object_names_include
    , p_schema_source => null
    , p_schema_target => p_schema_target
    , p_network_link_source => null
    , p_network_link_target => p_network_link_target
    , p_exclude_objects => p_exclude_objects
    , p_include_objects => p_include_objects
    );

$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
    dbug.leave;
  exception
    when others
    then
      dbug.leave_on_error;
      raise;
$end
  end uninstall;

  procedure get_member_ddl
  ( p_schema_ddl in oracle_tools.t_schema_ddl
  , p_member_ddl_tab out nocopy oracle_tools.t_schema_ddl_tab
  )
  is
    -- attribute/column data
    type t_member is record
    ( -- attribute/column
      member# number
    , member_name all_tab_columns.column_name%type
    , data_type_name all_tab_columns.data_type%type
    , data_type_mod all_tab_columns.data_type_mod%type
    , data_type_owner all_tab_columns.data_type_owner%type
    , data_length all_tab_columns.data_length%type
    , data_precision all_tab_columns.data_precision%type
    , data_scale all_tab_columns.data_scale%type
    , character_set_name all_tab_columns.character_set_name%type
    -- column only
    , nullable all_tab_columns.nullable%type
    , default_length all_tab_columns.default_length%type
    , data_default varchar2(32767 char)
    , char_col_decl_length all_tab_columns.char_col_decl_length%type
    , char_length all_tab_columns.char_length%type
    , char_used all_tab_columns.char_used%type
    );

    type t_member_tab is table of t_member;

    type t_type_method is record
    ( -- see ALL_TYPE_METHODS
      member# number
    , member_name all_type_methods.method_name%type
    , method_type all_type_methods.method_type%type
    , parameters all_type_methods.parameters%type
    , results all_type_methods.results%type
    , final all_type_methods.final%type
    , instantiable all_type_methods.instantiable%type
    , overriding all_type_methods.overriding%type
    );

    type t_type_method_tab is table of t_type_method;

    l_statement varchar2(4000 char) := null;
    l_cursor sys_refcursor;
    -- type attributes/table columns 
    l_member_tab t_member_tab;
    -- type methods and their arguments
    l_type_method_tab t_type_method_tab;    
    l_argument_tab t_argument_object_tab;    

    l_member_object oracle_tools.t_type_attribute_object;
    l_type_method_object oracle_tools.t_type_method_object;
    l_member_ddl oracle_tools.t_schema_ddl;

    l_table_ddl_clob clob := null;
    l_member_ddl_clob clob := null;
    l_data_default oracle_tools.t_text_tab;
    l_data_default_clob clob := null;

    l_pos pls_integer;
    l_start pls_integer;
    l_pattern varchar2(4000 char);

    "ADD" constant varchar2(5) := ' ADD ';

    procedure cleanup
    is
    begin
      if l_cursor%isopen
      then
        close l_cursor;
      end if;
      if l_table_ddl_clob is not null
      then
        dbms_lob.freetemporary(l_table_ddl_clob);
      end if;
      if l_member_ddl_clob is not null
      then
        dbms_lob.freetemporary(l_member_ddl_clob);
      end if;
      if l_data_default_clob is not null
      then
        dbms_lob.freetemporary(l_data_default_clob);
      end if;
    end cleanup;
  begin
$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
    dbug.enter(g_package_prefix || 'GET_MEMBER_DDL');
    p_schema_ddl.print();
$end

    p_member_ddl_tab := oracle_tools.t_schema_ddl_tab();

    dbms_lob.createtemporary(l_table_ddl_clob, true);
    dbms_lob.createtemporary(l_member_ddl_clob, true);
    dbms_lob.createtemporary(l_data_default_clob, true);

    case p_schema_ddl.obj.object_type()
      when 'TYPE_SPEC'
      then
        l_statement := '
select  att.attr_no as member#
,       att.attr_name as member_name
,       att.attr_type_name as data_type_name
,       att.attr_type_mod
,       att.attr_type_owner
,       att.length as data_length
,       att.precision as data_precision
,       att.scale as data_scale
,       att.character_set_name
,       to_char(null) as nullable
,       to_number(null) as default_length
,       to_number(null) as data_default
,       to_number(null) as char_col_decl_length
,       to_number(null) as char_length
,       to_char(null) as char_used
from    all_type_attrs' || case when p_schema_ddl.obj.network_link() is not null then '@' || get_db_link(p_schema_ddl.obj.network_link()) end || ' att
where   att.owner = :b1
and     att.type_name = :b2
order by
        member#';

      when 'TABLE'
      then
        -- Assume data_default is at most 32767 characters (it is a LONG)
        l_statement := '
select  col.column_id as member#
,       col.column_name as member_name
,       col.data_type as data_type_name
,       col.data_type_mod
,       col.data_type_owner
,       col.data_length
,       col.data_precision
,       col.data_scale
,       col.character_set_name
,       col.nullable
,       col.default_length
,       col.data_default
,       col.char_col_decl_length
,       col.char_length
,       col.char_used
from    all_tab_columns' || case when p_schema_ddl.obj.network_link() is not null then '@' || get_db_link(p_schema_ddl.obj.network_link()) end || ' col
where   col.owner = :b1
and     col.table_name = :b2
order by
        member#';

        dbms_lob.trim(l_table_ddl_clob, 0);
        oracle_tools.pkg_str_util.text2clob
        ( pi_text_tab => p_schema_ddl.ddl_tab(1).text -- CREATE TABLE statement
        , pio_clob => l_table_ddl_clob
        , pi_append => false
        );
        l_start := 1;
    end case;        

    open l_cursor for l_statement using p_schema_ddl.obj.object_schema(), p_schema_ddl.obj.object_name();
    fetch l_cursor bulk collect into l_member_tab limit g_max_fetch;
    close l_cursor;

$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
    dbug.print(dbug."info", 'l_member_tab.count: %s', l_member_tab.count);
$end

    if l_member_tab.count > 0
    then
      <<member_loop>>
      for i_idx in l_member_tab.first .. l_member_tab.last
      loop
$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
        dbug.print(dbug."info", 'l_member_tab(%s); member#: %s; member_name: %s', i_idx, l_member_tab(i_idx).member#, l_member_tab(i_idx).member_name);
$end
        case p_schema_ddl.obj.object_type()
          when 'TYPE_SPEC'
          then
            begin
              l_member_object :=
                oracle_tools.t_type_attribute_object
                ( p_base_object => treat(p_schema_ddl.obj as oracle_tools.t_named_object)
                , p_member# => l_member_tab(i_idx).member#
                , p_member_name => l_member_tab(i_idx).member_name
                , p_data_type_name => l_member_tab(i_idx).data_type_name
                , p_data_type_mod => l_member_tab(i_idx).data_type_mod
                , p_data_type_owner => l_member_tab(i_idx).data_type_owner
                , p_data_length => l_member_tab(i_idx).data_length
                , p_data_precision => l_member_tab(i_idx).data_precision
                , p_data_scale => l_member_tab(i_idx).data_scale
                , p_character_set_name => l_member_tab(i_idx).character_set_name
                );

              l_member_ddl := oracle_tools.t_type_attribute_ddl(l_member_object);

$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
              l_member_ddl.print();
$end

              p_member_ddl_tab.extend(1);
              p_member_ddl_tab(p_member_ddl_tab.last) := l_member_ddl;
            exception
              when others
              then
$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
                dbug.on_error;
$end
                oracle_tools.pkg_ddl_error.reraise_error('attribute [' || i_idx || ']: ' || l_member_tab(i_idx).member_name);
            end;

          when 'TABLE'
          then
            begin
              if l_member_tab(i_idx).default_length > 0
              then
                dbms_lob.trim(l_data_default_clob, 0);
                oracle_tools.pkg_str_util.append_text
                ( pi_buffer => l_member_tab(i_idx).data_default
                , pio_clob => l_data_default_clob
                );
                l_data_default := oracle_tools.pkg_str_util.clob2text(l_data_default_clob);
              else
                l_data_default := null;
              end if;

              l_member_object :=
                oracle_tools.t_table_column_object
                ( p_base_object => treat(p_schema_ddl.obj as oracle_tools.t_named_object)
                , p_member# => l_member_tab(i_idx).member#
                , p_member_name => l_member_tab(i_idx).member_name
                , p_data_type_name => l_member_tab(i_idx).data_type_name
                , p_data_type_mod => l_member_tab(i_idx).data_type_mod
                , p_data_type_owner => l_member_tab(i_idx).data_type_owner
                , p_data_length => l_member_tab(i_idx).data_length
                , p_data_precision => l_member_tab(i_idx).data_precision
                , p_data_scale => l_member_tab(i_idx).data_scale
                , p_character_set_name => l_member_tab(i_idx).character_set_name
                , p_nullable => l_member_tab(i_idx).nullable
                , p_default_length => l_member_tab(i_idx).default_length
                , p_data_default => l_data_default
                , p_char_col_decl_length => l_member_tab(i_idx).char_col_decl_length
                , p_char_length => l_member_tab(i_idx).char_length
                , p_char_used => l_member_tab(i_idx).char_used
                );

              dbms_lob.trim(l_member_ddl_clob, 0);

              oracle_tools.pkg_str_util.append_text
              ( pi_buffer => 'ALTER TABLE "' || p_schema_ddl.obj.object_schema() || '"."' || p_schema_ddl.obj.object_name() || '"' || "ADD" -- no ADD COLUMN
              , pio_clob => l_member_ddl_clob
              );

              -- This is an example of table DDL:
              --
              --CREATE TABLE "<owner>"."<table>" 
              --   (  "SEQ" NUMBER GENERATED BY DEFAULT AS IDENTITY MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 NOCACHE  ORDER  NOCYCLE  NOT NULL ENABLE, 
              --  "CREATEDATETIME" DATE, 
              --  "CREATEUSER" VARCHAR2(100 CHAR), 
              --  "UPDATEDATETIME" DATE, 
              --  "UPDATEUSER" VARCHAR2(100 CHAR)
              --   ) ...
              --
              -- Observations:
              -- a) declaration is ("<column>" ... )<end> where end is ',' || <whitespace> || "<next column>" if there is a next column
              -- b) declaration is ("<column>" ... )<end> where end is chr(10) || '   )' if there is NO next column

              -- find start of column declaration ("<column>")
              l_pattern := '"' || l_member_tab(i_idx).member_name || '"';

              l_pos := dbms_lob.instr(lob_loc => l_table_ddl_clob, pattern => l_pattern, offset => l_start);

$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
              dbug.print(dbug."info", 'l_pattern: %s; l_start: %s; l_pos: %s', l_pattern, l_start, l_pos);
$end

              if l_pos > 0
              then
                l_start := l_pos;
              else
                raise program_error;
              end if;

              -- find end of column declaration
              l_pattern := case
                             -- is there is a next column?
                             when i_idx < l_member_tab.last
                             then '"' || l_member_tab(i_idx+1).member_name || '"'
                             else chr(10) || '   )'
                           end;

              l_pos := dbms_lob.instr(lob_loc => l_table_ddl_clob, pattern => l_pattern, offset => l_start);

$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
              dbug.print(dbug."info", 'l_pattern: %s; l_start: %s; l_pos: %s', l_pattern, l_start, l_pos);
$end

              if l_pos > 0
              then
                if i_idx < l_member_tab.last
                then
                  -- strip command and whitespace before "<next column>"
                  while oracle_tools.pkg_str_util.dbms_lob_substr(p_clob => l_table_ddl_clob, p_amount => 1, p_offset => l_pos - 1) in (',', ' ', chr(9), chr(10), chr(13))
                  loop
                    l_pos := l_pos - 1;
                  end loop;
                end if;

                -- append part of a clob to another clob
                dbms_lob.copy
                ( dest_lob => l_member_ddl_clob
                , src_lob => l_table_ddl_clob
                , amount => l_pos - l_start
                , dest_offset => 1 + dbms_lob.getlength(l_member_ddl_clob)
                , src_offset => l_start
                );

                if c_use_sqlterminator
                then
                  oracle_tools.pkg_str_util.append_text
                  ( pi_buffer => chr(10) || '/'
                  , pio_clob => l_member_ddl_clob
                  );
                end if;

                -- use the default constructor so we can determine the DDL
                l_member_ddl := oracle_tools.t_table_column_ddl(l_member_object, oracle_tools.t_ddl_tab());
                l_member_ddl.add_ddl
                ( p_verb => 'ALTER'
                , p_text => oracle_tools.pkg_str_util.clob2text(l_member_ddl_clob)
                );

                l_start := l_pos; -- next start position for search
              else
                raise program_error;
              end if;

$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
              l_member_ddl.print();
$end

              l_member_ddl.chk(p_schema_ddl.obj.object_schema());

              p_member_ddl_tab.extend(1);
              p_member_ddl_tab(p_member_ddl_tab.last) := l_member_ddl;
            exception
              when others
              then
$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
                dbug.on_error;
$end
                oracle_tools.pkg_ddl_error.reraise_error('column [' || i_idx || ']: ' || l_member_tab(i_idx).member_name);
            end;
        end case;
      end loop member_loop;
    end if;

    -- type methods
    if p_schema_ddl.obj.object_type() = 'TYPE_SPEC'
    then
      l_statement := '
select  m.method_no as member#
,       m.method_name as member_name
,       m.method_type
,       m.parameters
,       m.results
,       m.final
,       m.instantiable
,       m.overriding
from    all_type_methods' || case when p_schema_ddl.obj.network_link() is not null then '@' || get_db_link(p_schema_ddl.obj.network_link()) end || ' m
where   m.owner = :b1
and     m.type_name = :b2
and     m.inherited = ''NO''
order by
        member#';

      open l_cursor for l_statement using p_schema_ddl.obj.object_schema(), p_schema_ddl.obj.object_name();
      fetch l_cursor bulk collect into l_type_method_tab limit g_max_fetch;
      close l_cursor;

$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
      dbug.print(dbug."info", 'l_type_method_tab.count: %s', l_type_method_tab.count);
$end

      if l_type_method_tab.count > 0
      then
        l_statement := '
select  oracle_tools.t_argument_object
        ( p_argument# => a.position
        , p_argument_name => a.argument_name
        , p_data_type_name => a.data_type
        , p_in_out => a.in_out
        , p_type_owner => a.type_owner
        , p_type_name => a.type_name
        )
from    all_arguments' || case when p_schema_ddl.obj.network_link() is not null then '@' || get_db_link(p_schema_ddl.obj.network_link()) end || ' a
where   a.owner = :b1
and     a.package_name = :b2
and     a.object_name = :b3
and     a.subprogram_id = :b4
and     a.data_level = 0
order by
        a.position';

        for i_idx in l_type_method_tab.first .. l_type_method_tab.last
        loop
$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
          dbug.print(dbug."info", 'l_type_method_tab(%s); member#: %s; member_name: %s', i_idx, l_type_method_tab(i_idx).member#, l_type_method_tab(i_idx).member_name);
$end
          begin
            open l_cursor for l_statement
              using p_schema_ddl.obj.object_schema()
                  , p_schema_ddl.obj.object_name()
                  , l_type_method_tab(i_idx).member_name
                  , l_type_method_tab(i_idx).member#;
            fetch l_cursor bulk collect into l_argument_tab limit g_max_fetch;
            close l_cursor;

            l_type_method_object :=
              oracle_tools.t_type_method_object
              ( p_base_object => treat(p_schema_ddl.obj as oracle_tools.t_named_object)
              , p_member# => l_type_method_tab(i_idx).member#
              , p_member_name => l_type_method_tab(i_idx).member_name
              , p_method_type => l_type_method_tab(i_idx).method_type
              , p_parameters => l_type_method_tab(i_idx).parameters
              , p_results => l_type_method_tab(i_idx).results
              , p_final => l_type_method_tab(i_idx).final
              , p_instantiable => l_type_method_tab(i_idx).instantiable
              , p_overriding => l_type_method_tab(i_idx).overriding
              , p_arguments => l_argument_tab
              );

            l_member_ddl := oracle_tools.t_type_method_ddl(l_type_method_object);

$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
            l_member_ddl.print();
$end

            l_member_ddl.chk(p_schema_ddl.obj.object_schema());

            p_member_ddl_tab.extend(1);
            p_member_ddl_tab(p_member_ddl_tab.last) := l_member_ddl;
          exception
            when others
            then
$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
              dbug.on_error;
$end
              oracle_tools.pkg_ddl_error.reraise_error('attribute [' || i_idx || ']: ' || l_member_tab(i_idx).member_name);
          end;
        end loop;
      end if;
    end if; -- if p_schema_ddl.obj.object_type() = 'TYPE_SPEC'

    cleanup;

$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
    dbug.leave;
$end
  exception
    when others
    then
      cleanup;
$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
      dbug.leave_on_error;
$end
      raise;
  end get_member_ddl;

  procedure do_chk
  ( p_object_type in t_metadata_object_type
  , p_value in boolean
  )
  is
  begin
$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
    dbug.enter(g_package_prefix || 'DO_CHK (1)');
    dbug.print(dbug."input", 'p_object_type: %s; p_value: %s', p_object_type, dbug.cast_to_varchar2(p_value));
$end

    if p_object_type is null
    then
      for i_idx in g_schema_md_object_type_tab.first .. g_schema_md_object_type_tab.last
      loop
        -- no endless recursion
        if g_schema_md_object_type_tab(i_idx) is null
        then
          raise program_error;
        end if;
        do_chk(g_schema_md_object_type_tab(i_idx), p_value);
      end loop;
    else
      g_chk_tab(p_object_type) :=
        case
          when p_object_type = 'OBJECT_GRANT' -- too slow, see oracle_tools.t_object_grant_object
          then 0
          when p_value
          then 1
          else 0
        end;
    end if;

$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
    dbug.leave;
  exception
    when others
    then
      dbug.leave_on_error;
      raise;
$end
  end do_chk;

  function do_chk
  ( p_object_type in t_metadata_object_type
  )
  return boolean
  is
    l_value boolean;
  begin
$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
    dbug.enter(g_package_prefix || 'DO_CHK (2)');
    dbug.print(dbug."input", 'p_object_type: %s', p_object_type);
$end

    l_value := case when g_chk_tab.exists(p_object_type) and g_chk_tab(p_object_type) = 1 then true else false end;

$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
    dbug.print(dbug."output", 'return: %s', l_value);
    dbug.leave;
$end

    return l_value;
  end do_chk;

  procedure chk_schema_object
  ( p_schema_object in oracle_tools.t_schema_object
  , p_schema in varchar2
  )
  is
  begin
$if oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
    dbug.enter(g_package_prefix || 'CHK_SCHEMA_OBJECT (1)');
    dbug.print(dbug."input", 'p_schema_object:');
    p_schema_object.print();
$end

    if p_schema_object.object_type() is null
    then
      oracle_tools.pkg_ddl_error.raise_error
      ( oracle_tools.pkg_ddl_error.c_object_not_valid -- GJP 2023-01-06 oracle_tools.pkg_ddl_error.c_invalid_parameters
      , 'Object type should not be empty'
      , p_schema_object.schema_object_info()
      );
    elsif p_schema_object.dict2metadata_object_type() = p_schema_object.object_type()
    then
      null; -- ok
    else
      oracle_tools.pkg_ddl_error.raise_error
      ( oracle_tools.pkg_ddl_error.c_object_not_valid -- GJP 2023-01-06 oracle_tools.pkg_ddl_error.c_invalid_parameters
      , 'Object type (' ||
        p_schema_object.object_type() ||
        ') should be equal to this DBMS_METADATA object type (' ||
        p_schema_object.dict2metadata_object_type() ||
        ')'
      , p_schema_object.schema_object_info()  
      );
    end if;

    if (p_schema_object.base_object_type() is null) != (p_schema_object.base_object_schema() is null)
    then
      oracle_tools.pkg_ddl_error.raise_error
      ( oracle_tools.pkg_ddl_error.c_object_not_valid -- GJP 2023-01-06 oracle_tools.pkg_ddl_error.c_invalid_parameters
      , 'Base object type (' ||
        p_schema_object.base_object_type() ||
        ') and base object schema (' ||
        p_schema_object.base_object_schema() ||
        ') must both be empty or both not empty'
      , p_schema_object.schema_object_info()  
      );
    end if;

    if (p_schema_object.base_object_name() is null) != (p_schema_object.base_object_schema() is null)
    then
      oracle_tools.pkg_ddl_error.raise_error
      ( oracle_tools.pkg_ddl_error.c_object_not_valid -- GJP 2023-01-06 oracle_tools.pkg_ddl_error.c_invalid_parameters
      , 'Base object name (' ||
        p_schema_object.base_object_name() ||
        ') and base object schema (' ||
        p_schema_object.base_object_schema() ||
        ') must both be empty or both not empty'
      , p_schema_object.schema_object_info()  
      );
    end if;

$if oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
    dbug.leave;
  exception
    when others
    then
      dbug.leave_on_error;
      raise;
$end
  end chk_schema_object;

  procedure chk_schema_object
  ( p_dependent_or_granted_object in oracle_tools.t_dependent_or_granted_object
  , p_schema in varchar2
  )
  is
  begin
$if oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
    dbug.enter(g_package_prefix || 'CHK_SCHEMA_OBJECT (2)');
$end

    chk_schema_object(p_schema_object => p_dependent_or_granted_object, p_schema => p_schema);

    if p_dependent_or_granted_object.object_schema() is null or p_dependent_or_granted_object.object_schema() = p_schema
    then
      null; -- ok
    else
      oracle_tools.pkg_ddl_error.raise_error
      ( oracle_tools.pkg_ddl_error.c_object_not_valid -- GJP 2023-01-06 oracle_tools.pkg_ddl_error.c_invalid_parameters
      , 'Object schema should be empty or ' || p_schema
      , p_dependent_or_granted_object.schema_object_info()
      );
    end if;

    if p_dependent_or_granted_object.base_object_seq$ is null
    then
      oracle_tools.pkg_ddl_error.raise_error
      ( oracle_tools.pkg_ddl_error.c_object_not_valid -- GJP 2023-01-06 oracle_tools.pkg_ddl_error.c_invalid_parameters
      , 'Base object should not be empty.'
      , p_dependent_or_granted_object.schema_object_info()
      );
    end if;

    -- GPA 2017-01-18 too strict for triggers, synonyms, indexes, etc.
    /*
    if p_dependent_or_granted_object.base_object_schema() = p_schema
    then
      null; -- ok
    else
      raise_application_error(oracle_tools.pkg_ddl_error.c_invalid_parameters, 'Base object schema must be ' || p_schema);
    end if;
    */

    if p_dependent_or_granted_object.base_object_schema() is null
    then
      oracle_tools.pkg_ddl_error.raise_error
      ( oracle_tools.pkg_ddl_error.c_object_not_valid -- GJP 2023-01-06 oracle_tools.pkg_ddl_error.c_invalid_parameters
      , 'Base object schema should not be empty'
      , p_dependent_or_granted_object.schema_object_info()
      );
    end if;

    if p_dependent_or_granted_object.base_object_type() is null
    then
      oracle_tools.pkg_ddl_error.raise_error
      ( oracle_tools.pkg_ddl_error.c_object_not_valid -- GJP 2023-01-06 oracle_tools.pkg_ddl_error.c_invalid_parameters
      , 'Base object type should not be empty'
      , p_dependent_or_granted_object.schema_object_info()
      );
    end if;

    if p_dependent_or_granted_object.base_object_name() is null
    then
      oracle_tools.pkg_ddl_error.raise_error
      ( oracle_tools.pkg_ddl_error.c_object_not_valid -- GJP 2023-01-06 oracle_tools.pkg_ddl_error.c_invalid_parameters
      , 'Base object name should not be empty'
      , p_dependent_or_granted_object.schema_object_info()
      );
    end if;

$if oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
    dbug.leave;
  exception
    when others
    then
      dbug.leave_on_error;
      raise;
$end
  end chk_schema_object;

  procedure chk_schema_object
  ( p_named_object in oracle_tools.t_named_object
  , p_schema in varchar2
  )
  is
$if oracle_tools.pkg_ddl_util.c_#140920801 $then
    -- Capture invalid objects before releasing to next enviroment.
    l_status all_objects.status%type := null;
$end  
  begin
$if oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
    dbug.enter(g_package_prefix || 'CHK_SCHEMA_OBJECT (3)');
$end

    chk_schema_object(p_schema_object => p_named_object, p_schema => p_schema);

    if p_named_object.object_name() is null
    then
      oracle_tools.pkg_ddl_error.raise_error
      ( oracle_tools.pkg_ddl_error.c_object_not_valid -- GJP 2023-01-06 oracle_tools.pkg_ddl_error.c_invalid_parameters
      , 'Object name should not be empty'
      , p_named_object.schema_object_info()
      );
    end if;
    if p_named_object.object_schema() = p_schema
    then
      null; -- ok
    else
      oracle_tools.pkg_ddl_error.raise_error
      ( oracle_tools.pkg_ddl_error.c_object_not_valid -- GJP 2023-01-06 oracle_tools.pkg_ddl_error.c_invalid_parameters
      , 'Object schema (' ||
        p_named_object.object_schema() ||
        ') must be ' ||
        p_schema
      , p_named_object.schema_object_info()
      );
    end if;

$if oracle_tools.pkg_ddl_util.c_#140920801 $then

    -- Capture invalid objects before releasing to next enviroment.
    if oracle_tools.pkg_ddl_util.do_chk(p_named_object.object_type()) and p_named_object.network_link() is null
    then
      begin
        select  obj.status
        into    l_status
        from    all_objects obj
        where   obj.owner = p_named_object.object_schema()
        and     obj.object_type = p_named_object.dict_object_type()
        and     obj.object_name = p_named_object.object_name()
$if oracle_tools.pkg_ddl_util.c_exclude_system_objects $then
        and     obj.generated = 'N' -- GPA 2016-12-19 #136334705
$end        
        ;
        if l_status = 'VALID'
        then
          null;
        else
          raise value_error;
        end if;
      exception
        when no_data_found
        then null;

        when value_error
        then
          oracle_tools.pkg_ddl_error.raise_error
          ( oracle_tools.pkg_ddl_error.c_object_not_valid
          , 'Object status (' ||
            l_status ||
            ') must be VALID'
          , p_named_object.schema_object_info()
          );
      end;
    end if;

$end

$if oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
    dbug.leave;
  exception
    when others
    then
      dbug.leave_on_error;
      raise;
$end
  end chk_schema_object;

  procedure chk_schema_object
  ( p_constraint_object in oracle_tools.t_constraint_object
  , p_schema in varchar2
  )
  is
    l_error_message varchar2(2000 char) := null;
  begin
$if oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
    dbug.enter(g_package_prefix || 'CHK_SCHEMA_OBJECT (4)');
$end

    oracle_tools.pkg_ddl_util.chk_schema_object(p_dependent_or_granted_object => p_constraint_object, p_schema => p_schema);

    if p_constraint_object.object_schema() = p_schema
    then
      null; -- ok
    else
      l_error_message := 'Object schema (' || p_constraint_object.object_schema() || ') must be ' || p_schema;
    end if;
    if p_constraint_object.base_object_schema() is null
    then
      l_error_message := 'Base object schema should not be empty.';
    end if;
    if p_constraint_object.constraint_type() is null
    then
      l_error_message := 'Constraint type should not be empty.';
    end if;

    case 
      when p_constraint_object.constraint_type() in ('P', 'U', 'R')
      then
        if p_constraint_object.column_names() is null
        then
          l_error_message := 'Column names should not be empty';
        end if;
        if p_constraint_object.search_condition() is not null
        then
          l_error_message := 'Search condition should be empty';
        end if;

      when p_constraint_object.constraint_type() in ('C')
      then
        if p_constraint_object.column_names() is not null
        then
          l_error_message := 'Column names should be empty';
        end if;
        if p_constraint_object.search_condition() is null
        then
          l_error_message := 'Search condition should not be empty';
        end if;

    end case;

    if l_error_message is not null
    then
      oracle_tools.pkg_ddl_error.raise_error
      ( oracle_tools.pkg_ddl_error.c_object_not_valid -- GJP 2023-01-06 oracle_tools.pkg_ddl_error.c_invalid_parameters
      , l_error_message
      , p_constraint_object.schema_object_info()
      );
    end if;

$if oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
    dbug.leave;
  exception
    when others
    then
      dbug.leave_on_error;
      raise;
$end
  end chk_schema_object;

  function is_dependent_object_type
  ( p_object_type in t_metadata_object_type
  )
  return t_numeric_boolean
  deterministic
  is
  begin
    return
      case
        when p_object_type in ('INDEX', 'TRIGGER')
        then null /* zowel standaard als dependent object */
        when p_object_type in ('OBJECT_GRANT', 'COMMENT', 'CONSTRAINT', 'REF_CONSTRAINT')
        then 1 /* alleen op te vragen via base object */
        else 0
      end;
  end is_dependent_object_type;

  procedure get_exclude_name_expr_tab
  ( p_object_type in varchar2
  , p_object_name in varchar2 default null
  , p_exclude_name_expr_tab out nocopy oracle_tools.t_text_tab
  )
  is
  begin
    if not(g_object_exclude_name_expr_tab.exists(p_object_type))
    then
      p_exclude_name_expr_tab := oracle_tools.t_text_tab();
    else
      if p_object_name is null
      then
        p_exclude_name_expr_tab := g_object_exclude_name_expr_tab(p_object_type);
      else
        p_exclude_name_expr_tab := oracle_tools.t_text_tab();
        for i_idx in g_object_exclude_name_expr_tab(p_object_type).first .. g_object_exclude_name_expr_tab(p_object_type).last
        loop
          if p_object_name like g_object_exclude_name_expr_tab(p_object_type)(i_idx) escape '\'
          then
            p_exclude_name_expr_tab.extend(1);
            p_exclude_name_expr_tab(p_exclude_name_expr_tab.last) := g_object_exclude_name_expr_tab(p_object_type)(i_idx);
          end if;
        end loop;
      end if;
    end if;
  end get_exclude_name_expr_tab;

  function is_exclude_name_expr
  ( p_object_type in t_metadata_object_type
  , p_object_name in t_object_name
  )
  return integer
  deterministic
  is
    l_result integer;
    l_exclude_name_expr_tab oracle_tools.t_text_tab;
  begin
$if oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
    dbug.enter(g_package_prefix || 'IS_EXCLUDE_NAME_EXPR');
    dbug.print(dbug."input", 'p_object_type: %s; p_object_name: %s', p_object_type, p_object_name);    
$end

    get_exclude_name_expr_tab(p_object_type => p_object_type, p_object_name => p_object_name, p_exclude_name_expr_tab => l_exclude_name_expr_tab);
    l_result := sign(l_exclude_name_expr_tab.count); -- when 0 return 0; when > 0 return 1

$if oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
    dbug.print(dbug."output", 'return: %s', l_result);
    dbug.leave;
$end

    return l_result;
  end is_exclude_name_expr;

  /*
  -- Help function to get the DDL belonging to a list of allowed objects returned by get_schema_objects()
  */
  function fetch_ddl
  ( p_object_type in varchar2
  , p_object_schema in varchar2
  , p_object_name_tab in oracle_tools.t_text_tab
  , p_base_object_schema in varchar2
  , p_base_object_name_tab in oracle_tools.t_text_tab
  , p_transform_param_list in varchar2
  )
  return sys.ku$_ddls
  pipelined
  is
    -- ORA-31642: the following SQL statement fails:
    -- BEGIN "SYS"."DBMS_SCHED_EXPORT_CALLOUTS".SCHEMA_CALLOUT(:1,1,1,'11.02.00.00.00'); END;
    -- ORA-06512: at "SYS.DBMS_SYS_ERROR", line 86
    -- ORA-06512: at "SYS.DBMS_METADATA", line 1225
    -- ORA-04092: cannot COMMIT in a trigger
    pragma autonomous_transaction;
    
    l_handle number := null;

    l_transform_param_tab t_transform_param_tab;
  begin
    get_transform_param_tab(p_transform_param_list, l_transform_param_tab);
    
    md_open
    ( p_object_type => p_object_type
    , p_object_schema => p_object_schema
    , p_object_name_tab => p_object_name_tab
    , p_base_object_schema => p_base_object_schema
    , p_base_object_name_tab => p_base_object_name_tab
    , p_transform_param_tab => l_transform_param_tab
    , p_handle => l_handle
    );

    -- objects fetched for this param
    <<fetch_loop>>
    loop
      md_fetch_ddl(l_handle, true);

      exit fetch_loop when g_ddl_tab is null;

      if g_ddl_tab.count > 0
      then
        for i_ku$ddls_idx in g_ddl_tab.first .. g_ddl_tab.last
        loop
          pipe row (g_ddl_tab(i_ku$ddls_idx));
        end loop;
      end if;
    end loop fetch_loop;

    md_close(l_handle);
  exception
    when no_data_needed
    then
      if l_handle is not null
      then
        md_close(l_handle);
      end if;
      
    when others
    then
      if l_handle is not null
      then
        md_close(l_handle);
      end if;
      if p_object_type = 'SCHEMA_EXPORT'
      then
        null;
      else
        raise;
      end if;
  end fetch_ddl;

  /*
  -- Help functions to get the DDL belonging to a list of allowed objects returned by get_schema_objects()
  */
  function get_schema_ddl
  ( p_schema in varchar2 default user
  , p_object_type in varchar2 default null
  , p_object_names in varchar2 default null
  , p_object_names_include in integer default null
  , p_grantor_is_schema in integer default 0
  , p_exclude_objects in clob default null
  , p_include_objects in clob default null
  , p_transform_param_list in varchar2 default c_transform_param_list
  )
  return oracle_tools.t_schema_ddl_tab  
  pipelined
  is
    l_schema_object_filter oracle_tools.t_schema_object_filter;
    l_schema_object_tab oracle_tools.t_schema_object_tab;
  begin
    l_schema_object_filter :=
      oracle_tools.t_schema_object_filter
      ( p_schema => p_schema
      , p_object_type => p_object_type
      , p_object_names => p_object_names
      , p_object_names_include => p_object_names_include
      , p_grantor_is_schema => p_grantor_is_schema
      , p_exclude_objects => p_exclude_objects
      , p_include_objects => p_include_objects
      );
    oracle_tools.pkg_schema_object_filter.get_schema_objects
    ( p_schema_object_filter => l_schema_object_filter
    , p_schema_object_tab => l_schema_object_tab
    );
    for r in
    ( select  value(t) as obj
      from    table
              ( oracle_tools.pkg_ddl_util.get_schema_ddl
                ( p_schema_object_filter => l_schema_object_filter
                , p_schema_object_tab => l_schema_object_tab
                , p_transform_param_list => p_transform_param_list
                )
              ) t
    )
    loop
      pipe row (r.obj);
    end loop;
    return;
  end get_schema_ddl;
  
  function get_schema_ddl
  ( p_schema_object_filter in oracle_tools.t_schema_object_filter
  , p_schema_object_tab in oracle_tools.t_schema_object_tab
  , p_transform_param_list in varchar2
  )
  return oracle_tools.t_schema_ddl_tab
  pipelined
  is
    l_program constant t_module := 'GET_SCHEMA_DDL'; -- geen schema omdat l_program in dbms_application_info wordt gebruikt

    -- GJP 2022-12-15

    -- DBMS_METADATA DDL generation with SCHEMA_EXPORT export does not provide CONSTRAINTS AS ALTER.
    -- https://github.com/paulissoft/oracle-tools/issues/98
    -- Solve that by adding the individual objects as well but quitting as soon as possible.

    l_use_schema_export t_numeric_boolean_nn := 0;
    l_schema_object_tab oracle_tools.t_schema_object_tab := null;
    l_object_lookup_tab t_object_lookup_tab; -- list of all objects
    l_constraint_lookup_tab t_constraint_lookup_tab;
    l_object_key t_object;
    l_nr_objects_countdown positiven := 1; -- any value > 0 will do, see init()

    cursor c_params
    ( b_schema in varchar2
    , b_use_schema_export in t_numeric_boolean_nn
    , b_schema_object_tab in oracle_tools.t_schema_object_tab
    ) is
      select  object_type
      ,       object_schema
      ,       base_object_schema
      ,       object_name_tab
      ,       base_object_name_tab
      ,       nr_objects
      from    ( with src as
                ( select  'SCHEMA_EXPORT' as object_type
                  ,       b_schema as object_schema
                  ,       null as object_name
                  ,       null as base_object_schema
                  ,       null as base_object_name
                  ,       null as column_name -- to get the count right
                  ,       null as grantee -- to get the count right
                  ,       null as privilege -- to get the count right
                  ,       null as grantable -- to get the count right
                  from    dual
                  where   b_use_schema_export != 0
                  union all
                  select  t.object_type()
                  ,       case
                            when t.object_type() in ('CONSTRAINT', 'REF_CONSTRAINT')
                            then null
                            else t.object_schema()
                          end as object_schema
                  ,       case
                            when t.object_type() in ('CONSTRAINT', 'REF_CONSTRAINT')
                            then null
                            else t.object_name()
                          end as object_name
                  ,       case
                            when t.object_type() in ('INDEX', 'TRIGGER')
                            then null
                            when t.object_type() = 'SYNONYM' and t.object_schema() = b_schema
                            then null
                            else t.base_object_schema()
                          end as base_object_schema
                  ,       case
                            when t.object_type() in ('INDEX', 'TRIGGER') and t.object_schema() = b_schema
                            then null
                            when t.object_type() = 'SYNONYM' and t.object_schema() = b_schema
                            then null
                            else t.base_object_name()
                          end as base_object_name
                  ,       t.column_name()
                  ,       t.grantee()
                  ,       t.privilege()
                  ,       t.grantable()
                  from    table(b_schema_object_tab) t
                  where   b_use_schema_export = 0
                )
                select  t.object_type
                ,       t.object_schema
                ,       t.base_object_schema
                ,       cast
                        ( multiset
                          ( select  l.object_name
                            from    src l
                            where   l.object_type || 'X' = t.object_type || 'X' -- null == null
                            and     l.object_schema || 'X' = t.object_schema || 'X'
                            and     l.base_object_schema || 'X' = t.base_object_schema || 'X'
                            and     l.object_name is not null
                          ) as oracle_tools.t_text_tab
                        ) as object_name_tab
                ,       cast
                        ( multiset
                          ( select  l.base_object_name
                            from    src l
                            where   l.object_type || 'X' = t.object_type || 'X' -- null == null
                            and     l.object_schema || 'X' = t.object_schema || 'X'
                            and     l.base_object_schema || 'X' = t.base_object_schema || 'X'
                            and     l.base_object_name is not null
                          ) as oracle_tools.t_text_tab
                        ) as base_object_name_tab
                ,       count(*) as nr_objects
                from    src t
                group by
                        t.object_type
                ,       t.object_schema
                ,       t.base_object_schema
              )
      order by
              case object_schema when 'PUBLIC' then 0 when b_schema then 1 else 2 end -- PUBLIC synonyms first
      ,       case object_type
                when 'SCHEMA_EXPORT' then 0
                else 1
              end -- SCHEMA_EXPORT next
      ,       object_type
      ,       object_schema
      ,       base_object_schema
    ;

    type t_params_tab is table of c_params%rowtype;

    l_params_tab t_params_tab;
    r_params c_params%rowtype;
    l_params_idx pls_integer;

    -- dbms_application_info stuff
    l_longops_rec t_longops_rec;

    procedure init(p_schema_object_tab in oracle_tools.t_schema_object_tab)
    is
      l_schema_object oracle_tools.t_schema_object;
      l_ref_constraint_object oracle_tools.t_ref_constraint_object;
    begin
$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
      dbug.enter(g_package_prefix || l_program || '.INIT');
$end

      if p_schema_object_tab is not null and p_schema_object_tab.count > 0
      then
        for i_idx in p_schema_object_tab.first .. p_schema_object_tab.last
        loop
          begin
            l_schema_object := p_schema_object_tab(i_idx);

            l_schema_object.chk(p_schema_object_filter.schema());

            l_object_key := l_schema_object.id();

            if not l_object_lookup_tab.exists(l_object_key)
            then
              -- Here we initialise l_object_lookup_tab(l_object_key).schema_ddl.
              -- l_object_lookup_tab(l_object_key).count will be 0 (default).
              -- l_object_lookup_tab(l_object_key).ready will be false (default).
              oracle_tools.t_schema_ddl.create_schema_ddl
              ( p_obj => l_schema_object
              , p_ddl_tab => oracle_tools.t_ddl_tab()
              , p_schema_ddl => l_object_lookup_tab(l_object_key).schema_ddl
              );
            else
              raise dup_val_on_index;
            end if;

$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
            l_schema_object.print();
$end

            -- now we are going to store constraints for faster lookup in parse_ddl()
            if l_schema_object.object_type() in ('CONSTRAINT', 'REF_CONSTRAINT')
            then
              -- not by constraint name (dbms_metadata does not supply that) but by signature
              l_object_key := l_schema_object.signature();

              if not l_constraint_lookup_tab.exists(l_object_key)
              then
                l_constraint_lookup_tab(l_object_key) := l_schema_object.id();
              else
                raise dup_val_on_index;
              end if;
            end if;
          exception
            when others
            then oracle_tools.pkg_ddl_error.reraise_error('Object id: ' || l_schema_object.id() || chr(10) || 'Object signature: ' || l_object_key);
          end;  
        end loop;
      end if;

      begin
        l_nr_objects_countdown := l_object_lookup_tab.count;
      exception
        when value_error
        then
          -- no objects to lookup
          raise no_data_found;
      end;

$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
      dbug.leave;
    exception
      when others
      then
        dbug.leave_on_error;
        raise;
$end
    end init;

    procedure cleanup
    is
    begin
      if c_params%isopen
      then
        close c_params;
      end if;
    end cleanup;
  begin
$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
    dbug.enter(g_package_prefix || l_program);
    dbug.print
    ( dbug."input"
    , 'p_schema: %s; p_schema_object_tab.count: %s'
    , p_schema_object_filter.schema()
    , case when p_schema_object_tab is not null then p_schema_object_tab.count end
    );
$end

$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
    dbug.print
    ( dbug."info"
    , 'p_schema_object_filter.match_perc(): %s; p_schema_object_filter.match_perc_threshold: %s'
    , p_schema_object_filter.match_perc()
    , p_schema_object_filter.match_perc_threshold()
    );
$end

    -- now we can calculate the percentage matches (after get_schema_objects)
    l_use_schema_export :=
      case
        when p_schema_object_filter.match_perc() >= p_schema_object_filter.match_perc_threshold()
        then 1
        else 0
      end;

    init(p_schema_object_tab);

    l_longops_rec := oracle_tools.api_longops_pkg.longops_init
                     ( p_op_name => 'fetch'
                     , p_units => 'objects'
                     , p_target_desc => l_program
                     , p_totalwork => l_object_lookup_tab.count
                     );

    -- GJP 2022-12-17 Note SCHEMA_EXPORT.
    -- Under some circumstances just a SCHEMA_EXPORT does not do the job,
    -- for instance when named not null constraints do not show up as
    -- ALTER TABLE commands although we have asked DBMS_METADATA to do so.
    -- In that case we will try the other variant as well as long
    -- as there are objects to retrieve DDL for (l_nr_objects_countdown > 0).
    -- We may as well generalise that: if you start with use_schema_export
    -- being 1, you may try use_schema_export 0 later. And vice versa.
    -- So just a loop of two values and we quit the loop as soon as the
    -- countdown is 0.
    <<outer_loop>>
    for i_use_schema_export in l_use_schema_export .. l_use_schema_export+1
    loop
$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
      dbug.enter(g_package_prefix || l_program || '.EXPORT.' || i_use_schema_export);
$end

$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
      dbug.print
      ( dbug."info"
      , 'i_use_schema_export: %s; l_use_schema_export: %s'
      , i_use_schema_export
      , l_use_schema_export
      );
$end

      -- sanity check
      if mod(i_use_schema_export, 2) = 0 and l_schema_object_tab is null and p_schema_object_tab is null
      then
        raise program_error;
      end if;
          
      open c_params
      ( p_schema_object_filter.schema()
      , mod(i_use_schema_export, 2) -- so it will always be 0 or 1
      , case mod(i_use_schema_export, 2)
          when 0 then nvl(l_schema_object_tab, p_schema_object_tab) -- yes, first l_schema_object_tab, see end of params_loop
          else null -- not relevant for SCHEMA_EXPORT
        end
      );

      <<params_loop>>
      loop
        fetch c_params bulk collect into l_params_tab limit g_max_fetch;

$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
        dbug.print(dbug."debug", 'l_params_tab.count: %s', l_params_tab.count);
$end
        
        l_params_idx := l_params_tab.first;
        <<param_loop>>
        loop
          exit param_loop when l_params_idx is null;

          r_params := l_params_tab(l_params_idx);

$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
          dbug.print
          ( dbug."debug"
          , 'r_params.object_type: %s; r_params.object_schema: %s; r_params.base_object_schema: %s: r_params.object_name_tab.count: %s; r_params.base_object_name_tab.count: %s'
          , r_params.object_type
          , r_params.object_schema
          , r_params.base_object_schema
          , r_params.object_name_tab.count
          , r_params.base_object_name_tab.count
          );
          dbug.print
          ( dbug."debug"
          , 'r_params.nr_objects: %s'
          , r_params.nr_objects
          );
$end

          <<fetch_loop>>
          for r in
          ( select  value(t) as obj
            from    table
                    ( oracle_tools.pkg_ddl_util.fetch_ddl
                      ( p_object_type => r_params.object_type
                      , p_object_schema => r_params.object_schema
                      , p_object_name_tab => r_params.object_name_tab
                      , p_base_object_schema => r_params.base_object_schema
                      , p_base_object_name_tab => r_params.base_object_name_tab
                      , p_transform_param_list => p_transform_param_list
                      )
                    ) t
          )
          loop
            begin
              parse_object
              ( p_schema_object_filter => p_schema_object_filter
              , p_constraint_lookup_tab => l_constraint_lookup_tab
              , p_object_lookup_tab => l_object_lookup_tab
              , p_ku$_ddl => r.obj
              , p_object_key => l_object_key
              );

              if l_object_key is not null
              then
                -- some checks
                if not(l_object_lookup_tab.exists(l_object_key))
                then
                  raise_application_error
                  ( oracle_tools.pkg_ddl_error.c_object_not_found
                  , 'Can not find object with key "' || l_object_key || '"'
                  );
                end if;

                if not(l_object_lookup_tab(l_object_key).ready)
                then
                  pipe row (l_object_lookup_tab(l_object_key).schema_ddl);
                  l_object_lookup_tab(l_object_key).ready := true;
                  begin
                    l_nr_objects_countdown := l_nr_objects_countdown - 1;

$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
                    dbug.print(dbug."info", '# objects to go: %s', l_nr_objects_countdown);
$end         
                  exception
                    when value_error -- tried to set it to 0 (it is positiven i.e. always > 0): we are ready
                    then
                    -- every object in l_object_lookup_tab is ready
$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
                      dbug.print(dbug."info", 'all schema DDL fetched');
$end
                      exit outer_loop;
                  end;
                end if;
              end if;

              oracle_tools.api_longops_pkg.longops_show(l_longops_rec, 0);
            exception
              when oracle_tools.pkg_ddl_error.e_object_not_found
              then
$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
                l_object_key := l_object_lookup_tab.first;
                <<object_loop>>
                while l_object_key is not null
                loop
                  dbug.print
                  ( dbug."debug"
                  , 'Object key: %s'
                  , l_object_key
                  );
                  l_object_key := l_object_lookup_tab.next(l_object_key);
                end loop object_loop;
$end        
                raise;
            end;
          end loop fetch_loop;

          l_params_idx := l_params_tab.next(l_params_idx);
        end loop param_loop;
        
        exit params_loop when l_params_tab.count < g_max_fetch; -- next fetch will return 0
      end loop params_loop;
      
      close c_params;

      -- Apparently we are not done.
      -- 1) first iteration (i_use_schema_export = l_use_schema_export) with SCHEMA_EXPORT:
      --    construct a schema object list with just the missing objects and
      --    execute the second iteration
      -- 2) second iteration (i_use_schema_export != l_use_schema_export):
      --    just output the objects with missing DDL (better than to throw an exception)
      --    and add a comment (-- No DDL retrieved.)
      
      if i_use_schema_export = l_use_schema_export
      then
        if l_use_schema_export = 1 -- case 1, next iteration uses l_schema_object_tab
        then
          l_schema_object_tab := oracle_tools.t_schema_object_tab();
        else
          l_schema_object_tab := null;
        end if;  
      end if;
        
      l_object_key := l_object_lookup_tab.first;
      while l_object_key is not null
      loop
        if not(l_object_lookup_tab(l_object_key).ready)
        then
          if i_use_schema_export != l_use_schema_export
          then
            -- case 2
            -- add comment otherwise the schema DDL table is empty and will this object never be displayed
            l_object_lookup_tab(l_object_key).schema_ddl.add_ddl
            ( p_verb => '--'
            , p_text => '-- No DDL retrieved.'
            );

            pipe row (l_object_lookup_tab(l_object_key).schema_ddl);
          elsif l_use_schema_export = 1
          then
            -- case 1
            l_schema_object_tab.extend(1);
            l_schema_object_tab(l_schema_object_tab.last) := l_object_lookup_tab(l_object_key).schema_ddl.obj;
          end if;          
        end if;
        l_object_key := l_object_lookup_tab.next(l_object_key);
      end loop;
      
$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
      dbug.leave;
$end
    end loop outer_loop;
    
    -- overall
    oracle_tools.api_longops_pkg.longops_done(l_longops_rec);

$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
    dbug.leave;
$end

    cleanup;

    return; -- essential for a pipelined function
  exception
    when no_data_needed
    then
      cleanup;
$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
      dbug.leave;
$end
      -- no need to reraise

    when no_data_found
    then
      cleanup;
$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
      dbug.leave_on_error;
$end
      -- GJP 2022-12-29
$if oracle_tools.pkg_ddl_util.c_err_pipelined_no_data_found $then
      oracle_tools.pkg_ddl_error.reraise_error(l_program);
$else      
      null;
$end      

    when others
    then
      cleanup;
$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
      dbug.leave_on_error;
$end
      raise;
  end get_schema_ddl;

  /*
  -- Help procedure to store the results of display_ddl_schema on a remote database.
  */
  procedure set_display_ddl_schema_args
  ( p_exclude_objects in clob
  , p_include_objects in clob
  )
  is
  begin
    oracle_tools.pkg_str_util.split
    ( p_str => p_exclude_objects
    , p_delimiter => chr(10)
    , p_str_tab => g_exclude_objects
    );
    oracle_tools.pkg_str_util.split
    ( p_str => p_include_objects
    , p_delimiter => chr(10)
    , p_str_tab => g_include_objects
    );
  end set_display_ddl_schema_args;
  
  procedure get_display_ddl_schema_args
  ( p_exclude_objects out nocopy dbms_sql.varchar2a
  , p_include_objects out nocopy dbms_sql.varchar2a
  )
  is
  begin
    p_exclude_objects := g_exclude_objects;
    p_include_objects := g_include_objects;
  end get_display_ddl_schema_args;
  
  procedure set_display_ddl_schema_args
  ( p_schema in t_schema_nn
  , p_new_schema in t_schema
  , p_sort_objects_by_deps in t_numeric_boolean_nn
  , p_object_type in t_metadata_object_type
  , p_object_names in t_object_names
  , p_object_names_include in t_numeric_boolean
  , p_network_link in t_network_link_nn
  , p_grantor_is_schema in t_numeric_boolean_nn
  , p_transform_param_list in varchar2
  , p_exclude_objects in clob
  , p_include_objects in clob
  )
  is
    l_network_link all_db_links.db_link%type := null;
    l_cursor integer := dbms_sql.open_cursor;
    l_statement varchar2(4000 char) := null;
    l_dummy integer;
    l_sqlcode integer := null;
    l_sqlerrm varchar2(32767 char) := null;
    l_error_backtrace varchar2(32767 char) := null;

    procedure cleanup
    is
    begin
      if l_cursor is not null
      then
        dbms_sql.close_cursor(l_cursor);
        l_cursor := null;
      end if;
    end cleanup;
  begin
    -- check whether database link exists
    check_network_link(p_network_link);
    l_network_link := get_db_link(p_network_link);

    if l_network_link is null
    then
      raise program_error;
    end if;

    l_network_link := oracle_tools.data_api_pkg.dbms_assert$simple_sql_name(l_network_link, 'database link');

    set_display_ddl_schema_args
    ( p_exclude_objects => p_exclude_objects
    , p_include_objects => p_include_objects
    );
 
    l_statement :=
      utl_lms.format_message
      ( '
declare
  l_exclude_objects dbms_sql.varchar2a;
  l_include_objects dbms_sql.varchar2a;
  l_exclude_objects_r dbms_sql.varchar2a@%s;
  l_include_objects_r dbms_sql.varchar2a@%s;
begin
  oracle_tools.pkg_ddl_util.get_display_ddl_schema_args
  ( p_exclude_objects => l_exclude_objects
  , p_include_objects => l_include_objects
  );
  if l_exclude_objects.count > 0
  then
    for i_idx in l_exclude_objects.first .. l_exclude_objects.last
    loop
      l_exclude_objects_r(i_idx) := l_exclude_objects(i_idx);
    end loop;
  end if;
  if l_include_objects.count > 0
  then
    for i_idx in l_include_objects.first .. l_include_objects.last
    loop
      l_include_objects_r(i_idx) := l_include_objects(i_idx);
    end loop;
  end if;
  oracle_tools.pkg_ddl_util.set_display_ddl_schema_args_r@%s
  ( p_schema => :b01
  , p_new_schema => :b02
  , p_sort_objects_by_deps => :b03
  , p_object_type => :b04
  , p_object_names => :b05
  , p_object_names_include => :b06
  , p_grantor_is_schema => :b07
  , p_transform_param_list => :b08
  , p_exclude_objects => l_exclude_objects_r
  , p_include_objects => l_include_objects_r
  );
exception
  when others
  then
    :b09 := sqlcode;
    :b10 := sqlerrm;
    :b11 := dbms_utility.format_error_backtrace;
    raise;
end;'
      , l_network_link
      , l_network_link
      , l_network_link
      );
    oracle_tools.api_pkg.dbms_output_enable(l_network_link);
    oracle_tools.api_pkg.dbms_output_clear(l_network_link);

$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
    dbug.print(dbug."info", 'l_statement: %', l_statement);
$end

    dbms_sql.parse(l_cursor, l_statement, dbms_sql.native);

    dbms_sql.bind_variable(l_cursor, ':b01', p_schema);
    dbms_sql.bind_variable(l_cursor, ':b02', p_new_schema);
    dbms_sql.bind_variable(l_cursor, ':b03', p_sort_objects_by_deps);
    dbms_sql.bind_variable(l_cursor, ':b04', p_object_type);
    dbms_sql.bind_variable(l_cursor, ':b05', p_object_names);
    dbms_sql.bind_variable(l_cursor, ':b06', p_object_names_include);
    dbms_sql.bind_variable(l_cursor, ':b07', p_grantor_is_schema);
    dbms_sql.bind_variable(l_cursor, ':b08', p_transform_param_list);
    -- output bind variables must be bound as well
    dbms_sql.bind_variable(l_cursor, ':b09', l_sqlcode);
    dbms_sql.bind_variable(l_cursor, ':b10', l_sqlerrm);
    dbms_sql.bind_variable(l_cursor, ':b11', l_error_backtrace);
    l_dummy := dbms_sql.execute(l_cursor);
    dbms_sql.variable_value(l_cursor, ':b09', l_sqlcode);
    dbms_sql.variable_value(l_cursor, ':b10', l_sqlerrm);
    dbms_sql.variable_value(l_cursor, ':b11', l_error_backtrace);
    
    oracle_tools.api_pkg.dbms_output_flush(l_network_link);
    cleanup;
    
$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
    dbug.leave;
$end
  exception
    when others
    then    
      oracle_tools.api_pkg.dbms_output_flush(l_network_link);
      cleanup;
      
$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
      dbug.print(dbug."error", 'remote error: %s', l_sqlcode);
      dbug.print(dbug."error", 'remote error message: %s', l_sqlerrm);
      dbug.print(dbug."error", 'remote error backtrace: %s', l_error_backtrace);
      dbug.leave_on_error;
$end

      raise_application_error(oracle_tools.pkg_ddl_error.c_execute_via_db_link, l_statement, true);
      raise; -- to keep the compiler happy
  end set_display_ddl_schema_args;

  procedure set_display_ddl_schema_args_r
  ( p_schema in t_schema_nn
  , p_new_schema in t_schema
  , p_sort_objects_by_deps in t_numeric_boolean_nn
  , p_object_type in t_metadata_object_type
  , p_object_names in t_object_names
  , p_object_names_include in t_numeric_boolean /* OK (remote no copying of types) */
  , p_grantor_is_schema in t_numeric_boolean_nn
  , p_transform_param_list in varchar2
  , p_exclude_objects in dbms_sql.varchar2a
  , p_include_objects in dbms_sql.varchar2a
  )
  is
    l_exclude_objects clob;
    l_include_objects clob;
    l_cursor sys_refcursor;
  begin
$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
    dbug.enter(g_package_prefix || 'SET_DISPLAY_DDL_SCHEMA_ARGS_R');
    dbug.print(dbug."input"
               ,'p_schema: %s; p_new_schema: %s; p_sort_objects_by_deps: %s; p_object_type: %s; p_object_names: %s'
               ,p_schema
               ,p_new_schema
               ,p_sort_objects_by_deps
               ,p_object_type
               ,p_object_names);
    dbug.print(dbug."input"
               ,'p_object_names_include: %s; p_grantor_is_schema: %s; p_transform_param_list: %s; p_exclude_objects size: %s; p_include_objects size: %s'
               ,p_object_names_include
               ,p_grantor_is_schema
               ,p_transform_param_list
               ,p_exclude_objects.count
               ,p_include_objects.count
               );
$end

    oracle_tools.pkg_str_util.join(p_exclude_objects, chr(10), l_exclude_objects);
    oracle_tools.pkg_str_util.join(p_include_objects, chr(10), l_include_objects);

    open l_cursor for
      select  value(t) as schema_ddl
      from    table
              ( oracle_tools.pkg_ddl_util.display_ddl_schema
                ( p_schema => p_schema
                , p_new_schema => p_new_schema
                , p_sort_objects_by_deps => p_sort_objects_by_deps
                , p_object_type => p_object_type
                , p_object_names => p_object_names
                , p_object_names_include => p_object_names_include
                , p_network_link => null
                , p_grantor_is_schema => p_grantor_is_schema
                , p_transform_param_list => p_transform_param_list
                , p_exclude_objects => l_exclude_objects
                , p_include_objects => l_include_objects
                )
              ) t;
    -- PLS-00994: Cursor Variables cannot be declared as part of a package
    g_cursor := dbms_sql.to_cursor_number(l_cursor);  
$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
    dbug.print(dbug."info", 'sid: %s; g_cursor: %s', sys_context('userenv','sid'), g_cursor);
$end
  end set_display_ddl_schema_args_r;

  /*
  -- Help procedure to retrieve the results of display_ddl_schema on a remote database.
  --
  -- Remark 1: Uses view v_display_ddl_schema2 because pipelined functions and a database link are not allowed.
  -- Remark 2: A call to display_ddl_schema() with a database linke will invoke set_display_ddl_schema() at the remote database.
  */
  function get_display_ddl_schema
  return oracle_tools.t_schema_ddl_tab
  pipelined
  is
    l_cursor sys_refcursor;
    l_schema_ddl oracle_tools.t_schema_ddl;
    l_program constant t_module := 'GET_DISPLAY_DDL_SCHEMA'; -- geen schema omdat l_program in dbms_application_info wordt gebruikt

    -- dbms_application_info stuff
    l_longops_rec t_longops_rec := oracle_tools.api_longops_pkg.longops_init(p_target_desc => l_program, p_op_name => 'fetch', p_units => 'objects');
  begin
$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
    dbug.enter(g_package_prefix || l_program);
$end

    -- PLS-00994: Cursor Variables cannot be declared as part of a package
$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
    dbug.print(dbug."info", 'sid: %s; g_cursor: %s', sys_context('userenv','sid'), g_cursor);
$end
    if g_cursor is null
    then
      raise program_error;
    end if;
    l_cursor := dbms_sql.to_refcursor(g_cursor);
    g_cursor := null;
    loop
      fetch l_cursor into l_schema_ddl;
      exit when l_cursor%notfound;
      pipe row (l_schema_ddl);
      oracle_tools.api_longops_pkg.longops_show(l_longops_rec);
    end loop;
    close l_cursor;

    oracle_tools.api_longops_pkg.longops_done(l_longops_rec);

$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
    dbug.leave;
$end
  exception
    when no_data_found
    then
$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
      dbug.leave_on_error;
$end
      -- GJP 2022-12-29
$if oracle_tools.pkg_ddl_util.c_err_pipelined_no_data_found $then
      oracle_tools.pkg_ddl_error.reraise_error(l_program);
$else      
      null;
$end      
  end get_display_ddl_schema;

  /*
  -- Sort objects on dependencies
  */
  function sort_objects_by_deps
  ( p_schema_object_tab in oracle_tools.t_schema_object_tab
  , p_schema in t_schema_nn
  )
  return oracle_tools.t_schema_object_tab
  pipelined
  is
    cursor c_dependencies is
      with allowed_types as
      ( select  t.column_value as type
        from    table(g_schema_md_object_type_tab) t
      ), obj as
      ( select  obj.owner
        ,       obj.object_type
        ,       obj.object_name
        ,       obj.status
        ,       obj.generated
        ,       obj.temporary
        ,       obj.subobject_name
                -- use scalar subqueries for a (possible) better performance
        ,       ( select substr(oracle_tools.t_schema_object.dict2metadata_object_type(obj.object_type), 1, 23) from dual ) as md_object_type
        ,       ( select oracle_tools.t_schema_object.is_a_repeatable(obj.object_type) from dual ) as is_a_repeatable
        ,       ( select oracle_tools.pkg_ddl_util.is_exclude_name_expr(oracle_tools.t_schema_object.dict2metadata_object_type(obj.object_type), obj.object_name) from dual ) as is_exclude_name_expr
        ,       ( select oracle_tools.pkg_ddl_util.is_dependent_object_type(obj.object_type) from dual ) as is_dependent_object_type
        from    all_objects obj
      ), deps as
      ( select  oracle_tools.t_schema_object.create_schema_object
                ( d.owner
                , d.md_type
                , d.name
                ) as obj -- a named object
        ,       oracle_tools.t_schema_object.create_schema_object
                ( d.referenced_owner
                , d.md_referenced_type
                , d.referenced_name
                ) as ref_obj -- a named object
        from    ( select  d.*
                          -- scalar subqueries for a better performance
                  ,       ( select oracle_tools.t_schema_object.dict2metadata_object_type(d.type) from dual ) as md_type
                  ,       ( select oracle_tools.t_schema_object.dict2metadata_object_type(d.referenced_type) from dual ) as md_referenced_type
                  from    all_dependencies d
                  where   d.owner = p_schema
                  and     d.referenced_owner = p_schema
                          -- ignore database links
                  and     d.referenced_link_name is null
                          -- GJP 2021-08-30 Ignore synonyms: they will be created early like this (no dependencies hence dsort will put them in front)
                  and     d.type != 'SYNONYM'
                  and     d.referenced_type != 'SYNONYM'
                ) d
        where   d.md_type in ( select t.type from allowed_types t )
        and     d.md_referenced_type in ( select t.type from allowed_types t )
        union all
$if not(oracle_tools.pkg_ddl_util.c_#138707615_2) $then -- GJP 2022-07-16 FALSE
        -- dependencies based on foreign key constraints
        select  oracle_tools.t_schema_object.create_schema_object
                ( t1.owner
                , 'TABLE' -- already meta
                , t1.table_name
                ) as obj -- a named object
        ,       oracle_tools.t_schema_object.create_schema_object
                ( t2.owner
                , 'TABLE' -- already meta
                , t2.table_name
                ) as ref_obj -- a named object
        from    all_constraints t1
                inner join all_constraints t2
                on t2.owner = t1.r_owner and t2.constraint_name = t1.r_constraint_name
        where   t1.owner = p_schema
        and     t1.owner = t2.owner /* same schema */
        and     t1.constraint_type = 'R'
$if oracle_tools.pkg_ddl_util.c_exclude_system_constraints $then
        -- no need to exclude since this is dependency checking not object selection
$end        
$else -- GJP 2022-07-16 TRUE
        -- more simple: just the constraints
        select  oracle_tools.t_schema_object.create_schema_object
                ( c.owner
                , 'REF_CONSTRAINT' -- already meta
                , c.constraint_name
                , tc.owner
                , tc.md_object_type
                , tc.object_name
                ) as obj -- belongs to a base table/mv
        ,       oracle_tools.t_schema_object.create_schema_object
                ( c.r_owner
                , 'CONSTRAINT' -- already meta
                , c.r_constraint_name
                , tr.owner
                , tr.md_object_type
                , tr.object_name
                ) as ref_obj -- belongs to a base table/mv
        from    all_constraints c
                inner join obj tc
                on tc.owner = c.owner and tc.object_name = c.table_name
                inner join all_constraints r
                on r.owner = c.r_owner and r.constraint_name = c.r_constraint_name
                inner join obj tr
                on tr.owner = r.owner and tr.object_name = r.table_name
        where   c.owner = p_schema
        and     c.constraint_type = 'R'
        and     tc.md_object_type in ( select t.type from allowed_types t )
        and     tr.md_object_type in ( select t.type from allowed_types t )
$if oracle_tools.pkg_ddl_util.c_exclude_system_constraints $then
        -- no need to exclude since this is dependency checking not object selection
$end
$end
        union all
        -- dependencies based on prebuilt tables
        select  oracle_tools.t_schema_object.create_schema_object
                ( t1.owner
                , 'MATERIALIZED_VIEW' -- already meta
                , t1.mview_name
                ) as obj -- a named object
        ,       oracle_tools.t_schema_object.create_schema_object
                ( t2.owner
                , 'TABLE' -- already meta
                , t2.table_name
                ) as ref_obj -- a named object
        from    all_mviews t1
                inner join all_tables t2
                on t2.owner = t1.owner and t2.table_name = t1.mview_name
        where   t2.owner = p_schema
        and     t1.build_mode = 'PREBUILT'
        union all
        -- dependencies from constraints to indexes
        select  oracle_tools.t_schema_object.create_schema_object
                ( c.owner
                , case c.constraint_type when 'R' then 'REF_CONSTRAINT' else 'CONSTRAINT' end
                , c.constraint_name
                , tc.owner
                , tc.md_object_type
                , tc.object_name
                ) as obj -- a named object
        ,       oracle_tools.t_schema_object.create_schema_object
                ( c.index_owner
                , 'INDEX'
                , c.index_name
                , i.table_owner
                , i.table_type
                , i.table_name
                ) as ref_obj -- a named object
        from    all_constraints c
                inner join obj tc
                on tc.owner = c.owner and tc.object_name = c.table_name and tc.object_type in ('TABLE', 'VIEW') /* GJP 2021-12-15 A table name can be the same as an index or materialized view name but the base object must be a table/view */
                inner join all_indexes i
                on i.owner = c.index_owner and i.index_name = c.index_name
        where   c.owner = p_schema
        and     c.index_owner is not null
        and     c.index_name is not null
        and     tc.md_object_type in ( select t.type from allowed_types t )
        and     i.table_type in ( select t.type from allowed_types t )
$if oracle_tools.pkg_ddl_util.c_exclude_system_constraints $then
        -- no need to exclude since this is dependency checking not object selection
$end
      )
      select  t1.*
      from    deps t1
              inner join ( select value(t2) as obj from table(p_schema_object_tab) t2 ) t2
              on t2.obj = t1.obj
              inner join ( select value(t3) as ref_obj from table(p_schema_object_tab) t3 ) t3
              on t3.ref_obj = t1.ref_obj
    ;

    type t_schema_object_lookup_tab is table of oracle_tools.t_schema_object index by t_object;

    -- l_schema_object_lookup_tab(object.id) = object;
    l_schema_object_lookup_tab t_schema_object_lookup_tab;

    -- l_object_dependency_tab(obj1)(obj2) = true means obj1 must be created before obj2
    l_object_dependency_tab t_object_dependency_tab;

    l_object_by_dep_tab dbms_sql.varchar2_table;

    l_dependent_or_granted_object oracle_tools.t_dependent_or_granted_object;

    l_schema_object oracle_tools.t_schema_object;

    l_program constant t_module := 'SORT_OBJECTS_BY_DEPS';

    -- dbms_application_info stuff
    l_longops_rec t_longops_rec := oracle_tools.api_longops_pkg.longops_init(p_target_desc => l_program, p_units => 'objects');
  begin
$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
    dbug.enter(g_package_prefix || l_program);
    dbug.print(dbug."input", 'p_schema: %s; p_schema_object_tab.count: %s', p_schema, p_schema_object_tab.count);
    dbug.print(dbug."input", 'p_schema_object_tab(1).id: %s', case when p_schema_object_tab.count > 0 then p_schema_object_tab(1).id end);    
$end

    if p_schema_object_tab.count > 0
    then
      for i_idx in p_schema_object_tab.first .. p_schema_object_tab.last
      loop
        l_schema_object_lookup_tab(p_schema_object_tab(i_idx).id) := p_schema_object_tab(i_idx);
        -- objects without dependencies must be part of this list too
        l_object_dependency_tab(p_schema_object_tab(i_idx).id) := c_object_no_dependencies_tab;
      end loop;
    end if;

    for r in c_dependencies
    loop
      -- object depends on object dependency so the latter must be there first

$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
      dbug.print(dbug."info", 'object %s depends on object %s', r.obj.id, r.ref_obj.id);
$end

      l_object_dependency_tab(r.ref_obj.id)(r.obj.id) := null;

      /*
       * GJP 2022-07-17
       *
       * BUG: the referential constraints are not created in the correct order in the install.sql file (https://github.com/paulissoft/oracle-tools/issues/35).
       *
       * The solution is to have a better dependency sort order and thus let the referential constraint depend on the primary / unique key and not on the base table / view.
       */ 

      -- but the object also depends on its own base object
      if r.obj is of (oracle_tools.t_dependent_or_granted_object)
      then
        l_dependent_or_granted_object := treat(r.obj as oracle_tools.t_dependent_or_granted_object);

        if l_dependent_or_granted_object is not null and
           l_dependent_or_granted_object.base_object_seq$ is not null and
           l_dependent_or_granted_object.base_object().id != r.ref_obj.id /* no need to add the same entry twice */
        then
$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
          dbug.print
          ( dbug."info"
          , 'object %s depends on its base object %s'
          , l_dependent_or_granted_object.id
          , l_dependent_or_granted_object.base_object().id
          );
$end

          l_object_dependency_tab(l_dependent_or_granted_object.base_object().id)(l_dependent_or_granted_object.id) := null;
        end if;  
      end if;
    end loop;

    dsort(l_object_dependency_tab, l_object_by_dep_tab);

    if l_object_by_dep_tab.count > 0
    then
      for i_idx in l_object_by_dep_tab.first .. l_object_by_dep_tab.last
      loop
        /* GJP 2022-08-11 
           When DDL is generated with the 'sort objects by dependencies' flag, an error is raised for unknown dependencies.
           See also https://github.com/paulissoft/oracle-tools/issues/47
        */
        begin
$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
          dbug.print(dbug."debug", 'l_object_by_dep_tab(%s): %s', i_idx, l_object_by_dep_tab(i_idx));
$end
          l_schema_object := l_schema_object_lookup_tab(l_object_by_dep_tab(i_idx));

$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
          dbug.print(dbug."debug", 'l_schema_object.id: %s', l_schema_object.id);
$end

          pipe row(l_schema_object);

          oracle_tools.api_longops_pkg.longops_show(l_longops_rec);
        exception
          when no_data_found
          then
$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
            dbug.on_error;
$end
            null;
        end;
      end loop;
    end if;

    -- GJP 2021-08-28
    -- TO DO: rest of objects

    -- 100%
    oracle_tools.api_longops_pkg.longops_done(l_longops_rec);

$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
    dbug.leave;
$end

    return; -- essential for a pipelined function

  exception
    when no_data_needed
    then
$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
      dbug.leave;
$end
      null; -- not a real error, just a way to some cleanup

    when no_data_found -- verdwijnt anders in het niets omdat het een pipelined function betreft die al data ophaalt
    then
$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
      dbug.leave_on_error;
$end
      -- GJP 2022-12-29
$if oracle_tools.pkg_ddl_util.c_err_pipelined_no_data_found $then
      oracle_tools.pkg_ddl_error.reraise_error(l_program);
$else      
      null;
$end      

$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
    when others
    then
      dbug.leave_on_error;
      raise;
$end
  end sort_objects_by_deps;

  procedure migrate_schema_ddl
  ( p_source in oracle_tools.t_schema_ddl
  , p_target in oracle_tools.t_schema_ddl
  , p_schema_ddl in out nocopy oracle_tools.t_schema_ddl
  )
  is
    l_line_tab dbms_sql.varchar2a;

    l_source_text clob := null;
    l_target_text clob := null;

    procedure cleanup
    is
    begin
      null;
    end cleanup;
  begin
$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
    dbug.enter(g_package_prefix || 'MIGRATE_SCHEMA_DDL');
$end

    oracle_tools.pkg_str_util.text2clob(p_source.ddl_tab(1).text, l_source_text);
    oracle_tools.pkg_str_util.text2clob(p_target.ddl_tab(1).text, l_target_text);

    oracle_tools.pkg_str_util.compare
    ( p_source => l_source_text
    , p_target => l_target_text
    , p_delimiter => chr(10)
    , p_compare_line_tab => l_line_tab
    );

    l_line_tab(0) := 'No license to use DBMS_METADATA_DIFF so you must create an ALTER statement given this diff output:';
    for i_idx in l_line_tab.first .. l_line_tab.last
    loop
      l_line_tab(i_idx) := '-- ' || l_line_tab(i_idx);
    end loop;

    p_schema_ddl.add_ddl
    ( p_verb => '--'
    , p_text => lines2text(l_line_tab)
    );

    cleanup;

$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
    dbug.leave;
$end
  exception
    when others
    then
      cleanup;
$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
      dbug.leave_on_error;
$end
      raise;
  end migrate_schema_ddl;

  function get_md_object_type_tab
  ( p_what in varchar2
  )  
  return oracle_tools.t_text_tab
  deterministic
  is
  begin
    return case upper(p_what)
             when 'DBA'
             then g_dba_md_object_type_tab
             when 'PUBLIC'
             then g_public_md_object_type_tab
             when 'SCHEMA'
             then g_schema_md_object_type_tab
             when 'DEPENDENT'
             then g_dependent_md_object_type_tab
           end;
  end get_md_object_type_tab;

  procedure check_schema
  ( p_schema in t_schema
  , p_network_link in t_network_link
  , p_description in varchar2 default 'Schema'
  )
  is
  begin
    if p_schema is null and
       p_network_link is not null
    then
      raise_application_error
      ( oracle_tools.pkg_ddl_error.c_schema_wrong
      , p_description || ' is empty and the network link not.'
      );
    elsif p_schema is not null and
          p_network_link is null
    then
      begin
        if dbms_assert.schema_name(p_schema) is null
        then
          -- will not come here since dbms_assert.schema_name() will raise an exception
          raise no_data_found;
        end if;
      exception
        when others
        then
          raise_application_error
          ( oracle_tools.pkg_ddl_error.c_schema_does_not_exist
          , p_description || '"' || p_schema || '"' || ' does not exist.'
          );
      end;
    end if;
  end check_schema;

  procedure check_numeric_boolean
  ( p_numeric_boolean in pls_integer
  , p_description in varchar2 
  )
  is
  begin
    if (p_numeric_boolean is not null and p_numeric_boolean not in (0, 1))
    then
      raise_application_error
      ( oracle_tools.pkg_ddl_error.c_numeric_boolean_wrong
      , 'The flag ' || p_description || ' (' || p_numeric_boolean || ') is not empty and not 0 or 1.'
      );
    end if;
  end check_numeric_boolean;

$if oracle_tools.cfg_pkg.c_testing $then

  function metadata_object_type2dict
  ( p_metadata_object_type in varchar2
  )
  return varchar2
  deterministic
  is
  begin
    return
      case p_metadata_object_type
        when 'DB_LINK'               then 'DATABASE LINK'
        when 'JAVA_SOURCE'           then 'JAVA SOURCE'
        when 'MATERIALIZED_VIEW'     then 'MATERIALIZED VIEW'
        when 'PACKAGE_BODY'          then 'PACKAGE BODY'
        when 'PACKAGE_SPEC'          then 'PACKAGE'
        when 'TYPE_BODY'             then 'TYPE BODY'
        when 'TYPE_SPEC'             then 'TYPE'
        when 'XMLSCHEMA'             then 'XML SCHEMA'
        else p_metadata_object_type
      end;
  end metadata_object_type2dict;  

  /*
  -- GPA 2015-12-22
  --
  -- On Oracle 12c release 1 (oink1/tink1) you get a
  --
  --   ORA-03113: end-of-file on communication channel
  --
  -- when deleting trailing whitespace lines from a collection which contains the code for APPL_INKOMEN.PACKAGE_BODY.BEHEERBEROEPEN
  --
  -- The funny thing is that when you gather information for all package bodies the package body size is 195 (with one trailing whitespace line).
  --
  -- When you just gather info for package body BEHEERBEROEPEN the line size is 194, no delete is performed and no error shows up.
  --
  -- The workaround is just to determine the begin and end of the actual code, i.e. not to use p_text_tab.first / p_text_tab.last.
  */
  procedure skip_ws_lines_around
  (
    p_text_tab in out nocopy dbms_sql.varchar2a
  , p_first out pls_integer
  , p_last out pls_integer
  )
  is
  begin
$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
    dbug.enter(g_package_prefix || 'SKIP_WS_LINES_AROUND');
    dbug.print(dbug."input", 'p_text_tab.count: %s; p_text_tab.first: %s; p_text_tab.last: %s', p_text_tab.count, p_text_tab.first, p_text_tab.last);
$end

    p_first := p_text_tab.first;
    p_last := p_text_tab.last;

    loop
      if p_first <= p_last
      then
$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
        dbug.print(dbug."info", 'p_text_tab(%s): "%s"', p_first, case when p_text_tab.exists(p_first) then p_text_tab(p_first) else '<DOES NOT EXIST>' end);
$end
        if p_text_tab.exists(p_first) and trim(p_text_tab(p_first)) is null
        then
$if not(dbms_db_version.version = 12 and dbms_db_version.release = 1) $then
          p_text_tab.delete(p_first);
$end
          p_first := p_first + 1;
        elsif not(p_text_tab.exists(p_first))
        then
          p_first := p_first + 1;
        else
          exit;
        end if;
      else
        exit;
      end if;
    end loop;

    while p_first <= p_last and p_text_tab.exists(p_last) and trim(p_text_tab(p_last)) is null
    loop
$if not(dbms_db_version.version = 12 and dbms_db_version.release = 1) $then
      p_text_tab.delete(p_last);
$end

      p_last := p_last - 1;
    end loop;

    if p_first > p_last
    then
      p_text_tab.delete;
      p_first := null;
      p_last := null;
    else
      -- skip white space before the first line
      if p_first is not null and p_text_tab.exists(p_first)
      then
        p_text_tab(p_first) := ltrim(p_text_tab(p_first));
      end if;

      -- skip white space after the last line
      if p_last is not null and p_text_tab.exists(p_last)
      then
        p_text_tab(p_last) := rtrim(p_text_tab(p_last));
      end if;
    end if;

$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
    dbug.print(dbug."output", 'p_text_tab.count: %s; p_first: %s; p_last: %s', p_text_tab.count, p_first, p_last);
    dbug.leave;
  exception
    when others
    then
      dbug.leave_on_error;
      raise;
$end
  end skip_ws_lines_around;

  procedure get_source
  ( p_owner in varchar2
  , p_object_type in varchar2
  , p_object_name in varchar2
  , p_line_tab out nocopy dbms_sql.varchar2a
  , p_first out pls_integer
  , p_last out pls_integer
  )
  is
    function get_ddl
    return clob
    is
      l_metadata_object_type constant t_metadata_object_type :=
        oracle_tools.t_schema_object.dict2metadata_object_type
        ( case
            when p_object_type in ('TYPE', 'PACKAGE')
            then p_object_type || '_SPEC'
            else p_object_type
          end
        );

      -- ORA-31608: specified object of type COMMENT not found
      e_error exception;
      pragma exception_init(e_error, -31608);
    begin
      return case l_metadata_object_type
                 when 'COMMENT'
                 then dbms_metadata.get_dependent_ddl(object_type => l_metadata_object_type, base_object_name => p_object_name, base_object_schema => p_owner)
                 else dbms_metadata.get_ddl(object_type => l_metadata_object_type, name => p_object_name, schema => p_owner)
               end;
    exception
      when e_error
      then
        return null;
    end;
  begin
$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
    dbug.enter(g_package_prefix || 'GET_SOURCE');
    dbug.print(dbug."input", 'p_owner: %s; p_object_type: %s; p_object_name: %s', p_owner, p_object_type, p_object_name);
$end

    oracle_tools.pkg_str_util.split
    ( p_str => get_ddl
    , p_delimiter => chr(10)
    , p_str_tab => p_line_tab
    );

    skip_ws_lines_around(p_line_tab, p_first, p_last);

$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
    dbug.print(dbug."output", 'p_line_tab.count: %s; p_first: %s; p_last: %s', p_line_tab.count, p_first, p_last);
    dbug.leave;
  exception
    when others
    then
      dbug.leave_on_error;
      raise;
$end
  end get_source;

  function show_diff
  ( p_line1_tab in dbms_sql.varchar2a
  , p_first1 in pls_integer
  , p_last1 in pls_integer
  , p_line2_tab in dbms_sql.varchar2a
  , p_first2 in pls_integer
  , p_last2 in pls_integer
  )
  return varchar2
  is
    l_idx1 pls_integer := p_first1;
    l_idx2 pls_integer := p_first2;
    l_line1 varchar2(32767 char);
    l_line2 varchar2(32767 char);

    function normalize(p_line in varchar2)
    return varchar2
    is
    begin
      -- 1: ALTER TABLE "ORACLE_TOOLS"."DEMO_CONSTRAINT_LOOKUP" ADD CONSTRAINT "DEMO_CONSTRAINT_LOOKUP_PK" PRIMARY KEY ("CONSTRAINT_NAME") ENABLE
      -- 2: ALTER TABLE "ORACLE_TOOLS"."DEMO_CONSTRAINT_LOOKUP" ADD CONSTRAINT "DEMO_CONSTRAINT_LOOKUP_PK" PRIMARY KEY ("CONSTRAINT_NAME")
      
      -- GJP 2021-08-27 Ignore this special case
      -- 1: <NULL>
      -- 2: ALTER TRIGGER "ORACLE_TOOLS"."UI_APEX_MESSAGES_TRG" ENABLE

      -- USING INDEX "ORACLE_TOOLS"."EBA_INTRACK_ERROR_LOOKUP_PK"
      
      return
        case
          when ltrim(p_line) like 'PCTFREE %' 
          then null
          when ltrim(p_line) like 'ALTER TRIGGER % ENABLE'
          then null
          when ltrim(p_line) like 'USING INDEX%'
          then null
          when ltrim(p_line) like 'TABLESPACE %'
          then null
          when ltrim(p_line) like 'NOCOMPRESS LOGGING%'
          then null
          else rtrim(rtrim(p_line), ' ENABLE')
        end;        
    end normalize;
  begin
    if (p_first1 is null and p_line1_tab.first is null and p_line1_tab.last is null and p_last1 is null) or
       (p_first1 >= p_line1_tab.first and p_line1_tab.last >= p_last1 and p_first1 <= p_last1)
    then
      null;
    else
      raise_application_error
      ( oracle_tools.pkg_ddl_error.c_invalid_parameters
      , 'p_first1: ' || p_first1 || '; p_line1_tab.first: ' || p_line1_tab.first ||
        '; p_last1: ' || p_last1 || '; p_line1_tab.last: ' || p_line1_tab.last
      );
    end if;

    if (p_first2 is null and p_line2_tab.first is null and p_line2_tab.last is null and p_last2 is null) or
       (p_first2 >= p_line2_tab.first and p_line2_tab.last >= p_last2 and p_first2 <= p_last2)
    then
      null;
    else
      raise_application_error
      ( oracle_tools.pkg_ddl_error.c_invalid_parameters
      , 'p_first2: ' || p_first2 || '; p_line2_tab.first: ' || p_line2_tab.first ||
        '; p_last2: ' || p_last2 || '; p_line2_tab.last: ' || p_line2_tab.last
      );
    end if;

    <<line_loop>>
    while (l_idx1 <= p_last1 or l_idx2 <= p_last2)
    loop
      l_line1 := case when l_idx1 <= p_last1 and p_line1_tab.exists(l_idx1) then normalize(p_line1_tab(l_idx1)) else null end;
      l_line2 := case when l_idx2 <= p_last2 and p_line2_tab.exists(l_idx2) then normalize(p_line2_tab(l_idx2)) else null end;
      
      if ( l_line1 is null and l_line2 is null ) or l_line1 = l_line2
      then
        null; -- lines equal
      else
        -- one line does not exist or the lines are not equal
        return l_idx1 || chr(10) || l_line1 || chr(10) || l_idx2 || chr(10) || l_line2;
      end if;
      l_idx1 := l_idx1 + 1;
      l_idx2 := l_idx2 + 1;
    end loop line_loop;
    
    return null; -- ok
  end show_diff;

  function eq
  ( p_line1_tab in dbms_sql.varchar2a
  , p_first1 in pls_integer
  , p_last1 in pls_integer
  , p_line2_tab in dbms_sql.varchar2a
  , p_first2 in pls_integer
  , p_last2 in pls_integer
  )
  return boolean
  is
    l_result varchar2(32767 char) := null;
  begin
$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
    dbug.enter(g_package_prefix || 'EQ');
    dbug.print(dbug."input", 'p_line1_tab.count: %s; p_first1: %s; p_last1: %s', p_line1_tab.count, p_first1, p_last1);
    dbug.print(dbug."input", 'p_line2_tab.count: %s; p_first2: %s; p_last2: %s', p_line2_tab.count, p_first2, p_last2);
$end

    l_result := show_diff(p_line1_tab, p_first1, p_last1, p_line2_tab, p_first2, p_last2);
    
$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
    if l_result is not null
    then
      declare
        l_part_tab dbms_sql.varchar2a;
      begin
        oracle_tools.pkg_str_util.split(l_result, chr(10), l_part_tab);
        dbug.print
        ( dbug."warning"
        , 'difference found:'
        );
        dbug.print
        ( dbug."warning"
        , 'p_line1_tab(%s): "%s"'
        , l_part_tab(1)
        , l_part_tab(2)
        );
        dbug.print
        ( dbug."warning"
        , 'p_line2_tab(%s): "%s"'
        , l_part_tab(3)
        , l_part_tab(4)
        );
      end;
    end if;
$end

$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
    dbug.print(dbug."output", 'return: %s', l_result is null);
    dbug.leave;
$end

   return l_result is null;

$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
  exception
    when others
    then
      dbug.leave_on_error;
      raise;
$end
  end eq;

  procedure cleanup_empty
  is
    l_drop_schema_ddl_tab oracle_tools.t_schema_ddl_tab;
    l_network_link_target constant t_network_link := g_empty; -- in order to have the same privileges
    l_program constant t_module := 'CLEANUP_EMPTY';
  begin
$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
    dbug.enter(l_program);
$end

    uninstall
    ( p_schema_target => g_empty
    , p_network_link_target => l_network_link_target
    );

    -- drop (user created) objects which are excluded in get_schema_objects()
    l_drop_schema_ddl_tab := oracle_tools.t_schema_ddl_tab();
    for r in
    ( select  oracle_tools.t_schema_ddl.create_schema_ddl
              ( p_obj => oracle_tools.t_named_object.create_named_object
                         ( p_object_type => o.object_type
                         , p_object_schema => o.object_schema
                         , p_object_name => o.object_name
                         )
              , p_ddl_tab => oracle_tools.t_ddl_tab()
              ) as obj
      from    ( select  o.owner as object_schema
                ,       o.object_name
                        -- use scalar subqueries for a (possible) better performance
                ,       ( select substr(oracle_tools.t_schema_object.dict2metadata_object_type(o.object_type), 1, 23) from dual ) as object_type
                ,       ( select oracle_tools.pkg_ddl_util.is_dependent_object_type(o.object_type) from dual ) as is_dependent_object_type

                from    all_objects o
                where   o.owner = g_empty
$if oracle_tools.pkg_ddl_util.c_exclude_system_objects $then
                and     o.generated = 'N' -- GPA 2016-12-19 #136334705
$end                
              ) o
      where   o.is_dependent_object_type = 0
    )
    loop
      l_drop_schema_ddl_tab.extend(1);
      create_schema_ddl
      ( p_source_schema_ddl => null
      , p_target_schema_ddl => r.obj
      , p_skip_repeatables => 0
      , p_schema_ddl => l_drop_schema_ddl_tab(l_drop_schema_ddl_tab.last)
      );
    end loop;

    execute_ddl(l_drop_schema_ddl_tab, l_network_link_target);

$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
    dbug.leave;
$end
  exception
    when others
    then
      null;
$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
      dbug.leave;
$end
  end cleanup_empty;

  procedure ut_cleanup_empty
  is
    pragma autonomous_transaction;

    l_found pls_integer;
  begin
    begin
      -- schema EMPTY should exist
      select  1
      into    l_found
      from    all_users
      where   username = g_empty
      ;
    exception
      when no_data_found
      then raise_application_error(oracle_tools.pkg_ddl_error.c_missing_schema, 'User EMPTY must exist', true);
    end;

    begin
      cleanup_empty;
    exception
      when others
      then null;
    end;

    -- schema EMPTY should not have user created objects
    begin
      select  1
      into    l_found
      from    all_objects o
      where   o.owner = g_empty
$if oracle_tools.pkg_ddl_util.c_exclude_system_objects $then
      and     o.generated = 'N' -- GPA 2016-12-19 #136334705
$end      
      and     rownum = 1
      ;
      raise too_many_rows;
    exception
      when no_data_found
      then null;
      when too_many_rows
      then raise_application_error(oracle_tools.pkg_ddl_error.c_schema_not_empty, 'User EMPTY should have NO objects', true);
    end;

    commit;
  end ut_cleanup_empty;

  procedure ut_disable_schema_export
  is
    l_transform_param_tab t_transform_param_tab;
  begin
    -- so p_schema_object_filter.match_perc() >= p_schema_object_filter.match_perc_threshold() will always be false meaning no SCHEMA_EXPORT will be used
    oracle_tools.pkg_schema_object_filter.default_match_perc_threshold(null);
    
    get_transform_param_tab
    ( p_transform_param_list => c_transform_param_list_testing
    , p_transform_param_tab => l_transform_param_tab
    );

    md_set_transform_param
    ( p_use_object_type_param => false -- no SCHEMA_EXPORT
    , p_transform_param_tab => l_transform_param_tab
    ); -- for get_source    
  end ut_disable_schema_export;
  
  procedure ut_enable_schema_export
  is
  begin
    dbms_metadata$set_transform_param(dbms_metadata.session_transform, 'DEFAULT', true); -- back to the defaults
    oracle_tools.pkg_schema_object_filter.default_match_perc_threshold; -- back to the defaults
  end ut_enable_schema_export;

  -- test functions
  procedure ut_setup
  is
    pragma autonomous_transaction;

    l_found pls_integer;
    l_cursor sys_refcursor;
    l_loopback_global_name global_name.global_name%type;
  begin
    select  t.table_owner
    into    g_owner_utplsql
    from    all_synonyms t
    where   t.table_name = 'UT';

    if get_db_link(g_empty) is null
    then
      raise_application_error(oracle_tools.pkg_ddl_error.c_missing_db_link, 'Database link EMPTY must exist');
    end if;

    begin
      select  1
      into    l_found
      from    all_db_links t
      where   t.owner = g_owner
      and     t.db_link = 'LOOPBACK'
      and     t.username = g_owner
      ;

      open l_cursor for 'select t.global_name from global_name@loopback t';
      fetch l_cursor into l_loopback_global_name;
      close l_cursor;

      select  1
      into    l_found
      from    global_name t
      where   t.global_name = l_loopback_global_name;
    exception
      when no_data_found
      then
        raise_application_error(oracle_tools.pkg_ddl_error.c_wrong_db_link, 'Private database link LOOPBACK should point to this schema and database.', true);
    end;

    -- GJP 2022-09-25
    -- The ddl unit test fails when the ORACLE_TOOLS schema has a synonym for a non-existing object.
    -- https://github.com/paulissoft/oracle-tools/issues/61
    execute immediate 'create or replace synonym nowhere for sys.nowhere';

    commit;
  end ut_setup;

  procedure ut_teardown
  is
    pragma autonomous_transaction;

  begin
    execute immediate 'drop synonym nowhere';

    commit;
  end ut_teardown;

  procedure ut_display_ddl_schema_chk
  is
    -- dbms_application_info stuff
    l_program constant t_module := 'UT_DISPLAY_DDL_SCHEMA_CHK';

    c_no_exception_raised constant integer := -20001;

    procedure chk
    ( p_description in varchar2
    , p_sqlcode_expected in integer
    , p_schema in varchar2 default 'HR' -- just a few objects
    , p_new_schema in varchar2 default null
    , p_sort_objects_by_deps in number default 0
    , p_object_type in varchar2 default null
    , p_object_names in varchar2 default null
    , p_object_names_include in number default null
    , p_network_link in varchar2 default null
    , p_grantor_is_schema in number default 0
    )
    is
      cursor c_display_ddl_schema
      ( b_schema in varchar2
      , b_new_schema in varchar2
      , b_sort_objects_by_deps in number
      , b_object_type in varchar2
      , b_object_names in varchar2
      , b_object_names_include in number
      , b_network_link in varchar2
      , b_grantor_is_schema in number
      )
      is
        select value(t)
        from   table
               ( oracle_tools.pkg_ddl_util.display_ddl_schema
                 ( p_schema => b_schema
                 , p_new_schema => b_new_schema
                 , p_sort_objects_by_deps => b_sort_objects_by_deps
                 , p_object_type => b_object_type
                 , p_object_names => b_object_names
                 , p_object_names_include => b_object_names_include
                 , p_network_link => b_network_link
                 , p_grantor_is_schema => b_grantor_is_schema
                 , p_exclude_objects => null
                 , p_include_objects => null
                 )
               ) t
        ;
      l_schema_ddl oracle_tools.t_schema_ddl;
    begin
$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
      dbug.enter(g_package_prefix || l_program || '.CHK');
      dbug.print
      ( dbug."input"
      , 'p_description: %s; p_sqlcode_expected: %s; p_schema: %s; p_new_schema: %s; p_sort_objects_by_deps: %s'
      , p_description
      , p_sqlcode_expected
      , p_schema
      , p_new_schema
      , p_sort_objects_by_deps
      );
      dbug.print
      ( dbug."input"
      , 'p_object_type: %s; p_object_names: %s; p_object_names_include: %s; p_network_link: %s; p_grantor_is_schema: %s'
      , p_object_type
      , p_object_names
      , p_object_names_include
      , p_network_link
      , p_grantor_is_schema
      );
$end
      open c_display_ddl_schema
           ( p_schema
           , p_new_schema
           , p_sort_objects_by_deps
           , p_object_type
           , p_object_names
           , p_object_names_include
           , p_network_link
           , p_grantor_is_schema
           );
--      fetch c_display_ddl_schema into l_schema_ddl;
      close c_display_ddl_schema;

      raise_application_error(c_no_exception_raised, 'OK');
    exception
      when others
      then
        if c_display_ddl_schema%isopen then close c_display_ddl_schema; end if;
$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
        dbug.leave_on_error;
$end        
        ut.expect(sqlcode, l_program || '#' || p_description).to_equal(p_sqlcode_expected);
    end chk;
  begin
$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
    dbug.enter(g_package_prefix || l_program);
$end

    chk
    ( p_description => 'Schema is empty.'
    , p_sqlcode_expected => -6502
    , p_schema => null
    );

    chk
    ( 'Invalid schema when p_network_link is empty and p_schema is not correct.'
    , p_sqlcode_expected => oracle_tools.pkg_ddl_error.c_schema_does_not_exist
    , p_schema => 'ABC'
    );

    chk
    ( p_description => 'New schema empty'
    , p_sqlcode_expected => c_no_exception_raised
    , p_new_schema => null
    );

    chk
    ( p_description => 'New schema ABC'
    , p_sqlcode_expected => c_no_exception_raised
    , p_new_schema => 'ABC'
    );

    for r in
    ( select  column_value
      from    table
              ( sys.odcinumberlist
                ( null
                , -1
                , 0
                , 1
                , 2
                )
              )
    )
    loop
      chk
      ( p_description => 'Sort_objects_by_deps (' || r.column_value || ')'
      , p_sqlcode_expected => case
                                 when r.column_value is null
                                 then -6502 -- VALUE_ERROR want NATURALN staat null niet toe
                                 when r.column_value in (0, 1)
                                 then c_no_exception_raised
                                 when r.column_value < 0
                                 then -6502 -- VALUE_ERROR want NATURALN staat negatieve getallen niet toe
                                 else oracle_tools.pkg_ddl_error.c_numeric_boolean_wrong
                               end
      , p_sort_objects_by_deps => r.column_value
      );
    end loop;

    chk
    ( p_description => 'When p_object_names is not empty and p_object_names_include empty.'
    , p_sqlcode_expected => oracle_tools.pkg_ddl_error.c_objects_wrong
    , p_object_names => 'ABC'
    );

    chk
    ( p_description => 'When p_object_names is not empty and p_object_names_include not empty and not in (0, 1).'
    , p_sqlcode_expected => oracle_tools.pkg_ddl_error.c_numeric_boolean_wrong
    , p_object_names => 'ABC'
    , p_object_names_include => 2
    );

    chk
    ( p_description => 'When p_object_names is not empty and p_object_names_include not empty and not in (0, 1).'
    , p_sqlcode_expected => -6502 -- VALUE_ERROR want NATURAL staat alleen null, 0 of positieve gehele getallen toe.
    , p_object_names => 'ABC'
    , p_object_names_include => -1
    );

    chk
    ( p_description => 'When p_object_names is empty and p_object_names_include not empty.'
    , p_sqlcode_expected => oracle_tools.pkg_ddl_error.c_objects_wrong
    , p_object_names => null
    , p_object_names_include => 0
    );

    for r in
    ( select  column_value
      from    table
              ( sys.odcinumberlist
                ( null
                , -1
                , 0
                , 1
                , 2
                )
              )
    )
    loop
      chk
      ( p_description => 'grantor_is_schema (' || r.column_value || ')'
      , p_sqlcode_expected => case
                                 when r.column_value is null then -6502 -- VALUE_ERROR want NATURALN staat null niet toe
                                 when r.column_value in (0, 1) then c_no_exception_raised
                                 when r.column_value < 0 then -6502 -- VALUE_ERROR want NATURALN staat negatieve getallen niet toe
                                 else oracle_tools.pkg_ddl_error.c_numeric_boolean_wrong
                               end
      , p_grantor_is_schema => r.column_value
      , p_object_names => 'ABC'
      , p_object_names_include => 1
      );
    end loop;

$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
    dbug.leave;
  exception
    when others
    then
      dbug.leave_on_error;
      raise;
$end
  end ut_display_ddl_schema_chk;

  procedure ut_display_ddl_schema
  is
    pragma autonomous_transaction;

    l_line1_tab    dbms_sql.varchar2a;
    l_clob1        clob := null;
    l_first1       pls_integer := null;
    l_last1        pls_integer := null;
    l_line2_tab    dbms_sql.varchar2a;
    l_clob2        clob := null;
    l_first2       pls_integer := null;
    l_last2        pls_integer := null;
    l_lwb          pls_integer := 1;
    l_upb          pls_integer := 1;

    l_prev_object_schema t_schema := null;
    l_prev_object_name t_object_name := null;
    l_prev_object_type t_metadata_object_type := null;

    l_schema_ddl_tab oracle_tools.t_schema_ddl_tab;

    l_schema t_schema;
    l_object_names_include t_numeric_boolean;
    l_object_names t_object_names;

    -- dbms_application_info stuff
    l_program constant t_module := 'UT_DISPLAY_DDL_SCHEMA';
    l_longops_rec t_longops_rec;

    procedure replace_sequence_start_with(p_line_tab in out nocopy dbms_sql.varchar2a)
    is
      "CREATE SEQUENCE " constant varchar2(100) := 'CREATE SEQUENCE ';
    begin
      for i_idx in p_line_tab.first .. p_line_tab.last
      loop
        if substr(p_line_tab(i_idx), 1, length("CREATE SEQUENCE ")) = "CREATE SEQUENCE "
        then
          -- CREATE SEQUENCE  "<owner>"."<sequence>"  MINVALUE 1 MAXVALUE 999999999999999999999999999 INCREMENT BY 1 START WITH 13849101
          p_line_tab(i_idx) := regexp_replace(p_line_tab(i_idx), '( START WITH )(\d+)', '\1 1');
        end if;
      end loop;
    end replace_sequence_start_with;

    procedure read_ddl
    ( p_new_schema in varchar2
    , p_clob in out nocopy clob
    , p_line_tab out nocopy dbms_sql.varchar2a
    )
    is
    begin      
      if p_clob is not null
      then
        dbms_lob.trim(p_clob, 0);
      end if;
      l_longops_rec :=
        oracle_tools.api_longops_pkg.longops_init
        ( p_op_name => 'Read DDL ' || p_new_schema
        , p_units => 'DDL'
        , p_target_desc => l_program
        , p_totalwork => 0
        );
      for r in
      ( with src as
        (        select u.text
          ,      row_number() over (partition by t.obj.object_schema(), t.obj.object_type() order by t.obj.object_name()) as seq
          from   table
                 ( oracle_tools.pkg_ddl_util.display_ddl_schema
                   ( p_schema => $$PLSQL_UNIT_OWNER
                   , p_new_schema => p_new_schema
                   , p_sort_objects_by_deps => 1
                   , p_object_type => null
                   , p_object_names => $$PLSQL_UNIT
                   , p_object_names_include => 1
                   , p_network_link => null
                   , p_grantor_is_schema => 0
                   , p_exclude_objects => null
                   , p_include_objects => null
                   , p_transform_param_list => c_transform_param_list_testing
                   )
                 ) t
          ,      table(t.ddl_tab) u
          where  t.obj.object_type() <> 'OBJECT_GRANT'
        )
        select  src.text
        from    src
        where   src.seq = 1
      )
      loop
        oracle_tools.pkg_str_util.text2clob(r.text, p_clob, true); -- append to p_clob
        oracle_tools.api_longops_pkg.longops_show(l_longops_rec);
      end loop;
      if l_longops_rec.sofar = 0
      then
        raise program_error;
      end if;
      oracle_tools.api_longops_pkg.longops_done(l_longops_rec);
      l_longops_rec.totalwork := null;
      oracle_tools.pkg_str_util.split(p_str => p_clob, p_str_tab => p_line_tab, p_delimiter => chr(10));
    end read_ddl;

    procedure compare_source
    ( p_try in pls_integer
    , p_owner in varchar2
    , p_object_type in varchar2
    , p_object_name in varchar2
    , p_clob in out nocopy clob
    )
    is
    begin
      -- Copy all lines from p_clob to l_line1_tab but skip empty lines for comments.
      -- So we use an intermediary l_line2_tab first.
      oracle_tools.pkg_str_util.split(p_str => p_clob, p_str_tab => l_line2_tab, p_delimiter => chr(10));
      l_line1_tab.delete;
      for i_idx in l_line2_tab.first .. l_line2_tab.last
      loop
        if p_object_type <> 'COMMENT' or trim(l_line2_tab(i_idx)) is not null
        then
          l_line1_tab(l_line1_tab.count+1) := l_line2_tab(i_idx);
        end if;
      end loop;

      skip_ws_lines_around(l_line1_tab, l_first1, l_last1);

      -- Skip line 1 (create ...) because it may differ
      if l_first1 between l_line1_tab.first and l_line1_tab.last and
         ltrim(l_line1_tab(l_first1)) like 'CREATE %'
      then
        l_line1_tab.delete(l_first1);
        l_first1 := l_first1 + 1;
        skip_ws_lines_around(l_line1_tab, l_first1, l_last1);
      end if;

      get_source(p_owner => p_owner
                ,p_object_type => p_object_type
                ,p_object_name => p_object_name
                ,p_line_tab => l_line2_tab
                ,p_first => l_first2
                ,p_last => l_last2);

      -- Skip line 1 (create ...) because it may differ
      if l_first2 between l_line2_tab.first and l_line2_tab.last and
         ltrim(l_line2_tab(l_first2)) like 'CREATE %'
      then
        l_line2_tab.delete(l_first2);
        l_first2 := l_first2 + 1;
        skip_ws_lines_around(l_line2_tab, l_first2, l_last2);
      end if;

      ut.expect
      ( show_diff(l_line1_tab, l_first1, l_last1, l_line2_tab, l_first2, l_last2)
      , l_program || '#' || p_owner || '#' || p_object_type || '#' || p_object_name || '#' || p_try || '#eq'
      ).to_be_null();
      
      dbms_lob.trim(p_clob, 0);
    end compare_source;

    procedure cleanup
    is
    begin
      if l_clob1 is not null
      then
        dbms_lob.freetemporary(l_clob1);
        l_clob1 := null;
      end if;
      if l_clob2 is not null
      then
        dbms_lob.freetemporary(l_clob2);
        l_clob2 := null;
      end if;
    end cleanup;
  begin
$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
    dbug.enter(g_package_prefix || l_program);
$end

    -- The oracle_tools.pkg_ddl_util PACKAGE_SPEC must be created first for an empty schema
    begin
      read_ddl(null, l_clob1, l_line1_tab);
      read_ddl(g_empty, l_clob2, l_line2_tab);

      if (l_line1_tab.first is null and l_line2_tab.first is null) or l_line1_tab.first = l_line2_tab.first
      then
        null;
      else
        raise program_error;
      end if;

      for i_line_idx in l_line1_tab.first .. greatest(l_line1_tab.last, l_line2_tab.last)
      loop
        if l_line1_tab.exists(i_line_idx) and
           l_line2_tab.exists(i_line_idx)
        then
          l_line1_tab(i_line_idx) := modify_ddl_text(p_ddl_text => l_line1_tab(i_line_idx), p_schema => g_owner, p_new_schema => g_empty);

          ut.expect
          ( l_line1_tab(i_line_idx)
          , l_program || '#' || g_owner || '#' || g_package || '#line ' || i_line_idx
          ).to_equal(l_line2_tab(i_line_idx));
        elsif l_line1_tab.exists(i_line_idx)
        then
          ut.expect
          ( l_line1_tab(i_line_idx)
          , l_program || '#' || g_owner || '#' || g_package || '#line ' || i_line_idx
          ).to_be_null();
        elsif l_line2_tab.exists(i_line_idx)
        then
          ut.expect
          ( l_line2_tab(i_line_idx)
          , l_program || '#' || g_owner || '#' || g_package || '#line ' || i_line_idx
          ).to_be_null();
        end if;
      end loop;
    end;

    -- Create an include object CLOB
    if l_clob1 is null
    then
      raise program_error;
    end if;
    if l_clob2 is null
    then
      raise program_error;
    end if;

    dbms_lob.trim(l_clob2, 0);

    -- Check objects in this schema
    for r in (select t.owner
                    ,case t.object_type
                       when 'TABLE'
                       then 'COMMENT'
                       else t.object_type
                     end as object_type
                    ,t.object_name
                    ,count(*) over () as total
              from   ( select  t.*
                               -- use scalar subqueries for a (possible) better performance
                       ,       ( select oracle_tools.t_schema_object.is_a_repeatable(t.object_type) from dual ) as is_a_repeatable
                       ,       ( select oracle_tools.pkg_ddl_util.is_exclude_name_expr(oracle_tools.t_schema_object.dict2metadata_object_type(t.object_type), t.object_name) from dual ) as is_exclude_name_expr              
                       ,       row_number() over (partition by t.owner, t.object_type order by t.object_name) as orderseq
                       from    all_objects t
$if oracle_tools.pkg_ddl_util.c_exclude_system_objects $then
                       where   t.generated = 'N' /* GPA 2016-12-19 #136334705 */
$end                       
                     ) t
              where  t.owner = g_owner -- g_owner_utplsql
              and    t.orderseq <= 3 -- reduce the time
              and    (t.is_a_repeatable = 1 or /* for comments */ t.object_type = 'TABLE')
              and    t.object_type not in ('EVALUATION CONTEXT','JOB','PROGRAM','RULE','RULE SET','JAVA CLASS','JAVA SOURCE')
              and    ( t.owner = g_owner or
                       t.object_type not like '%BODY' -- CREATE ANY PROCEDURE system privilege needed to lookup
                     )
              and    ( t.object_type <> 'TRIGGER' or
                       (t.owner, t.object_name) in (select owner, trigger_name from all_triggers where base_object_type in ('TABLE', 'VIEW'))
                     )
              and    t.is_exclude_name_expr = 0
              order  by case t.object_type
                          when 'TABLE'
                          then 0
                          when 'TRIGGER'
                          then 1
                          when 'VIEW'
                          then 2
                          when 'TYPE_SPEC'
                          then 3
                          else null
                        end nulls last -- tables and triggers first
                       ,t.object_type
                       ,t.object_name)
    loop
      oracle_tools.pkg_str_util.text2clob
      ( oracle_tools.t_text_tab
        ( r.owner || ':' || oracle_tools.t_schema_object.dict2metadata_object_type(r.object_type) || ':' || r.object_name || ':*:*:*:*:*:*:*'
        , chr(10)
        )
      , l_clob2
      , true
      );
      l_longops_rec.totalwork := r.total;
    end loop;

$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
    dbug.print(dbug."info", 'l_clob2: %s', oracle_tools.pkg_str_util.dbms_lob_substr(l_clob2, 255, 1));
$end

    l_upb := case when g_loopback is not null then 2 else 1 end;

    l_longops_rec :=
      oracle_tools.api_longops_pkg.longops_init
      ( p_op_name => 'Test source'
      , p_units => 'objects'
      , p_target_desc => l_program
      , p_totalwork => l_longops_rec.totalwork * l_upb
      );

    <<try_loop>>
    for i_try in l_lwb .. l_upb
    loop
      dbms_lob.trim(l_clob1, 0);
      
      -- ddl for all objects
      for r_text in
      ( select t.obj.object_schema() as object_schema
        ,      t.obj.object_name() as object_name
        ,      t.obj.object_type() as object_type
        ,      u.text
        from   table
               ( oracle_tools.pkg_ddl_util.display_ddl_schema
                 ( p_schema => g_owner
                 , p_new_schema => null
                 , p_sort_objects_by_deps => 0
                 , p_object_type => null
                 , p_object_names => null
                 , p_object_names_include => null
                 , p_network_link => case when i_try = 2 then g_loopback end
                 , p_grantor_is_schema => 0
                 , p_exclude_objects => null
                 , p_include_objects => l_clob2
                 , p_transform_param_list => c_transform_param_list_testing
                 )
               ) t
        ,      table(t.ddl_tab) u
        where  u.ddl#() = 1
        order by
               u.verb()
        ,      t.obj.object_schema()
        ,      t.obj.object_type()
        ,      t.obj.object_name()
        ,      t.obj.base_object_schema()
        ,      t.obj.base_object_type()
        ,      t.obj.base_object_name()
        ,      t.obj.column_name()
        ,      t.obj.grantee()
        ,      t.obj.privilege()
        ,      t.obj.grantable()
        ,      u.ddl#()
      )
      loop
$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
        dbug.print
        ( dbug."info"
        , 'r_text.object_schema: %s; r_text.object_type: %s; r_text.object_name: %s'
        , r_text.object_schema
        , r_text.object_type
        , r_text.object_name
        );
$end

        if l_prev_object_schema = r_text.object_schema and
           l_prev_object_type = r_text.object_type and
           l_prev_object_name = r_text.object_name
        then
          null;
        elsif l_prev_object_schema is not null and
              l_prev_object_type is not null and
              l_prev_object_name is not null and
              dbms_lob.getlength(l_clob1) > 0
        then
          -- compare old
          compare_source
          ( i_try
          , l_prev_object_schema
          , metadata_object_type2dict(l_prev_object_type)
          , l_prev_object_name
          , l_clob1
          );
        end if;

        oracle_tools.pkg_str_util.text2clob(r_text.text, l_clob1, true);

        l_prev_object_schema := r_text.object_schema;
        l_prev_object_type := r_text.object_type;
        l_prev_object_name := r_text.object_name;
      end loop;

      -- do not forget the last one
      if l_prev_object_schema is not null and
         l_prev_object_type is not null and
         l_prev_object_name is not null and
         dbms_lob.getlength(l_clob1) > 0
      then
        compare_source
        ( l_upb
        , l_prev_object_schema
        , metadata_object_type2dict(l_prev_object_type)
        , l_prev_object_name
        , l_clob1
        );      
      end if;

      oracle_tools.api_longops_pkg.longops_show(l_longops_rec);
    end loop try_loop;

    oracle_tools.api_longops_pkg.longops_done(l_longops_rec);

    cleanup;

    commit;

$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
    dbug.leave;
$end
  exception
    when others
    then
      cleanup;
$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
      dbug.leave_on_error;
$end
      raise;
  end ut_display_ddl_schema;

  procedure ut_display_ddl_schema_diff_chk
  is
    -- dbms_application_info stuff
    l_program constant t_module := 'UT_DISPLAY_DDL_SCHEMA_DIFF_CHK';

    c_no_exception_raised constant integer := -20001;

    procedure chk
    ( p_description in varchar2
    , p_sqlcode_expected in integer
    , p_object_type in varchar2 default null
    , p_object_names in varchar2 default null
    , p_object_names_include in number default null
    , p_schema_source in varchar2 default 'HR' -- just a few objects
    , p_schema_target in varchar2 default 'HR'
    , p_network_link_source in varchar2 default null
    , p_network_link_target in varchar2 default null
    , p_skip_repeatables in number default 1
    )
    is
      cursor c_display_ddl_schema_diff
      ( b_object_type in varchar2
      , b_object_names in varchar2
      , b_object_names_include in number
      , b_schema_source in varchar2
      , b_schema_target in varchar2
      , b_network_link_source in varchar2
      , b_network_link_target in varchar2
      , b_skip_repeatables in number
      )
      is
        select value(t)
        from   table
               ( oracle_tools.pkg_ddl_util.display_ddl_schema_diff
                 ( p_object_type => b_object_type
                 , p_object_names => b_object_names
                 , p_object_names_include => b_object_names_include
                 , p_schema_source => b_schema_source
                 , p_schema_target => b_schema_target
                 , p_network_link_source => b_network_link_source
                 , p_network_link_target => b_network_link_target
                 , p_skip_repeatables => b_skip_repeatables
                 , p_exclude_objects => null
                 , p_include_objects => null
                 )
               ) t
        ;

      l_schema_ddl oracle_tools.t_schema_ddl;
    begin
$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
      dbug.enter(g_package_prefix || l_program || '.CHK');
      dbug.print
      ( dbug."input"
      , 'p_description: %s; p_sqlcode_expected: %s; p_object_type: %s; p_object_names: %s; p_object_names_include: %s'
      , p_description
      , p_sqlcode_expected
      , p_object_type
      , p_object_names
      , p_object_names_include
      );
      dbug.print
      ( dbug."input"
      , 'p_schema_source: %s; p_schema_target: %s; p_network_link_source: %s; p_network_link_target: %s; p_skip_repeatables: %s'
      , p_schema_source
      , p_schema_target
      , p_network_link_source
      , p_network_link_target
      , p_skip_repeatables
      );
$end

      open c_display_ddl_schema_diff
           ( p_object_type
           , p_object_names
           , p_object_names_include
           , p_schema_source
           , p_schema_target
           , p_network_link_source
           , p_network_link_target
           , p_skip_repeatables
           );
--      fetch c_display_ddl_schema_diff into l_schema_ddl;
      close c_display_ddl_schema_diff;

      raise_application_error(c_no_exception_raised, 'OK');
    exception
      when others
      then
        if c_display_ddl_schema_diff%isopen then close c_display_ddl_schema_diff; end if;
$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
        dbug.leave_on_error;
$end        
        ut.expect(sqlcode, l_program || '#' || p_description).to_equal(p_sqlcode_expected);
    end chk;
  begin
$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
    dbug.enter(g_package_prefix || l_program);
$end

/*
    chk
    ( p_description => 'When p_object_names is not empty and p_object_names_include empty.'
    , p_sqlcode_expected => oracle_tools.pkg_ddl_error.c_objects_wrong
    , p_object_names => 'ABC'
    , p_schema_source => 'SYS' -- need to add it since
    );

    chk
    ( p_description => 'When p_object_names is not empty and p_object_names_include not empty and not in (0, 1).'
    , p_sqlcode_expected => oracle_tools.pkg_ddl_error.c_numeric_boolean_wrong
    , p_object_names => 'ABC'
    , p_object_names_include => 2
    );

    chk
    ( p_description => 'When p_object_names is not empty and p_object_names_include not empty and not in (0, 1).'
    , p_sqlcode_expected => -6502 -- VALUE_ERROR vanwege NATURAL datatype
    , p_object_names => 'ABC'
    , p_object_names_include => -1
    );

    chk
    ( p_description => 'When p_object_names is empty and p_object_names_include not empty.'
    , p_sqlcode_expected => oracle_tools.pkg_ddl_error.c_objects_wrong
    , p_object_names_include => 1
    );
*/
    chk
    ( p_description => 'When p_schema_source is empty and p_network_link_source not empty.'
    , p_sqlcode_expected => oracle_tools.pkg_ddl_error.c_schema_wrong
    , p_schema_source => null
    , p_network_link_source => g_dbname
    );

    chk
    ( p_description => 'When p_schema_target is empty.'
    , p_sqlcode_expected => -6502 -- VALUE_ERROR vanwege NATURAL datatype
    , p_schema_target => null
    );

    chk
    ( p_description => 'When p_network_link_source is empty, p_schema_source not empty and non-existing.'
    , p_sqlcode_expected => oracle_tools.pkg_ddl_error.c_schema_does_not_exist
    , p_schema_source => 'ABC'
    );

    chk
    ( p_description => 'When p_network_link_target is empty, p_schema_target not empty and non-existing.'
    , p_sqlcode_expected => oracle_tools.pkg_ddl_error.c_schema_does_not_exist
    , p_schema_target => 'ABC'
    );

    chk
    ( p_description => 'When source equals target.'
    , p_sqlcode_expected => oracle_tools.pkg_ddl_error.c_source_and_target_equal
    , p_schema_source => g_owner
    , p_schema_target => g_owner
    );

    chk
    ( p_description => 'When p_network_link_source not empty and unknown.'
    , p_sqlcode_expected => oracle_tools.pkg_ddl_error.c_database_link_does_not_exist
    , p_network_link_source => 'ABC'
    );

    chk
    ( p_description => 'When p_network_link_target not empty and unknown.'
    , p_sqlcode_expected => oracle_tools.pkg_ddl_error.c_database_link_does_not_exist
    , p_network_link_target => 'ABC'
    );

    -- check skip_repeatables
    for r in
    ( select  column_value
      from    table
              ( sys.odcinumberlist
                ( null
                , -1
                , 0
                , 1
                , 2
                )
              )
    )
    loop
      chk
      ( p_description => 'skip_repeatables: ' || r.column_value
      , p_sqlcode_expected => case
                                when r.column_value is null
                                then -6502 -- VALUE_ERROR want NATURALN staat null niet toe
                                when r.column_value in (0, 1)
                                then c_no_exception_raised
                                when r.column_value < 0
                                then -6502 -- VALUE_ERROR want NATURALN staat negatieve getallen niet toe
                                else oracle_tools.pkg_ddl_error.c_numeric_boolean_wrong
                              end
      , p_skip_repeatables => r.column_value
      , p_object_names => 'ABC'
      , p_object_names_include => 1
      , p_schema_source => null
      );
    end loop;

    chk
    ( p_description => 'Running against empty source schema should work'
    , p_sqlcode_expected => c_no_exception_raised -- oracle_tools.pkg_ddl_error.c_no_schema_objects
    , p_schema_target => g_empty
    , p_schema_source => null
    );

$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
    dbug.leave;
  exception
    when others
    then
      dbug.leave_on_error;
      raise;
$end
  end ut_display_ddl_schema_diff_chk;

  procedure ut_display_ddl_schema_diff
  is
    pragma autonomous_transaction;

    l_line1_tab    dbms_sql.varchar2a;
    l_clob1        clob := null;
    l_first1       pls_integer := null;
    l_last1        pls_integer := null;
    l_line2_tab    dbms_sql.varchar2a;
    l_first2       pls_integer := null;
    l_last2        pls_integer := null;

    l_schema_ddl_tab oracle_tools.t_schema_ddl_tab;

    -- dbms_application_info stuff
    l_program constant t_module := 'UT_DISPLAY_DDL_SCHEMA_DIFF';
    l_longops_rec t_longops_rec;

    procedure cleanup
    is
    begin
      if l_clob1 is not null
      then
        dbms_lob.freetemporary(l_clob1);
        l_clob1 := null;
      end if;
    end cleanup;
  begin
$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
    dbug.enter(g_package_prefix || l_program);
$end

    -- Check this schema
    for r in (select t.owner
                    ,case t.object_type when 'TABLE' then 'COMMENT' else t.object_type end as object_type
                    ,t.object_name
                    ,count(*) over () as total
              from   ( select  t.*
                               -- use scalar subqueries for a (possible) better performance
                       ,       ( select oracle_tools.t_schema_object.is_a_repeatable(t.object_type) from dual ) as is_a_repeatable
                       ,       ( select oracle_tools.pkg_ddl_util.is_exclude_name_expr(oracle_tools.t_schema_object.dict2metadata_object_type(t.object_type), t.object_name) from dual ) as is_exclude_name_expr
                       ,       row_number() over (partition by t.owner, t.object_type order by t.object_name) as orderseq
                       from    all_objects t
$if oracle_tools.pkg_ddl_util.c_exclude_system_objects $then
                       where   t.generated = 'N' /* GPA 2016-12-19 #136334705 */
$end                       
                     ) t
              where  t.owner in (g_owner, g_owner_utplsql)
              and    t.orderseq <= 3
              and    (t.is_a_repeatable = 1 or /* for comments */ t.object_type = 'TABLE')
              and    t.object_type not in ('EVALUATION CONTEXT','JOB','PROGRAM','RULE','RULE SET','JAVA CLASS','JAVA SOURCE')
              and    ( t.owner = g_owner or
                       t.object_type not like '%BODY' -- CREATE ANY PROCEDURE system privilege needed to lookup
                     )
              and    ( t.object_type <> 'TRIGGER' or
                       (t.owner, t.object_name) in (select owner, trigger_name from all_triggers where base_object_type in ('TABLE', 'VIEW'))
                     )
              and    t.is_exclude_name_expr = 0
              order  by case t.object_type
                          when 'TABLE'
                          then 0
                          when 'TRIGGER'
                          then 1
                          when 'VIEW'
                          then 2
                          when 'TYPE_SPEC'
                          then 3
                          else null
                        end nulls last -- tables and triggers first
                       ,t.object_type
                       ,t.object_name
             )
    loop
      if l_longops_rec.totalwork is null
      then
        l_longops_rec := oracle_tools.api_longops_pkg.longops_init(p_op_name => 'Test', p_units => 'objects', p_target_desc => l_program, p_totalwork => r.total);
      end if;

$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
      dbug.print
      ( dbug."info"
      , 'r.owner: %s; r.object_type: %s; r.object_name: %s'
      , r.owner
      , r.object_type
      , r.object_name
      );
$end

      <<try_loop>>
      for i_try in 1 .. case when g_loopback is not null then 2 else 1 end
      loop
        if l_clob1 is not null
        then
          dbms_lob.trim(l_clob1, 0);
        end if;

$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
        dbug.print(dbug."info", 'try %s; retrieving l_line1_tab', i_try);
$end

        for r_text in
        ( select t.obj.object_schema() as object_schema
          ,      t.obj.object_type() as object_type
          ,      t.obj.object_name() as object_name
          ,      u.text
          from   table
                 ( oracle_tools.pkg_ddl_util.display_ddl_schema_diff
                   ( p_object_type => oracle_tools.t_schema_object.dict2metadata_object_type(r.object_type)
                   , p_object_names => r.object_name
                   , p_object_names_include => 1
                   , p_schema_source => r.owner
                   , p_schema_target => g_empty
                   , p_network_link_source => case when i_try = 2 then g_loopback end
                   , p_network_link_target => case when i_try = 2 then g_loopback end
                   , p_skip_repeatables => 0
                   , p_exclude_objects => null
                   , p_include_objects => null
                   , p_transform_param_list => c_transform_param_list_testing
                   )
                 ) t
          ,      table(t.ddl_tab) u                                                          
          where  u.verb() != '--' -- no comments
          and    t.obj.object_type() = oracle_tools.t_schema_object.dict2metadata_object_type(r.object_type)
          order by
                 u.verb()
          ,      t.obj.object_schema()
          ,      t.obj.object_type()
          ,      t.obj.object_name()
          ,      t.obj.base_object_schema()
          ,      t.obj.base_object_type()
          ,      t.obj.base_object_name()
          ,      t.obj.column_name()
          ,      t.obj.grantee()
          ,      t.obj.privilege()
          ,      t.obj.grantable()
          ,      u.ddl#()
        )
        loop
$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
          dbug.print
          ( dbug."info"
          , 'r_text.object_schema: %s; r_text.object_type: %s; r_text.object_name: %s'
          , r_text.object_schema
          , r_text.object_type
          , r_text.object_name
          );
          if cardinality(r_text.text) > 0
          then
            for i_line_idx in r_text.text.first .. r_text.text.last
            loop
              dbug.print(dbug."info", 'line1: %s', r_text.text(i_line_idx));
            end loop;
          end if;
$end
          oracle_tools.pkg_str_util.text2clob(r_text.text, l_clob1, true);
        end loop;

        -- Copy all lines from l_clob1 to l_line1_tab but skip empty lines for comments.
        -- So we use an intermediary l_line2_tab first.
        oracle_tools.pkg_str_util.split(p_str => l_clob1, p_str_tab => l_line2_tab, p_delimiter => chr(10));
        l_line1_tab.delete;
        for i_idx in l_line2_tab.first .. l_line2_tab.last
        loop
          if r.object_type <> 'COMMENT' or trim(l_line2_tab(i_idx)) is not null
          then
            l_line1_tab(l_line1_tab.count+1) := l_line2_tab(i_idx);
          end if;
        end loop;

        skip_ws_lines_around(l_line1_tab, l_first1, l_last1);

        -- Skip line 1 (create ...) because it may differ
        if l_first1 between l_line1_tab.first and l_line1_tab.last and
           ltrim(l_line1_tab(l_first1)) like 'CREATE %'
        then
          l_line1_tab.delete(l_first1);
          l_first1 := l_first1 + 1;
          skip_ws_lines_around(l_line1_tab, l_first1, l_last1);
        end if;

$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
        dbug.print(dbug."info", 'try %s; retrieving l_line2_tab', i_try);
$end

        get_source(p_owner => r.owner
                  ,p_object_type => r.object_type
                  ,p_object_name => r.object_name
                  ,p_line_tab => l_line2_tab
                  ,p_first => l_first2
                  ,p_last => l_last2);

        -- Skip line 1 (create ...) because it may differ
        if l_first2 between l_line2_tab.first and l_line2_tab.last and
           ltrim(l_line2_tab(l_first2)) like 'CREATE %'
        then
          l_line2_tab.delete(l_first2);
          l_first2 := l_first2 + 1;
          skip_ws_lines_around(l_line2_tab, l_first2, l_last2);
        end if;

        if l_first2 <= l_last2
        then
          for i_line_idx in l_first2 .. l_last2
          loop
$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
            dbug.print
            ( dbug."info"
            , 'line2: %s'
            , l_line2_tab(i_line_idx)
            );
$end
            l_line2_tab(i_line_idx) :=
              modify_ddl_text
              ( p_ddl_text => l_line2_tab(i_line_idx)
              , p_schema => r.owner
              , p_new_schema => g_empty
              );
          end loop;
        end if;

        ut.expect
        ( show_diff(l_line1_tab, l_first1, l_last1, l_line2_tab, l_first2, l_last2)
        , l_program || '#' || r.owner || '#' || r.object_type || '#' || r.object_name || '#' || i_try || '#eq'
        ).to_be_null();
      end loop try_loop;

      oracle_tools.api_longops_pkg.longops_show(l_longops_rec);
    end loop;

    commit;

$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
    dbug.leave;
  exception
    when others
    then
      dbug.leave_on_error;
      raise;
$end
  end ut_display_ddl_schema_diff;

  procedure ut_object_type_order
  is
    pragma autonomous_transaction;

  begin
    null;

    commit;
  end ut_object_type_order;

  procedure ut_dict2metadata_object_type
  is
    pragma autonomous_transaction;

    l_metadata_object_type t_metadata_object_type;

    l_program constant t_module := 'UT_DICT2METADATA_OBJECT_TYPE';
  begin
$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
    dbug.enter(g_package_prefix || l_program);
$end

    -- null as parameter
    ut.expect(oracle_tools.t_schema_object.dict2metadata_object_type(to_char(null)), l_program || '#null').to_be_null();

    -- ABC XYZ as parameter
    ut.expect(oracle_tools.t_schema_object.dict2metadata_object_type('ABC XYZ'), l_program || '#ABC XYZ').to_equal('ABC_XYZ');

    for r in
    ( select  distinct
              t.object_type
      from    all_objects t
$if oracle_tools.pkg_ddl_util.c_exclude_system_objects $then
      where   t.generated = 'N' /* GPA 2016-12-19 #136334705 */
$end      
      order by
              t.object_type
    )
    loop
      l_metadata_object_type := case
                                  when r.object_type in ('JOB','PROGRAM','RULE','RULE SET','EVALUATION CONTEXT') then
                                   'PROCOBJ'
                                  when r.object_type = 'GRANT' then
                                   'OBJECT_GRANT'
                                  when r.object_type in ('PACKAGE', 'TYPE') then
                                   r.object_type || '_SPEC'
                                  else
                                   replace(r.object_type, ' ', '_')
                                end;

      ut.expect(oracle_tools.t_schema_object.dict2metadata_object_type(r.object_type), l_program || '#' || r.object_type).to_equal(l_metadata_object_type);
    end loop;

    commit;

$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
    dbug.leave;
$end
  end ut_dict2metadata_object_type;

  procedure ut_is_a_repeatable
  is
    pragma autonomous_transaction;

    l_program constant t_module := 'UT_IS_A_REPEATABLE';
    l_object_type_tab oracle_tools.t_text_tab;
  begin
$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
    dbug.enter(g_package_prefix || l_program);
$end

    -- null as parameter
    ut.expect(oracle_tools.t_schema_object.is_a_repeatable(to_char(null)), l_program || '#null').to_be_null();

    -- ABC XYZ as parameter
    ut.expect(oracle_tools.t_schema_object.is_a_repeatable('ABC XYZ'), l_program || '#ABC XYZ').to_be_null();

    for i_try in 1 .. 3
    loop
      l_object_type_tab := case i_try
                             when 1 then
                              g_dba_md_object_type_tab
                             when 2 then
                              g_public_md_object_type_tab
                             else
                              g_schema_md_object_type_tab
                           end;

      for i_idx in l_object_type_tab.first .. l_object_type_tab.last
      loop
        ut.expect( oracle_tools.t_schema_object.is_a_repeatable(l_object_type_tab(i_idx))
                 , l_program || '#' || i_try || '#' || l_object_type_tab(i_idx)
                 ).to_equal( case
                               when l_object_type_tab(i_idx) in ('CLUSTER'
                                                                ,'DB_LINK'
                                                                ,'DIMENSION'
                                                                ,'INDEXTYPE'
                                                                ,'LIBRARY'
                                                                ,'OPERATOR'
                                                                ,'INDEX'
                                                                ,'MATERIALIZED_VIEW'
                                                                ,'MATERIALIZED_VIEW_LOG'
                                                                ,'QUEUE'
                                                                ,'QUEUE_TABLE'
                                                                ,'SEQUENCE'
                                                                ,'TABLE'
                                                                ,'TYPE_SPEC'
                                                                ,'REFRESH_GROUP'
                                                                ,'XMLSCHEMA'
                                                                ,'PROCOBJ'
                                                                ) then
                                0

                               else
                                1
                             end
                           );
      end loop;
    end loop;

    commit;

$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
    dbug.leave;
  exception
    when others
    then
      dbug.leave_on_error;
      raise;
$end
  end ut_is_a_repeatable;

  procedure ut_synchronize
  is
    pragma autonomous_transaction;

    l_drop_schema_ddl_tab oracle_tools.t_schema_ddl_tab;
    l_diff_schema_ddl_tab oracle_tools.t_schema_ddl_tab;

    l_schema t_schema;
    l_network_link_source t_network_link;
    l_network_link_target constant t_network_link := g_empty; -- in order to have the same privileges

    -- GJP 2021-09-02
    c_object_type constant t_metadata_object_type := null; -- 'TYPE_SPEC';
    c_object_names constant t_object_name := null; -- 'EXCELTABLEIMPL';
    c_object_names_include constant t_numeric_boolean := null; -- 1;

    cursor c_display_ddl_schema_diff
    ( b_object_type in t_metadata_object_type default c_object_type
    , b_object_names in t_object_names default c_object_names
    , b_object_names_include in t_numeric_boolean default c_object_names_include
    , b_schema_source in t_schema default g_owner
    , b_schema_target in t_schema default g_owner
    , b_network_link_source in t_network_link default null
    , b_network_link_target in t_network_link default null
    , b_skip_repeatables in t_numeric_boolean default 1
    )
    is
      select value(t)
      from   table
             ( oracle_tools.pkg_ddl_util.display_ddl_schema_diff
               ( p_object_type => b_object_type
               , p_object_names => b_object_names
               , p_object_names_include => b_object_names_include
               , p_schema_source => b_schema_source
               , p_schema_target => b_schema_target
               , p_network_link_source => b_network_link_source
               , p_network_link_target => b_network_link_target
               , p_skip_repeatables => b_skip_repeatables
               , p_exclude_objects => null
               , p_include_objects => null
               )
             ) t
      ,      table(t.ddl_tab) u
      where  u.verb() != '--' -- no comments
      ;

    l_count pls_integer;

    l_program constant t_module := g_package || '.UT_SYNCHRONIZE';

    procedure cleanup is
    begin
      null; -- special beforetest annotation will take care of cleaning EMPTY
    end cleanup;
  begin
$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
    dbug.enter(l_program);
$end

    /*
    -- Scenario: install a schema to the EMPTY schema on this database
    --
    -- 1) empty the schema EMPTY
    -- 2) check that the source schema has no public synonyms (we do not want to change them)
    -- 3) invoke synchronize
    -- 4) calculate the difference DDL
    -- 5) remove object grants which failed to execute
    --
    -- Now there must be no differences
    */

    for i_try in 1..1
    loop
      case i_try
        when 1
        then
          l_schema := g_owner;
          l_network_link_source := null; -- this is l_schema

        when 2 -- GJP 2021-08-31
        then
          l_schema := g_owner;
          l_network_link_source := g_loopback; -- this is l_schema

      end case;

$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then        
      dbug.print(dbug."info", 'step 1');
$end

      /* step 1 */
      cleanup; -- empty EMPTY

      select  count(*)
      into    l_count
      from    all_objects t
      where   t.owner = g_empty
$if oracle_tools.pkg_ddl_util.c_exclude_system_objects $then
      and     t.generated = 'N' -- GPA 2016-12-19 #136334705
$end      
      and     ( select oracle_tools.pkg_ddl_util.is_exclude_name_expr(oracle_tools.t_schema_object.dict2metadata_object_type(t.object_type), t.object_name) from dual ) = 0;

      ut.expect(l_count, l_program || '#cleanup' || '#' || i_try).to_equal(0);

$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then        
      if l_count != 0
      then
        dbug.print(dbug."error", 'schema %s should not contain user created objects', g_empty);
        for r in
        ( select  o.object_type
          ,       o.object_name
          from    all_objects o
          where   o.owner = g_empty
$if oracle_tools.pkg_ddl_util.c_exclude_system_objects $then
          and     o.generated = 'N' -- GPA 2016-12-19 #136334705
$end          
          order by
                  o.object_type
          ,       o.object_name
        )
        loop
          dbug.print(dbug."error", 'object_type: %s; object_name: %s', r.object_type, r.object_name);
        end loop;
        raise_application_error(oracle_tools.pkg_ddl_error.c_schema_not_empty, g_empty);
      end if;
$end          

$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then        
      dbug.print(dbug."info", 'step 2');
$end

      /* step 2 */
      select  count(*)
      into    l_count
      from    all_synonyms t
      where   t.owner = 'PUBLIC'
      and     t.table_owner = l_schema;

      ut.expect(l_count, l_program || '#no public synonyms' || '#' || i_try).to_equal(0);

$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then        
      dbug.print(dbug."info", 'step 3');
$end

      /* step 3 */
      synchronize
      ( p_object_type => c_object_type
      , p_object_names => c_object_names
      , p_object_names_include => c_object_names_include
      , p_schema_source => l_schema
      , p_schema_target => g_empty
      , p_network_link_source => l_network_link_source
      , p_network_link_target => l_network_link_target
      , p_exclude_objects => null
      , p_include_objects => null
      );

$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then        
      dbug.print(dbug."info", 'step 4');
$end
      /* step 4 */

      -- Bereken de verschillen, i.e. de CREATE statements.
      -- Gebruik database links om aan te loggen met de juiste gebruiker.
      open c_display_ddl_schema_diff( b_object_type => c_object_type
                                    , b_object_names => c_object_names
                                    , b_object_names_include => c_object_names_include
                                    , b_schema_source => l_schema
                                    , b_schema_target => g_empty
                                    , b_network_link_source => l_network_link_source
                                    , b_network_link_target => l_network_link_target
                                    );
      fetch c_display_ddl_schema_diff bulk collect into l_diff_schema_ddl_tab limit g_max_fetch;
      close c_display_ddl_schema_diff;

$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then        
      dbug.print(dbug."info", 'step 5');
$end

      /* step 5 */

      /* see step 2: there are no public synonyms */
      /*
      -- Skip public synonyms
      remove_public_synonyms(l_diff_schema_ddl_tab);
      */
      -- ORA-01720: grant option does not exist for '<owner>.PARTY'
      remove_object_grants(l_diff_schema_ddl_tab);

      ut.expect(l_diff_schema_ddl_tab.count, l_program || '#differences' || '#' || i_try).to_equal(0);

$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
      if l_diff_schema_ddl_tab.count > 0
      then
        dbug.print(dbug."error", 'schema DDL differences found');
        for i_idx in l_diff_schema_ddl_tab.first .. l_diff_schema_ddl_tab.last
        loop
          dbug.print(dbug."error", 'schema DDL %s', i_idx);
          l_diff_schema_ddl_tab(i_idx).print();
        end loop;
        raise_application_error(-20000, 'schema DDL differences found');
      end if;
$end          

      cleanup;
    end loop;

    commit;

$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
    dbug.leave;
  exception
    when others
    then
      dbug.leave_on_error;
      -- do not invoke cleanup() so we can better investigate the error
      raise;
$end
  end ut_synchronize;

  procedure ut_sort_objects_by_deps
  is
    pragma autonomous_transaction;

    l_graph t_graph;
    l_result dbms_sql.varchar2_table;
    l_idx pls_integer;

    l_schema t_schema;    
    l_schema_object_tab1 oracle_tools.t_schema_object_tab;
    l_schema_object_tab2 oracle_tools.t_schema_object_tab;
    l_expected t_object;
    l_schema_object_filter oracle_tools.t_schema_object_filter;

    l_program constant t_module := g_package_prefix || 'UT_SORT_OBJECTS_BY_DEPS';
  begin
$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
    dbug.enter(l_program);
$end

    l_graph('1')('2') := 1;
    l_graph('1')('3') := 1;
    l_graph('1')('4') := 1;
    l_graph('2')('1') := 1;
    l_graph('2')('3') := 1;
    l_graph('2')('4') := 1;
    l_graph('3')('1') := 1;
    l_graph('3')('2') := 1;
    l_graph('3')('4') := 1;
    l_graph('4')('1') := 1;
    l_graph('4')('2') := 1;
    l_graph('4')('3') := 1;

    dsort
    ( l_graph
    , l_result
    );

    ut.expect(l_result.count, l_program || '#0#count').to_equal(4);
    l_idx := l_result.first;
    while l_idx is not null
    loop
      ut.expect(l_result(l_idx), l_program || '#0#' || to_char(1 + l_idx - l_result.first)).to_equal(to_char(1 + l_result.last - l_idx));      
      l_idx := l_result.next(l_idx);
    end loop;

    for i_test in 1..2
    loop
      l_schema_object_filter :=
        oracle_tools.t_schema_object_filter
        ( p_schema => g_owner
        , p_object_type => null
        , p_object_names => case i_test when 1 then 'PKG_DDL_UTIL,PKG_STR_UTIL' when 2 then 'T_NAMED_OBJECT,T_DEPENDENT_OR_GRANTED_OBJECT,T_SCHEMA_OBJECT' END
        , p_object_names_include => 1
        , p_exclude_objects => null
        , p_include_objects => null
        );
      oracle_tools.pkg_schema_object_filter.get_schema_objects
      ( p_schema_object_filter => l_schema_object_filter          
      , p_schema_object_tab => l_schema_object_tab1
      );

      select  value(t)
      bulk collect
      into    l_schema_object_tab2
      from    table
              ( oracle_tools.pkg_ddl_util.sort_objects_by_deps
                ( p_schema_object_tab => l_schema_object_tab1
                , p_schema => g_owner
                )
              ) t;

      ut.expect(l_schema_object_tab1.count, l_program || '#' || i_test || '#count#1').not_to_equal(0);
      ut.expect(l_schema_object_tab2.count, l_program || '#' || i_test || '#count#2').to_equal(l_schema_object_tab1.count);

      if l_schema_object_tab2.count > 0
      then
        for i_idx in l_schema_object_tab2.first .. l_schema_object_tab2.last
        loop
          l_expected :=
            case i_test
              when 1
              then
                case i_idx
                  when 1 then g_owner || ':PACKAGE_SPEC:PKG_STR_UTIL:::::::'
                  when 2 then g_owner || ':PACKAGE_SPEC:PKG_DDL_UTIL:::::::'
                  when 3 then g_owner || ':PACKAGE_BODY:PKG_STR_UTIL:::::::'
                  when 4 then g_owner || ':PACKAGE_BODY:PKG_DDL_UTIL:::::::'
                  when 5 then ':OBJECT_GRANT::' || g_owner || '::PKG_STR_UTIL::PUBLIC:EXECUTE:NO'
                  when 6 then ':OBJECT_GRANT::' || g_owner || '::PKG_DDL_UTIL::PUBLIC:EXECUTE:NO'
                end

              when 2
              then
                case i_idx
                  when 1 then g_owner || ':TYPE_SPEC:T_SCHEMA_OBJECT:::::::'
                  when 2 then g_owner || ':TYPE_SPEC:T_NAMED_OBJECT:::::::'
                  when 3 then g_owner || ':TYPE_SPEC:T_DEPENDENT_OR_GRANTED_OBJECT:::::::'
                  when 4 then g_owner || ':TYPE_BODY:T_SCHEMA_OBJECT:::::::'
                  when 5 then g_owner || ':TYPE_BODY:T_NAMED_OBJECT:::::::'
                  when 6 then g_owner || ':TYPE_BODY:T_DEPENDENT_OR_GRANTED_OBJECT:::::::'
                  when 7 then ':OBJECT_GRANT::' || g_owner || '::T_SCHEMA_OBJECT::PUBLIC:EXECUTE:NO'
                  when 8 then ':OBJECT_GRANT::' || g_owner || '::T_NAMED_OBJECT::PUBLIC:EXECUTE:NO'
                  when 9 then ':OBJECT_GRANT::' || g_owner || '::T_DEPENDENT_OR_GRANTED_OBJECT::PUBLIC:EXECUTE:NO'
                end
            end;

          ut.expect(l_schema_object_tab2(i_idx).id, l_program || '#' || i_test || '#' || i_idx || '#id').to_equal(l_expected);
        end loop;
      end if;
    end loop;

    commit;

$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
    dbug.leave;
  exception
    when others
    then
      dbug.leave_on_error;
      raise;
$end
  end ut_sort_objects_by_deps;

  procedure ut_modify_ddl_text
  is
    l_text constant varchar2(32767 char) :=
      chr(10) || -- test multi line
      'oracle_tools' || -- yes
      chr(10) ||
      ' oracle_tools' || -- yes
      chr(10) ||
      'oracle_tools ' || -- yes
      chr(10) ||
      ' Oracle_tools ' || -- yes (upper)
      chr(10) ||
      ' ORACLE_TOOLS.' || -- yes
      chr(10) ||
      '$oracle_tools' || -- no
      chr(10) ||
      '#oracle_tools' || -- no
      chr(10) ||
      '_oracle_tools' || -- no
      chr(10) ||
      '0oracle_tools' || -- no
      chr(10) ||
      'aoracle_tools' || -- no
      chr(10) ||
      'Zoracle_tools' || -- no
      chr(10) ||
      '(oracle_tools)' || -- yes
      chr(10) ||
      ' abcdefghij   ' || -- no
      chr(10)
    ;  
    l_text_actual constant varchar2(32767 char) :=
      modify_ddl_text
      ( p_ddl_text => l_text
      , p_schema => 'ORACLE_TOOLS'
      , p_new_schema => g_empty
      );
    l_text_expected constant varchar2(32767 char) :=
      chr(10) || -- test multi line
      'empty' || -- yes
      chr(10) ||
      ' empty' || -- yes
      chr(10) ||
      'empty ' || -- yes
      chr(10) ||
      ' EMPTY ' || -- yes (upper)
      chr(10) ||
      ' EMPTY.' || -- yes
      chr(10) ||
      '$oracle_tools' || -- no
      chr(10) ||
      '#oracle_tools' || -- no
      chr(10) ||
      '_oracle_tools' || -- no
      chr(10) ||
      '0oracle_tools' || -- no
      chr(10) ||
      'aoracle_tools' || -- no
      chr(10) ||
      'Zoracle_tools' || -- no
      chr(10) ||
      '(empty)' || -- yes
      chr(10) ||
      ' abcdefghij   ' || -- no
      chr(10)
    ;  
  begin
    ut.expect(l_text_actual, 'total').to_equal(l_text_expected);
    -- show just the first different index
    for i_idx in 1 .. greatest(length(l_text_actual), length(l_text_expected))
    loop
      ut.expect(ascii(substr(l_text_actual, i_idx, 1)), 'ascii char at index ' || i_idx).to_equal(ascii(substr(l_text_expected, i_idx, 1)));
      if substr(l_text_actual, i_idx, 1) = substr(l_text_expected, i_idx, 1)
      then
        null;
      else
        exit;
      end if;
     end loop;
  end ut_modify_ddl_text;

$end -- $if oracle_tools.cfg_pkg.c_testing $then

begin
  -- ensure unicode kees working
  if unistr('\20AC') <> c_euro_sign
  then
    raise value_error;
  end if;

  dbms_lob.createtemporary(g_clob, true);

  select global_name.global_name into g_dbname from global_name;

  i_object_exclude_name_expr_tab;
end pkg_ddl_util;
/

