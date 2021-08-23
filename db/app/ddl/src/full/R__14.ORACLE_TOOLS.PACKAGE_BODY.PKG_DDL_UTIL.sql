CREATE OR REPLACE PACKAGE BODY "ORACLE_TOOLS"."PKG_DDL_UTIL" IS

  /* TYPES */

  type t_db_link_tab is table of all_db_links.db_link%type index by all_db_links.db_link%type;

  type t_object_natural_tab is table of natural /* >= 0 */
  index by t_object;

  type t_object_dependency_tab is table of t_object_natural_tab index by t_object;

  type t_object_lookup_rec is record
  ( count t_numeric_boolean default 0
  , schema_ddl t_schema_ddl
  , ready boolean default false -- pipe row has been issued
  );

  type t_object_lookup_tab is table of t_object_lookup_rec index by t_object;

  -- key is t_schema_object.signature(), value is t_schema_object.id()
  type t_constraint_lookup_tab is table of t_object index by t_object; -- for parse_ddl

  -- just to make the usage of VIEW V_DISPLAY_DDL_SCHEMA in dynamic SQL explicit
  subtype t_stm_v_display_ddl_schema is v_display_ddl_schema%rowtype;

  subtype t_graph is t_object_dependency_tab;
  /*
  -- l_object_dependency_tab t_graph;
  -- l_object_dependency_tab(l_object_dependency)(l_object) := null;
  */
  -- This means l_object depends on l_object_dependency

  type t_object_exclude_name_expr_tab is table of t_text_tab index by t_metadata_object_type;

  /* CONSTANTS */

  -- a simple check to ensure the euro sign gets not scrambled, i.e. whether generate_ddl.pl can write down unicode characters
  c_euro_sign constant varchar2(1 char) := '€';

  c_use_schema_export constant pls_integer := 1;
  c_dbms_metadata_set_count constant pls_integer := 100;

  -- ORA-01795: maximum number of expressions in a list is 1000
  c_max_object_name_tab_count constant integer := 1000;

  c_fetch_limit constant pls_integer := 100;

  g_dbname global_name.global_name%type := null;

  g_package constant varchar2(61 char) := 'PKG_DDL_UTIL';

  g_package_prefix constant varchar2(61 char) := g_package || '.';

  c_not_a_directed_acyclic_graph constant integer := -20001;

$if cfg_pkg.c_testing $then

  "EMPTY"                    constant all_objects.owner%type := 'EMPTY';

  g_owner constant all_objects.owner%type := 'ORACLE_TOOLS';

  g_owner_utplsql all_objects.owner%type; -- not a real constant but set only once

  g_empty constant all_objects.owner%type := "EMPTY";

  g_raise_exc constant boolean := true;

  g_loopback constant varchar2(10 char) := 'LOOPBACK';

  g_object_names constant varchar2(32767 char) :=
'BIU_EBA_DEMO_LOAD_EMP
,EBA_CM_CHECKLIST_SAMPLE
,EBA_CM_CHECKLIST_STD
,EBA_CM_FW
,EBA_CUST
,EBA_CUST_FLEX_FW
,EBA_CUST_FW
,EBA_CUST_SAMPLE_DATA
,EBA_DEMO_CHART_DEPT
,EBA_DEMO_CHART_EMP
,EBA_DEMO_CHART_POPULATION
,EBA_DEMO_CHART_PROJECTS
,EBA_DEMO_CHART_STOCKS
,EBA_DEMO_CHART_TASKS
,EBA_DEMO_LOAD_DATA
,EBA_DEMO_LOAD_DEPT
,EBA_DEMO_LOAD_EMP
,EBA_DP
,EBA_DPS_SEQ
,EBA_DP_ACCESS_LEVELS
,EBA_DP_ACTIVE_FILTERS_T
,EBA_DP_ACTIVE_FILTERS_TBL
,EBA_DP_CALENDARS
,EBA_DP_CATEGORIES
,EBA_DP_DASHBOARD
,EBA_DP_DATASRC_TYPES
,EBA_DP_DATA_ACCESS
,EBA_DP_DATA_SOURCES
,EBA_DP_DATA_SOURCE_PERMS
,EBA_DP_DEMO_DATA
,EBA_DP_DEMO_PROJECTS
,EBA_DP_DEMO_PROJECT_DATA
,EBA_DP_ERRORS
,EBA_DP_ERROR_LOOKUP
,EBA_DP_FAVORITES
,EBA_DP_FILES
,EBA_DP_FILTER2_FW
,EBA_DP_FILTER_COLUMN_T
,EBA_DP_FILTER_COL_TBL
,EBA_DP_FILTER_REPORT
,EBA_DP_FILTER_RPT_FILTERS
,EBA_DP_FORMAT_MASKS
,EBA_DP_FW
,EBA_DP_HISTORY
,EBA_DP_INVOCATIONS
,EBA_DP_NOTES
,EBA_DP_NOTIFICATIONS
,EBA_DP_PARSER
,EBA_DP_PDF
,EBA_DP_PDF_RPT
,EBA_DP_PDF_RPT_SRC
,EBA_DP_PDF_RPT_SRC_COLS
,EBA_DP_PREFERENCES
,EBA_DP_REPORTS
,EBA_DP_REPORT_PERMS
,EBA_DP_REPORT_VALIDATIONS
,EBA_DP_RESERVED_NAMES
,EBA_DP_RPT_TYPES
,EBA_DP_RPT_VAL_DEPENDENCYS
,EBA_DP_RPT_VAL_HISTORY_V
,EBA_DP_RPT_VAL_V
,EBA_DP_SECURITY
,EBA_DP_TAGS
,EBA_DP_TAGS_SUM
,EBA_DP_TAGS_TYPE_SUM
,EBA_DP_UI
,EBA_DP_USERS
,EBA_DP_USER_PREF
,EBA_DP_VIEWERS
,EBA_DP_VIEWER_GROUPS
,EBA_DP_VIEWER_GROUP_REF
,EBA_DP_WHITELIST_OBJECTS
,EBA_DP_WIDGETS
,EBA_DP_WIDGET_TYPES
,EBA_GLCL
,EBA_GLCLS_REMOVE_DATA
,EBA_GLCL_ACCESS_LEVELS
,EBA_GLCL_CATEGORIES
,EBA_GLCL_DATA_LOAD
,EBA_GLCL_ERRORS
,EBA_GLCL_ERROR_LOOKUP
,EBA_GLCL_FILES
,EBA_GLCL_FW
,EBA_GLCL_HELP_PAGE
,EBA_GLCL_HISTORY
,EBA_GLCL_ITEMS
,EBA_GLCL_LINKS
,EBA_GLCL_NOTES
,EBA_GLCL_NOTIFICATIONS
,EBA_GLCL_PREFERENCES
,EBA_GLCL_PROJECTS
,EBA_GLCL_RPT
,EBA_GLCL_SEQ
,EBA_GLCL_STATUS_CODES
,EBA_GLCL_SUB_CATEGORIES
,EBA_GLCL_TAGS
,EBA_GLCL_TAGS_SUM
,EBA_GLCL_TAGS_TYPE_SUM
,EBA_GLCL_TZ_PREF
,EBA_GLCL_USERS
,EBA_LIVEPOLL
,EBA_LIVEPOLL_ACCOUNT
,EBA_LIVEPOLL_EMAIL_API
,EBA_LIVEPOLL_FW
,EBA_LIVEPOLL_QUIZ
,EBA_SALES_ACL_API
,EBA_SALES_DATA
,EBA_SALES_FW
,EBA_SB
,EBA_SB_EMAIL_API
,EBA_SB_FW
,EBA_SB_SAMPLE';

$end -- $if cfg_pkg.c_testing $then

  /* EXCEPTIONS */

  e_not_a_directed_acyclic_graph exception;
  pragma exception_init(e_not_a_directed_acyclic_graph, -20001);

  -- ORA-31603: object ... of type MATERIALIZED_VIEW not found in schema ...
  e_object_not_found exception;
  pragma exception_init(e_object_not_found, -31603);

  -- ORA-31623: a job is not attached to this session via the specified handle
  e_job_is_not_attached exception;
  pragma exception_init(e_job_is_not_attached, -31623);

  -- ORA-31604: invalid transform NAME parameter "MODIFY" for object type ON_USER_GRANT in function ADD_TRANSFORM
  e_invalid_transform_parameter exception;
  pragma exception_init(e_invalid_transform_parameter, -31604);

  -- ORA-31602: parameter OBJECT_TYPE value "XMLSCHEMA" in function ADD_TRANSFORM inconsistent with HANDLE
  e_wrong_transform_object_type exception;
  pragma exception_init(e_wrong_transform_object_type, -31602);


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
  -- AUTHID DEFINER) the AUTHID for pkg_ddl_util will be the same,
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

  -- Oracle 10g does not allow us to store a ref cursor as a package variable
  -- not does it allow us to retrieve collections via dbms_sql.
  -- So just put everything into a collection in set_display_ddl_schema_args().
  g_schema_ddl_tab t_schema_ddl_tab;
$else
  -- PLS-00994: Cursor Variables cannot be declared as part of a package
  -- So store a dbms_sql cursor (integer) and convert to sys_refcursor whenever necessary.
  -- Only available in Oracle 11g and above.
  g_cursor integer := null;
$end

  g_clob clob := null;

  -- DBMS_METADATA object types voor DBA gerelateerde taken (DBA rol)
  g_dba_md_object_type_tab constant t_text_tab := t_text_tab( 'CONTEXT'
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
  g_public_md_object_type_tab constant t_text_tab := t_text_tab('DB_LINK');

  -- DBMS_METADATA object types ordered by least dependencies (see also sort_objects_by_deps)
  g_schema_md_object_type_tab constant t_text_tab :=
    t_text_tab
    ( 'SEQUENCE'
    , 'TYPE_SPEC'
    , 'CLUSTER'
$if pkg_ddl_util.c_get_queue_ddl $then
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
$if pkg_ddl_util.c_get_db_link_ddl $then
    , 'DB_LINK'
$end                                                                                   
$if pkg_ddl_util.c_get_dimension_ddl $then
    , 'DIMENSION'
$end                                                                                   
$if pkg_ddl_util.c_get_indextype_ddl $then
    , 'INDEXTYPE'
$end                                                                                   
    , 'JAVA_SOURCE'
$if pkg_ddl_util.c_get_library_ddl $then
    , 'LIBRARY'
$end                                                                                   
$if pkg_ddl_util.c_get_operator_ddl $then
    , 'OPERATOR'
$end                                                                                   
    , 'REFRESH_GROUP'
$if pkg_ddl_util.c_get_xmlschema_ddl $then
    , 'XMLSCHEMA'
$end 
    , 'PROCOBJ'
    );

  g_chk_tab t_object_natural_tab;

  g_transform_param_tab t_transform_param_tab;

  /* PRIVATE ROUTINES */

  type t_longops_rec is record (
    rindex binary_integer
  , slno binary_integer
  , sofar binary_integer
  , totalwork binary_integer
  , op_name varchar2(64 char)
  , units varchar2(10 char)
  , target_desc varchar2(32 char)
  );

  procedure longops_show
  ( p_longops_rec in out nocopy t_longops_rec
  , p_increment in naturaln default 1
  )
  is
  begin
    p_longops_rec.sofar := p_longops_rec.sofar + p_increment;
    dbms_application_info.set_session_longops( rindex => p_longops_rec.rindex
                                             , slno => p_longops_rec.slno
                                             , op_name => p_longops_rec.op_name
                                             , sofar => p_longops_rec.sofar
                                             , totalwork => p_longops_rec.totalwork
                                             , target_desc => p_longops_rec.target_desc
                                             , units => p_longops_rec.units
                                             );
  end longops_show;                                             

  function longops_init
  ( p_target_desc in varchar2
  , p_totalwork in binary_integer default 0
  , p_op_name in varchar2 default 'fetch'
  , p_units in varchar2 default 'rows'
  )
  return t_longops_rec
  is
    l_longops_rec t_longops_rec;
  begin
    l_longops_rec.rindex := dbms_application_info.set_session_longops_nohint;
    l_longops_rec.slno := null;
    l_longops_rec.sofar := 0;
    l_longops_rec.totalwork := p_totalwork;
    l_longops_rec.op_name := p_op_name;
    l_longops_rec.units := p_units;
    l_longops_rec.target_desc := p_target_desc;

    longops_show(l_longops_rec, 0);

    return l_longops_rec;
  end longops_init;

  procedure longops_done
  ( p_longops_rec in out nocopy t_longops_rec
  )
  is
  begin
    if p_longops_rec.totalwork = p_longops_rec.sofar
    then
      null; -- nothing has changed and dbms_application_info.set_session_longops() would show a duplicate
    else
      p_longops_rec.totalwork := p_longops_rec.sofar;
      longops_show(p_longops_rec, 0);
    end if;
  end longops_done;

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
        select  dbms_assert.enquote_name(t.db_link)
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
      raise_application_error(c_schema_wrong, p_description || ' is empty and the network link not.');
    elsif p_schema is not null and
          p_network_link is null and
          dbms_assert.schema_name(p_schema) is null
    then
      raise_application_error
      ( c_schema_does_not_exist
      , p_description || '"' || p_schema || '"' || ' does not exist.'
      ); -- hier komt ie niet omdat dbms_assert.schema_name() al een exceptie genereert
    end if;
  end check_schema;

  procedure check_numeric_boolean
  ( p_numeric_boolean in t_numeric_boolean
  , p_description in varchar2 
  )
  is
  begin
    if (p_numeric_boolean is not null and p_numeric_boolean not in (0, 1))
    then
      raise_application_error(c_numeric_boolean_wrong, p_description || ' (' || p_numeric_boolean || ') is not empty and not 0 or 1.');
    end if;
  end check_numeric_boolean;

  procedure check_object_names
  ( p_object_names in t_object_names
  , p_object_names_include in t_numeric_boolean
  )
  is
  begin
    if (p_object_names is not null and p_object_names_include is null)
    then
      raise_application_error
      ( c_object_names_wrong
      , 'The include flag (' ||
        p_object_names_include ||
        ') is empty and the list of object names is not empty:' ||
        chr(10) ||
        '"' ||
        p_object_names ||
        '"'
      );
    elsif (p_object_names is null and p_object_names_include is not null)
    then
      raise_application_error
      ( c_object_names_wrong
      , 'The include flag (' ||
        p_object_names_include ||
        ') is not empty and the list of object names is empty:' ||
        chr(10) ||
        '"' ||
        p_object_names ||
        '"'
      );
    end if;
  end check_object_names;

  procedure check_network_link
  ( p_network_link in t_network_link
  , p_description in varchar2 default 'Database link'
  )
  is
  begin
    if p_network_link is not null and
       get_db_link(p_network_link) is null
    then
      raise_application_error(c_database_link_does_not_exist, p_description || ' "' || p_network_link || '" unknown.');
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
      raise_application_error(c_source_and_target_equal, 'Source and target may not be equal.');
    end if;
  end check_source_target;

  procedure check_object_type
  ( p_object_type in t_metadata_object_type
  )
  is
  begin
    if p_object_type is null or
$if not(pkg_ddl_util.c_get_queue_ddl) $then
       p_object_type in ('AQ_QUEUE', 'AQ_QUEUE_TABLE') or
$end
       p_object_type in ('CONSTRAINT', 'REF_CONSTRAINT') or
       p_object_type member of g_schema_md_object_type_tab
    then
      null; -- ok
    else
      raise_application_error(c_object_type_wrong, 'Object type (' || p_object_type || ') is not one of the metadata schema object types.');
    end if;
  end check_object_type;

$if cfg_pkg.c_debugging $then

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
  , p_text_tab in t_text_tab
  )
  is
    l_str varchar2(32767 char);
    l_line_tab dbms_sql.varchar2a;
  begin
    if p_text_tab is not null and p_text_tab.count > 0
    then
      l_str := p_text_tab(p_text_tab.first); -- to prevent a VALUE_ERROR (?!)
      pkg_str_util.split(p_str => l_str, p_delimiter => chr(10), p_str_tab => l_line_tab);
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
  )
  is
    l_m t_object;
  begin
    if p_marked_nodes.exists(p_n)
    then
      if p_marked_nodes(p_n) = 1 /* A */
      then
        raise_application_error(c_not_a_directed_acyclic_graph, 'Node ' || p_n || ' has been visited before.');
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
          ); /* E */
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
  )
  is
    l_unmarked_nodes t_object_natural_tab;
    l_marked_nodes t_object_natural_tab; -- l_marked_nodes(n) = 1 (temporarily marked) or 2 (permanently marked)
    l_n t_object;
    l_m t_object;
  begin
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
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
      );
    end loop;

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
    dbug.leave;
  exception
    when others
    then
      dbug.leave_on_error;
      raise;
$end
  end tsort;

  function get_host(p_network_link in varchar2)
  return varchar2
  is
    l_host all_db_links.host%type;
  begin
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
    dbug.enter(g_package_prefix || 'GET_HOST');
    dbug.print(dbug."input", 'p_network_link: %s', p_network_link);
$end

    if p_network_link is null
    then
      select dbms_assert.enquote_name(t.global_name) into l_host from global_name t;
    else
      select dbms_assert.enquote_name(t.host) into l_host from all_db_links t where t.db_link = upper(p_network_link);
    end if;

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
    dbug.print(dbug."output", 'return: %s', l_host);
    dbug.leave;
$end

    return l_host;
  exception
    when others then
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
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
    procedure parse_alter
    is
      l_constraint varchar2(32767 char) := dbms_lob.substr(lob_loc => p_ddl.ddlText, amount => 32767);
      l_constraint_expr_tab constant t_text_tab :=
        t_text_tab
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
          'ALTER % "%"."%" MODIFY ("%" NOT NULL ENABLE)%' -- system generated not null constraint
        , -- 7) ALTER TABLE "BATCHPRICEAGREEMENTS" MODIFY ("SEQ" GENERATED BY DEFAULT AS IDENTITY MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH  LIMIT VALUE  NOCACHE  ORDER  NOCYCLE );
          'ALTER % "%"."%" MODIFY ("%" GENERATED %)%' -- identity management
        );

      l_pos1 pls_integer := null;
      l_pos2 pls_integer := null;
      l_column_names varchar2(32767 char);
      l_search_condition varchar2(32767 char);

      l_base_object t_named_object;
      l_ref_object t_named_object;
      l_constraint_object t_constraint_object := null;
      l_ref_object_schema t_schema;
      l_ref_object_type t_metadata_object_type;
      l_ref_object_name t_object;

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
    begin
      -- skip whitespace at the beginning
      l_pos1 := 1;
      l_pos2 := length(l_constraint);
      while l_pos1 <= l_pos2 and substr(l_constraint, l_pos1, 1) in (chr(9), chr(10), chr(13), chr(32))
      loop
        l_pos1 := l_pos1 + 1;
      end loop;
      l_constraint := substr(l_constraint, l_pos1);

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
      dbug.print(dbug."info", 'l_constraint: "%s"', l_constraint);
$end
      if l_constraint like l_constraint_expr_tab(1)
      or l_constraint like l_constraint_expr_tab(2)
      or l_constraint like l_constraint_expr_tab(3)
      or l_constraint like l_constraint_expr_tab(4)
      or l_constraint like l_constraint_expr_tab(5)
      or l_constraint like l_constraint_expr_tab(6)
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

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
        dbug.print
        ( dbug."info"
        , 'p_object_type: %s; named constraint?: %s'
        , p_object_type
        , dbug.cast_to_varchar2(l_constraint like l_constraint_expr_tab(1))
        );
$end
        -- NAMED CONSTRAINT?
        -- GPA 2016-11-24
        -- When object type is TABLE/VIEW, the object name is the name of the TABLE/VIEW and not the name of the constraint.
        if p_object_type in ('TABLE', 'VIEW') and
           l_constraint like l_constraint_expr_tab(1)
        then
          l_pos1 := instr(l_constraint, '"', 1, 5);
          l_pos2 := instr(l_constraint, '"', 1, 6);
          p_object_name := substr(l_constraint, l_pos1+1, l_pos2 - (l_pos1+1));
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
          dbug.print
          ( dbug."info"
          , 'l_pos1: %s; l_pos2: %s; p_object_name: %s'
          , l_pos1
          , l_pos2
          , p_object_name
          );
$end
        -- UNNAMED NON CHECK CONSTRAINT?
        elsif p_object_type in ('TABLE', 'VIEW') and
              ( l_constraint like l_constraint_expr_tab(2) or
                l_constraint like l_constraint_expr_tab(3) or
                l_constraint like l_constraint_expr_tab(4) )
        then
          -- get the column names (without spaces)
          l_pos1 := instr(l_constraint, '(');
          l_pos2 := instr(l_constraint, ')');
          if l_pos1 > 0 and l_pos2 > l_pos1
          then
            l_column_names := replace(substr(l_constraint, l_pos1+1, l_pos2 - (l_pos1+1)), ' ');

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
            dbug.print
            ( dbug."info"
            , 'l_pos1: %s; l_pos2: %s; l_column_names: %s'
            , l_pos1
            , l_pos2
            , l_column_names
            );
$end

            l_base_object :=
              t_named_object.create_named_object
              ( p_object_type => p_base_object_type
              , p_object_schema => p_base_object_schema
              , p_object_name => p_base_object_name
              );

            case
              when l_constraint like l_constraint_expr_tab(2) -- primary key
              then l_constraint_object := t_constraint_object
                                          ( p_base_object => l_base_object
                                          , p_object_schema => p_base_object_schema
                                          , p_object_name => null -- constraint name is not known
                                          , p_constraint_type => 'P'
                                          , p_column_names => l_column_names
                                          );
              when l_constraint like l_constraint_expr_tab(3) -- unique key
              then l_constraint_object := t_constraint_object
                                          ( p_base_object => l_base_object
                                          , p_object_schema => p_base_object_schema
                                          , p_object_name => null -- constraint name is not known
                                          , p_constraint_type => 'U'
                                          , p_column_names => l_column_names
                                          );
              when l_constraint like l_constraint_expr_tab(4) -- foreign key
              then
                -- ALTER TABLE "<owner>"."<table>" ADD FOREIGN KEY ("CMMSEQ") REFERENCES "<owner>"."<rtable>" ("SEQ")

                -- get the reference object schema, since l_pos2 is the position of the first ')'
                l_pos1 := instr(l_constraint, '"', l_pos2+1);
                l_pos2 := instr(l_constraint, '"', l_pos1+1);
                l_ref_object_schema := substr(l_constraint, l_pos1+1, l_pos2 - (l_pos1+1));

                l_pos1 := instr(l_constraint, '"', l_pos2+1);
                l_pos2 := instr(l_constraint, '"', l_pos1+1);
                l_ref_object_name := substr(l_constraint, l_pos1+1, l_pos2 - (l_pos1+1));

                select  min(oracle_tools.t_schema_object.dict2metadata_object_type(obj.object_type)) -- always return one value
                into    l_ref_object_type
                from    all_objects obj
                where   obj.owner = l_ref_object_schema
                and     obj.object_name = l_ref_object_name;

                l_ref_object :=
                  t_named_object.create_named_object
                  ( p_object_schema => l_ref_object_schema
                  , p_object_type => l_ref_object_type
                  , p_object_name => l_ref_object_name
                  );

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
                l_ref_object.print();
$end

                l_constraint_object := t_ref_constraint_object
                                       ( p_base_object => l_base_object
                                       , p_object_schema => p_base_object_schema
                                       , p_object_name => null -- constraint name unknown
                                       , p_constraint_type => 'R'
                                       , p_column_names => l_column_names
                                       , p_ref_object => l_ref_object
                                       );
            end case;

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
            l_constraint_object.print();
$end

            begin
              p_object_name := p_object_lookup_tab(p_constraint_lookup_tab(l_constraint_object.signature())).schema_ddl.obj.object_name();
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
              dbug.print( dbug."info", 'p_object_name (%s) determined by lookup', p_object_name);
$end
            exception
              when others
              then
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
                dbug.print( dbug."warning", 'p_object_name could not be determined by lookup: %s', sqlerrm);
$end
                for r_cc in
                ( select  c.constraint_name
                  ,       oracle_tools.t_constraint_object.get_column_names
                          ( c.owner
                          , c.constraint_name
                          , c.table_name
                          ) as column_names
                  from    all_constraints c
                  where   c.owner = p_schema
                  and     c.table_name = p_base_object_name
                )
                loop
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
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
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
                    dbug.print( dbug."info", 'p_object_name (%s) determined by dictionary search', p_object_name);
$end
                    exit;
                  end if;
                end loop;
            end;
          end if; -- if l_pos1 > 0 and l_pos2 > l_pos1

        -- UNNAMED CHECK CONSTRAINT?
        elsif p_object_type in ('TABLE', 'VIEW') and
              ( l_constraint like l_constraint_expr_tab(5) or
                l_constraint like l_constraint_expr_tab(6)
              )
        then
          l_pos1 := instr(l_constraint, '(');
          l_pos2 := instr(l_constraint, ')', -1); -- get the last parenthesis
          if l_pos1 > 0 and l_pos2 > l_pos1
          then
            l_search_condition := substr(l_constraint, l_pos1+1, l_pos2 - (l_pos1+1));

            if l_constraint like l_constraint_expr_tab(6)
            then
              l_search_condition := replace(l_search_condition, ' NOT NULL ENABLE', ' IS NOT NULL');
            end if;

            l_base_object :=
              t_named_object.create_named_object
              ( p_object_type => p_base_object_type
              , p_object_schema => p_base_object_schema
              , p_object_name => p_base_object_name
              );

            l_constraint_object := t_constraint_object
                                   ( p_base_object => l_base_object
                                   , p_object_schema => p_base_object_schema
                                   , p_object_name => null -- constraint name is not known
                                   , p_constraint_type => 'C'
                                   , p_search_condition => l_search_condition
                                   );

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
            l_constraint_object.print();
$end

            begin
              p_object_name := p_object_lookup_tab(p_constraint_lookup_tab(l_constraint_object.signature())).schema_ddl.obj.object_name();
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
              dbug.print( dbug."info", 'p_object_name (%s) determined by lookup', p_object_name);
$end
            exception
              when others
              then
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
                dbug.print( dbug."warning", 'p_object_name could not be determined by lookup: %s', sqlerrm);
$end
                open c_con(b_schema => p_schema, b_table_name => p_base_object_name);
                <<fetch_loop>>
                loop
                  fetch c_con into r_con;

                  exit fetch_loop when c_con%notfound;

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
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
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
                    dbug.print( dbug."info", 'p_object_name (%s) determined by dictionary search', p_object_name);
$end
                    exit fetch_loop;
                  end if;
                end loop fetch_loop;
                close c_con;
            end;
          end if; -- if l_pos1 > 0 and l_pos2 > l_pos1
        end if; -- if p_object_type in ('TABLE', 'VIEW') and

        -- Oracle DBMS_METADATA bug?
        -- <owner>:CONSTRAINT:UN_DG_LIST_UN_DG_CLASSIFI_FK1::::
        -- =>
        -- <owner>:REF_CONSTRAINT:UN_DG_LIST_UN_DG_CLASSIFI_FK1::::

        p_object_type := case when instr(l_constraint, ' FOREIGN KEY ') > 0 then 'REF_CONSTRAINT' else 'CONSTRAINT' end;
      elsif l_constraint not like l_constraint_expr_tab(7)
      then
        raise_application_error(-20000, 'Could not parse "' || l_constraint || '"');
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
      l_comment constant all_tab_comments.comments%type := dbms_lob.substr(lob_loc => p_ddl.ddlText, amount => case when l_pos1 > 0 then l_pos1 else 2000 end);
    begin
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
            and     obj.generated = 'N' -- GPA 2016-12-19 #136334705
            ;

          when l_comment like '% ON MATERIALIZED VIEW %'
          then
            p_base_object_type := 'MATERIALIZED_VIEW';

          else -- column
            select  min(obj.object_type)
            into    p_base_object_type
            from    all_objects obj
            where   obj.owner = p_schema
            and     obj.object_name = p_base_object_name
            and     obj.object_type in ( 'TABLE', 'MATERIALIZED VIEW', 'VIEW' )
            and     obj.generated = 'N' -- GPA 2016-12-19 #136334705
            ;

        end case;
      end if;
    exception
      when others
      then
        raise_application_error
        ( -20000
        , 'Comment: ' || l_comment ||
          '; p_schema: ' || p_schema ||
          '; p_base_object_name: ' || p_base_object_name
        , true
        );
    end parse_comment;

    procedure parse_procobj
    is
      l_plsql_block varchar2(4000 char) := dbms_lob.substr(lob_loc => p_ddl.ddlText, amount => 4000);
      l_pos1 pls_integer := null;
      l_pos2 pls_integer := null;
    begin
      if upper(l_plsql_block) like q'[%DBMS_SCHEDULER.CREATE_%('"%"'%]'
      then
        l_pos1 := instr(l_plsql_block, '"', 1, 1);
        l_pos2 := instr(l_plsql_block, '"', 1, 2);
        p_object_name := substr(l_plsql_block, l_pos1+1, l_pos2 - (l_pos1+1));
      end if;
    end parse_procobj;

    procedure parse_index
    is
      l_index varchar2(4000 char) := dbms_lob.substr(lob_loc => p_ddl.ddlText, amount => 4000);
      l_pos1 pls_integer := null;
      l_pos2 pls_integer := null;
    begin
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
    end parse_index;

    procedure parse_object_grant
    is
      l_object_grant varchar2(4000 char) := dbms_lob.substr(lob_loc => p_ddl.ddlText, amount => 4000);
      l_pos1 pls_integer := null;
      l_pos2 pls_integer := null;
    begin
      -- GRANT SELECT ON "<owner>"."<table>" TO "<owner>";
      -- or
      -- GRANT SELECT ON "<owner>"."<table>" TO "<owner>" WITH GRANT OPTION;
      p_grantable := case when l_object_grant like '% WITH GRANT OPTION%' then 'YES' else 'NO' end;
      l_pos1 := instr(l_object_grant, 'GRANT ') + length('GRANT ');
      l_pos2 := instr(l_object_grant, ' ON "');
      p_privilege := substr(l_object_grant, l_pos1, l_pos2 - l_pos1);
    end parse_object_grant;

  begin
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
    dbug.enter(g_package_prefix || 'PARSE_DDL');
    dbug.print
    ( dbug."input"
    , 'p_schema: %s; p_ddl.ddlText: %s'
    , p_schema
    , dbms_lob.substr(lob_loc => p_ddl.ddlText, amount => 100)
    );
$end

    if p_ddl.parseditems is not null and
       p_ddl.parseditems.count > 0
    then
      <<parse_item_loop>>
      for i_parsed_item_idx in p_ddl.parseditems.first .. p_ddl.parseditems.last
      loop
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
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
            p_object_type := t_schema_object.dict2metadata_object_type(p_ddl.parseditems(i_parsed_item_idx).value);
          when 'SCHEMA' then
            p_object_schema := p_ddl.parseditems(i_parsed_item_idx).value;
          when 'BASE_OBJECT_NAME' then
            p_base_object_name := p_ddl.parseditems(i_parsed_item_idx).value;
          when 'BASE_OBJECT_TYPE' then
            p_base_object_type := t_schema_object.dict2metadata_object_type(p_ddl.parseditems(i_parsed_item_idx).value);
          when 'BASE_OBJECT_SCHEMA' then
            p_base_object_schema := p_ddl.parseditems(i_parsed_item_idx).value;
          when 'GRANTEE' then
            p_grantee := p_ddl.parseditems(i_parsed_item_idx).value;
        end case;
      end loop parse_item_loop;

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
      end if;
    end if;

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
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
  exception
    when others then
      dbug.leave_on_error;
      raise;
$end
  end parse_ddl;

  procedure i_object_exclude_name_expr_tab
  is
    procedure add(p_object_type in varchar2, p_exclude_name_expr in varchar2)
    is
    begin
      if not(g_object_exclude_name_expr_tab.exists(p_object_type))
      then
        g_object_exclude_name_expr_tab(p_object_type) := t_text_tab();
      end if;

      g_object_exclude_name_expr_tab(p_object_type).extend(1);
      g_object_exclude_name_expr_tab(p_object_type)(g_object_exclude_name_expr_tab(p_object_type).last) := p_exclude_name_expr;
    end add;

    procedure add(p_object_type_tab in t_text_tab, p_exclude_name_expr in varchar2)
    is
    begin
      for i_idx in p_object_type_tab.first .. p_object_type_tab.last
      loop
        add(p_object_type_tab(i_idx), p_exclude_name_expr);
      end loop;
    end add;
  begin
    -- no dropped tables
    add(t_text_tab('TABLE', 'INDEX', 'TRIGGER', 'OBJECT_GRANT'), 'BIN$%');

    -- no AQ indexes/views
    add(t_text_tab('INDEX', 'VIEW', 'OBJECT_GRANT'), 'AQ$%');

    -- no Flashback archive tables/indexes
    add(t_text_tab('TABLE', 'INDEX'), 'SYS\_FBA\_%');

    -- no system generated indexes
    add('INDEX', 'SYS\_C%');

    -- no generated types by declaring pl/sql table types in package specifications
    add(t_text_tab('SYNONYM', 'TYPE_SPEC', 'TYPE_BODY', 'OBJECT_GRANT'), 'SYS\_PLSQL\_%');

    -- see http://orasql.org/2012/04/28/a-funny-fact-about-collect/
    add(t_text_tab('SYNONYM', 'TYPE_SPEC', 'TYPE_BODY', 'OBJECT_GRANT'), 'SYSTP%');

    -- no datapump tables, see pkg_datapump_util
    add(t_text_tab('TABLE', 'OBJECT_GRANT'), 'SYS\_SQL\_FILE\_SCHEMA%');
    add(t_text_tab('TABLE', 'OBJECT_GRANT'), user || '\_DDL');
    add(t_text_tab('TABLE', 'OBJECT_GRANT'), user || '\_DML');
    -- no Oracle generated datapump tables
    add(t_text_tab('TABLE', 'OBJECT_GRANT'), 'SYS\_EXPORT\_FULL\_%');

    -- no Flyway stuff
    -- old schema history table
    add(t_text_tab('TABLE', 'OBJECT_GRANT', 'INDEX', 'CONSTRAINT', 'REF_CONSTRAINT'), 'schema_version%');
    -- new schema history table
    add(t_text_tab('TABLE', 'OBJECT_GRANT', 'INDEX', 'CONSTRAINT', 'REF_CONSTRAINT'), 'flyway_schema_history%');

    -- no identity column sequences
    add(t_text_tab('SEQUENCE', 'OBJECT_GRANT'), 'ISEQ$$%');
  end i_object_exclude_name_expr_tab;

  procedure md_set_remap_param
  ( p_object_type in varchar2
  , p_object_schema in varchar2
  , p_new_object_schema in varchar2
  , p_base_object_schema in varchar2
  , p_handle in number
  )
  is
    l_transform_handle number := null;
    l_object_type_tab t_text_tab;
  begin
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
    dbug.enter(g_package_prefix || 'MD_SET_REMAP_PARAM');
    dbug.print(dbug."input"
               ,'p_object_type: %s; p_object_schema: %s; p_new_object_schema: %s; p_base_object_schema: %s'
               ,p_object_type
               ,p_object_schema
               ,p_new_object_schema
               ,p_base_object_schema);
$end

    -- first, are we going to remap?
    if p_object_schema != p_new_object_schema or p_base_object_schema != p_new_object_schema
    then
      if p_object_type = 'SCHEMA_EXPORT'
      then
        if p_object_schema != p_new_object_schema
        then
          l_object_type_tab := g_schema_md_object_type_tab;

          for i_idx in l_object_type_tab.first .. l_object_type_tab.last
          loop
            begin
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
              dbug.print(dbug."info", 'l_object_type_tab(%s): %s', i_idx, l_object_type_tab(i_idx));
$end
              l_transform_handle :=
                dbms_metadata.add_transform
                ( handle => p_handle
                , name => 'MODIFY'
                , object_type => l_object_type_tab(i_idx)
                );

              if p_object_schema != p_new_object_schema
              then
                dbms_metadata.set_remap_param
                ( transform_handle => l_transform_handle
                , name => 'REMAP_SCHEMA'
                , old_value => p_object_schema
                , new_value => p_new_object_schema
                , object_type => l_object_type_tab(i_idx)
                );
              end if;
              if p_base_object_schema != p_new_object_schema
              then
                dbms_metadata.set_remap_param
                ( transform_handle => l_transform_handle
                , name => 'REMAP_SCHEMA'
                , old_value => p_base_object_schema
                , new_value => p_new_object_schema
                , object_type => l_object_type_tab(i_idx)
                );
              end if;
            exception
              when e_invalid_transform_parameter or e_wrong_transform_object_type
              then
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
                dbug.on_error;
$end
                null;
            end;
          end loop;
        end if;
      else
        begin
          l_transform_handle := dbms_metadata.add_transform(handle => p_handle, name => 'MODIFY');

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

              if p_object_schema != p_new_object_schema
              then
                dbms_metadata.set_remap_param(transform_handle => l_transform_handle
                                             ,name => 'REMAP_SCHEMA'
                                             ,old_value => p_object_schema
                                             ,new_value => p_new_object_schema);
              end if;
            else
              if is_dependent_object_type(p_object_type => p_object_type) = 1
              then
                null; -- OK
              else
                raise program_error;
              end if;

              if p_base_object_schema != p_new_object_schema
              then
                dbms_metadata.set_remap_param(transform_handle => l_transform_handle
                                             ,name => 'REMAP_SCHEMA'
                                             ,old_value => p_base_object_schema
                                             ,new_value => p_new_object_schema);
              end if;
            end if;
          elsif p_object_type = 'SYNONYM'
          then
            if p_object_schema != 'PUBLIC' and p_object_schema != p_new_object_schema
            then
              dbms_metadata.set_remap_param(transform_handle => l_transform_handle
                                           ,name => 'REMAP_SCHEMA'
                                           ,old_value => p_object_schema
                                           ,new_value => p_new_object_schema);
            elsif p_object_schema = 'PUBLIC' and p_base_object_schema != p_new_object_schema
            then
              dbms_metadata.set_remap_param(transform_handle => l_transform_handle
                                           ,name => 'REMAP_SCHEMA'
                                           ,old_value => p_base_object_schema
                                           ,new_value => p_new_object_schema);
            end if;
          else
            if p_object_schema != 'DBA'
            then
              if p_object_schema != p_new_object_schema
              then
                dbms_metadata.set_remap_param(transform_handle => l_transform_handle
                                             ,name => 'REMAP_SCHEMA'
                                             ,old_value => p_object_schema
                                             ,new_value => p_new_object_schema);
              end if;
            end if;
          end if;
        exception
          when e_invalid_transform_parameter or e_wrong_transform_object_type
          then
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
            dbug.on_error;
$end
            null;
        end;
      end if; -- if p_object_type = 'SCHEMA_EXPORT'
    end if;

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
    dbug.leave;
  exception
    when others
    then
      dbug.leave_on_error;
      raise;
$end
  end md_set_remap_param;

  procedure get_transform_param_tab
  ( p_transform_param_list in varchar2
  , p_transform_param_tab out nocopy t_transform_param_tab
  )
  is
    l_line_tab dbms_sql.varchar2a;
  begin
    p_transform_param_tab := g_transform_param_tab;

    if p_transform_param_list is not null
    then
      pkg_str_util.split(p_str => p_transform_param_list, p_delimiter => ',', p_str_tab => l_line_tab);
      if l_line_tab.count > 0
      then
        for i_idx in l_line_tab.first .. l_line_tab.last
        loop
          p_transform_param_tab(upper(trim(l_line_tab(i_idx)))) := true;
        end loop;
      end if;
    end if;
  end get_transform_param_tab;

  procedure md_set_transform_param
  ( p_transform_handle in number default dbms_metadata.session_transform
  , p_object_type_tab in t_text_tab default t_text_tab('INDEX', 'TABLE', 'CLUSTER', 'CONSTRAINT', 'TABLE', 'VIEW', 'TYPE_SPEC')
  , p_use_object_type_param in boolean default false
  , p_transform_param_tab in t_transform_param_tab default g_transform_param_tab
  )
  is
  begin
    dbms_metadata.set_transform_param(p_transform_handle, 'PRETTY'              , true );
    dbms_metadata.set_transform_param(p_transform_handle, 'SQLTERMINATOR'       , c_use_sqlterminator );

    for i_idx in p_object_type_tab.first .. p_object_type_tab.last
    loop
      if p_object_type_tab(i_idx) in ('TABLE', 'INDEX', 'CLUSTER', 'CONSTRAINT', 'ROLLBACK_SEGMENT', 'TABLESPACE')
      then
        dbms_metadata.set_transform_param(p_transform_handle, 'SEGMENT_ATTRIBUTES'  , p_transform_param_tab('SEGMENT_ATTRIBUTES'), case when p_use_object_type_param then p_object_type_tab(i_idx) end);
        dbms_metadata.set_transform_param(p_transform_handle, 'STORAGE'             , p_transform_param_tab('STORAGE'           ), case when p_use_object_type_param then p_object_type_tab(i_idx) end);
        dbms_metadata.set_transform_param(p_transform_handle, 'TABLESPACE'          , p_transform_param_tab('TABLESPACE'        ), case when p_use_object_type_param then p_object_type_tab(i_idx) end);
      end if;
      if p_object_type_tab(i_idx) = 'TABLE'
      then
        dbms_metadata.set_transform_param(p_transform_handle, 'REF_CONSTRAINTS'     , true , case when p_use_object_type_param then p_object_type_tab(i_idx) end);
        dbms_metadata.set_transform_param(p_transform_handle, 'CONSTRAINTS_AS_ALTER', true , case when p_use_object_type_param then p_object_type_tab(i_idx) end);
      end if;
      if p_object_type_tab(i_idx) in ('TABLE', 'VIEW')
      then
        dbms_metadata.set_transform_param(p_transform_handle, 'CONSTRAINTS'         , true , case when p_use_object_type_param then p_object_type_tab(i_idx) end);
      end if;
      if p_object_type_tab(i_idx) = 'VIEW'
      then
        -- GPA 2016-12-01 The FORCE keyword may be removed by the generate_ddl.pl script, depending on an option.
        dbms_metadata.set_transform_param(p_transform_handle, 'FORCE'               , true , case when p_use_object_type_param then p_object_type_tab(i_idx) end);
      end if;
      if p_object_type_tab(i_idx) = 'TYPE_SPEC'
      then
        dbms_metadata.set_transform_param(p_transform_handle, 'OID'                 , p_transform_param_tab('OID'), case when p_use_object_type_param then p_object_type_tab(i_idx) end);
      end if;
    end loop;
  end md_set_transform_param;

  procedure md_set_filter
  ( p_object_type in varchar2
  , p_object_schema in varchar2
  , p_object_name_tab in t_text_tab
  , p_base_object_schema in varchar2
  , p_base_object_name_tab in t_text_tab
  , p_handle in number
  )
  is
    function in_list_expr(p_object_name_tab in t_text_tab)
    return varchar2
    is
      l_in_list varchar2(32767 char) := 'IN (';
    begin
      if p_object_name_tab is not null and p_object_name_tab.count > 0
      then
        for i_idx in p_object_name_tab.first .. p_object_name_tab.last
        loop
          -- trim tab, linefeed, carriage return and space from the input
          l_in_list := l_in_list || '''' || dbms_assert.simple_sql_name(trim(chr(9) from trim(chr(10) from trim(chr(13) from trim(' ' from p_object_name_tab(i_idx)))))) || ''',';
        end loop;
        l_in_list := rtrim(l_in_list, ',');
      end if;
      l_in_list := l_in_list || ')';

      return l_in_list;
    end in_list_expr;

    procedure set_exclude_name_expr(p_object_type in t_metadata_object_type, p_name in varchar2)
    is
      l_exclude_name_expr_tab t_text_tab;
    begin
      get_exclude_name_expr_tab(p_object_type => p_object_type, p_exclude_name_expr_tab => l_exclude_name_expr_tab);
      if l_exclude_name_expr_tab.count > 0
      then
        for i_idx in l_exclude_name_expr_tab.first .. l_exclude_name_expr_tab.last
        loop
          dbms_metadata.set_filter(handle => p_handle, name => p_name, value => q'[LIKE ']' || l_exclude_name_expr_tab(i_idx) || q'[' ESCAPE '\']');
        end loop;
      end if;
    end set_exclude_name_expr;
  begin
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
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
      dbms_metadata.set_filter(handle => p_handle, name => 'SCHEMA', value => p_object_schema);
      -- dbms_metadata.set_filter(handle => p_handle, name => 'INCLUDE_USER', value => true);
      dbms_metadata.set_filter
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
$if not(pkg_ddl_util.c_get_db_link_ddl) $then
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

          dbms_metadata.set_filter(handle => p_handle, name => 'SYSTEM_GENERATED', value => false);
          dbms_metadata.set_filter(handle => p_handle, name => 'SCHEMA', value => p_object_schema);

          if p_object_name_tab is not null and
             p_object_name_tab.count between 1 and c_max_object_name_tab_count
          then
            dbms_metadata.set_filter(handle => p_handle
                                    ,name => 'NAME_EXPR'
                                    ,value => in_list_expr(p_object_name_tab));
          end if;

          if p_base_object_name_tab is not null and
             p_base_object_name_tab.count between 1 and c_max_object_name_tab_count
          then
            dbms_metadata.set_filter(handle => p_handle
                                    ,name => 'BASE_OBJECT_NAME_EXPR'
                                    ,value => in_list_expr(p_base_object_name_tab));
          end if;

          -- always exclude table "schema_version" and its indexes, constraints
          dbms_metadata.set_filter(handle => p_handle
                                  ,name => 'EXCLUDE_BASE_OBJECT_NAME_EXPR'
                                  ,value => in_list_expr(t_text_tab('schema_version')));
        else
          if is_dependent_object_type(p_object_type => p_object_type) = 1
          then
            null; -- OK
          else
            raise program_error;
          end if;

          dbms_metadata.set_filter(handle => p_handle, name => 'BASE_OBJECT_SCHEMA', value => p_base_object_schema);

          if p_base_object_name_tab is not null and
             p_base_object_name_tab.count between 1 and c_max_object_name_tab_count
          then
            dbms_metadata.set_filter(handle => p_handle
                                    ,name => 'BASE_OBJECT_NAME_EXPR'
                                    ,value => in_list_expr(p_base_object_name_tab));
          end if;

          -- always exclude table "schema_version" and its indexes, constraints
          dbms_metadata.set_filter(handle => p_handle
                                  ,name => 'EXCLUDE_BASE_OBJECT_NAME_EXPR'
                                  ,value => in_list_expr(t_text_tab('schema_version')));
          if p_object_type = 'OBJECT_GRANT'
          then
            set_exclude_name_expr(p_object_type => 'TYPE_SPEC', p_name => 'EXCLUDE_BASE_OBJECT_NAME_EXPR');
          end if;
        end if;
      elsif p_object_type = 'SYNONYM'
      then
        dbms_metadata.set_filter(handle => p_handle, name => 'SCHEMA', value => p_object_schema);

        -- Voor synoniemen moet gelden:
        -- 1a) lange naam van synonym moet gelijk zijn aan korte naam EN
        -- 1b) schema van synoniem is niet PUBLIC of object waar naar verwezen wordt zit in base object schema
        if p_object_schema != 'PUBLIC'
        then
          -- simple custom filter: always allowed
          dbms_metadata.set_filter(handle => p_handle
                                  ,name => 'CUSTOM_FILTER'
                                  ,value => '/* 1a */ KU$.SYN_LONG_NAME = KU$.SCHEMA_OBJ.NAME');
        else
          -- simple custom filter: always allowed
          dbms_metadata.set_filter(handle => p_handle
                                  ,name => 'CUSTOM_FILTER'
                                  ,value => q'[/* 1a */ KU$.SYN_LONG_NAME = KU$.SCHEMA_OBJ.NAME AND /* 1b */ KU$.OWNER_NAME = ']' ||
                                            dbms_assert.schema_name(p_base_object_schema) || q'[']');
        end if;

        if p_object_name_tab is not null and
           p_object_name_tab.count between 1 and c_max_object_name_tab_count
        then
          dbms_metadata.set_filter(handle => p_handle
                                  ,name => 'NAME_EXPR'
                                  ,value => in_list_expr(p_object_name_tab));
        end if;
      else
        if p_object_schema != 'DBA'
        then
          dbms_metadata.set_filter(handle => p_handle, name => 'SCHEMA', value => p_object_schema);
        end if;

        if p_object_type not in ('DEFAULT_ROLE', 'FGA_POLICY', 'ROLE_GRANT')
        then
          if p_object_name_tab is not null and
             p_object_name_tab.count between 1 and c_max_object_name_tab_count
          then
            dbms_metadata.set_filter(handle => p_handle
                                    ,name => 'NAME_EXPR'
                                    ,value => in_list_expr(p_object_name_tab));
          end if;

          -- always exclude table "schema_version"
          dbms_metadata.set_filter(handle => p_handle
                                  ,name => 'EXCLUDE_NAME_EXPR'
                                  ,value => in_list_expr(t_text_tab('schema_version')));
        end if;

        if p_object_type = 'TABLE'
        then
          dbms_metadata.set_filter(handle => p_handle, name => 'SECONDARY', value => false);
        end if;
      end if;

      if p_object_type <> 'OBJECT_GRANT'
      then
        set_exclude_name_expr(p_object_type => p_object_type, p_name => 'EXCLUDE_NAME_EXPR');
      end if;
    end if; -- if p_object_type = 'SCHEMA_EXPORT'

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
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
  , p_object_name_tab in t_text_tab
  , p_new_object_schema in varchar2
  , p_base_object_schema in varchar2
  , p_base_object_name_tab in t_text_tab
  , p_transform_param_tab in t_transform_param_tab
  , p_handle out number
  )
  is
    l_found pls_integer := null;
  begin
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
    dbug.enter(g_package_prefix || 'MD_OPEN');
    dbug.print(dbug."input"
               ,'p_object_type: %s; p_object_schema: %s; p_new_object_schema: %s; p_base_object_schema: %s'
               ,p_object_type
               ,p_object_schema
               ,p_new_object_schema
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
          ( -20000
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
            ( -20000
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
          ( -20000
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
          ( -20000
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
            ( -20000
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
            ( -20000
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

    md_set_remap_param
    ( p_object_type => p_object_type
    , p_object_schema => p_object_schema
    , p_new_object_schema => p_new_object_schema
    , p_base_object_schema => p_base_object_schema
    , p_handle => p_handle
    );
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
      , p_object_type_tab => t_text_tab(p_object_type)
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

    dbms_metadata.set_count(handle => p_handle, value => c_dbms_metadata_set_count);

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
    dbug.leave;
  exception
    when others then
      dbug.leave_on_error;
      raise_application_error(-20000, p_object_type||';'||p_object_schema||';'||p_new_object_schema||';'||p_base_object_schema, true);
$end
  end md_open;

  procedure md_fetch_ddl
  ( p_handle in number
  , p_ddl_tab out nocopy sys.ku$_ddls
  )
  is
    l_line_tab dbms_sql.varchar2a;
    l_statement varchar2(4000 char);
    l_privileges varchar2(4000 char);
    l_pos1 pls_integer;
    l_pos2 pls_integer;
    l_ddl_tab_last pls_integer;
  begin
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
    dbug.enter(g_package_prefix || 'MD_FETCH_DDL');
$end

    begin
      p_ddl_tab := dbms_metadata.fetch_ddl(handle => p_handle);

      if p_ddl_tab is not null and p_ddl_tab.count > 0
      then
        -- GRANT DELETE, INSERT, SELECT, UPDATE, REFERENCES, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ...
        l_ddl_tab_last := p_ddl_tab.last; -- the collection may expand so just store the last entry
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
        dbug.print(dbug."info", 'p_ddl_tab.first: %s; l_ddl_tab_last: %s', p_ddl_tab.first, l_ddl_tab_last);
$end
        for i_ku$ddls_idx in p_ddl_tab.first .. l_ddl_tab_last
        loop
          l_statement := dbms_lob.substr(lob_loc => p_ddl_tab(i_ku$ddls_idx).ddlText, offset => 1, amount => 4000);
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
          dbug.print(dbug."info", 'i_ku$ddls_idx: %s; ltrim(l_statement): %s', i_ku$ddls_idx, ltrim(l_statement));
$end
          if ltrim(l_statement) like 'GRANT %, % ON "%'
          then
            l_pos1 := instr(l_statement, 'GRANT ') + length('GRANT ');
            l_pos2 := instr(l_statement, ' ON "');
            l_privileges := substr(l_statement, l_pos1, l_pos2 - l_pos1);

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
            dbug.print(dbug."info", 'l_privileges: %s', l_privileges);
$end

            pkg_str_util.split
            ( p_str => l_privileges
            , p_delimiter => ', '
            , p_str_tab => l_line_tab
            );
            if l_line_tab.count > 0
            then
              -- free and nullify the ddlText so a copy will not create a new temporary on the fly
              dbms_lob.freetemporary(p_ddl_tab(i_ku$ddls_idx).ddlText);
              p_ddl_tab(i_ku$ddls_idx).ddlText := null;

              for i_idx in l_line_tab.first .. l_line_tab.last
              loop
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
                dbug.print(dbug."info", 'replace(l_statement, l_privileges, l_line_tab(%s)): %s', i_idx, replace(l_statement, l_privileges, l_line_tab(i_idx)));
$end
                if i_idx = l_line_tab.first
                then
                  -- replace i_ku$ddls_idx
                  dbms_lob.createtemporary(p_ddl_tab(i_ku$ddls_idx).ddlText, true);
                  pkg_str_util.append_text
                  ( pi_buffer => replace(l_statement, l_privileges, l_line_tab(i_idx))
                  , pio_clob => p_ddl_tab(i_ku$ddls_idx).ddlText
                  );
                else
                  -- extend the table
                  p_ddl_tab.extend(1);
                  -- copy everything (including the null ddlText)
                  p_ddl_tab(p_ddl_tab.last) := p_ddl_tab(i_ku$ddls_idx);
                  -- create a new clob
                  dbms_lob.createtemporary(p_ddl_tab(p_ddl_tab.last).ddlText, true);
                  pkg_str_util.append_text
                  ( pi_buffer => replace(l_statement, l_privileges, l_line_tab(i_idx))
                  , pio_clob => p_ddl_tab(p_ddl_tab.last).ddlText
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
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
        dbug.on_error;
$end
        p_ddl_tab := null;
    end;

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
    dbug.print(dbug."output", 'p_ddl_tab.count: %s', case when p_ddl_tab is not null then p_ddl_tab.count end);
    dbug.leave;
  exception
    when others
    then
      dbug.leave_on_error;
      raise;
$end
  end md_fetch_ddl;

  procedure parse_object
  ( p_schema in varchar2
  , p_new_schema in varchar2
  , p_constraint_lookup_tab in t_constraint_lookup_tab
  , p_object_lookup_tab in out nocopy t_object_lookup_tab
  , p_ku$_ddl in out nocopy sys.ku$_ddl
  , p_object_key out nocopy varchar2
  )
  is
    l_verb varchar2(4000 char) := null;
    l_object_name varchar2(4000 char) := null;
    l_object_type varchar2(4000 char) := null;
    l_object_schema varchar2(4000 char) := null;
    l_base_object_name varchar2(4000 char) := null;
    l_base_object_type varchar2(4000 char) := null;
    l_base_object_schema varchar2(4000 char) := null;
    l_column_name varchar2(4000 char) := null;
    l_grantee varchar2(4000 char) := null;
    l_privilege varchar2(4000 char) := null;
    l_grantable varchar2(4000 char) := null;

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
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
    dbug.enter(g_package_prefix || 'PARSE_OBJECT');
    dbug.print
    ( dbug."input"
    , 'p_schema: %s; p_new_schema: %s'
    , p_schema
    , p_new_schema
    );
$end

    parse_ddl
    ( p_ku$_ddl
    , p_schema
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

    -- GPA 2017-02-05 parse_ddl() did not change base_object_schema for OBJECT_GRANT
    if p_new_schema != p_schema
    then
      if l_object_schema = p_schema
      then
        l_object_schema := p_new_schema;
      end if;
      if l_base_object_schema = p_schema
      then
        l_base_object_schema := p_new_schema;
      end if;
    end if;

    p_object_key :=
      t_schema_object.id
      ( p_object_schema => l_object_schema
      , p_object_type => t_schema_object.dict2metadata_object_type(l_object_type)
      , p_object_name => l_object_name
      , p_base_object_schema => l_base_object_schema
      , p_base_object_type => t_schema_object.dict2metadata_object_type(l_base_object_type)
      , p_base_object_name => l_base_object_name
      , p_column_name => l_column_name
      , p_grantee => l_grantee
      , p_privilege => l_privilege
      , p_grantable => l_grantable
      );

    begin
      if not(p_object_lookup_tab(p_object_key).ready)
      then
        p_object_lookup_tab(p_object_key).schema_ddl.add_ddl
        ( p_verb => l_verb
        , p_text => case
                      when p_new_schema != p_schema
                      then modify_ddl_text
                           ( p_ddl_text => p_ku$_ddl.ddlText
                           , p_schema => p_schema
                           , p_new_schema => p_new_schema
                           , p_object_type => p_object_lookup_tab(p_object_key).schema_ddl.obj.object_type()
                           )
                      else p_ku$_ddl.ddlText
                    end
        );

        begin
          p_object_lookup_tab(p_object_key).schema_ddl.chk(nvl(p_new_schema, p_schema));
        exception
          when others
          then
            raise_application_error(-20000, 'Object ' || p_object_lookup_tab(p_object_key).schema_ddl.obj.id() || ' is not correct.', true);
        end;

        -- the normal stuff
        p_object_lookup_tab(p_object_key).count := p_object_lookup_tab(p_object_key).count + 1;
      end if; -- if not(p_object_lookup_tab(p_object_key).ready)
    exception
      when no_data_found
      then
        p_object_key := null;
        case
          when l_object_name like 'schema_version%'
          then
            -- skip Flyway stuff
            null;

          when t_schema_object.dict2metadata_object_type(l_object_type) = 'PROCACT_SCHEMA'
          then
            null;

          -- GPA 2017-02-05 Ignore the old job package DBMS_JOB
          when t_schema_object.dict2metadata_object_type(l_object_type) = 'PROCOBJ' and l_verb = 'DBMS_JOB.SUBMIT'
          then
            null;

          else
            null;
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
            dbug.print
            ( dbug."warning"
            , 'object not found in allowed objects: %s; ddl: %s'
            , p_object_key
            , dbms_lob.substr(p_ku$_ddl.ddlText, 100)
            );
            raise program_error;
$end
        end case;
    end;

    cleanup;

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
    dbug.print(dbug."output", 'p_object_key: %s', p_object_key);
    dbug.leave;
$end
  exception
    when others
    then
      p_object_key := null;
      cleanup;
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
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
  , p_schema_ddl_tab in out nocopy t_schema_ddl_tab
  )
  is
    l_idx pls_integer := p_schema_ddl_tab.last;
  begin
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
    dbug.enter(g_package || '.REMOVE_DDL');
    dbug.print(dbug."input", 'p_object_schema: %s; p_object_type: %s; p_filter: %s; p_schema_ddl_tab.count: %s', p_object_schema, p_object_type, p_filter, p_schema_ddl_tab.count);
$end

    loop
      exit when l_idx is null;

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
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

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
    dbug.print(dbug."output", 'p_schema_ddl_tab.count: %s', p_schema_ddl_tab.count);
    dbug.leave;
$end
  end remove_ddl;

  procedure remove_public_synonyms(p_schema_ddl_tab in out nocopy t_schema_ddl_tab) is
  begin
    remove_ddl(p_object_schema => 'PUBLIC'
              ,p_object_type => 'SYNONYM'
              ,p_filter => '% PUBLIC SYNONYM %'
              ,p_schema_ddl_tab => p_schema_ddl_tab);
  end remove_public_synonyms;

  procedure remove_object_grants(p_schema_ddl_tab in out nocopy t_schema_ddl_tab)
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

  procedure compare_ddl
  ( p_source_line_tab in dbms_sql.varchar2a
  , p_target_line_tab in dbms_sql.varchar2a
  , p_stop_after_first_diff in boolean default false
  , p_show_equal_lines in boolean default true
  , p_compare_line_tab out nocopy dbms_sql.varchar2a
  )
  is
    type t_array_1_dim_tab is table of pls_integer index by binary_integer; /* simple_integer may not be null */
    type t_array_2_dim_tab is table of t_array_1_dim_tab index by binary_integer;
    l_opt_tab t_array_2_dim_tab;
    l_stop boolean := false;

    function eq(p_target_line in varchar2, p_source_line in varchar2)
    return boolean
    is
    begin
      return ( p_target_line is null and p_source_line is null ) or p_target_line = p_source_line;
    end eq;

    procedure add(p_line in varchar2, p_marker in varchar2, p_old in pls_integer, p_new in pls_integer)
    is
    begin
      if p_marker <> '=' or p_show_equal_lines
      then
        p_compare_line_tab(p_compare_line_tab.count+1) := '[' || to_char(p_old) || '][' || to_char(p_new) || '] ' || p_marker || ' ' || p_line;
      end if;
      if p_marker <> '=' and p_stop_after_first_diff
      then
        l_stop := true;
      end if;
    end add;
  begin
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
    dbug.enter(g_package_prefix || 'COMPARE_DDL');
    dbug.print
    ( dbug."output"
    , 'p_source_line_tab.count: %s; p_target_line_tab.count: %s; p_stop_after_first_diff: %s; p_show_equal_lines: %s'
    , p_source_line_tab.count
    , p_target_line_tab.count
    , dbug.cast_to_varchar2(p_stop_after_first_diff)
    , dbug.cast_to_varchar2(p_show_equal_lines)
    );
$end

    -- Some checks to make life more easier.
    if p_target_line_tab.count > 0 and (p_target_line_tab.first != 1 or (p_target_line_tab.last - p_target_line_tab.first) + 1 != p_target_line_tab.count)
    then
      raise program_error;
    elsif p_source_line_tab.count > 0 and (p_source_line_tab.first != 1 or (p_source_line_tab.last - p_source_line_tab.first) + 1 != p_source_line_tab.count)
    then
      raise program_error;
    end if;

    /*
       The code is taken from Diff.java (http://introcs.cs.princeton.edu/java/96optimization/Diff.java.html)

       Variables:

       Java example  Here
       ------------  ----
       x             p_target_line_tab
       y             p_source_line_tab
       M             p_target_line_tab.count
       N             p_source_line_tab.count
       opt           l_opt_tab
    */

    /*
       In Java this creates a 2 dimensional array with all the indices filled and opt[i][j] = 0.

       int[][] opt = new int[M+1][N+1];

       Please note that in Java arrays start with index 0.

       The collections here start with 1 (due to the checks at the start).
    */

    -- Create an empty array slice with one more element than
    if p_source_line_tab.count > 0
    then
      for j in p_source_line_tab.first .. p_source_line_tab.last
      loop
        l_opt_tab(1)(j) := 0;
      end loop;
      l_opt_tab(1)(p_source_line_tab.count+1) := 0;
    end if;

    -- Use the empty array slice to fill the others.
    for i in 2 .. p_target_line_tab.count+1
    loop
      l_opt_tab(i) := l_opt_tab(1);
    end loop;

    -- compute length of LCS and all subproblems via dynamic programming
    if p_target_line_tab.count > 0
    then
      for i in reverse p_target_line_tab.first .. p_target_line_tab.last
      loop
        if p_source_line_tab.count > 0
        then
          for j in reverse p_source_line_tab.first .. p_source_line_tab.last
          loop
            if eq(p_target_line_tab(i), p_source_line_tab(j))
            then
              l_opt_tab(i)(j) := l_opt_tab(i+1)(j+1) + 1;
            else
              l_opt_tab(i)(j) := greatest(l_opt_tab(i+1)(j), l_opt_tab(i)(j+1));
            end if;
          end loop;
        end if;
      end loop;
    end if;

    declare
      i pls_integer := nvl(p_target_line_tab.first, 1);
      j pls_integer := nvl(p_source_line_tab.first, 1);
    begin
      -- recover LCS itself
      while (i <= p_target_line_tab.count and j <= p_source_line_tab.count) and not(l_stop)
      loop
        if eq(p_target_line_tab(i), p_source_line_tab(j))
        then
          add(p_target_line_tab(i), '=', i, j);
          i := i + 1;
          j := j + 1;
        elsif l_opt_tab(i+1)(j) >= l_opt_tab(i)(j+1)
        then
          add(p_target_line_tab(i), '-', i, j);
          i := i + 1;
        else
          add(p_source_line_tab(j), '+', i, j);
          j := j + 1;
        end if;
      end loop;

      -- dump out one remainder of one collection if the other is exhausted
      while (i <= p_target_line_tab.count or j <= p_source_line_tab.count) and not(l_stop)
      loop
        if i > p_target_line_tab.count
        then
          add(p_source_line_tab(j), '+', i, j);
          j := j + 1;
        elsif j > p_source_line_tab.count
        then
          add(p_target_line_tab(i), '-', i, j);
          i := i + 1;
        end if;
      end loop;
    end;

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
    dbug.print
    ( dbug."output"
    , 'p_compare_line_tab.count: %s'
    , p_compare_line_tab.count
    );
    dbug.leave;
$end

  end compare_ddl;

  procedure add2text
  ( p_str in varchar2
  , p_text_tab in out nocopy t_text_tab
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
  return t_text_tab
  is
    l_text_tab t_text_tab := t_text_tab();
  begin
    for i_idx in p_line_tab.first .. p_line_tab.last
    loop
      add2text(p_line_tab(i_idx) || chr(10), l_text_tab);
    end loop;
    return l_text_tab;
  end lines2text;

  /* PUBLIC ROUTINES */
  function get_sorted_dependency_list
  ( p_object_tab in t_text_tab
  , p_dependency_refcursor in sys_refcursor -- query with two columns: object1 depends on object2, i.e. select owner, referenced_owner from all_dependencies ...
  )
  return t_text_tab pipelined
  is
    l_object_tab t_object_natural_tab;
    l_object1 t_object;
    l_object2 t_object;
    l_graph t_graph;
    l_result dbms_sql.varchar2_table;
  begin
    for i_idx in p_object_tab.first .. p_object_tab.last
    loop
      l_object_tab(p_object_tab(i_idx)) := 1;
    end loop;

    loop
      fetch p_dependency_refcursor into l_object1, l_object2;

      exit when p_dependency_refcursor%notfound;

      if l_object_tab.exists(l_object1) and l_object_tab.exists(l_object2)
      then
        l_graph(l_object2)(l_object1) := 1;
      end if;
    end loop;

    close p_dependency_refcursor;

    while l_graph.first is not null
    loop
      begin
        tsort(l_graph, l_result);

        exit; -- successful: stop
      exception
        when e_not_a_directed_acyclic_graph
        then
          l_graph.delete(l_graph.first);
      end;
    end loop;

    if l_result.count > 0
    then
      for i_idx in l_result.first .. l_result.last
      loop
        pipe row (l_result(i_idx));
        l_object_tab.delete(l_result(i_idx));
      end loop;
    end if;

    while l_object_tab.first is not null
    loop
      pipe row (l_object_tab.first);
      l_object_tab.delete(l_object_tab.first);
    end loop;

    return;
  end get_sorted_dependency_list;

  function get_sorted_dependency_list
  ( p_object_refcursor in sys_refcursor
  , p_dependency_refcursor in sys_refcursor -- query with two columns: object1 depends on object2, i.e. select owner, referenced_owner from all_dependencies ...
  )
  return t_text_tab pipelined
  is
    l_object_tab t_text_tab;
  begin
    fetch p_object_refcursor bulk collect into l_object_tab;
    close p_object_refcursor;

    for r in
    ( select  t.column_value
      from    table(oracle_tools.pkg_ddl_util.get_sorted_dependency_list(l_object_tab, p_dependency_refcursor)) t
    )
    loop
      pipe row (r.column_value);
    end loop;

    return;
  end get_sorted_dependency_list;

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
  )
  return t_schema_ddl_tab
  pipelined
  is
    l_network_link all_db_links.db_link%type := null;
    l_cursor sys_refcursor;
    l_schema_ddl_tab t_schema_ddl_tab;
    l_schema_object_tab t_schema_object_tab;
    l_sort_objects_by_deps_tab t_sort_objects_by_deps_tab;
    l_transform_param_tab t_transform_param_tab;
    l_line_tab dbms_sql.varchar2a;
    l_program constant varchar2(30 char) := 'DISPLAY_DDL_SCHEMA'; -- geen schema omdat l_program in dbms_application_info wordt gebruikt

    -- dbms_application_info stuff
    l_longops_rec t_longops_rec := longops_init(p_target_desc => l_program, p_op_name => 'fetch', p_units => 'objects');
  begin
$if cfg_pkg.c_debugging $then
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
$end

    -- input checks
    check_schema(p_schema => p_schema, p_network_link => p_network_link);
    -- no checks for new schema: it may be null or any name
    check_numeric_boolean(p_numeric_boolean => p_sort_objects_by_deps, p_description => 'Sort objects by deps');
    check_object_type(p_object_type => p_object_type);
    check_object_names(p_object_names => p_object_names, p_object_names_include => p_object_names_include);
    check_numeric_boolean(p_numeric_boolean => p_object_names_include, p_description => 'Object names include');
    check_numeric_boolean(p_numeric_boolean => p_grantor_is_schema, p_description => 'Grantor is schema');
    check_network_link(p_network_link => p_network_link);

    get_transform_param_tab(p_transform_param_list, l_transform_param_tab);

    if p_network_link is not null
    then
      l_network_link := get_db_link(p_network_link);

      if l_network_link is null
      then
        raise program_error;
      else
        l_network_link := '@' || l_network_link;
      end if;

      pkg_ddl_util.set_display_ddl_schema_args
      ( p_schema => p_schema
      , p_new_schema => p_new_schema
      , p_sort_objects_by_deps => p_sort_objects_by_deps
      , p_object_type => p_object_type
      , p_object_names => p_object_names
      , p_object_names_include => p_object_names_include
      , p_network_link => p_network_link
      , p_grantor_is_schema => p_grantor_is_schema
      , p_transform_param_list => p_transform_param_list
      );

      open l_cursor for 'select t.schema_ddl from oracle_tools.v_display_ddl_schema' || l_network_link || ' t';
    else -- local
      /* GPA 27-10-2016
         The queries below may invoke the objects clause twice.
         Now if it that means invoking get_schema_ddl() twice that may be costly.
         The solution is to retrieve all the object ddl info once and use it twice.
      */
      pkg_ddl_util.get_schema_object
      ( p_schema => p_schema
      , p_object_type => p_object_type
      , p_object_names => p_object_names
      , p_object_names_include => p_object_names_include
      , p_grantor_is_schema => 0
      , p_schema_object_tab => l_schema_object_tab
      );

      if nvl(p_sort_objects_by_deps, 0) != 0
      then
        select  value(s)
        bulk collect
        into    l_schema_ddl_tab
        from    table
                ( oracle_tools.pkg_ddl_util.get_schema_ddl
                  ( p_schema
                  , p_new_schema
                  , case when p_object_type is not null then 0 when p_object_names_include = 1 then 0 else 1 end
                  , l_schema_object_tab
                  , p_transform_param_list
                  )
                ) s
        ;

        select  value(d)
        bulk collect
        into    l_sort_objects_by_deps_tab
        from    table
                ( oracle_tools.pkg_ddl_util.sort_objects_by_deps
                  ( cursor( select  distinct
                                    object_schema
                            ,       object_type
                            ,       object_name
                            from    ( select  nvl(o.object_schema(), o.base_object_schema()) as object_schema
                                      ,       nvl(o.object_type(), o.base_object_type()) as object_type
                                      ,       nvl(o.object_name(), o.base_object_name()) as object_name
                                      from    table(l_schema_object_tab) o
                                    )
                            order by
                                    oracle_tools.t_schema_object.object_type_order(object_type) nulls last
                            ,       object_name
                            ,       object_schema
                          )
                  , p_schema
                  )
                ) d
        ;

        open l_cursor for
          select  s.schema_ddl
          from    ( select  value(s) as schema_ddl
                    ,       s.obj.object_schema() as object_schema
                    ,       s.obj.object_type() as object_type
                    ,       s.obj.object_name() as object_name
                    ,       s.obj.base_object_schema() as base_object_schema
                    ,       s.obj.base_object_type() as base_object_type
                    ,       s.obj.base_object_name() as base_object_name
                    ,       s.obj.column_name() as column_name
                    ,       s.obj.grantee() as grantee
                    ,       s.obj.privilege() as privilege
                    ,       s.obj.grantable() as grantable
                    from    table(l_schema_ddl_tab) s
                  ) s
                  -- GPA 27-10-2016 We should not forget objects so use left outer join
                  left outer join
                  ( select  d.object_schema
                    ,       d.object_type
                    ,       d.object_name
                    ,       d.nr
                    from    table(l_sort_objects_by_deps_tab) d
                  ) d
                  -- GPA 21-12-2015 Als er een naar een nieuw schema wordt gesynchroniseerd dan moet wel volgens dependencies uit oude schema worden aangemaakt.
                  on d.object_schema = nvl
                                       ( case when s.object_schema = p_new_schema then p_schema else s.object_schema end
                                       , case when s.base_object_schema = p_new_schema then p_schema else s.base_object_schema end
                                       ) and
                     d.object_type = nvl(s.object_type, s.base_object_type) and
                     d.object_name = nvl(s.object_name, s.base_object_name)
          order by
                  d.nr nulls last
          ,       s.object_schema
          ,       s.object_type
          ,       s.object_name
          ,       s.base_object_schema
          ,       s.base_object_type
          ,       s.base_object_name
          ,       s.column_name
          ,       s.grantee
          ,       s.privilege
          ,       s.grantable
          ;
      else
        -- normal stuff: no network link, no dependency sorting
        open l_cursor for
          select  value(s) as schema_ddl
          from    table
                  ( oracle_tools.pkg_ddl_util.get_schema_ddl
                    ( p_schema
                    , p_new_schema
                    , case when p_object_type is not null then 0 when p_object_names_include = 1 then 0 else 1 end
                    , l_schema_object_tab
                    , p_transform_param_list
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

          pipe row(l_schema_ddl_tab(i_idx));

          longops_show(l_longops_rec);
        end loop;
      end if;
      exit fetch_loop when l_schema_ddl_tab.count < c_fetch_limit;
    end loop fetch_loop;
    close l_cursor;

    longops_done(l_longops_rec);

$if cfg_pkg.c_debugging $then
    dbug.leave;
$end

    return;

  exception
    when no_data_needed then
$if cfg_pkg.c_debugging $then
      dbug.leave_on_error;
$end
      null; -- not a real error, just a way to some cleanup

    when no_data_found -- verdwijnt anders in het niets omdat het een pipelined function betreft die al data ophaalt
    then
$if cfg_pkg.c_debugging $then
      dbug.leave_on_error;
$end
      raise program_error;

$if cfg_pkg.c_debugging $then
    when others then
      dbug.leave_on_error;
      raise;
$end
  end display_ddl_schema;

  procedure create_schema_ddl
  ( p_source_schema_ddl in t_schema_ddl
  , p_target_schema_ddl in t_schema_ddl
  , p_skip_repeatables in t_numeric_boolean
  , p_schema_ddl out nocopy t_schema_ddl
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
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
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

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
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
        -- Toon originele DDL als
        -- a) indien het een object type is dat kan worden vervangen EN
        --    1) het object in target schema niet bestaat OF
        --    2) er een verschil is
        -- b) indien het een object type is dat niet kan worden vervangen EN
        --    het object niet in target schema bestaat
        --
        -- Anders,
        -- c1) toon een invalid ALTER statement indien DBMS_METADATA_DIFF niet gelicentieerd is en er een verschil is
        -- c2) toon dan de door DBMS_METADATA_DIFF berekende DDL als dit het eerste voorkomen van dat object is
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

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
    dbug.print(dbug."info", 'l_action: %s; l_comment: %s', l_action, l_comment);
$end

    -- create with an empty ddl list
    t_schema_ddl.create_schema_ddl
    ( case
        when p_source_schema_ddl is not null
        then p_source_schema_ddl.obj
        else p_target_schema_ddl.obj
      end
    , t_ddl_tab()
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

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
    dbug.leave;
$end
  exception
    when others
    then
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
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
  )
  return t_schema_ddl_tab
  pipelined
  is
    l_schema_ddl t_schema_ddl;
    l_source_schema_ddl_tab t_schema_ddl_tab;
    l_target_schema_ddl_tab t_schema_ddl_tab;
    l_sort_objects_by_deps_tab t_sort_objects_by_deps_tab;

    l_object t_object;
    l_text_tab dbms_sql.varchar2a;
    l_program constant varchar2(30 char) := 'DISPLAY_DDL_SCHEMA_DIFF';

    -- dbms_application_info stuff
    l_longops_rec t_longops_rec := longops_init(p_op_name => 'fetch', p_units => 'objects', p_target_desc => l_program);

    procedure free_memory
    ( p_schema_ddl_tab in out nocopy t_schema_ddl_tab
    )
    is
    begin
      /* GPA 2017-04-12 #142504743 The DDL incremental generator fails on the Oracle XE database with an ORA-22813 error.

         In spite of the remark below (#141477987 ) we have to free up memory if and only if:
         - parameter p_skip_repeatables != 0 AND
         - the object are repeatable objects (excluding t_type_method_ddl because it uses ddl_tab(1))
      */
      if p_skip_repeatables != 0 and cardinality(p_schema_ddl_tab) > 0
      then
        for i_idx in p_schema_ddl_tab.first .. p_schema_ddl_tab.last
        loop
          if p_schema_ddl_tab(i_idx).obj.is_a_repeatable() != 0 and
             not(p_schema_ddl_tab(i_idx) is of (t_type_method_ddl))
          then
            p_schema_ddl_tab(i_idx).ddl_tab := t_ddl_tab();
          end if;
        end loop;
      end if;
    end free_memory;
  begin
$if cfg_pkg.c_debugging $then
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
$end

    -- input checks
    check_object_type(p_object_type => p_object_type);
    check_object_names(p_object_names => p_object_names, p_object_names_include => p_object_names_include);
    check_numeric_boolean(p_numeric_boolean => p_object_names_include, p_description => 'Object names include');
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
      l_source_schema_ddl_tab := t_schema_ddl_tab();
    else
      select  value(s)
      bulk collect
      into    l_source_schema_ddl_tab
      from    table
              ( oracle_tools.pkg_ddl_util.display_ddl_schema
                ( p_schema_source
                , p_schema_target
                , 1 -- sort for create
                , p_object_type
                , p_object_names
                , p_object_names_include
                , p_network_link_source
                , 0 -- any grantor
                , p_transform_param_list
                )
              ) s
      ;
      free_memory(l_source_schema_ddl_tab);
    end if;

$if cfg_pkg.c_debugging $then
    dbug.print(dbug."info", 'cardinality(l_source_schema_ddl_tab): %s', cardinality(l_source_schema_ddl_tab));
$end

    if p_schema_target is null
    then
      l_target_schema_ddl_tab := t_schema_ddl_tab();
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
                ( p_schema_target
                , null
                , 1 -- sort for drop
                , p_object_type
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
                , case when p_object_names_include = 1 then p_object_names end 
                , case when p_object_names_include = 1 then p_object_names_include end
                , p_network_link_target
                , 1 -- only grantor equal to p_schema_target so we can revoke the grant if necessary
                , p_transform_param_list
                )
              ) t
      ;
      free_memory(l_target_schema_ddl_tab);
    end if;

$if cfg_pkg.c_debugging $then
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
      -- Since the map function is used (which uses signature()) some objects may have the seem id but not
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
      create_schema_ddl
      ( p_source_schema_ddl => r_schema_ddl.source_schema_ddl
      , p_target_schema_ddl => r_schema_ddl.target_schema_ddl
      , p_skip_repeatables => p_skip_repeatables
      , p_schema_ddl => l_schema_ddl
      );

      pipe row(l_schema_ddl);

      longops_show(l_longops_rec);
    end loop schema_source_loop;

    longops_done(l_longops_rec);

$if cfg_pkg.c_debugging $then
    dbug.leave;
$end

    return; -- essential for a pipelined function

  exception
    when no_data_needed
    then
$if cfg_pkg.c_debugging $then
      dbug.leave_on_error;
$end
      null; -- not a real error, just a way to some cleanup

    when no_data_found -- verdwijnt anders in het niets omdat het een pipelined function betreft die al data ophaalt
    then
$if cfg_pkg.c_debugging $then
      dbug.leave_on_error;
$end
      raise program_error;

    when others
    then
$if cfg_pkg.c_debugging $then
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
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
    dbug.enter(g_package_prefix || 'EXECUTE_DDL (1)');
    dbug.print(dbug."input", 'p_id: %s; p_text: %s', p_id, p_text);
$end

    -- GPA 2017-06-27 #147914109 - As an release operator I do not want that index/constraint rename actions fail when the target already exists.
    t_schema_ddl.execute_ddl(p_id => p_id, p_text => p_text);

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
    dbug.leave;
  exception
    when others
    then
      dbug.leave_on_error;
      raise;
$end
  end execute_ddl;

  procedure execute_ddl
  ( p_ddl_text_tab in t_text_tab
  , p_network_link in varchar2 default null
  )
  is
    l_statement varchar2(32767) := null;
    l_network_link all_db_links.db_link%type := null;
  begin
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
    dbug.enter(g_package_prefix || 'EXECUTE_DDL (2)');
    dbug.print(dbug."input", 'p_network_link: %s; p_ddl_text_tab(1): %s', p_network_link, p_ddl_text_tab(1));
$end

    if p_network_link is not null
    then
      check_network_link(p_network_link);

      l_network_link := get_db_link(p_network_link);

      if l_network_link is null
      then
        raise program_error;
      else
        l_network_link := '@' || l_network_link;
      end if;
    end if;

    l_statement := '
declare
  l_ddl_text_tab constant oracle_tools.t_text_tab := :b1;
  l_ddl_tab dbms_sql.varchar2a' || l_network_link || ';
  l_cursor integer;
  l_last_error_position integer := null;

  -- ORA-24344: success with compilation error due to missing privileges
  e_s6_with_compilation_error exception;
  pragma exception_init(e_s6_with_compilation_error, -24344);
  -- ORA-04063: view "EMPTY.V_DISPLAY_DDL_SCHEMA" has errors
  e_view_has_errors exception;
  pragma exception_init(e_view_has_errors, -4063);
  -- ORA-01720: grant option does not exist for <owner>.PARTY
  e_grant_option_does_not_exist exception;
  pragma exception_init(e_grant_option_does_not_exist, -1720);
begin
  l_cursor := dbms_sql.open_cursor' || l_network_link || ';
  -- kopieer naar (remote) array
  if l_ddl_text_tab.count > 0
  then
    for i_idx in l_ddl_text_tab.first .. l_ddl_text_tab.last
    loop
      l_ddl_tab(i_idx) := l_ddl_text_tab(i_idx);
    end loop;
  end if;
  --
  dbms_sql.parse' || l_network_link || '
  ( c => l_cursor
  , statement => l_ddl_tab
  , lb => l_ddl_tab.first
  , ub => l_ddl_tab.last
  , lfflg => false
  , language_flag => dbms_sql.native
  );
  --
  dbms_sql.close_cursor' || l_network_link || '(l_cursor);
exception
  when e_s6_with_compilation_error or e_view_has_errors or e_grant_option_does_not_exist
  then dbms_sql.close_cursor' || l_network_link || '(l_cursor);
  when others
  then
    /* DBMS_SQL.LAST_ERROR_POSITION 
       This function returns the byte offset in the SQL statement text where the error occurred. 
       The first character in the SQL statement is at position 0. 
    */
    l_last_error_position := 1 + nvl(dbms_sql.last_error_position' || l_network_link || ', 0);
    dbms_sql.close_cursor' || l_network_link || '(l_cursor);
    raise_application_error
    ( -20000
    , ''Error at position '' || l_last_error_position || '': '' || substr(oracle_tools.pkg_str_util.text2clob(l_ddl_text_tab), l_last_error_position, 2000)
    , true
    );
end;';

    execute immediate l_statement using p_ddl_text_tab;

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
    dbug.leave;
  exception
    when others
    then
      dbug.leave_on_error;
      raise;
$end
  end execute_ddl;

  procedure execute_ddl
  ( p_schema_ddl_tab in t_schema_ddl_tab
  , p_network_link in varchar2 default null
  )
  is
  begin
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
    dbug.enter(g_package_prefix || 'EXECUTE_DDL (3)');
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
            begin
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
              p_schema_ddl_tab(i_idx).ddl_tab(i_ddl_idx).print();
$end          
              if p_schema_ddl_tab(i_idx).ddl_tab(i_ddl_idx).verb() = '--' 
              then
                -- this is a comment
                null;
              else
                execute_ddl(p_schema_ddl_tab(i_idx).ddl_tab(i_ddl_idx).text, p_network_link);
              end if;
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
            exception
              when others
              then
                p_schema_ddl_tab(i_idx).ddl_tab(i_ddl_idx).print();
                raise;
$end          
            end;
          end loop;
        end if; -- if cardinality(p_schema_ddl_tab(i_idx).ddl_tab) > 0
      end loop;
    end if;

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
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
  )
  is
    l_diff_schema_ddl_tab t_schema_ddl_tab;

$if cfg_pkg.c_debugging $then
    l_program constant varchar2(61) := g_package_prefix || 'SYNCHRONIZE';
$end
  begin
$if cfg_pkg.c_debugging $then
    dbug.enter(l_program);
$end

    -- Bereken de verschillen, i.e. de CREATE statements.
    -- Gebruik database links om aan te loggen met de juiste gebruiker.
    select value(t)
    bulk collect
    into   l_diff_schema_ddl_tab
    from   table(oracle_tools.pkg_ddl_util.display_ddl_schema_diff(/*p_object_type =>*/ p_object_type
                                                                   ,/*p_object_names =>*/ p_object_names
                                                                   ,/*p_object_names_include =>*/ p_object_names_include
                                                                   ,/*p_schema_source =>*/ p_schema_source
                                                                   ,/*p_schema_target =>*/ p_schema_target
                                                                   ,/*p_network_link_source =>*/ p_network_link_source
                                                                   ,/*p_network_link_target =>*/ p_network_link_target
                                                                   ,/*p_skip_repeatables =>*/ 0)) t
    ;

    -- Skip public synonyms on the same database
    if get_host(p_network_link_source) = get_host(p_network_link_target)
    then
      remove_public_synonyms(l_diff_schema_ddl_tab);
    end if;

    execute_ddl(l_diff_schema_ddl_tab, p_network_link_target);

$if cfg_pkg.c_debugging $then
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
  )
  is
    l_drop_schema_ddl_tab t_schema_ddl_tab;

$if cfg_pkg.c_debugging $then
    l_program constant varchar2(61) := g_package_prefix || 'UNINSTALL';
$end
  begin
$if cfg_pkg.c_debugging $then
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
    );

$if cfg_pkg.c_debugging $then
    dbug.leave;
  exception
    when others
    then
      dbug.leave_on_error;
      raise;
$end
  end uninstall;

  procedure get_schema_object
  ( p_schema in t_schema_nn
  , p_object_type in t_metadata_object_type
  , p_object_names in t_object_names
  , p_object_names_include in t_numeric_boolean
  , p_grantor_is_schema in t_numeric_boolean_nn
  , p_schema_object_tab out nocopy t_schema_object_tab
  )
  is
    l_object_names constant varchar2(4000 char) :=
      ',' ||
      replace(replace(replace(replace(p_object_names, chr(9)), chr(13)), chr(10)), chr(32)) ||
      ',';

    type t_excluded_tables_tab is table of boolean index by all_tables.table_name%type;

    l_excluded_tables_tab t_excluded_tables_tab;

    l_named_object_tab t_schema_object_tab := t_schema_object_tab();
    l_schema_object_tab t_schema_object_tab := t_schema_object_tab();
    l_schema_object t_schema_object;

    l_refcursor sys_refcursor;

    l_longops_rec t_longops_rec := longops_init(p_target_desc => 'GET_SCHEMA_OBJECT');

    -- see all the queries where base info is stored
    l_dependent_object_type_tab constant t_text_tab := t_text_tab('OBJECT_GRANT', 'SYNONYM', 'COMMENT', 'CONSTRAINT', 'REF_CONSTRAINT', 'INDEX', 'TRIGGER');

    /*
      We have two steps in this routine:
      1) gathering named objects
      2) gathering dependent objects (sometimes based on the named objects)

      In step 1 we should not check the named objects because they need to be created for step 2, 
      unless we will never gather dependent objects. Or, in other words, if p_object_type
      is not one of the dependent object types and not INDEX or TRIGGER we can already check in 
      step 1 which will lead to a better performance.

      If we do not check named objects, we must do it later on, after step 2.
    */
    l_object_types_to_check t_text_tab :=
      case
        when p_object_type member of l_dependent_object_type_tab
        then l_dependent_object_type_tab -- do not check for example TABLE
        else g_schema_md_object_type_tab -- check all
      end;

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
    procedure check_duplicates(p_schema_object_tab in t_schema_object_tab)
    is
      l_object_tab t_object_natural_tab;
    begin
      if p_schema_object_tab.count > 0
      then
        for i_idx in p_schema_object_tab.first .. p_schema_object_tab.last
        loop
          p_schema_object_tab(i_idx).print();
          if l_object_tab.exists(p_schema_object_tab(i_idx).signature())
          then
            raise_application_error(-20000, 'The signature of the object is a duplicate: ' || p_schema_object_tab(i_idx).signature());
          else
            l_object_tab(p_schema_object_tab(i_idx).signature()) := 0;
          end if;
        end loop;
      end if;
    end check_duplicates;
$end            

    procedure cleanup
    is
    begin
      if l_refcursor%isopen
      then
        close l_refcursor;
      end if;
    end cleanup;
  begin
$if cfg_pkg.c_debugging $then
    dbug.enter(g_package_prefix || 'GET_SCHEMA_OBJECT');
    dbug.print(dbug."input"
               ,'p_schema: %s; p_object_type: %s; p_object_names: %s; p_object_names_include: %s; p_grantor_is_schema: %s'
               ,p_schema
               ,p_object_type
               ,p_object_names
               ,p_object_names_include
               ,p_grantor_is_schema);
$end

    -- input checks
    check_schema(p_schema => p_schema, p_network_link => null);
    check_object_type(p_object_type => p_object_type);
    check_object_names(p_object_names => p_object_names, p_object_names_include => p_object_names_include);
    check_numeric_boolean(p_numeric_boolean => p_object_names_include, p_description => 'Object names include');
    check_numeric_boolean(p_numeric_boolean => p_grantor_is_schema, p_description => 'Grantor is schema');

    -- queue table
    for r in
    ( select  q.owner
      ,       q.queue_table
      from    all_queue_tables q
      where   q.owner = p_schema
    )
    loop
      longops_show(l_longops_rec);
      l_excluded_tables_tab(r.queue_table) := true;
$if pkg_ddl_util.c_get_queue_ddl $then
      -- this is a special case since we need to exclude first
      if oracle_tools.pkg_ddl_util.schema_object_matches_filter
         ( -- filter values
           p_object_type => p_object_type
         , p_object_names => l_object_names
         , p_object_names_include => p_object_names_include
         , p_object_types_to_check => l_object_types_to_check
           -- database values
         , p_metadata_object_type => 'AQ_QUEUE_TABLE'
         , p_object_name => r.queue_table
         ) = 1
      then
        l_named_object_tab.extend(1);
        t_named_object.create_named_object
        ( p_object_type => 'AQ_QUEUE_TABLE'
        , p_object_schema => r.owner
        , p_object_name => r.queue_table
        , p_named_object => l_named_object_tab(l_named_object_tab.last)
        );
      end if;
$else
      /* ORA-00904: "KU$"."SCHEMA_OBJ"."TYPE": invalid identifier */
$end
    end loop;

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
    check_duplicates(l_named_object_tab);
$end

    -- no MATERIALIZED VIEW tables unless PREBUILT
    for r in
    ( select  m.owner
      ,       m.mview_name
      ,       m.build_mode
      from    all_mviews m
      where   m.owner = p_schema
    )
    loop
      longops_show(l_longops_rec);
      if r.build_mode != 'PREBUILT'
      then
        l_excluded_tables_tab(r.mview_name) := true;
      end if;
      -- this is a special case since we need to exclude first
      if oracle_tools.pkg_ddl_util.schema_object_matches_filter
         ( -- filter values
           p_object_type => p_object_type
         , p_object_names => l_object_names
         , p_object_names_include => p_object_names_include
         , p_object_types_to_check => l_object_types_to_check
           -- database values
         , p_metadata_object_type => 'MATERIALIZED_VIEW'
         , p_object_name => r.mview_name
         ) = 1
      then
        l_named_object_tab.extend(1);
        l_named_object_tab(l_named_object_tab.last) := t_materialized_view_object(r.owner, r.mview_name);
      end if;
    end loop;

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
    check_duplicates(l_named_object_tab);
$end

    for r in
    ( select  t.owner
      ,       t.table_name
      ,       t.tablespace_name
      ,       'TABLE' as object_type
      from    all_tables t
      where   t.owner = p_schema
      and     t.nested = 'NO' -- Exclude nested tables, their DDL is part of their parent table.
      and     ( t.iot_type is null or t.iot_type = 'IOT' ) -- Only the IOT table itself, not an overflow or mapping
              -- GPA 2017-06-28 #147916863 - As a release operator I do not want comments without table or column.
      and     substr(t.table_name, 1, 5) not in (/*'APEX$', */'MLOG$', 'RUPD$') 
      union -- not union all because since Oracle 12, temporary tables are also shown in all_tables
      -- temporary tables
      select  t.owner
      ,       t.object_name as table_name
      ,       null as tablespace_name
      ,       t.object_type
      from    all_objects t
      where   t.owner = p_schema
      and     t.object_type = 'TABLE'
      and     t.temporary = 'Y'
      and     t.generated = 'N' -- GPA 2016-12-19 #136334705
              -- GPA 2017-06-28 #147916863 - As a release operator I do not want comments without table or column.
      and     substr(t.object_name, 1, 5) not in (/*'APEX$', */'MLOG$', 'RUPD$') 
    )
    loop
      longops_show(l_longops_rec);
      if r.object_type <> 'TABLE'
      then
        raise program_error;
      end if;
      if oracle_tools.pkg_ddl_util.schema_object_matches_filter
         ( -- filter values
           p_object_type => p_object_type
         , p_object_names => l_object_names
         , p_object_names_include => p_object_names_include
         , p_object_types_to_check => l_object_types_to_check
           -- database values
         , p_metadata_object_type => r.object_type
         , p_object_name => r.table_name
         ) = 1
      then
        l_schema_object := t_table_object(r.owner, r.table_name, r.tablespace_name);
        if not(l_excluded_tables_tab.exists(l_schema_object.object_name()))
        then
          l_named_object_tab.extend(1);
          l_named_object_tab(l_named_object_tab.last) := l_schema_object;
        end if;
      end if;
    end loop;

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
    check_duplicates(l_named_object_tab);
$end

    for r in
    ( /*
      -- Just the base objects, i.e. no constraints, comments, grant nor public synonyms to base objects.
      */
      select  o.owner
      ,       o.object_type
      ,       o.object_name
      from    ( select  o.owner
                        -- use scalar subquery cache
                ,       (select oracle_tools.t_schema_object.dict2metadata_object_type(o.object_type) from dual) as object_type
                ,       o.object_name
                from    all_objects o
                where   o.owner = p_schema
                and     o.object_type not in ('QUEUE', 'MATERIALIZED VIEW', 'TABLE', 'TRIGGER', 'INDEX', 'SYNONYM')
                and     o.generated = 'N' -- GPA 2016-12-19 #136334705
                        -- OWNER  OBJECT_NAME           SUBOBJECT_NAME
                        -- =====  ===========           ==============
                        -- ORACLE_TOOLS T_TABLE_COLUMN_DDL  $VSN_1
                and     o.subobject_name is null
                        -- GPA 2017-06-28 #147916863 - As a release operator I do not want comments without table or column.
                and     not( o.object_type = 'SEQUENCE' and substr(o.object_name, 1, 5) = 'ISEQ$' )
              ) o
      where   o.object_type member of g_schema_md_object_type_tab
              -- use scalar subquery cache
      and     (select oracle_tools.pkg_ddl_util.is_dependent_object_type(p_object_type => o.object_type) from dual) = 0
      and     oracle_tools.pkg_ddl_util.schema_object_matches_filter
              ( -- filter values
                p_object_type => p_object_type
              , p_object_names => l_object_names
              , p_object_names_include => p_object_names_include
              , p_object_types_to_check => l_object_types_to_check
                -- database values
              , p_metadata_object_type => o.object_type
              , p_object_name => o.object_name
              ) = 1
    )
    loop
      longops_show(l_longops_rec);
      l_named_object_tab.extend(1);
      t_named_object.create_named_object
      ( p_object_type => r.object_type
      , p_object_schema => r.owner
      , p_object_name => r.object_name
      , p_named_object => l_named_object_tab(l_named_object_tab.last)
      );
    end loop;

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
    check_duplicates(l_named_object_tab);
$end

    /*
    -- now dependent objects based on the retrieved objects thus far or
    -- dependent objects based on an object in another schema
    */

    for r in
    ( -- before Oracle 12 there was no type column in all_tab_privs
      with prv as -- use this clause to speed up the query for <owner>
      ( -- several grantors may have executed the same grant statement
        select  p.table_schema
        ,       p.table_name
        ,       p.grantee
        ,       p.privilege
        ,       max(p.grantable) as grantable -- YES comes after NO
        from    all_tab_privs p
        where   p.table_schema = p_schema
        and     ( p_grantor_is_schema = 0 or p.grantor = p_schema )
        group by
                p.table_schema
        ,       p.table_name
        ,       p.grantee
        ,       p.privilege
      )
      -- grants for all our objects
      select  obj.obj as base_object
      ,       null as object_schema
      ,       p.grantee
      ,       p.privilege
      ,       p.grantable
      from    ( select  obj.object_type() as object_type
                ,       obj.object_schema() as object_schema
                ,       obj.object_name() as object_name
                ,       value(obj) as obj
                from    table(l_named_object_tab) obj
              ) obj
              inner join prv p
              on p.table_schema = obj.object_schema and p.table_name = obj.object_name
      where   obj.object_type not like '%BODY'
      and     obj.object_type not in ('MATERIALIZED_VIEW') -- grants are on underlying tables
      and     oracle_tools.pkg_ddl_util.schema_object_matches_filter
              ( -- filter values
                p_object_type => p_object_type
              , p_object_names => l_object_names
              , p_object_names_include => p_object_names_include
              , p_object_types_to_check => l_object_types_to_check
                -- database values
              , p_metadata_object_type => 'OBJECT_GRANT'
              , p_object_name => null
              , p_metadata_base_object_type => obj.object_type
              , p_base_object_name => obj.object_name
              ) = 1
    )
    loop
      longops_show(l_longops_rec);
      l_schema_object_tab.extend(1);
      l_schema_object_tab(l_schema_object_tab.last) :=
        t_object_grant_object
        ( p_base_object => treat(r.base_object as t_named_object)
        , p_object_schema => r.object_schema
        , p_grantee => r.grantee
        , p_privilege => r.privilege
        , p_grantable => r.grantable
        );
    end loop;

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
    check_duplicates(l_schema_object_tab);
$end

    for r in
    ( select  t.*
      from    ( -- public synonyms for all our objects
                select  value(obj)     as base_object
                ,       s.owner        as object_schema
                ,       'SYNONYM'      as object_type
                ,       s.synonym_name as object_name
                ,       null           as column_name
                from    table(l_named_object_tab) obj
                        inner join all_synonyms s
                        on s.table_owner = obj.object_schema() and s.table_name = obj.object_name()
                where   obj.object_type() not like '%BODY'
                and     obj.object_type() <> 'MATERIALIZED_VIEW'
                and     s.owner = 'PUBLIC'
                union all
                -- table/view comments
                select  value(obj)     as base_object
                ,       null           as object_schema
                ,       'COMMENT'      as object_type
                ,       null           as object_name
                ,       null           as column_name
                from    table(l_named_object_tab) obj
                        inner join all_tab_comments t
                        on t.owner = obj.object_schema() and t.table_type = obj.object_type() and t.table_name = obj.object_name()
                where   obj.object_type() in ('TABLE', 'VIEW')
                and     t.comments is not null
                union all
                -- materialized view comments
                select  value(obj)     as base_object
                ,       null           as object_schema
                ,       'COMMENT'      as object_type
                ,       null           as object_name
                ,       null           as column_name
                from    table(l_named_object_tab) obj
                        inner join all_mview_comments m
                        on m.owner = obj.object_schema() and m.mview_name = obj.object_name()
                where   obj.object_type() = 'MATERIALIZED_VIEW'
                and     m.comments is not null
                union all
                -- column comments
                select  value(obj)     as base_object
                ,       null           as object_schema
                ,       'COMMENT'      as object_type
                ,       null           as object_name
                ,       c.column_name  as column_name
                from    table(l_named_object_tab) obj
                        inner join all_col_comments c
                        on c.owner = obj.object_schema() and c.table_name = obj.object_name()
                where   obj.object_type() in ('TABLE', 'VIEW', 'MATERIALIZED_VIEW')
                and     c.comments is not null
              ) t
      where   oracle_tools.pkg_ddl_util.schema_object_matches_filter
              ( -- filter values
                p_object_type => p_object_type
              , p_object_names => l_object_names
              , p_object_names_include => p_object_names_include
              , p_object_types_to_check => l_object_types_to_check
                -- database values
              , p_metadata_object_type => t.object_type
              , p_object_name => t.object_name
              , p_metadata_base_object_type => t.base_object.object_type()
              , p_base_object_name => t.base_object.object_name()
              ) = 1
    )
    loop
      longops_show(l_longops_rec);
      l_schema_object_tab.extend(1);
      case r.object_type
        when 'SYNONYM'
        then
          l_schema_object_tab(l_schema_object_tab.last) :=
            t_synonym_object
            ( p_base_object => treat(r.base_object as t_named_object)
            , p_object_schema => r.object_schema
            , p_object_name => r.object_name
            );
        when 'COMMENT'
        then
          l_schema_object_tab(l_schema_object_tab.last) :=
            t_comment_object
            ( p_base_object => treat(r.base_object as t_named_object)
            , p_object_schema => r.object_schema
            , p_column_name => r.column_name
            );
      end case;
    end loop;

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
    check_duplicates(l_schema_object_tab);
$end

    for r in
    ( -- constraints for objects in the same schema
      select  t.*
      from    ( select  value(obj) as base_object
                ,       c.owner as object_schema
                ,       case when c.constraint_type = 'R' then 'REF_CONSTRAINT' else 'CONSTRAINT' end as object_type
                ,       c.constraint_name as object_name
$if pkg_ddl_util.c_#138707615_1 $then
                ,       c.search_condition
                ,       case c.constraint_type
                          when 'C'
                          then ( select  cc.column_name
                                 from    all_cons_columns cc
                                 where   cc.owner = c.owner
                                 and     cc.table_name = c.table_name
                                 and     cc.constraint_name = c.constraint_name
                                 and     rownum = 1
                               )
                          else null
                        end as any_column_name
$end                          
                from    table(l_named_object_tab) obj
                        inner join all_constraints c
                        on c.owner = obj.object_schema() and c.table_name = obj.object_name()
                where   obj.object_type() in ('TABLE', 'VIEW')
                        /* Type of constraint definition:
                           C (check constraint on a table)
                           P (primary key)
                           U (unique key)
                           R (referential integrity)
                           V (with check option, on a view)
                           O (with read only, on a view)
                        */
                and     c.constraint_type in ('C', 'P', 'U', 'R')
$if not(pkg_ddl_util.c_#138707615_1) $then
                        -- exclude system generated not null constraints
                and     ( c.constraint_name not like 'SYS\_C%' escape '\' or
                          c.constraint_type <> 'C' or
                          -- column is the only column in the check constraint and must be nullable
                          ( 1, 'Y' ) in
                          ( select  count(cc.column_name)
                            ,       max(tc.nullable)
                            from    all_cons_columns cc
                                    inner join all_tab_columns tc
                                    on tc.owner = cc.owner and tc.table_name = cc.table_name and tc.column_name = cc.column_name
                            where   cc.owner = c.owner
                            and     cc.table_name = c.table_name
                            and     cc.constraint_name = c.constraint_name
                          )
                        )
$end
              ) t
      where   oracle_tools.pkg_ddl_util.schema_object_matches_filter
              ( -- filter values
                p_object_type => p_object_type
              , p_object_names => l_object_names
              , p_object_names_include => p_object_names_include
              , p_object_types_to_check => l_object_types_to_check
                -- database values
              , p_metadata_object_type => t.object_type
              , p_object_name => t.object_name
              , p_metadata_base_object_type => t.base_object.object_type()
              , p_base_object_name => t.base_object.object_name()
              ) = 1
    )
    loop
$if pkg_ddl_util.c_#138707615_1 $then
      -- We do NOT want a NOT NULL constraint, named or not.
      -- Since search_condition is a LONG we must use PL/SQL to filter
      if r.search_condition is not null and
         r.any_column_name is not null and
         r.search_condition = '"' || r.any_column_name || '" IS NOT NULL'
      then
        -- This is a not null constraint.
        -- Since search_condition has only one column, any column name is THE column name.
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
        dbug.print
        ( dbug."info"
        , 'ignoring not null constraint: owner: %s; table: %s; constraint: %s; search_condition: %s'
        , r.object_schema
        , r.base_object.object_name()
        , r.object_name
        , r.search_condition
        );
$end
        null;
      else
$end

        longops_show(l_longops_rec);
        l_schema_object_tab.extend(1);
        case r.object_type
          when 'REF_CONSTRAINT'
          then
            l_schema_object_tab(l_schema_object_tab.last) :=
              t_ref_constraint_object
              ( p_base_object => treat(r.base_object as t_named_object)
              , p_object_schema => r.object_schema
              , p_object_name => r.object_name
              );

          when 'CONSTRAINT'
          then
            l_schema_object_tab(l_schema_object_tab.last) :=
              t_constraint_object
              ( p_base_object => treat(r.base_object as t_named_object)
              , p_object_schema => r.object_schema
              , p_object_name => r.object_name
              );
        end case;

$if pkg_ddl_util.c_#138707615_1 $then
      end if;
$end        
    end loop;

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
    check_duplicates(l_schema_object_tab);
$end

    for r in
    ( select  t.*
      from    ( -- private synonyms for this schema which may point to another schema
                select  s.owner as object_schema
                ,       'SYNONYM' as object_type
                ,       s.synonym_name as object_name
                ,       obj.owner as base_object_schema
                        -- use scalar subquery cache
                ,       (select oracle_tools.t_schema_object.dict2metadata_object_type(obj.object_type) from dual) as base_object_type
                ,       obj.object_name as base_object_name
                ,       null as column_name
                from    all_objects obj inner join all_synonyms s
                        on s.table_owner = obj.owner and s.table_name = obj.object_name
                where   obj.object_type not like '%BODY'
                and     obj.object_type <> 'MATERIALIZED VIEW'
                and     s.owner = p_schema
                union all
                -- triggers for this schema which may point to another schema
                select  t.owner as object_schema
                ,       'TRIGGER' as object_type
                ,       t.trigger_name as object_name
/* GJP 20170106 see t_schema_object.chk()
                -- when the trigger is based on an object in another schema, no base info
                ,       case when t.owner = t.table_owner then t.table_owner end as base_object_schema
                ,       case when t.owner = t.table_owner then t.base_object_type end as base_object_type
                ,       case when t.owner = t.table_owner then t.table_name end as base_object_name
*/
                ,       t.table_owner as base_object_schema
                        -- use scalar subquery cache
                ,       (select oracle_tools.t_schema_object.dict2metadata_object_type(t.base_object_type) from dual) as base_object_type
                ,       t.table_name as base_object_name
                ,       null as column_name
                from    all_triggers t
                where   t.owner = p_schema
                and     t.base_object_type in ('TABLE', 'VIEW')
              ) t
      where   oracle_tools.pkg_ddl_util.schema_object_matches_filter
              ( -- filter values
                p_object_type => p_object_type
              , p_object_names => l_object_names
              , p_object_names_include => p_object_names_include
              , p_object_types_to_check => l_object_types_to_check
                -- database values
              , p_metadata_object_type => t.object_type
              , p_object_name => t.object_name
              , p_metadata_base_object_type => t.base_object_type
              , p_base_object_name => t.base_object_name
              ) = 1
    )
    loop
      longops_show(l_longops_rec);
      l_schema_object_tab.extend(1);
      t_schema_object.create_schema_object
      ( p_object_schema => r.object_schema
      , p_object_type => r.object_type
      , p_object_name => r.object_name
      , p_base_object_schema => r.base_object_schema
      , p_base_object_type => r.base_object_type
      , p_base_object_name => r.base_object_name
      , p_column_name => r.column_name
      , p_schema_object => l_schema_object_tab(l_schema_object_tab.last)
      );
    end loop;

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
    check_duplicates(l_schema_object_tab);
$end

    for r in
    ( -- indexes
      select  i.owner as object_schema
      ,       i.index_name as object_name
/* GJP 20170106 see t_schema_object.chk()
      -- when the index is based on an object in another schema, no base info
      ,       case when i.owner = i.table_owner then i.table_owner end as base_object_schema
      ,       case when i.owner = i.table_owner then i.table_type end as base_object_type
      ,       case when i.owner = i.table_owner then i.table_name end as base_object_name
*/
      ,       i.table_owner as base_object_schema
              -- use scalar subquery cache
      ,       (select oracle_tools.t_schema_object.dict2metadata_object_type(i.table_type) from dual) as base_object_type
      ,       i.table_name as base_object_name
      ,       i.tablespace_name
      from    all_indexes i
      where   i.owner = p_schema
              -- GPA 2017-06-28 #147916863 - As a release operator I do not want comments without table or column.
      and     not(/*substr(i.index_name, 1, 5) = 'APEX$' or */substr(i.index_name, 1, 7) = 'I_MLOG$')
      and     oracle_tools.pkg_ddl_util.schema_object_matches_filter
              ( -- filter values
                p_object_type => p_object_type
              , p_object_names => l_object_names
              , p_object_names_include => p_object_names_include
              , p_object_types_to_check => l_object_types_to_check
                -- database values
              , p_metadata_object_type => 'INDEX'
              , p_object_name => i.index_name
              , p_metadata_base_object_type => oracle_tools.t_schema_object.dict2metadata_object_type(i.table_type)
              , p_base_object_name => i.table_name
              ) = 1
    )
    loop
      longops_show(l_longops_rec);
      l_schema_object_tab.extend(1);
      l_schema_object_tab(l_schema_object_tab.last) :=
        t_index_object
        ( p_base_object =>
            t_named_object.create_named_object
            ( p_object_schema => r.base_object_schema
            , p_object_type => r.base_object_type
            , p_object_name => r.base_object_name
            )
        , p_object_schema => r.object_schema
        , p_object_name => r.object_name
        , p_tablespace_name => r.tablespace_name
        );
    end loop;

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
    check_duplicates(l_schema_object_tab);
$end

    if l_object_types_to_check = g_schema_md_object_type_tab
    then
      -- every object in l_named_object_tab has been checked already by oracle_tools.pkg_ddl_util.schema_object_matches_filter()

      -- combine and filter based on the map function of t_schema_object and its subtypes
      -- GPA 2017-01-27 For performance reasons do not use DISTINCT since the sets should be unique and distinct already
      p_schema_object_tab := l_named_object_tab multiset union /*distinct*/ l_schema_object_tab;
    else
      -- objects in l_named_object_tab have NOT been totally checked by oracle_tools.pkg_ddl_util.schema_object_matches_filter()
      l_object_types_to_check := g_schema_md_object_type_tab;

      select  value(obj) as base_object
      bulk collect
      into    p_schema_object_tab
      from    table(l_named_object_tab) obj
      where   oracle_tools.pkg_ddl_util.schema_object_matches_filter
              ( -- filter values
                p_object_type => p_object_type
              , p_object_names => l_object_names
              , p_object_names_include => p_object_names_include
              , p_object_types_to_check => l_object_types_to_check
                -- database values
              , p_metadata_object_type => obj.object_type()
              , p_object_name => obj.object_name()
              , p_metadata_base_object_type => obj.base_object_type()
              , p_base_object_name => obj.base_object_name()
              ) = 1
      ;

      p_schema_object_tab := p_schema_object_tab multiset union /*distinct*/ l_schema_object_tab;
    end if;

    longops_done(l_longops_rec);

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
    check_duplicates(p_schema_object_tab);
$end

    cleanup;

$if cfg_pkg.c_debugging $then
    dbug.print(dbug."output", 'cardinality(p_schema_object_tab): %s', cardinality(p_schema_object_tab));
    dbug.leave;
$end

  exception
    when others
    then
      cleanup;
$if cfg_pkg.c_debugging $then
      dbug.leave_on_error;
$end
      raise;
  end get_schema_object;

  function get_schema_object
  ( p_schema in t_schema_nn
  , p_object_type in t_metadata_object_type
  , p_object_names in t_object_names
  , p_object_names_include in t_numeric_boolean
  , p_grantor_is_schema in t_numeric_boolean_nn
  )
  return t_schema_object_tab
  pipelined
  is
    l_schema_object_tab t_schema_object_tab;
  begin
    oracle_tools.pkg_ddl_util.get_schema_object
    ( p_schema => p_schema
    , p_object_type => p_object_type
    , p_object_names => p_object_names
    , p_object_names_include => p_object_names_include
    , p_grantor_is_schema => p_grantor_is_schema
    , p_schema_object_tab => l_schema_object_tab
    );
    if l_schema_object_tab is not null and l_schema_object_tab.count > 0
    then
      for i_idx in l_schema_object_tab.first .. l_schema_object_tab.last
      loop
        pipe row (l_schema_object_tab(i_idx));
      end loop;
    end if;
  end get_schema_object;

  procedure get_member_ddl
  ( p_schema_ddl in t_schema_ddl
  , p_member_ddl_tab out nocopy t_schema_ddl_tab
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

    l_member_object t_type_attribute_object;
    l_type_method_object t_type_method_object;
    l_member_ddl t_schema_ddl;

    l_table_ddl_clob clob := null;
    l_member_ddl_clob clob := null;
    l_data_default t_text_tab;
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
$if cfg_pkg.c_debugging $then
    dbug.enter(g_package_prefix || 'GET_MEMBER_DDL');
    p_schema_ddl.print();
$end

    p_member_ddl_tab := t_schema_ddl_tab();

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
        pkg_str_util.text2clob
        ( pi_text_tab => p_schema_ddl.ddl_tab(1).text -- CREATE TABLE statement
        , pio_clob => l_table_ddl_clob
        , pi_append => false
        );
        l_start := 1;
    end case;        

    open l_cursor for l_statement using p_schema_ddl.obj.object_schema(), p_schema_ddl.obj.object_name();
    fetch l_cursor bulk collect into l_member_tab;
    close l_cursor;

$if cfg_pkg.c_debugging $then
    dbug.print(dbug."info", 'l_member_tab.count: %s', l_member_tab.count);
$end

    if l_member_tab.count > 0
    then
      <<member_loop>>
      for i_idx in l_member_tab.first .. l_member_tab.last
      loop
$if cfg_pkg.c_debugging $then
        dbug.print(dbug."info", 'l_member_tab(%s); member#: %s; member_name: %s', i_idx, l_member_tab(i_idx).member#, l_member_tab(i_idx).member_name);
$end
        case p_schema_ddl.obj.object_type()
          when 'TYPE_SPEC'
          then
            begin
              l_member_object :=
                t_type_attribute_object
                ( p_base_object => treat(p_schema_ddl.obj as t_named_object)
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

              l_member_ddl := t_type_attribute_ddl(l_member_object);

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
              l_member_ddl.print();
$end

              p_member_ddl_tab.extend(1);
              p_member_ddl_tab(p_member_ddl_tab.last) := l_member_ddl;
            exception
              when others
              then
$if cfg_pkg.c_debugging $then
                dbug.on_error;
$end
                raise_application_error(-20000, 'attribute [' || i_idx || ']: ' || l_member_tab(i_idx).member_name, true);
            end;

          when 'TABLE'
          then
            begin
              if l_member_tab(i_idx).default_length > 0
              then
                dbms_lob.trim(l_data_default_clob, 0);
                pkg_str_util.append_text
                ( pi_buffer => l_member_tab(i_idx).data_default
                , pio_clob => l_data_default_clob
                );
                l_data_default := pkg_str_util.clob2text(l_data_default_clob);
              else
                l_data_default := null;
              end if;

              l_member_object :=
                t_table_column_object
                ( p_base_object => treat(p_schema_ddl.obj as t_named_object)
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

              pkg_str_util.append_text
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

$if cfg_pkg.c_debugging $then
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

$if cfg_pkg.c_debugging $then
              dbug.print(dbug."info", 'l_pattern: %s; l_start: %s; l_pos: %s', l_pattern, l_start, l_pos);
$end

              if l_pos > 0
              then
                if i_idx < l_member_tab.last
                then
                  -- strip command and whitespace before "<next column>"
                  while dbms_lob.substr(lob_loc => l_table_ddl_clob, amount => 1, offset => l_pos - 1) in (',', ' ', chr(9), chr(10), chr(13))
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
                  pkg_str_util.append_text
                  ( pi_buffer => chr(10) || '/'
                  , pio_clob => l_member_ddl_clob
                  );
                end if;

                -- use the default constructor so we can determine the DDL
                l_member_ddl := t_table_column_ddl(l_member_object, t_ddl_tab());
                l_member_ddl.add_ddl
                ( p_verb => 'ALTER'
                , p_text => pkg_str_util.clob2text(l_member_ddl_clob)
                );

                l_start := l_pos; -- next start position for search
              else
                raise program_error;
              end if;

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
              l_member_ddl.print();
$end

              l_member_ddl.chk(p_schema_ddl.obj.object_schema());

              p_member_ddl_tab.extend(1);
              p_member_ddl_tab(p_member_ddl_tab.last) := l_member_ddl;
            exception
              when others
              then
$if cfg_pkg.c_debugging $then
                dbug.on_error;
$end
                raise_application_error(-20000, 'column [' || i_idx || ']: ' || l_member_tab(i_idx).member_name, true);
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
      fetch l_cursor bulk collect into l_type_method_tab;
      close l_cursor;

$if cfg_pkg.c_debugging $then
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
$if cfg_pkg.c_debugging $then
          dbug.print(dbug."info", 'l_type_method_tab(%s); member#: %s; member_name: %s', i_idx, l_type_method_tab(i_idx).member#, l_type_method_tab(i_idx).member_name);
$end
          begin
            open l_cursor for l_statement
              using p_schema_ddl.obj.object_schema()
                  , p_schema_ddl.obj.object_name()
                  , l_type_method_tab(i_idx).member_name
                  , l_type_method_tab(i_idx).member#;
            fetch l_cursor bulk collect into l_argument_tab;
            close l_cursor;

            l_type_method_object :=
              t_type_method_object
              ( p_base_object => treat(p_schema_ddl.obj as t_named_object)
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

            l_member_ddl := t_type_method_ddl(l_type_method_object);

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
            l_member_ddl.print();
$end

            l_member_ddl.chk(p_schema_ddl.obj.object_schema());

            p_member_ddl_tab.extend(1);
            p_member_ddl_tab(p_member_ddl_tab.last) := l_member_ddl;
          exception
            when others
            then
$if cfg_pkg.c_debugging $then
              dbug.on_error;
$end
              raise_application_error(-20000, 'attribute [' || i_idx || ']: ' || l_member_tab(i_idx).member_name, true);
          end;
        end loop;
      end if;
    end if; -- if p_schema_ddl.obj.object_type() = 'TYPE_SPEC'

    cleanup;

$if cfg_pkg.c_debugging $then
    dbug.leave;
$end
  exception
    when others
    then
      cleanup;
$if cfg_pkg.c_debugging $then
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
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
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
          when p_object_type = 'OBJECT_GRANT' -- too slow, see T_OBJECT_GRANT_OBJECT
          then 0
          when p_value
          then 1
          else 0
        end;
    end if;

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
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
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
    dbug.enter(g_package_prefix || 'DO_CHK (2)');
    dbug.print(dbug."input", 'p_object_type: %s', p_object_type);
$end

    l_value := case when g_chk_tab.exists(p_object_type) and g_chk_tab(p_object_type) = 1 then true else false end;

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
    dbug.print(dbug."output", 'return: %s', l_value);
    dbug.leave;
$end

    return l_value;
  end do_chk;

  procedure chk_schema_object
  ( p_schema_object in t_schema_object
  , p_schema in varchar2
  )
  is
  begin
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
    dbug.enter(g_package_prefix || 'CHK_SCHEMA_OBJECT (1)');
    dbug.print(dbug."input", 'p_schema_object:');
    p_schema_object.print();
$end

    if p_schema_object.object_type() is null
    then
      raise_application_error(-20000, 'Object type should not be empty');
    elsif p_schema_object.dict2metadata_object_type() = p_schema_object.object_type()
    then
      null; -- ok
    else
      raise_application_error
      ( -20000
      , 'Object type (' ||
        p_schema_object.object_type() ||
        ') should be equal to this DBMS_METADATA object type (' ||
        p_schema_object.dict2metadata_object_type() ||
        ')'
      );
    end if;

    if (p_schema_object.base_object_type() is null) != (p_schema_object.base_object_schema() is null)
    then
      raise_application_error
      ( -20000
      , 'Base object type (' ||
        p_schema_object.base_object_type() ||
        ') and base object schema (' ||
        p_schema_object.base_object_schema() ||
        ') must both be empty or both not empty'
      );
    end if;

    if (p_schema_object.base_object_name() is null) != (p_schema_object.base_object_schema() is null)
    then
      raise_application_error
      ( -20000
      , 'Base object name (' ||
        p_schema_object.base_object_name() ||
        ') and base object schema (' ||
        p_schema_object.base_object_schema() ||
        ') must both be empty or both not empty'
      );
    end if;

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
    dbug.leave;
  exception
    when others
    then
      dbug.leave_on_error;
      raise;
$end
  end chk_schema_object;

  procedure chk_schema_object
  ( p_dependent_or_granted_object in t_dependent_or_granted_object
  , p_schema in varchar2
  )
  is
  begin
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
    dbug.enter(g_package_prefix || 'CHK_SCHEMA_OBJECT (2)');
$end

    chk_schema_object(p_schema_object => p_dependent_or_granted_object, p_schema => p_schema);

    if p_dependent_or_granted_object.object_schema() is null or p_dependent_or_granted_object.object_schema() = p_schema
    then
      null; -- ok
    else
      raise_application_error(-20000, 'Object schema should be empty or ' || p_schema);
    end if;

    if p_dependent_or_granted_object.base_object$ is null
    then
      raise_application_error(-20000, 'Base object should not be empty.');
    end if;

    -- GPA 2017-01-18 too strict for triggers, synonyms, indexes, etc.
/*
    if p_dependent_or_granted_object.base_object_schema() = p_schema
    then
      null; -- ok
    else
      raise_application_error(-20000, 'Base object schema must be ' || p_schema);
    end if;
*/

    if p_dependent_or_granted_object.base_object_schema() is null
    then
      raise_application_error(-20000, 'Base object schema should not be empty');
    end if;

    if p_dependent_or_granted_object.base_object_type() is null
    then
      raise_application_error(-20000, 'Base object type should not be empty');
    end if;

    if p_dependent_or_granted_object.base_object_name() is null
    then
      raise_application_error(-20000, 'Base object name should not be empty');
    end if;

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
  end chk_schema_object;

  procedure chk_schema_object
  ( p_named_object in t_named_object
  , p_schema in varchar2
  )
  is
$if pkg_ddl_util.c_#140920801 $then
  -- Capture invalid objects before releasing to next enviroment.
  l_status all_objects.status%type := null;
$end  
  begin
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
    dbug.enter(g_package_prefix || 'CHK_SCHEMA_OBJECT (3)');
$end

    chk_schema_object(p_schema_object => p_named_object, p_schema => p_schema);

    if p_named_object.object_name() is null
    then
      raise_application_error(-20000, 'Object name should not be empty');
    end if;
    if p_named_object.object_schema() = p_schema
    then
      null; -- ok
    else
      raise_application_error
      ( -20000
      , 'Object schema (' ||
        p_named_object.object_schema() ||
        ') must be ' ||
        p_schema
      );
    end if;

$if pkg_ddl_util.c_#140920801 $then

  -- Capture invalid objects before releasing to next enviroment.
  if do_chk(p_named_object.object_type()) and p_named_object.network_link() is null
  then
    begin
      select  obj.status
      into    l_status
      from    all_objects obj
      where   obj.owner = p_named_object.object_schema()
      and     obj.object_type = p_named_object.dict_object_type()
      and     obj.object_name = p_named_object.object_name()
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
        raise_application_error
        ( -20000
        , 'Object status (' ||
          l_status ||
          ') must be VALID'
        , true
        );
    end;
  end if;

$end

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
    dbug.leave;
  exception
    when others
    then
      dbug.leave_on_error;
      raise;
$end
  end chk_schema_object;

  procedure chk_schema_object
  ( p_constraint_object in t_constraint_object
  , p_schema in varchar2
  )
  is
  begin
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
    dbug.enter(g_package_prefix || 'CHK_SCHEMA_OBJECT (4)');
$end

    pkg_ddl_util.chk_schema_object(p_dependent_or_granted_object => p_constraint_object, p_schema => p_schema);

    if p_constraint_object.object_schema() = p_schema
    then
      null; -- ok
    else
      raise_application_error(-20000, 'Object schema (' || p_constraint_object.object_schema() || ') must be ' || p_schema);
    end if;
    if p_constraint_object.base_object_schema() is null
    then
      raise_application_error(-20000, 'Base object schema should not be empty.');
    end if;
    if p_constraint_object.constraint_type() is null
    then
      raise_application_error(-20000, 'Constraint type should not be empty.');
    end if;

    case 
      when p_constraint_object.constraint_type() in ('P', 'U', 'R')
      then
        if p_constraint_object.column_names() is null
        then
          raise_application_error(-20000, 'Column names should not be empty');
        end if;
        if p_constraint_object.search_condition() is not null
        then
          raise_application_error(-20000, 'Search condition should be empty');
        end if;

      when p_constraint_object.constraint_type() in ('C')
      then
        if p_constraint_object.column_names() is not null
        then
          raise_application_error(-20000, 'Column names should be empty');
        end if;
        if p_constraint_object.search_condition() is null
        then
          raise_application_error(-20000, 'Search condition should not be empty');
        end if;

    end case;

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
    dbug.leave;
  exception
    when others
    then
      dbug.leave_on_error;
      raise;
$end
  end chk_schema_object;

  /*
  -- helper function
  */
  function schema_object_matches_filter
  ( -- filter values
    p_object_type in t_metadata_object_type
  , p_object_names in t_object_names
  , p_object_names_include in t_numeric_boolean
  , p_object_types_to_check in t_text_tab
    -- database values
  , p_metadata_object_type in t_metadata_object_type
  , p_object_name in t_object_name
  , p_metadata_base_object_type in t_metadata_object_type default null
  , p_base_object_name in t_object_name default null
  )
  return t_numeric_boolean_nn
  deterministic
  is
    l_result t_numeric_boolean_nn := 0;
  begin
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
    dbug.enter(g_package_prefix || 'SCHEMA_OBJECT_MATCHES_FILTER');
    dbug.print
    ( dbug."input"
    , 'p_object_types_to_check.count: %s; p_metadata_object_type: %s; p_object_name: %s; p_metadata_base_object_type: %s; p_base_object_name: %s'
    , p_object_types_to_check.count
    , p_metadata_object_type
    , p_object_name
    , p_metadata_base_object_type
    , p_base_object_name
    );

    check_object_type(p_object_type => p_object_type);
    check_object_names(p_object_names => substr(p_object_names, 2, length(p_object_names)-2), p_object_names_include => p_object_names_include);
    check_numeric_boolean(p_numeric_boolean => p_object_names_include, p_description => 'Object names include');
    check_object_type(p_object_type => p_metadata_object_type);
    check_object_type(p_object_type => p_metadata_base_object_type);
$end    

    case
      -- exclude certain (semi-)dependent objects
      when p_metadata_base_object_type is not null and
           p_base_object_name is not null and
           is_exclude_name_expr(p_metadata_base_object_type, p_base_object_name) = 1
      then
        l_result := 0;

      -- exclude certain objects
      when p_metadata_object_type is not null and
           p_object_name is not null and
           is_exclude_name_expr(p_metadata_object_type, p_object_name) = 1
      then
        l_result := 0;

      when p_metadata_object_type not member of p_object_types_to_check
      then
        l_result := 1; -- anything is fine

      when -- filter on object type
           ( p_object_type is null or
             p_object_type = p_metadata_object_type or
             p_object_type = p_metadata_base_object_type
           )
           and
           -- filter on object name
           ( p_object_names_include is null or
             p_object_names_include =
             case -- found?
               when p_object_name is not null and
                    instr(p_object_names, ','||p_object_name||',') > 0
               then 1
               when p_base_object_name is not null and
                    instr(p_object_names, ','||p_base_object_name||',') > 0
               then 1
               else 0
             end
           )
      then
        l_result := 1;

      else
        l_result := 0;
    end case;

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
    dbug.print(dbug."output", 'return: %s', l_result);
    dbug.leave;
$end

    return l_result;
  end schema_object_matches_filter;

  function is_dependent_object_type
  ( p_object_type in t_metadata_object_type
  )
  return t_numeric_boolean
  deterministic
  is
  begin
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 3 $then
    check_object_type(p_object_type);
$end    

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
  , p_exclude_name_expr_tab out nocopy t_text_tab
  )
  is
  begin
    if not(g_object_exclude_name_expr_tab.exists(p_object_type))
    then
      p_exclude_name_expr_tab := t_text_tab();
    else
      if p_object_name is null
      then
        p_exclude_name_expr_tab := g_object_exclude_name_expr_tab(p_object_type);
      else
        p_exclude_name_expr_tab := t_text_tab();
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
    l_exclude_name_expr_tab t_text_tab;
  begin
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
    dbug.enter(g_package_prefix || 'IS_EXCLUDE_NAME_EXPR');
    dbug.print(dbug."input", 'p_object_type: %s; p_object_name: %s', p_object_type, p_object_name);    
$end

    get_exclude_name_expr_tab(p_object_type => p_object_type, p_object_name => p_object_name, p_exclude_name_expr_tab => l_exclude_name_expr_tab);
    l_result := sign(l_exclude_name_expr_tab.count); -- when 0 return 0; when > 0 return 1

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
    dbug.print(dbug."output", 'return: %s', l_result);
    dbug.leave;
$end

    return l_result;
  end is_exclude_name_expr;

  /*
  -- Help function to get the DDL belonging to a list of allowed objects returned by get_schema_object()
  */
  function get_schema_ddl
  ( p_schema in t_schema_nn
  , p_new_schema in t_schema
  , p_use_schema_export in t_numeric_boolean_nn
  , p_schema_object_tab in t_schema_object_tab
  , p_transform_param_list in varchar2
  )
  return t_schema_ddl_tab
  pipelined
  is
    -- ORA-31642: the following SQL statement fails:
    -- BEGIN "SYS"."DBMS_SCHED_EXPORT_CALLOUTS".SCHEMA_CALLOUT(:1,1,1,'11.02.00.00.00'); END;
    -- ORA-06512: at "SYS.DBMS_SYS_ERROR", line 86
    -- ORA-06512: at "SYS.DBMS_METADATA", line 1225
    -- ORA-04092: cannot COMMIT in a trigger
    pragma autonomous_transaction;

    l_object_lookup_tab t_object_lookup_tab; -- list of all objects
    l_constraint_lookup_tab t_constraint_lookup_tab;
    l_object_key t_object;
    l_handle number := null;

    l_ddl_tab sys.ku$_ddls; -- moet package globaal zijn i.v.m. performance

    /*
      Only for the following object types both object_schema and base_object_schema may be not null:
      1) INDEX (based on an object in another schema)
      2) TRIGGER (based on an object in another schema)
      3) SYNONYM (object_schema is either PUBLIC and base_object_schema is p_schema or object_schema = p_schema)
      4) REF_CONSTRAINT/CONSTRAINT (based on an object in another schema)

      In the first three cases, you must supply an empty base_object_schema for dbms_metadata.open(), except
      when object_schema <> p_schema (e.g. the public synonyms).

      In the fourth case, you must supply an empty object_schema for dbms_metadata.open().

      For all other object types, either the object_schema or the base_object_schema is null.
    */

    cursor c_params is
      select  object_type
      ,       object_schema
      ,       base_object_schema
      ,       object_name_tab
      ,       base_object_name_tab
      ,       nr_objects
      from    ( with src as
                ( select  'SCHEMA_EXPORT' as object_type
                  ,       p_schema as object_schema
                  ,       null as object_name
                  ,       null as base_object_schema
                  ,       null as base_object_name
                  ,       null as column_name -- to get the count right
                  ,       null as grantee -- to get the count right
                  ,       null as privilege -- to get the count right
                  ,       null as grantable -- to get the count right
                  from    dual
                  where   c_use_schema_export * p_use_schema_export = 1
                  union
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
                            when t.object_type() = 'SYNONYM' and t.object_schema() = p_schema
                            then null
                            else t.base_object_schema()
                          end as base_object_schema
                  ,       case
                            when t.object_type() in ('INDEX', 'TRIGGER') and t.object_schema() = p_schema
                            then null
                            when t.object_type() = 'SYNONYM' and t.object_schema() = p_schema
                            then null
                            else t.base_object_name()
                          end as base_object_name
                  ,       t.column_name()
                  ,       t.grantee()
                  ,       t.privilege()
                  ,       t.grantable()
                  from    table(p_schema_object_tab) t
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
              case object_schema when 'PUBLIC' then 0 when p_schema then 1 else 2 end -- PUBLIC synonyms first
      ,       case when object_type = 'SCHEMA_EXPORT' then 0 else 1 end -- SCHEMA_EXPORT next
      ,       object_type
      ,       object_schema
      ,       base_object_schema
    ;

    type t_params_tab is table of c_params%rowtype;

    l_params_tab t_params_tab;
    r_params c_params%rowtype;
    l_params_idx pls_integer;

    l_transform_param_tab t_transform_param_tab;

    l_program constant varchar2(30 char) := 'GET_SCHEMA_DDL'; -- geen schema omdat l_program in dbms_application_info wordt gebruikt

    -- dbms_application_info stuff
    l_longops_rec t_longops_rec;

    -- dbms_application_info stuff for dbms_metadata.open
    l_longops_open_rec t_longops_rec;

    procedure init
    is
      l_schema_object t_schema_object;
      l_ref_constraint_object t_ref_constraint_object;
    begin
$if cfg_pkg.c_debugging $then
      dbug.enter(g_package_prefix || l_program || '.INIT');
$end

      get_transform_param_tab(p_transform_param_list, l_transform_param_tab);

      if p_schema_object_tab is not null and p_schema_object_tab.count > 0
      then
        for i_idx in p_schema_object_tab.first .. p_schema_object_tab.last
        loop
          begin
            l_schema_object := p_schema_object_tab(i_idx);

            if p_new_schema is not null
            then
              -- If we are going to move to another schema, adjust all schema attributes because the DDL generated
              -- will also be changed due to dbms_metadata.set_remap_param() being called.
              if l_schema_object.object_schema() = p_schema
              then
                l_schema_object.object_schema(p_new_schema);
              end if;
              if l_schema_object.base_object_schema() = p_schema
              then
                l_schema_object.base_object_schema(p_new_schema);
              end if;
              if l_schema_object is of (t_ref_constraint_object)
              then
                l_ref_constraint_object := treat(l_schema_object as t_ref_constraint_object);
                if l_ref_constraint_object.ref_object_schema() = p_schema
                then
                  l_ref_constraint_object.ref_object_schema(p_new_schema);
                  l_schema_object := l_ref_constraint_object;
                end if;
              end if;
            end if;

            l_schema_object.chk(nvl(p_new_schema, p_schema));

            l_object_key := l_schema_object.id();

            if not l_object_lookup_tab.exists(l_object_key)
            then
              t_schema_ddl.create_schema_ddl
              ( p_obj => l_schema_object
              , p_ddl_tab => t_ddl_tab()
              , p_schema_ddl => l_object_lookup_tab(l_object_key).schema_ddl
              );
            else
              raise dup_val_on_index;
            end if;

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
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
            then raise_application_error(-20000, 'Object id: ' || l_schema_object.id() || chr(10) || 'Object signature: ' || l_object_key, true);
          end;  
        end loop;
      end if;
$if cfg_pkg.c_debugging $then
      dbug.leave;
$end
    end init;

    procedure find_next_params
    is
    begin
$if cfg_pkg.c_debugging $then
      dbug.enter(g_package_prefix || l_program || '.FIND_NEXT_PARAMS');
$end
      -- now we are going to find an object type which has at least one object not ready
      <<find_next_params_loop>>
      loop
        l_params_idx := l_params_tab.next(l_params_idx);

        exit find_next_params_loop when l_params_idx is null or l_params_tab(l_params_idx).object_type = 'SCHEMA_EXPORT';

        -- determine whether there is no object which is not ready
        l_object_key := l_object_lookup_tab.first;
        <<object_loop>>
        while l_object_key is not null
        loop
          if not(l_object_lookup_tab(l_object_key).ready) and
             l_object_key like t_schema_object.id('%', l_params_tab(l_params_idx).object_type, '%', '%', '%', '%', '%', '%', '%', '%')
          then
            -- we must process this handle
$if cfg_pkg.c_debugging $then
            dbug.print
            ( dbug."warning"
            , 'Object %s not ready for schema %s and type %s'
            , l_object_key
            , l_params_tab(l_params_idx).object_schema
            , l_params_tab(l_params_idx).object_type
            );
$end
            exit find_next_params_loop;
          end if;

          l_object_key := l_object_lookup_tab.next(l_object_key);
        end loop object_loop;

$if cfg_pkg.c_debugging $then
        dbug.print
        ( dbug."info"
        , 'All objects found for schema %s and type %s'
        , l_params_tab(l_params_idx).object_schema
        , l_params_tab(l_params_idx).object_type
        );
$end
      end loop find_next_params_loop;
$if cfg_pkg.c_debugging $then
      dbug.leave;
$end
    end find_next_params;

$if cfg_pkg.c_debugging $then
    procedure chk
    is
    begin
      dbug.enter(g_package_prefix || l_program || '.CHK');
      l_object_key := l_object_lookup_tab.first;
      while l_object_key is not null
      loop
        dbug.print
        ( case sign(l_object_lookup_tab(l_object_key).count)
            when 1 -- found by get_schema_object and fetch_ddl
            then dbug."info"
            else dbug."warning"
          end
        , 'l_object_lookup_tab(%s): %s'
        , l_object_key
        , l_object_lookup_tab(l_object_key).count
        );
        if l_object_lookup_tab(l_object_key).count >= 1
        then
          null;
        else
          raise_application_error(-20000, 'No DDL retrieved for object ' || l_object_key);
        end if;
        l_object_key := l_object_lookup_tab.next(l_object_key);
      end loop;
      dbug.leave;
    end chk;
$end

    procedure cleanup
    is
    begin
      md_close(l_handle);
    end cleanup;
  begin
$if cfg_pkg.c_debugging $then
    dbug.enter(g_package_prefix || l_program);
    dbug.print
    ( dbug."input"
    , 'p_schema: %s; p_new_schema: %s; p_use_schema_export: %s; p_schema_object_tab.count: %s'
    , p_schema
    , p_new_schema
    , p_use_schema_export
    , case when p_schema_object_tab is not null then p_schema_object_tab.count end
    );
$end

    init;

    l_longops_rec := longops_init(p_op_name => 'fetch', p_units => 'objects', p_target_desc => l_program, p_totalwork => l_object_lookup_tab.count);

    open c_params;
    fetch c_params bulk collect into l_params_tab;
    close c_params;

    l_longops_open_rec := longops_init(p_op_name => 'open', p_units => 'handles', p_target_desc => 'DBMS_METADATA', p_totalwork => l_params_tab.count);

    l_params_idx := l_params_tab.first;
    <<open_handle_loop>>
    loop
      exit when l_params_idx is null;

      r_params := l_params_tab(l_params_idx);

      declare
        -- dbms_application_info stuff
        l_longops_type_rec t_longops_rec :=
          longops_init
          ( p_totalwork =>
              case
                when r_params.object_type = 'SCHEMA_EXPORT'
                then l_object_lookup_tab.count - l_longops_rec.sofar
                else r_params.nr_objects
              end
          , p_op_name =>
              'fetch' ||
              case when r_params.object_schema is not null then '; schema ' || r_params.object_schema end ||
              case when r_params.base_object_schema is not null then '; base schema ' || r_params.base_object_schema end
          , p_units => 'objects'
          , p_target_desc => r_params.object_type
          );
      begin
        md_open
        ( p_object_type => r_params.object_type
        , p_object_schema => r_params.object_schema
        , p_object_name_tab => r_params.object_name_tab
        , p_base_object_schema => r_params.base_object_schema
        , p_base_object_name_tab => r_params.base_object_name_tab
        , p_new_object_schema => p_new_schema
        , p_transform_param_tab => l_transform_param_tab
        , p_handle => l_handle
        );

        -- open handles
        l_longops_open_rec.target_desc := r_params.object_type;
        longops_show(l_longops_open_rec);

        -- objects fetched for this param
        <<fetch_loop>>
        loop
          md_fetch_ddl(l_handle, l_ddl_tab);

          exit fetch_loop when l_ddl_tab is null;

          if l_ddl_tab.count > 0
          then
            for i_ku$ddls_idx in l_ddl_tab.first .. l_ddl_tab.last
            loop
              parse_object
              ( p_schema => p_schema
              , p_new_schema => p_new_schema
              , p_ku$_ddl => l_ddl_tab(i_ku$ddls_idx)
              , p_constraint_lookup_tab => l_constraint_lookup_tab
              , p_object_lookup_tab => l_object_lookup_tab
              , p_object_key => l_object_key
              );
              if l_object_key is not null
              then
                -- some checks
                if not(l_object_lookup_tab.exists(l_object_key))
                then
                  raise program_error;
                end if;

                if not(l_object_lookup_tab(l_object_key).ready)
                then
                  pipe row (l_object_lookup_tab(l_object_key).schema_ddl);

                  l_longops_type_rec.sofar := l_longops_type_rec.sofar + 1;

                  l_object_lookup_tab(l_object_key).ready := true;
                end if;
              end if;
            end loop;
          end if;

          -- objects fetched for this param
          longops_show(l_longops_type_rec, 0);
        end loop fetch_loop;

        -- overall
        longops_done(l_longops_type_rec);        
        longops_show(l_longops_rec, l_longops_type_rec.totalwork);

        md_close(l_handle);
      exception
        when dup_val_on_index
        then
$if cfg_pkg.c_debugging $then
          dbug.on_error;
$end
          raise_application_error
          ( -20000
          , 'Duplicate objects to be retrieved: type: ' || r_params.object_type || '; schema: ' || r_params.object_schema || '; base schema: ' || r_params.base_object_schema
          );

        when program_error
        then
          raise;

        when others
        then
$if cfg_pkg.c_debugging $then
          dbug.on_error;
$end
          md_close(l_handle);
          if r_params.object_type = 'SCHEMA_EXPORT'
          then
            null;
          else
            raise;
          end if;
      end;

      find_next_params;
    end loop open_handle_loop;

    -- show 100%
    longops_done(l_longops_open_rec);
    longops_done(l_longops_rec);

$if cfg_pkg.c_debugging $then
    chk;
$end

    cleanup;

$if cfg_pkg.c_debugging $then
    dbug.leave;
$end

    commit; -- see pragma

    return; -- essential for a pipelined function
  exception
    when others
    then
      cleanup;
$if cfg_pkg.c_debugging $then
      dbug.leave_on_error;
$end
      raise;
  end get_schema_ddl;

  /*
  -- Help procedure to store the results of display_ddl_schema on a remote database.
  */
  procedure set_display_ddl_schema_args
  ( p_schema in t_schema_nn
  , p_new_schema in t_schema
  , p_sort_objects_by_deps in t_numeric_boolean_nn
  , p_object_type in t_metadata_object_type
  , p_object_names in t_object_names
  , p_object_names_include in t_numeric_boolean
  , p_network_link in t_network_link
  , p_grantor_is_schema in t_numeric_boolean_nn
  , p_transform_param_list in varchar2
  )
  is
$if not(dbms_db_version.ver_le_10) $then
    l_cursor sys_refcursor;
$end    
    l_network_link all_db_links.db_link%type := null;
  begin
$if cfg_pkg.c_debugging $then
    dbug.enter(g_package_prefix || 'SET_DISPLAY_DDL_SCHEMA_ARGS');
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
               ,p_transform_param_list);
$end

    if p_network_link is null
    then
$if dbms_db_version.ver_le_10 $then
      select  value(t) as schema_ddl
      bulk collect 
      into    g_schema_ddl_tab
      from    table
              ( oracle_tools.pkg_ddl_util.display_ddl_schema
                ( p_schema
                , p_new_schema
                , p_sort_objects_by_deps
                , p_object_type
                , p_object_names
                , p_object_names_include
                , null -- p_network_link
                , p_grantor_is_schema
                , p_transform_param_list
                )
              ) t;
$else  
      open l_cursor for
        select  value(t) as schema_ddl
        from    table
                ( oracle_tools.pkg_ddl_util.display_ddl_schema
                  ( p_schema
                  , p_new_schema
                  , p_sort_objects_by_deps
                  , p_object_type
                  , p_object_names
                  , p_object_names_include
                  , null -- p_network_link
                  , p_grantor_is_schema
                  , p_transform_param_list
                  )
                ) t;
      -- PLS-00994: Cursor Variables cannot be declared as part of a package
      g_cursor := dbms_sql.to_cursor_number(l_cursor);  
$if cfg_pkg.c_debugging $then
      dbug.print(dbug."info", 'sid: %s; g_cursor: %s', sys_context('userenv','sid'), g_cursor);
$end

$end
    else
      -- check whether database link exists
      check_network_link(p_network_link);
      l_network_link := get_db_link(p_network_link);

      if l_network_link is null
      then
        raise program_error;
      else
        l_network_link := '@' || l_network_link;
      end if;

      declare
        l_statement constant varchar2(4000 char) := q'[
begin
  oracle_tools.pkg_ddl_util.set_display_ddl_schema_args]' || l_network_link || q'[
  ( p_schema => :b1
  , p_new_schema => :b2
  , p_sort_objects_by_deps => :b3
  , p_object_type => :b4
  , p_object_names => :b5
  , p_object_names_include => :b6
  , p_network_link => null
  , p_grantor_is_schema => :b7
  , p_transform_param_list => :b8
  );
end;]';
      begin
        execute immediate l_statement
          using p_schema, p_new_schema, p_sort_objects_by_deps, p_object_type, p_object_names, p_object_names_include, p_grantor_is_schema, p_transform_param_list;
      exception
        when others
        then raise_application_error(-20000, l_statement, true);
      end;
    end if;

$if cfg_pkg.c_debugging $then
    dbug.leave;
  exception
    when others
    then
      dbug.leave_on_error;
      raise;
$end
  end set_display_ddl_schema_args;

  /*
  -- Help procedure to retrieve the results of display_ddl_schema on a remote database.
  --
  -- Remark 1: Uses view v_display_ddl_schema2 because pipelined functions and a database link are not allowed.
  -- Remark 2: A call to display_ddl_schema() with a database linke will invoke set_display_ddl_schema() at the remote database.
  */
  function get_display_ddl_schema
  return t_schema_ddl_tab
  pipelined
  is
$if not(dbms_db_version.ver_le_10) $then
    l_cursor sys_refcursor;
    l_schema_ddl t_schema_ddl;
$end    
  begin
$if cfg_pkg.c_debugging $then
    dbug.enter(g_package_prefix || 'GET_DISPLAY_DDL_SCHEMA');
$end

$if dbms_db_version.ver_le_10 $then
    if g_schema_ddl_tab is not null and g_schema_ddl_tab.count > 0
    then
      for i_idx in g_schema_ddl_tab.first .. g_schema_ddl_tab.last
      loop
        pipe row (g_schema_ddl_tab(i_idx));
      end loop;
    end if;
$else
    -- PLS-00994: Cursor Variables cannot be declared as part of a package
$if cfg_pkg.c_debugging $then
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
    end loop;
    close l_cursor;
$end

$if cfg_pkg.c_debugging $then
    dbug.leave;
$end
  end get_display_ddl_schema;

  /*
  -- Sorteer objecten op volgorde van afhankelijkheden.
  */
  function sort_objects_by_deps
  ( p_cursor in sys_refcursor
  , p_schema in t_schema_nn
  )
  return t_sort_objects_by_deps_tab
  pipelined
  is
    -- bepaal dependencies gebaseerd op PL/SQL
    cursor c_dependencies(b_schema in varchar2) is
      select  t.*
      from    ( select t.owner as object_owner
                      ,t.type as object_type
                      ,t.name as object_name
                      ,t.referenced_owner
                      ,t.referenced_type
                      ,t.referenced_name
                from   all_dependencies t
                where  t.owner = b_schema
                and    t.owner = t.referenced_owner
                and    t.referenced_link_name is null
                union
$if not(pkg_ddl_util.c_#138707615_2) $then
                -- bepaal dependencies gebaseerd op foreign key constraints
                select t1.owner as object_owner
                      ,'TABLE' as object_type
                      ,t1.table_name as object_name
                      ,t2.owner as referenced_owner
                      ,'TABLE' as referenced_type
                      ,t2.table_name as referenced_name
                from   all_constraints t1
                inner  join all_constraints t2
                on     t2.owner = t1.r_owner
                and    t2.constraint_name = t1.r_constraint_name
                where  t1.owner = b_schema
                and    t1.owner = t2.owner /* same schema */
                and    t1.constraint_type = 'R'
$else
                -- more simple: just the constraints
                select c.owner as object_owner
                      ,'REF_CONSTRAINT' as object_type
                      ,c.constraint_name as object_name
                      ,c.r_owner as referenced_owner
                      ,'CONSTRAINT' as referenced_type
                      ,c.r_constraint_name as referenced_name
                from   all_constraints c
                where  c.owner = b_schema
                and    c.constraint_type = 'R'
$end
                union
                -- bepaal dependencies gebaseerd op indexen van een tabel
                select i.owner as object_owner
                      ,'INDEX' as object_type
                      ,i.index_name as object_name
                      ,i.table_owner as referenced_owner
                      ,'TABLE' as referenced_type
                      ,i.table_name as referenced_name
                from   all_indexes i
                where  i.owner = b_schema
                union
                -- bepaal dependencies gebaseerd op indexen van een materialized view (niet PREBUILT)
                select t1.owner as object_owner
                      ,'INDEX' as object_type
                      ,t1.index_name as object_name
                      ,t1.table_owner as referenced_owner
                      ,'MATERIALIZED VIEW' as referenced_type
                      ,t1.table_name as referenced_name
                from   all_indexes t1
                       inner join all_mviews t2
                on     t2.owner = t1.table_owner
                and    t2.mview_name = t1.table_name
                where  t1.owner = b_schema
                and    t2.build_mode != 'PREBUILT'
                union
                -- bepaal dependencies gebaseerd op objecten waarnaar wordt verwezen door synoniemen
                select t1.owner as object_owner
                      ,'SYNONYM' as object_type
                      ,t1.synonym_name as object_name
                      ,t2.owner as referenced_owner
                      ,t2.object_type as referenced_type
                      ,t2.object_name as referenced_name
                from   all_synonyms t1
                inner  join all_objects t2
                on     t2.owner = t1.table_owner
                and    t2.object_name = t1.table_name
                and    t2.generated = 'N' -- GPA 2016-12-19 #136334705
                where  t2.owner = b_schema
                and    t2.object_type not like '% BODY'
                and    t2.object_type != 'LOB'
                union
                -- bepaal dependencies gebaseerd op grants naar objecten
$if dbms_db_version.version >= 12 $then
                -- from Oracle 12 on there is a type column in all_tab_privs
                select t1.table_schema as owner
                      ,'GRANT' as object_type
                      ,t1.table_name as object_name
                      ,t1.table_schema as referenced_owner
                      ,t1.type as referenced_type
                      ,t1.table_name as referenced_name
                from   all_tab_privs t1
                where  t1.table_schema = b_schema
                and    t1.type not like '% BODY'
                and    t1.type != 'LOB'
$else
                select t1.table_schema as owner
                      ,'GRANT' as object_type
                      ,t1.table_name as object_name
                      ,t2.owner as referenced_owner
                      ,t2.object_type as referenced_type
                      ,t2.object_name as referenced_name
                from   all_tab_privs t1
                inner  join all_objects t2
                on     t2.owner = t1.table_schema
                and    t2.object_name = t1.table_name
                and    t2.generated = 'N' -- GPA 2016-12-19 #136334705
                where  t2.owner = b_schema
                and    t2.object_type not like '% BODY'
                and    t2.object_type != 'LOB'
$end
                union
                -- bepaal dependencies gebaseerd op prebuilt tables
                select t1.owner as object_owner
                      ,'MATERIALIZED VIEW' as object_type
                      ,t1.mview_name as object_name
                      ,t2.owner as referenced_owner
                      ,'TABLE' as referenced_type
                      ,t2.table_name as referenced_name
                from   all_mviews t1
                inner  join all_tables t2
                on     t2.owner = t1.owner
                and    t2.table_name = t1.mview_name
                where  t2.owner = b_schema
                and    t1.build_mode = 'PREBUILT'
                union
                -- bepaal dependencies gebaseerd op table comments
                select t1.owner as object_owner
                      ,'COMMENT' as object_type
                      ,t1.table_name as object_name
                      ,t1.owner as referenced_owner
                      ,t1.table_type as referenced_type
                      ,t1.table_name as referenced_name
                from   all_tab_comments t1
                       -- some SYS comments have no parent table/view
                       inner join all_objects t2
                       on t2.owner = t1.owner and t2.object_name = t1.table_name and t2.generated = 'N' -- GPA 2016-12-19 #136334705
                where  t1.owner = b_schema
                union
                -- bepaal dependencies gebaseerd op column comments
                select t1.owner as object_owner
                      ,'COMMENT' as object_type
                      ,t1.table_name as object_name
                      ,t1.owner as referenced_owner
                      ,t2.object_type as referenced_type
                      ,t1.table_name as referenced_name
                from   all_col_comments t1
                       -- some SYS comments have no parent table/view
                       inner join all_objects t2
                       on t2.owner = t1.owner and t2.object_name = t1.table_name and t2.generated = 'N' -- GPA 2016-12-19 #136334705
                where  t1.owner = b_schema
                union
                -- bepaal dependencies van tabellen/views met een type als attribuut
                select t2.owner as object_owner
                      ,t2.object_type as object_type
                      ,t2.object_name as object_name
                      ,t1.data_type_owner as referenced_owner
                      ,'TYPE' as referenced_type
                      ,t1.data_type as referenced_name
                from   all_tab_columns t1
                inner  join all_objects t2
                on     t2.owner = t1.owner
                and    t2.object_name = t1.table_name
                and    t2.generated = 'N' -- GPA 2016-12-19 #136334705
                where  t2.owner = b_schema
                and    t1.data_type_owner is not null
                union
                -- bepaal dependencies van constraints naar indexen
                select t1.owner as object_owner
                      ,case t1.constraint_type when 'R' then 'REF_CONSTRAINT' else 'CONSTRAINT' end as object_type
                      ,t1.constraint_name as object_name
                      ,t1.index_owner as referenced_owner
                      ,'INDEX' as referenced_type
                      ,t1.index_name as referenced_name
                from   all_constraints t1
                where  t1.owner = b_schema
                and    t1.index_owner is not null
                and    t1.index_name is not null
              ) t
              -- use subquery scalar cache
      where   ( select oracle_tools.pkg_ddl_util.is_exclude_name_expr(oracle_tools.t_schema_object.dict2metadata_object_type(t.object_type), t.object_name) from dual ) = 0
      and     ( select oracle_tools.pkg_ddl_util.is_exclude_name_expr(oracle_tools.t_schema_object.dict2metadata_object_type(t.referenced_type), t.referenced_name) from dual ) = 0
    ;

    l_object_tab        dbms_sql.varchar2_table; -- objects returned by p_cursor
    l_object_lookup_tab t_object_natural_tab; -- objects returned by p_cursor
    l_object_by_dep_tab dbms_sql.varchar2_table; -- hoe eerder, hoe minder dependencies

    -- l_object_dependency_tab(obj1)(obj2) = true means obj1 depends on obj2
    l_object_dependency_tab t_object_dependency_tab;

    l_owner all_dependencies.owner%type;
    l_type t_metadata_object_type;
    l_name t_object_name;
    l_referenced_owner all_dependencies.referenced_owner%type;
    l_referenced_type all_dependencies.referenced_type%type;
    l_referenced_name t_object_name;

    l_object t_object;
    l_object_dependency t_object;
    l_idx pls_integer;

    l_program constant varchar2(30 char) := 'SORT_OBJECTS_BY_DEPS';

    -- dbms_application_info stuff
    l_longops_rec t_longops_rec := longops_init(p_target_desc => l_program, p_units => 'objects');

    procedure add_dependencies
    is
      l_owner_tab dbms_sql.varchar2_table;
      l_type_tab dbms_sql.varchar2_table;
      l_name_tab dbms_sql.varchar2_table;
      l_referenced_owner_tab dbms_sql.varchar2_table;
      l_referenced_type_tab dbms_sql.varchar2_table;
      l_referenced_name_tab dbms_sql.varchar2_table;
    begin
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
      dbug.enter(g_package_prefix || l_program || '.ADD_DEPENDENCIES');
$end
      open c_dependencies(p_schema);
      fetch c_dependencies
      bulk collect
      into l_owner_tab
      ,    l_type_tab
      ,    l_name_tab
      ,    l_referenced_owner_tab
      ,    l_referenced_type_tab
      ,    l_referenced_name_tab;
      close c_dependencies;

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
      dbug.print(dbug."info", 'number of dependencies: %s', l_owner_tab.count);
$end

      if l_owner_tab.count > 0
      then
        for i_idx in l_owner_tab.first .. l_owner_tab.last
        loop
          l_owner := l_owner_tab(i_idx);
          l_type := l_type_tab(i_idx);
          l_name := l_name_tab(i_idx);
          l_referenced_owner := l_referenced_owner_tab(i_idx);
          l_referenced_type := l_referenced_type_tab(i_idx);
          l_referenced_name := l_referenced_name_tab(i_idx);

          -- sanity checks
          if l_owner is null
          then
            raise program_error;
          elsif l_type is null
          then
            raise program_error;
          elsif l_name is null
          then
            raise program_error;
          elsif l_referenced_owner is null
          then
            raise program_error;
          elsif l_referenced_type is null
          then
            raise program_error;
          elsif l_referenced_name is null
          then
            raise program_error;
          end if;

          l_object := get_object(l_owner, t_schema_object.dict2metadata_object_type(l_type), l_name);
          l_object_dependency := get_object(l_referenced_owner
                                           ,t_schema_object.dict2metadata_object_type(l_referenced_type)
                                           ,l_referenced_name);

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
          dbug.print(dbug."info", '%s depends on %s', l_object, l_object_dependency);
$end

          -- Zowel object als dependency moeten aangeleverd zijn.
          if not(l_object_lookup_tab.exists(l_object))
          then
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
            dbug.print(dbug."info", '%s not delivered', l_object);
$else            
            null;
$end
          elsif not(l_object_lookup_tab.exists(l_object_dependency))
          then
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
            dbug.print(dbug."info", '%s not delivered', l_object_dependency);
$else
            null;
$end
          else
            -- l_object hangt af van l_object_dependency.
            l_object_dependency_tab(l_object_dependency)(l_object) := null;
          end if;
        end loop;
      end if;

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
      dbug.leave;
    exception
      when program_error
      then
        dbug.print(dbug."error", 'l_owner: %s; l_type: %s; l_name: %s', l_owner, l_type, l_name);
        dbug.print(dbug."error", 'l_referenced_owner: %s; l_referenced_type: %s; l_referenced_name: %s', l_referenced_owner, l_referenced_type, l_referenced_name);
        dbug.leave_on_error;
        raise;
$end
    end add_dependencies;
  begin
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
    dbug.enter(g_package_prefix || l_program);
    dbug.print(dbug."input", 'p_schema: %s', p_schema);
$end

    -- cursor p_cursor is already open
    <<fetch_loop>>
    loop
      fetch p_cursor
        into l_owner
            ,l_type
            ,l_name;

      exit fetch_loop when p_cursor%notfound;

      l_object_tab(l_object_tab.count + 1) := get_object(l_owner, l_type, l_name);
      l_object_lookup_tab(l_object_tab(l_object_tab.count + 0)) := 1;
    end loop fetch_loop;

    close p_cursor;

    add_dependencies;

    begin
      tsort(l_object_dependency_tab, l_object_by_dep_tab);
    exception
      when e_not_a_directed_acyclic_graph
      then
        l_object_by_dep_tab := l_object_tab;
    end;

    if l_object_by_dep_tab.count > 0
    then
      declare
        l_str_tab                  dbms_sql.varchar2a;
        l_sort_objects_by_deps_rec t_sort_objects_by_deps_rec := t_sort_objects_by_deps_rec(null, null, null, null, 0);
      begin
        for i_idx in l_object_by_dep_tab.first .. l_object_by_dep_tab.last
        loop
          l_object := l_object_by_dep_tab(i_idx);

          pkg_str_util.split(p_str => l_object, p_delimiter => '.', p_str_tab => l_str_tab);

          l_sort_objects_by_deps_rec.object_schema := l_str_tab(1); -- trim('"' from l_str_tab(1));
          l_sort_objects_by_deps_rec.object_type := l_str_tab(2);
          l_sort_objects_by_deps_rec.object_name := l_str_tab(3); -- trim('"' from l_str_tab(3));
          l_sort_objects_by_deps_rec.dependency_list := null;
          -- GPA 2016-12-12 #135961579
          l_sort_objects_by_deps_rec.nr := l_sort_objects_by_deps_rec.nr + 1;

          pipe row(l_sort_objects_by_deps_rec);

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
          dbug.print
          ( dbug."info"
          , 'l_sort_objects_by_deps_rec; object_schema: %s; object_type: %s; object_name: %s; nr: %s'
          , l_sort_objects_by_deps_rec.object_schema
          , l_sort_objects_by_deps_rec.object_type
          , l_sort_objects_by_deps_rec.object_name
          , l_sort_objects_by_deps_rec.nr
          );
$end

          longops_show(l_longops_rec);
        end loop;
      end;
    end if;

    -- 100%
    longops_done(l_longops_rec);

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
    dbug.leave;
$end

    return; -- essential for a pipelined function

  exception
    when no_data_needed then
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
      dbug.leave_on_error;
$end
      null; -- not a real error, just a way to some cleanup

    when no_data_found -- verdwijnt anders in het niets omdat het een pipelined function betreft die al data ophaalt
     then
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
      dbug.leave_on_error;
$end
      raise program_error;

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
    when others then
      dbug.leave_on_error;
      raise;
$end
  end sort_objects_by_deps;

  procedure init_clob is
  begin
    dbms_lob.trim(g_clob, 0);
  end init_clob;

  procedure append_clob(p_line in varchar2) is
  begin
    dbms_lob.writeappend(lob_loc => g_clob, amount => length(p_line || chr(10)), buffer => p_line || chr(10));
  end append_clob;

  function get_clob return clob is
  begin
    return g_clob;
  end get_clob;

  procedure migrate_schema_ddl
  ( p_source in t_schema_ddl
  , p_target in t_schema_ddl
  , p_schema_ddl in out nocopy t_schema_ddl
  )
  is
    l_line_tab dbms_sql.varchar2a;

    l_source_text clob := null;
    l_target_text clob := null;

    l_source_line_tab dbms_sql.varchar2a;
    l_target_line_tab dbms_sql.varchar2a;

    procedure cleanup
    is
    begin
      null;
    end cleanup;
  begin
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
    dbug.enter(g_package_prefix || 'MIGRATE_SCHEMA_DDL');
$end

    pkg_str_util.text2clob(p_source.ddl_tab(1).text, l_source_text);
    pkg_str_util.text2clob(p_target.ddl_tab(1).text, l_target_text);

    pkg_str_util.split
    ( p_str => l_source_text
    , p_delimiter => chr(10)
    , p_str_tab => l_source_line_tab
    );
    pkg_str_util.split
    ( p_str => l_target_text
    , p_delimiter => chr(10)
    , p_str_tab => l_target_line_tab
    );
    compare_ddl
    ( p_source_line_tab => l_source_line_tab
    , p_target_line_tab => l_target_line_tab
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

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
    dbug.leave;
$end
  exception
    when others
    then
      cleanup;
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
      dbug.leave_on_error;
$end
      raise;
  end migrate_schema_ddl;

  function modify_ddl_text
  ( p_ddl_text in clob
  , p_schema in t_schema_nn
  , p_new_schema in t_schema
  , p_object_type in t_metadata_object_type
  )
  return clob
  is
    l_ddl_text clob := null;
  begin
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
    dbug.enter(g_package_prefix || 'MODIFY_DDL_TEXT');
    dbug.print
    ( dbug."input"
    , 'p_schema: %s; p_new_schema: %s; p_object_type: %s; p_ddl_text: %s'
    , p_schema
    , p_new_schema
    , p_object_type
    , substr(p_ddl_text, 1, 255)
    );
$end

    l_ddl_text := p_ddl_text;

    /*
       ON "<owner>"."<table>" must be replaced by ON "EMPTY"."<table>"

       CREATE OR REPLACE EDITIONABLE TRIGGER "EMPTY"."<trigger>"
       BEFORE INSERT OR DELETE OR UPDATE ON "<owner>"."<table>"
       REFERENCING FOR EACH ROW
    */
    if p_schema <> p_new_schema
    then
      l_ddl_text :=
        replace
        ( replace
          ( replace
            ( l_ddl_text
            , '"' || p_schema || '"'
            , '"' || p_new_schema || '"'
            )
          , ' ' || p_schema || '.'
          , ' ' || p_new_schema || '.'
          )
        , ' ' || lower(p_schema) || '.'
        , ' ' || lower(p_new_schema) || '.'
        )
      ;
    end if;

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
    dbug.print(dbug."output", 'return: %s', substr(l_ddl_text, 1, 255));
    dbug.leave;
$end

    return l_ddl_text;

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
  exception
    when others
    then
      dbug.leave_on_error;
      raise;
$end
  end modify_ddl_text;

$if cfg_pkg.c_testing $then

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
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
    dbug.enter(g_package_prefix || 'SKIP_WS_LINES_AROUND');
    dbug.print(dbug."input", 'p_text_tab.count: %s; p_text_tab.first: %s; p_text_tab.last: %s', p_text_tab.count, p_text_tab.first, p_text_tab.last);
$end

    p_first := p_text_tab.first;
    p_last := p_text_tab.last;

    loop
      if p_first <= p_last
      then
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
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

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
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
  (
    p_owner in varchar2
   ,p_object_type in varchar2
   ,p_object_name in varchar2
   ,p_line_tab out nocopy dbms_sql.varchar2a
   ,p_first out pls_integer
   ,p_last out pls_integer
  )
  is
    function get_ddl
    return clob
    is
      l_metadata_object_type constant t_metadata_object_type :=
        t_schema_object.dict2metadata_object_type
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
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
    dbug.enter(g_package_prefix || 'GET_SOURCE');
    dbug.print(dbug."input", 'p_owner: %s; p_object_type: %s; p_object_name: %s', p_owner, p_object_type, p_object_name);
$end

    -- set transformation parameters for the dbms_metadata.get_xxx functions
    md_set_transform_param;

    pkg_str_util.split
    ( p_str => get_ddl
    , p_delimiter => chr(10)
    , p_str_tab => p_line_tab
    );

    dbms_metadata.set_transform_param(dbms_metadata.session_transform, 'DEFAULT', true); -- back to the defaults

    skip_ws_lines_around(p_line_tab, p_first, p_last);

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
    dbug.print(dbug."output", 'p_line_tab.count: %s; p_first: %s; p_last: %s', p_line_tab.count, p_first, p_last);
    dbug.leave;
  exception
    when others
    then
      dbug.leave_on_error;
      raise;
$end
  end get_source;

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
    l_idx1 pls_integer := p_first1;
    l_idx2 pls_integer := p_first2;
    l_result boolean := true;
  begin
$if cfg_pkg.c_debugging $then
    dbug.enter(g_package_prefix || 'EQ');
    dbug.print(dbug."input", 'p_line1_tab.count: %s; p_first1: %s; p_last1: %s', p_line1_tab.count, p_first1, p_last1);
    dbug.print(dbug."input", 'p_line2_tab.count: %s; p_first2: %s; p_last2: %s', p_line2_tab.count, p_first2, p_last2);
$end

    if (p_first1 is null and p_line1_tab.first is null and p_line1_tab.last is null and p_last1 is null) or
       (p_first1 >= p_line1_tab.first and p_line1_tab.last >= p_last1 and p_first1 <= p_last1)
    then
      null;
    else
      raise_application_error
      ( -20000
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
      ( -20000
      , 'p_first2: ' || p_first2 || '; p_line2_tab.first: ' || p_line2_tab.first ||
        '; p_last2: ' || p_last2 || '; p_line2_tab.last: ' || p_line2_tab.last
      );
    end if;

    <<line_loop>>
    while l_result and (l_idx1 <= p_last1 or l_idx2 <= p_last2)
    loop
      if (l_idx1 <= p_last1 and l_idx2 <= p_last2) and
         ( ( ( not(p_line1_tab.exists(l_idx1)) or p_line1_tab(l_idx1) is null ) and
             ( not(p_line2_tab.exists(l_idx2)) or p_line2_tab(l_idx2) is null ) ) or
           ( p_line1_tab.exists(l_idx1) and
             p_line2_tab.exists(l_idx2) and
             p_line1_tab(l_idx1) = p_line2_tab(l_idx2) ) )
      then
        null; -- lines equal
      else
        -- one line does not exist or the lines are not equal
        l_result := false;
$if cfg_pkg.c_debugging $then
        dbug.print
        ( dbug."warning"
        , 'difference found:'
        );
        dbug.print
        ( dbug."warning"
        , 'p_line1_tab(%s): "%s"'
        , l_idx1
        , case when p_line1_tab.exists(l_idx1) then p_line1_tab(l_idx1) else '<NOT FOUND>' end
        );
        dbug.print
        ( dbug."warning"
        , 'p_line2_tab(%s): "%s"'
        , l_idx2
        , case when p_line2_tab.exists(l_idx2) then p_line2_tab(l_idx2) else '<NOT FOUND>' end
        );
$end
      end if;
      l_idx1 := l_idx1 + 1;
      l_idx2 := l_idx2 + 1;
    end loop line_loop;

$if cfg_pkg.c_debugging $then
    dbug.print(dbug."output", 'return: %s', l_result);
    dbug.leave;
$end

   return l_result;

$if cfg_pkg.c_debugging $then
  exception
    when others
    then
      dbug.leave_on_error;
      raise;
$end
  end eq;

-- $if cfg_pkg.c_testing $then

  -- test functions
  procedure ut_setup
  is
    l_found pls_integer;
    l_cursor sys_refcursor;
    l_loopback_global_name global_name.global_name%type;
  begin
    select  t.table_owner
    into    g_owner_utplsql
    from    all_synonyms t
    where   t.table_name = 'UT';

    begin
      select  1
      into    l_found
      from    all_users
      where   username = g_empty
      ;
    exception
      when no_data_found
      then raise_application_error(-20000, 'User EMPTY must exist', true);
    end;

    if get_db_link(g_empty) is null
    then
      raise_application_error(-20000, 'Database link EMPTY must exist');
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
        raise_application_error(-20000, 'Private database link LOOPBACK should point to this schema and database.', true);
    end;
  end ut_setup;

  procedure ut_teardown
  is
  begin
    null;
  end ut_teardown;

  procedure ut_display_ddl_schema
  is
    l_line1_tab    dbms_sql.varchar2a;
    l_clob1        clob := null;
    l_first1       pls_integer := null;
    l_last1        pls_integer := null;
    l_line2_tab    dbms_sql.varchar2a;
    l_clob2        clob := null;
    l_first2       pls_integer := null;
    l_last2        pls_integer := null;

    l_schema_ddl_tab t_schema_ddl_tab;

    l_schema t_schema;
    l_object_names_include t_numeric_boolean;
    l_object_names t_object_names;

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
               ( b_schema
               , b_new_schema
               , b_sort_objects_by_deps
               , b_object_type
               , b_object_names
               , b_object_names_include
               , b_network_link
               , b_grantor_is_schema
               )
             ) t
      ;

    -- dbms_application_info stuff
    l_program constant varchar2(61 char) := 'UT_DISPLAY_DDL_SCHEMA';
    l_longops_rec t_longops_rec;

    c_no_exception_raised constant integer := -20001;

    procedure chk
    ( p_description in varchar2
    , p_sqlcode_expected in integer
    , p_schema in varchar2 default user
    , p_new_schema in varchar2 default null
    , p_sort_objects_by_deps in number default 0
    , p_object_type in varchar2 default null
    , p_object_names in varchar2 default null
    , p_object_names_include in number default null
    , p_network_link in varchar2 default null
    , p_grantor_is_schema in number default 0
    )
    is
    begin
$if cfg_pkg.c_debugging $then
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
      fetch c_display_ddl_schema bulk collect into l_schema_ddl_tab;
      close c_display_ddl_schema;

      raise_application_error(c_no_exception_raised, 'OK');
    exception
      when others
      then
        if c_display_ddl_schema%isopen then close c_display_ddl_schema; end if;
$if cfg_pkg.c_debugging $then
        dbug.leave;
$end        
        ut.expect(sqlcode, l_program || '#' || p_description).to_equal(p_sqlcode_expected);
    end chk;

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
$if cfg_pkg.c_debugging $then
    dbug.enter(g_package_prefix || l_program);
$end

    chk
    ( p_description => 'Schema is empty.'
    , p_sqlcode_expected => -6502
    , p_schema => null
    );

    chk
    ( 'Invalid schema indien p_network_link leeg is en p_schema geen correct schema.'
    , p_sqlcode_expected => -44001
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
                                 when r.column_value is null then -6502 -- VALUE_ERROR want NATURALN staat null niet toe
                                 when r.column_value in (0, 1) then c_object_names_wrong 
                                 when r.column_value < 0 then -6502 -- VALUE_ERROR want NATURALN staat negatieve getallen niet toe
                                 else c_numeric_boolean_wrong
                               end
      , p_sort_objects_by_deps => r.column_value
      , p_object_names => 'ABC'
      );
    end loop;

    chk
    ( p_description => 'Indien p_object_names niet leeg is en p_object_names_include leeg.'
    , p_sqlcode_expected => c_object_names_wrong
    , p_object_names => 'ABC'
    );

    chk
    ( p_description => 'Indien p_object_names niet leeg is en p_object_names_include niet leeg en niet in (0, 1).'
    , p_sqlcode_expected => c_numeric_boolean_wrong
    , p_object_names => 'ABC'
    , p_object_names_include => 2
    );

    chk
    ( p_description => 'Indien p_object_names niet leeg is en p_object_names_include niet leeg en niet in (0, 1).'
    , p_sqlcode_expected => -6502 -- VALUE_ERROR want NATURAL staat alleen null, 0 of positieve gehele getallen toe.
    , p_object_names => 'ABC'
    , p_object_names_include => -1
    );

    chk
    ( p_description => 'Indien p_object_names leeg is en p_object_names_include niet leeg.'
    , p_sqlcode_expected => c_object_names_wrong
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
                                 else c_numeric_boolean_wrong
                               end
      , p_grantor_is_schema => r.column_value
      , p_object_names => 'ABC'
      , p_object_names_include => 1
      );
    end loop;

    -- The PKG_DDL_UTIL PACKAGE_SPEC must be created first for an empty schema
    begin
      if l_clob1 is not null
      then
        dbms_lob.trim(l_clob1, 0);
      end if;
      for r in
      ( select u.text
        from   table
               ( oracle_tools.pkg_ddl_util.display_ddl_schema
                 ( g_owner
                 , null
                 , 1
                 , null
                 , g_package
                 , 1
                 , null
                 , 0
                 )
               ) t
        ,      table(t.ddl_tab) u
        where  t.obj.object_type() <> 'OBJECT_GRANT'
      )
      loop
        pkg_str_util.text2clob(r.text, l_clob1, true);
      end loop;
      pkg_str_util.split(p_str => l_clob1, p_str_tab => l_line1_tab, p_delimiter => chr(10));

      if l_clob2 is not null
      then
        dbms_lob.trim(l_clob2, 0);
      end if;
      for r in
      ( select u.text
        from   table
               ( oracle_tools.pkg_ddl_util.display_ddl_schema
                 ( g_owner
                 , g_empty
                 , 1
                 , null
                 , g_package
                 , 1
                 , null
                 , 0
                 )
               ) t
        ,      table(t.ddl_tab) u
        where  t.obj.object_type() <> 'OBJECT_GRANT'
      )
      loop
        pkg_str_util.text2clob(r.text, l_clob2, true);
      end loop;
      pkg_str_util.split(p_str => l_clob2, p_str_tab => l_line2_tab, p_delimiter => chr(10));

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
          begin
            l_line1_tab(i_line_idx) := modify_ddl_text(p_ddl_text => l_line1_tab(i_line_idx), p_schema => g_owner, p_new_schema => g_empty);

            ut.expect(l_line1_tab(i_line_idx), l_program || '#' || g_owner || '#' || g_package || '#line ' || i_line_idx).to_equal(l_line2_tab(i_line_idx));
$if cfg_pkg.c_debugging $then
          exception
            when others
            then
              dbug.print(dbug."info", 'l_line1_tab(%s): %s', i_line_idx, l_line1_tab(i_line_idx));
              dbug.print(dbug."info", 'l_line2_tab(%s): %s', i_line_idx, l_line2_tab(i_line_idx));
              raise;
$end
          end;
        elsif l_line1_tab.exists(i_line_idx)
        then
          ut.expect(l_line1_tab(i_line_idx), l_program || '#' || g_owner || '#' || g_package || '#line ' || i_line_idx).to_be_null();
        elsif l_line2_tab.exists(i_line_idx)
        then
          ut.expect(l_line2_tab(i_line_idx), l_program || '#' || g_owner || '#' || g_package || '#line ' || i_line_idx).to_be_null();
        end if;
      end loop;
    end;

    -- Check objects in this schema
    for r in (select t.owner
                    ,case t.object_type when 'TABLE' then 'COMMENT' else t.object_type end as object_type
                    ,t.object_name
                    ,count(*) over () as total
              from   ( select  t.*
                       ,       row_number() over (partition by t.owner, t.object_type order by t.object_name) as orderseq
                       from    all_objects t
                       where   t.generated = 'N' /* GPA 2016-12-19 #136334705 */
                     ) t
              where  t.owner in (g_owner, g_owner_utplsql)
              and    t.orderseq <= 3 -- reduce the time
              and    (oracle_tools.t_schema_object.is_a_repeatable(t.object_type) = 1 or /* for comments */ t.object_type = 'TABLE')
              and    t.object_type not in ('EVALUATION CONTEXT','JOB','PROGRAM','RULE','RULE SET','JAVA CLASS','JAVA SOURCE')
              and    ( t.owner = g_owner or
                       t.object_type not like '%BODY' -- CREATE ANY PROCEDURE system privilege needed to lookup
                     )
              and    ( t.object_type <> 'TRIGGER' or
                       (t.owner, t.object_name) in (select owner, trigger_name from all_triggers where base_object_type in ('TABLE', 'VIEW'))
                     )
              and    ( select  oracle_tools.pkg_ddl_util.is_exclude_name_expr
                               ( oracle_tools.t_schema_object.dict2metadata_object_type(t.object_type)
                               , t.object_name
                               )
                       from    dual
                     ) = 0
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
      if l_longops_rec.totalwork is null
      then
        l_longops_rec := longops_init(p_op_name => 'Test', p_units => 'objects', p_target_desc => l_program, p_totalwork => r.total);
      end if;

$if cfg_pkg.c_debugging $then
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

        for r_text in
        ( select t.obj.object_schema() as object_schema
          ,      t.obj.object_name() as object_name
          ,      t.obj.object_type() as object_type
          ,      u.text
          from   table
                 ( oracle_tools.pkg_ddl_util.display_ddl_schema
                   ( r.owner
                   , null
                   , 0
                   , oracle_tools.t_schema_object.dict2metadata_object_type(r.object_type)
                   , r.object_name
                   , 1
                   , case when i_try = 2 then g_loopback end
                   , 0
                   )
                 ) t
          ,      table(t.ddl_tab) u
          where  u.ddl#() = 1
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
$if cfg_pkg.c_debugging $then
          dbug.print
          ( dbug."info"
          , 'r_text.object_schema: %s; r_text.object_type: %s; r_text.object_name: %s'
          , r_text.object_schema
          , r_text.object_type
          , r_text.object_name
          );
$end

          pkg_str_util.text2clob(r_text.text, l_clob1, true);
        end loop;

        -- Copy all lines from l_clob1 to l_line1_tab but skip empty lines for comments.
        -- So we use an intermediary l_line2_tab first.
        pkg_str_util.split(p_str => l_clob1, p_str_tab => l_line2_tab, p_delimiter => chr(10));
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

        ut.expect(eq(l_line1_tab, l_first1, l_last1, l_line2_tab, l_first2, l_last2), l_program || '#' || r.owner || '#' || r.object_type || '#' || r.object_name || '#' || i_try || '#eq').to_be_true();
      end loop try_loop;

      longops_show(l_longops_rec);
    end loop;

    cleanup;

$if cfg_pkg.c_debugging $then
    dbug.leave;
$end
  exception
    when others
    then
      cleanup;
$if cfg_pkg.c_debugging $then
      dbug.leave_on_error;
$end
      raise;
  end ut_display_ddl_schema;

  procedure ut_display_ddl_schema_diff
  is
    l_line1_tab    dbms_sql.varchar2a;
    l_clob1        clob := null;
    l_first1       pls_integer := null;
    l_last1        pls_integer := null;
    l_line2_tab    dbms_sql.varchar2a;
    l_first2       pls_integer := null;
    l_last2        pls_integer := null;

    l_schema_ddl_tab t_schema_ddl_tab;

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
               ( b_object_type
               , b_object_names
               , b_object_names_include
               , b_schema_source
               , b_schema_target
               , b_network_link_source
               , b_network_link_target
               , b_skip_repeatables
               )
             ) t
      ;

    -- dbms_application_info stuff
    l_program constant varchar2(61 char) := 'UT_DISPLAY_DDL_SCHEMA_DIFF';
    l_longops_rec t_longops_rec;

    c_no_exception_raised constant integer := -20001;

    procedure chk
    ( p_description in varchar2
    , p_sqlcode_expected in integer
    , p_object_type in varchar2 default null
    , p_object_names in varchar2 default null
    , p_object_names_include in number default null
    , p_schema_source in varchar2 default user
    , p_schema_target in varchar2 default user
    , p_network_link_source in varchar2 default null
    , p_network_link_target in varchar2 default null
    , p_skip_repeatables in number default 1
    )
    is
    begin
$if cfg_pkg.c_debugging $then
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
      fetch c_display_ddl_schema_diff bulk collect into l_schema_ddl_tab;
      close c_display_ddl_schema_diff;

      raise_application_error(c_no_exception_raised, 'OK');
    exception
      when others
      then
        if c_display_ddl_schema_diff%isopen then close c_display_ddl_schema_diff; end if;
$if cfg_pkg.c_debugging $then
        dbug.leave;
$end        
        ut.expect(sqlcode, l_program || '#' || p_description).to_equal(p_sqlcode_expected);
    end chk;

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
$if cfg_pkg.c_debugging $then
    dbug.enter(g_package_prefix || l_program);
$end

    chk
    ( p_description => 'Indien p_object_names niet leeg is en p_object_names_include leeg.'
    , p_sqlcode_expected => c_object_names_wrong
    , p_object_names => 'ABC'
    );

    chk
    ( p_description => 'Indien p_object_names niet leeg is en p_object_names_include niet leeg en niet in (0, 1).'
    , p_sqlcode_expected => c_numeric_boolean_wrong
    , p_object_names => 'ABC'
    , p_object_names_include => 2
    );

    chk
    ( p_description => 'Indien p_object_names niet leeg is en p_object_names_include niet leeg en niet in (0, 1).'
    , p_sqlcode_expected => -6502 -- VALUE_ERROR vanwege NATURAL datatype
    , p_object_names => 'ABC'
    , p_object_names_include => -1
    );

    chk
    ( p_description => 'Indien p_object_names leeg is en p_object_names_include niet leeg.'
    , p_sqlcode_expected => c_object_names_wrong
    , p_object_names_include => 1
    );

    chk
    ( p_description => 'Indien p_schema_source leeg is en p_network_link_source niet leeg.'
    , p_sqlcode_expected => c_schema_wrong
    , p_schema_source => null
    , p_network_link_source => g_dbname
    );

    chk
    ( p_description => 'Indien p_schema_target leeg is.'
    , p_sqlcode_expected => -6502 -- VALUE_ERROR vanwege NATURAL datatype
    , p_schema_target => null
    );

    chk
    ( p_description => 'Indien p_network_link_source leeg is, p_schema_source niet leeg en niet bestaand.'
    , p_sqlcode_expected => -44001
    , p_schema_source => 'ABC'
    );

    chk
    ( p_description => 'Indien p_network_link_target leeg is, p_schema_target niet leeg en niet bestaand.'
    , p_sqlcode_expected => -44001
    , p_schema_target => 'ABC'
    );

    chk
    ( p_description => 'source en target zijn gelijk.'
    , p_sqlcode_expected => c_source_and_target_equal
    , p_schema_source => user
    , p_schema_target => user
    );

    chk
    ( p_description => 'p_network_link_source niet leeg en onbekend.'
    , p_sqlcode_expected => c_database_link_does_not_exist
    , p_network_link_source => 'ABC'
    );

    chk
    ( p_description => 'p_network_link_target niet leeg en onbekend.'
    , p_sqlcode_expected => c_database_link_does_not_exist
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
                                when r.column_value is null then -6502 -- VALUE_ERROR want NATURALN staat null niet toe
                                when r.column_value in (0, 1) then c_no_exception_raised
                                when r.column_value < 0 then -6502 -- VALUE_ERROR want NATURALN staat negatieve getallen niet toe
                                else c_numeric_boolean_wrong
                              end
      , p_skip_repeatables => r.column_value
      , p_object_names => 'ABC'
      , p_object_names_include => 1
      , p_schema_source => null
      );
    end loop;

    chk
    ( p_description => 'Running against empty source schema should work'
    , p_sqlcode_expected => c_no_exception_raised
    , p_schema_target => g_empty
    , p_schema_source => null
    );

    -- Check this schema
    for r in (select t.owner
                    ,case t.object_type when 'TABLE' then 'COMMENT' else t.object_type end as object_type
                    ,t.object_name
                    ,count(*) over () as total
              from   ( select  t.*
                       ,       row_number() over (partition by t.owner, t.object_type order by t.object_name) as orderseq
                       from    all_objects t
                       where   t.generated = 'N' /* GPA 2016-12-19 #136334705 */
                     ) t
              where  t.owner in (g_owner, g_owner_utplsql)
              and    t.orderseq <= 3
              and    (oracle_tools.t_schema_object.is_a_repeatable(t.object_type) = 1 or /* for comments */ t.object_type = 'TABLE')
              and    t.object_type not in ('EVALUATION CONTEXT','JOB','PROGRAM','RULE','RULE SET','JAVA CLASS','JAVA SOURCE')
              and    ( t.owner = g_owner or
                       t.object_type not like '%BODY' -- CREATE ANY PROCEDURE system privilege needed to lookup
                     )
              and    ( t.object_type <> 'TRIGGER' or
                       (t.owner, t.object_name) in (select owner, trigger_name from all_triggers where base_object_type in ('TABLE', 'VIEW'))
                     )
              and    ( select  oracle_tools.pkg_ddl_util.is_exclude_name_expr
                               ( oracle_tools.t_schema_object.dict2metadata_object_type(t.object_type)
                               , t.object_name
                               )
                       from    dual
                     ) = 0
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
        l_longops_rec := longops_init(p_op_name => 'Test', p_units => 'objects', p_target_desc => l_program, p_totalwork => r.total);
      end if;

$if cfg_pkg.c_debugging $then
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
        for r_text in
        ( select t.obj.object_schema() as object_schema
          ,      t.obj.object_type() as object_type
          ,      t.obj.object_name() as object_name
          ,      u.text
$if dbms_db_version.ver_le_10 $then
          from   table(oracle_tools.pkg_ddl_util.display_ddl_schema_diff( oracle_tools.t_schema_object.dict2metadata_object_type(r.object_type)
                                                                         , r.object_name
                                                                         , 1
                                                                         , r.owner
                                                                         , g_empty
                                                                         , case when i_try = 2 then g_loopback end
                                                                         , case when i_try = 2 then g_loopback end
                                                                         , 0)) t
$else
          from   table(oracle_tools.pkg_ddl_util.display_ddl_schema_diff( p_object_type => oracle_tools.t_schema_object.dict2metadata_object_type(r.object_type)
                                                                         , p_object_names => r.object_name
                                                                         , p_object_names_include => 1
                                                                         , p_schema_source => r.owner
                                                                         , p_schema_target => g_empty
                                                                         , p_network_link_source => case when i_try = 2 then g_loopback end
                                                                         , p_network_link_target => case when i_try = 2 then g_loopback end
                                                                         , p_skip_repeatables => 0)) t
$end
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
$if cfg_pkg.c_debugging $then
          dbug.print
          ( dbug."info"
          , 'r_text.object_schema: %s; r_text.object_type: %s; r_text.object_name: %s'
          , r_text.object_schema
          , r_text.object_type
          , r_text.object_name
          );
$end
          pkg_str_util.text2clob(r_text.text, l_clob1, true);
        end loop;

        -- Copy all lines from l_clob1 to l_line1_tab but skip empty lines for comments.
        -- So we use an intermediary l_line2_tab first.
        pkg_str_util.split(p_str => l_clob1, p_str_tab => l_line2_tab, p_delimiter => chr(10));
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
            l_line2_tab(i_line_idx) :=
              modify_ddl_text
              ( p_ddl_text => l_line2_tab(i_line_idx)
              , p_schema => r.owner
              , p_new_schema => g_empty
              , p_object_type => r.object_type
              );
          end loop;
        end if;

        begin
          ut.expect(eq(l_line1_tab, l_first1, l_last1, l_line2_tab, l_first2, l_last2), l_program || '#' || r.owner || '#' || r.object_type || '#' || r.object_name || '#eq').to_be_true();
$if cfg_pkg.c_debugging $then
        exception
          when others
          then
            dbug.print(dbug."warning", 'l_line1_tab');
            print(l_line1_tab, l_first1, l_last1);
            dbug.print(dbug."warning", 'l_line2_tab');
            print(l_line2_tab, l_first2, l_last2);
            raise;
$end
        end;
      end loop try_loop;

      longops_show(l_longops_rec);
    end loop;

$if cfg_pkg.c_debugging $then
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
  begin
    null;
  end ut_object_type_order;

  procedure ut_dict2metadata_object_type
  is
    l_metadata_object_type t_metadata_object_type;

    l_program constant varchar2(61 char) := 'UT_DICT2METADATA_OBJECT_TYPE';
  begin
$if cfg_pkg.c_debugging $then
    dbug.enter(g_package_prefix || l_program);
$end

    -- null as parameter
    ut.expect(t_schema_object.dict2metadata_object_type(to_char(null)), l_program || '#null').to_be_null();

    -- ABC XYZ as parameter
    ut.expect(t_schema_object.dict2metadata_object_type('ABC XYZ'), l_program || '#ABC XYZ').to_equal('ABC_XYZ');

    for r in (select distinct t.object_type from all_objects t where t.generated = 'N' /* GPA 2016-12-19 #136334705 */ order by t.object_type)
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

      ut.expect(t_schema_object.dict2metadata_object_type(r.object_type), l_program || '#' || r.object_type).to_equal(l_metadata_object_type);
    end loop;

$if cfg_pkg.c_debugging $then
    dbug.leave;
$end
  end ut_dict2metadata_object_type;

  procedure ut_is_a_repeatable
  is
    l_program constant varchar2(61 char) := 'UT_IS_A_REPEATABLE';
    l_object_type_tab t_text_tab;
  begin
$if cfg_pkg.c_debugging $then
    dbug.enter(g_package_prefix || l_program);
$end

    -- null as parameter
    ut.expect(t_schema_object.is_a_repeatable(to_char(null)), l_program || '#null').to_be_null();

    -- ABC XYZ as parameter
    ut.expect(t_schema_object.is_a_repeatable('ABC XYZ'), l_program || '#ABC XYZ').to_be_null();

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
        ut.expect( t_schema_object.is_a_repeatable(l_object_type_tab(i_idx))
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

$if cfg_pkg.c_debugging $then
    dbug.leave;
  exception
    when others
    then
      dbug.leave_on_error;
      raise;
$end
  end ut_is_a_repeatable;

  procedure ut_get_schema_object
  is
    l_schema_object_tab0 t_schema_object_tab;
    l_schema_object_tab1 t_schema_object_tab;
    l_schema t_schema;

    l_object_info_tab t_object_info_tab;

    l_object_names_include t_numeric_boolean;
    l_object_names t_object_names;

    l_count pls_integer;

    l_program constant varchar2(61 char) := 'UT_GET_SCHEMA_OBJECT';
  begin
$if cfg_pkg.c_debugging $then
    dbug.enter(g_package_prefix || l_program);
$end

$if pkg_ddl_util.c_get_queue_ddl $then

    -- check queue tables
    for r in
    ( select  q.owner
      ,       q.queue_table
      from    all_queue_tables q
      where   rownum = 1
    )
    loop
      for i_test in 1..2
      loop
        select  count(*)
        into    l_count
        from    table
                ( oracle_tools.pkg_ddl_util.get_schema_object
                  ( r.owner
                  , case i_test when 1 then null else 'AQ_QUEUE_TABLE' end
                  , r.queue_table
                  , 1
                  )
                ) t
        where   t.object_type() in ('TABLE', 'AQ_QUEUE_TABLE');

        ut.expect(l_count, l_program || '#queue table count#' || r.owner || '.' || r.queue_table || '#' || i_test).to_equal(1);
      end loop;
    end loop;

$else

    /* ORA-00904: "KU$"."SCHEMA_OBJ"."TYPE": invalid identifier */

$end

    -- check materialized views, prebuilt or not
    for r in
    ( select  min(m.owner||'.'||m.mview_name) as mview_name
      ,       m.build_mode
      from    all_mviews m
      group by
              m.build_mode
    )
    loop
      for i_test in 1..3
      loop
        select  count(*)
        into    l_count
        from    table
                ( oracle_tools.pkg_ddl_util.get_schema_object
                  ( substr(r.mview_name, 1, instr(r.mview_name, '.')-1)
                  , case i_test when 1 then null when 2 then 'MATERIALIZED_VIEW' when 3 then 'TABLE' end
                  , substr(r.mview_name, instr(r.mview_name, '.')+1)
                  , 1
                  )
                ) t
        where   t.object_type() in ('TABLE', 'MATERIALIZED_VIEW');

        ut.expect
        ( l_count
        , l_program || '#mview count#' || r.mview_name || '#' || r.build_mode || '#' || i_test
        ).to_equal( case
                      when r.build_mode = 'PREBUILT'
                      then
                        case i_test
                          when 1
                          then 2 -- table and mv returned
                          else 1 -- else table or mv
                        end
                      else
                        case i_test
                          when 3
                          then 0 -- nothing returned
                          else 1 -- mv returned
                        end
                    end
                  );
      end loop;
    end loop;

    -- check synonyms, indexes and triggers based on object from another schema
    for r in
    ( select  min(s.owner||'.'||s.synonym_name) as fq_object_name
      ,       'SYNONYM' as object_type
      from    all_synonyms s
      where   s.owner <> s.table_owner
      and     s.table_name is not null
      union
      select  min(t.owner||'.'||t.trigger_name) as fq_object_name
      ,       'TRIGGER' as object_type
      from    all_triggers t
      where   t.owner <> t.table_owner
      and     t.table_name is not null
      union
      select  min(i.owner||'.'||i.index_name) as fq_object_name
      ,       'INDEX' as object_type
      from    all_indexes i
      where   i.owner <> i.table_owner
      and     i.table_name is not null
    )
    loop
      if r.fq_object_name is not null
      then
        select  count(*)
        into    l_count
        from    table
                ( oracle_tools.pkg_ddl_util.get_schema_object
                  ( substr(r.fq_object_name, 1, instr(r.fq_object_name, '.')-1)
                  , r.object_type
                  , substr(r.fq_object_name, instr(r.fq_object_name, '.')+1)
                  , 1
                  )
                ) t;

        ut.expect
        ( l_count
        , l_program || '#object based on another schema count#' || r.fq_object_name
        ).to_equal(1);
      end if;
    end loop;

$if cfg_pkg.c_debugging $then
    dbug.leave;
  exception
    when others
    then
      dbug.leave_on_error;
      raise;
$end
  end ut_get_schema_object;

  procedure ut_synchronize
  is
    l_drop_schema_ddl_tab t_schema_ddl_tab;
    l_diff_schema_ddl_tab t_schema_ddl_tab;

    l_schema t_schema;
    l_network_link_source t_network_link;
    l_network_link_target constant t_network_link := g_empty; -- in order to have the same privileges

    cursor c_display_ddl_schema_diff
    ( b_object_type in t_metadata_object_type default null
    , b_object_names in t_object_names default null
    , b_object_names_include in t_numeric_boolean default null
    , b_schema_source in t_schema default user
    , b_schema_target in t_schema default user
    , b_network_link_source in t_network_link default null
    , b_network_link_target in t_network_link default null
    , b_skip_repeatables in t_numeric_boolean default 1
    )
    is
      select value(t)
      from   table
             ( oracle_tools.pkg_ddl_util.display_ddl_schema_diff
               ( b_object_type
               , b_object_names
               , b_object_names_include
               , b_schema_source
               , b_schema_target
               , b_network_link_source
               , b_network_link_target
               , b_skip_repeatables
               )
             ) t
      ,      table(t.ddl_tab) u
      where  u.verb() != '--' -- no comments
      ;

    l_count pls_integer;

    l_program constant varchar2(61) := g_package || '.UT_SYNCHRONIZE';

    procedure cleanup is
    begin
$if cfg_pkg.c_debugging $then
      dbug.enter(l_program||'.CLEANUP');
$end

      uninstall
      ( p_schema_target => g_empty
      , p_network_link_target => l_network_link_target
      );

      -- drop objects which are excluded in get_schema_object()
      l_drop_schema_ddl_tab := t_schema_ddl_tab();
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
                  ,       t_schema_object.dict2metadata_object_type(o.object_type) as object_type
                  ,       o.object_name
                  from    all_objects o
                  where   o.owner = g_empty
                ) o
        where   (select oracle_tools.pkg_ddl_util.is_dependent_object_type(p_object_type => o.object_type) from dual) = 0
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

$if cfg_pkg.c_debugging $then
      dbug.leave;
$end
    exception
      when others then
        null;
$if cfg_pkg.c_debugging $then
        dbug.leave;
$end
    end cleanup;
  begin
$if cfg_pkg.c_debugging $then
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
          l_network_link_source := g_loopback; -- this is l_schema

      end case;

      /* step 1 */
      begin
        cleanup; -- empty EMPTY

        select  count(*)
        into    l_count
        from    all_objects t
        where   t.owner = g_empty
        and     pkg_ddl_util.is_exclude_name_expr(oracle_tools.t_schema_object.dict2metadata_object_type(t.object_type), t.object_name) = 0;

        ut.expect(l_count, l_program || '#cleanup' || '#' || i_try).to_equal(0);
$if cfg_pkg.c_debugging $then        
      exception
        when others
        then
          for r in
          ( select  o.object_type
            ,       o.object_name
            from    all_objects o
            where   o.owner = g_empty
            order by
                    o.object_type
            ,       o.object_name
          )
          loop
            dbug.print(dbug."warning", 'object_type: %s; object_name: %s', r.object_type, r.object_name);
          end loop;
          raise;
$end          
      end;

      /* step 2 */
      select  count(*)
      into    l_count
      from    all_synonyms t
      where   t.owner = 'PUBLIC'
      and     t.table_owner = l_schema;

      ut.expect(l_count, l_program || '#no public synonyms' || '#' || i_try).to_equal(0);

      /* step 3 */
      synchronize
      ( p_object_type => null
      , p_object_names => null
      , p_object_names_include => null
      , p_schema_source => l_schema
      , p_schema_target => g_empty
      , p_network_link_source => l_network_link_source
      , p_network_link_target => l_network_link_target
      );

      /* step 4 */

      -- Bereken de verschillen, i.e. de CREATE statements.
      -- Gebruik database links om aan te loggen met de juiste gebruiker.
      open c_display_ddl_schema_diff( b_schema_source => l_schema
                                    , b_schema_target => g_empty
                                    , b_network_link_source => l_network_link_source
                                    , b_network_link_target => l_network_link_target
                                    );
      fetch c_display_ddl_schema_diff bulk collect into l_diff_schema_ddl_tab;
      close c_display_ddl_schema_diff;

      /* step 5 */

      /* see step 2: there are no public synonyms */
      /*
      -- Skip public synonyms
      remove_public_synonyms(l_diff_schema_ddl_tab);
      */
      -- ORA-01720: grant option does not exist for '<owner>.PARTY'
      remove_object_grants(l_diff_schema_ddl_tab);

      begin
        ut.expect(l_diff_schema_ddl_tab.count, l_program || '#differences' || '#' || i_try).to_equal(0);
$if cfg_pkg.c_debugging $then        
      exception
        when others
        then
          dbug.on_error;
          if l_diff_schema_ddl_tab.count > 0
          then
            for i_idx in l_diff_schema_ddl_tab.first .. l_diff_schema_ddl_tab.last
            loop
              l_diff_schema_ddl_tab(i_idx).print();
            end loop;
          end if;
          raise;
$end          
      end;

      cleanup;
    end loop;

$if cfg_pkg.c_debugging $then
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
    l_schema t_schema;    
    l_schema_object_tab t_schema_object_tab;
    l_object_info_tab oracle_tools.t_object_info_tab;
    l_sort_objects_by_deps_tab1 t_sort_objects_by_deps_tab;
    l_sort_objects_by_deps_tab2 t_sort_objects_by_deps_tab;
    l_program constant varchar2(61) := g_package_prefix || 'UT_SORT_OBJECTS_BY_DEPS';
  begin
$if cfg_pkg.c_debugging $then
    dbug.enter(l_program);
$end

    null;

$if cfg_pkg.c_debugging $then
    dbug.leave;
  exception
    when others
    then
      dbug.leave_on_error;
      raise;
$end
  end ut_sort_objects_by_deps;

$else -- $if cfg_pkg.c_testing $then

  -- test functions
  procedure ut_setup
  is
  begin
    raise program_error;
  end ut_setup;

  procedure ut_teardown
  is
  begin
    raise program_error;
  end ut_teardown;

  procedure ut_display_ddl_schema
  is
  begin
    raise program_error;
  end ut_display_ddl_schema;

  procedure ut_display_ddl_schema_diff
  is
  begin
    raise program_error;
  end ut_display_ddl_schema_diff;

  procedure ut_object_type_order
  is
  begin
    raise program_error;
  end ut_object_type_order;

  procedure ut_dict2metadata_object_type
  is
  begin
    raise program_error;
  end ut_dict2metadata_object_type;

  procedure ut_is_a_repeatable
  is
  begin
    raise program_error;
  end ut_is_a_repeatable;

  procedure ut_get_schema_object
  is
  begin
    raise program_error;
  end ut_get_schema_object;

  procedure ut_synchronize
  is
  begin
    raise program_error;
  end ut_synchronize;

  procedure ut_sort_objects_by_deps
  is
  begin
    raise program_error;
  end ut_sort_objects_by_deps;

$end -- $if cfg_pkg.c_testing $then

begin
  -- ensure unicode kees working
  if unistr('\20AC') <> c_euro_sign
  then
    raise value_error;
  end if;

  dbms_lob.createtemporary(g_clob, true);

  select global_name.global_name into g_dbname from global_name;

  i_object_exclude_name_expr_tab;

  g_transform_param_tab('SEGMENT_ATTRIBUTES'  ) := false;
  g_transform_param_tab('STORAGE'             ) := false;
  g_transform_param_tab('TABLESPACE'          ) := false;
  -- g_transform_param_tab('REF_CONSTRAINTS'     ) := false;
  -- g_transform_param_tab('CONSTRAINTS_AS_ALTER') := false;
  -- g_transform_param_tab('CONSTRAINTS'         ) := false;
  -- g_transform_param_tab('FORCE'               ) := false;
  g_transform_param_tab('OID'                 ) := false;
end pkg_ddl_util;
/

