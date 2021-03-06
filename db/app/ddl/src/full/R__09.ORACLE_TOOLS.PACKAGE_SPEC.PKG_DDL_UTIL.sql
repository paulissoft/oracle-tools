CREATE OR REPLACE PACKAGE "ORACLE_TOOLS"."PKG_DDL_UTIL" AUTHID CURRENT_USER IS

  /**
  * This package contains DDL utilities based on DBMS_METADATA and DBMS_METADATA_DIFF.
  *
  * <p>
  * These routines are available:
  * <ul>
  * <li>display_ddl_schema: display DDL for a schema</li>
  * <li>display_ddl_schema_diff: display DDL differences DDL between two schemas (like the patch utility)</li>
  * <li>execute_ddl: execute DDL</li>
  * <li>synchronize: synchronize a target schema based on a source schema</li>
  * <li>uninstall: uninstall a target schema</li>
  * </ul>
  * </p>
  *
  * <p>
  * The documentation is in Javadoc format and thus readable by PL/SQL Developer and pldoc.
  * </p>
  *
  */

  /* CONSTANTS */
  -- see 11g / 12c licensing
  c_use_sqlterminator constant boolean := false; -- pkg_dd_util v4/v5

  c_debugging constant naturaln := 1; -- 0: none, 1: standard, 2: verbose, 3: even more verbose

  -- pivotal issues

  -- GPA 2017-02-01 #138707615 named not null constraints are recreated
  c_#138707615_1 constant boolean := true;

  -- GPA 2017-01-31 #138707615 The diff DDL for XBIKE contained errors.
  --
  -- Constraints with different indexes fail because the index is already there:
  --
  -- ALTER TABLE "<owner>"."WORKORDERTYPE" ADD CONSTRAINT "WORKORDERTYPE_PK" PRIMARY KEY ("SEQ")
  -- USING INDEX (CREATE UNIQUE INDEX "<owner>"."WORKORDERTYPE1_PK" ON "<owner>"."WORKORDERTYPE" ("SEQ")
  -- PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS
  -- TABLESPACE "YSSINDEX" )  ENABLE;
  --
  c_#138707615_2 constant boolean := true;

  -- GPA 2017-02-01 #138550763 As a developer I want to migrate types correctly.
  c_#138550763 constant boolean := true;

  -- GPA 2017-02-01 As a developer I want to migrate function based indexes correctly.
  c_#138550749 constant boolean := true;

  -- GPA 2017-03-06 Capture invalid objects before releasing to next enviroment.
  c_#140920801 constant boolean := true; -- values: false - check nothing, true - allow checks

  -- see also generate_ddl.pl
  c_get_queue_ddl constant boolean := false;
  c_get_db_link_ddl constant boolean := false;
  c_get_dimension_ddl constant boolean := false;
  c_get_indextype_ddl constant boolean := false;
  c_get_library_ddl constant boolean := false;
  c_get_operator_ddl constant boolean := false;
  c_get_xmlschema_ddl constant boolean := false;

  c_transform_param_list constant varchar2(4000 char) := 'SEGMENT_ATTRIBUTES,TABLESPACE';

  /* TYPES */
  subtype t_dict_object_type is all_objects.object_type%type;
  subtype t_dict_object_type_nn is t_dict_object_type not null;

  subtype t_metadata_object_type is varchar2(30 char);
  subtype t_metadata_object_type_nn is t_metadata_object_type not null;

  subtype t_object_name is varchar2(4000 char);
  subtype t_object_name_nn is t_object_name not null;

  -- key: owner.object_type.object_name[.grantee]
  subtype t_object is varchar2(4000 char);
  subtype t_object_nn is t_object not null;

  subtype t_numeric_boolean is natural; -- must be null, 0 or 1
  subtype t_numeric_boolean_nn is naturaln; -- must be 0 or 1

  subtype t_schema is varchar2(30 char);
  subtype t_schema_nn is t_schema not null;

  subtype t_object_names is varchar2(4000 char);
  subtype t_object_names_nn is t_object_names not null;

  subtype t_network_link is all_db_links.db_link%type;
  subtype t_network_link_nn is t_network_link not null;

  type t_transform_param_tab is table of boolean index by varchar2(4000 char);

  /**
  * This function displays the DDL for one or more schema objects.
  *
  * <p>
  * Based on p_object_type you can filter on object types:
  * <ul>
  * <li>If empty display all object types mentioned in the DBMS_METADATA documentation.</li>
  * <li>Else, only those object types that match (LIKE) p_object_type.</li>
  * </ul>
  * </p>
  *
  * <p>
  * Based on p_object_names and p_object_names_include the filtering is like this:
  * <ul>
  * <li>If p_object_names_include is empty then there are no constraints regarding object names (although special objects like Flyway tables and Oracle objects will be ignored).</li>
  * <li>If p_object_names_include is 1, only names in p_object_names will be included like in DBMS_METADATA.SET_FILTER(name=>'NAME_EXPR', value=>'IN (...)').</li>
  * <li>If p_object_names_include is 0, only names in p_object_names will be excluded like in DBMS_METADATA.SET_FILTER(name=>'EXCLUDE_NAME_EXPR', value=>'IN (...)').</li>
  * </ul>
  * </p>
  *
  * <p>
  * NOTE: parameters p_schema and p_object_names will NOT be converted to upper case.
  * </p>
  *
  * @param p_schema                The schema name.
  * @param p_new_schema            The new schema name.
  * @param p_sort_objects_by_deps  Sort objecten in dependency order to reduce number of installation errors/warnings.
  * @param p_object_type           Filter for object type.
  * @param p_object_names          A comma separated list of (base) object names.
  * @param p_object_names_include  How to treat the object name list: include (1), exclude (0) or don't care (null)?
  * @param p_network_link          The network link.
  * @param p_grantor_is_schema     An extra filter for grants. If the value is 1, only grants with grantor equal to p_schema will be chosen.
  * @param p_transform_param_list  A comma separated list of transform parameters, see dbms_metadata.set_transform_param().
  *
  * @return A list of DDL text plus information about the object.
  */
  function display_ddl_schema
  ( p_schema in t_schema_nn default user
  , p_new_schema in t_schema default null
  , p_sort_objects_by_deps in t_numeric_boolean_nn default 0 -- >= 0, not null
  , p_object_type in t_metadata_object_type default null
  , p_object_names in t_object_names default null
  , p_object_names_include in t_numeric_boolean default null
  , p_network_link in t_network_link default null
  , p_grantor_is_schema in t_numeric_boolean_nn default 0
  , p_transform_param_list in varchar2 default c_transform_param_list
  )
  return oracle_tools.t_schema_ddl_tab
  pipelined;

  procedure create_schema_ddl
  ( p_source_schema_ddl in oracle_tools.t_schema_ddl
  , p_target_schema_ddl in oracle_tools.t_schema_ddl
  , p_skip_repeatables in t_numeric_boolean
  , p_schema_ddl out nocopy oracle_tools.t_schema_ddl
  );

  /**
  * Display DDL to migrate from source to target.
  *
  * <p>
  * See display_ddl_schema() for the usage of p_object_type, p_object_names and p_object_names_include.
  * </p>
  *
  * @param p_object_type             Filter for object type.
  * @param p_object_names            A comma separated list of (base) object names.
  * @param p_object_names_include    How to treat the object name list: include (1), exclude (0) or don't care (null)?
  * @param p_schema_source           Source schema (may be empty for uninstall).
  * @param p_schema_target           Target schema.
  * @param p_network_link_source     Source network link.
  * @param p_network_link_target     Target network link.
  * @param pi_skip_repeatables       Skip repeatables objects (1) or check all objects (0)
  * @param p_transform_param_list    A comma separated list of transform parameters, see dbms_metadata.set_transform_param().
  *
  * @return A list of DDL text plus information about the object.
  */
  function display_ddl_schema_diff
  ( p_object_type in t_metadata_object_type default null
  , p_object_names in t_object_names default null
  , p_object_names_include in t_numeric_boolean default null
  , p_schema_source in t_schema default user
  , p_schema_target in t_schema_nn default user
  , p_network_link_source in t_network_link default null
  , p_network_link_target in t_network_link default null
  , p_skip_repeatables in t_numeric_boolean_nn default 1 -- Default for Flyway with repeatable migrations
  , p_transform_param_list in varchar2 default c_transform_param_list
  )
  return oracle_tools.t_schema_ddl_tab
  pipelined;

  procedure execute_ddl
  ( p_id in varchar2
  , p_text in varchar2
  );

  procedure execute_ddl
  ( p_ddl_text_tab in oracle_tools.t_text_tab
  , p_network_link in varchar2 default null
  );

  procedure execute_ddl
  ( p_ddl_tab in dbms_sql.varchar2a
  );

  procedure execute_ddl
  ( p_schema_ddl_tab in oracle_tools.t_schema_ddl_tab
  , p_network_link in varchar2 default null
  );

  /**
  * Synchronize a target schema based on a source schema.
  *
  * <p>
  * See display_ddl_schema() for the usage of p_object_type, p_object_names and p_object_names_include.
  * </p>
  *
  * @param p_object_type             Filter for object type.
  * @param p_object_names            A comma separated list of (base) object names.
  * @param p_object_names_include    How to treat the object name list: include (1), exclude (0) or don't care (null)?
  * @param p_schema_source           Source schema (may be empty for uninstall).
  * @param p_schema_target           Target schema.
  * @param p_network_link_source     Source network link.
  * @param p_network_link_target     Target network link.
  */
  procedure synchronize
  ( p_object_type in t_metadata_object_type default null
  , p_object_names in t_object_names default null
  , p_object_names_include in t_numeric_boolean default null
  , p_schema_source in t_schema default user
  , p_schema_target in t_schema_nn default user
  , p_network_link_source in t_network_link default null
  , p_network_link_target in t_network_link default null
  );

  /**
  * This one uninstalls a target schema.
  *
  * <p>
  * See display_ddl_schema() for the usage of p_object_type, p_object_names and p_object_names_include.
  * </p>
  *
  * @param p_object_type             Filter for object type.
  * @param p_object_names            A comma separated list of (base) object names.
  * @param p_object_names_include    How to treat the object name list: include (1), exclude (0) or don't care (null)?
  * @param p_schema_target           Target schema.
  * @param p_network_link_target     Target network link.
  */
  procedure uninstall
  ( p_object_type in t_metadata_object_type default null
  , p_object_names in t_object_names default null
  , p_object_names_include in t_numeric_boolean default null
  , p_schema_target in t_schema_nn default user
  , p_network_link_target in t_network_link default null
  );

  /**
  * Get all the object info from the ALL_OBJECTS, ALL_SYNONYMS, ALL_TAB_PRIVS, ALL_TAB_COMMENTS and ALL_COL_COMMENTS.
  *
  * <p>
  * See display_ddl_schema() for a description of the usage of p_object_type, p_object_names and p_object_names_include.
  * </p>
  *
  * @param p_schema                Schema name.
  * @param p_object_type           Filter for object type.
  * @param p_object_names          A list of object names separated by a comma.
  * @param p_object_names_include  How to treat the object name list: include (1), exclude (0) or don't care (null)?
  * @param p_grantor_is_schema     An extra filter for grants. If the value is 1, only grants with grantor equal to p_schema will be chosen.
  * @param p_schema_object_tab     Only applicable for the procedure variant. See the description for return.
  *
  * @return A list of object info records where every object will have p_schema as its object_schema except for public synonyms to objects of this schema since they will have object_schema PUBLIC.
  */
  procedure get_schema_object
  ( p_schema in t_schema_nn default user
  , p_object_type in t_metadata_object_type default null
  , p_object_names in t_object_names default null
  , p_object_names_include in t_numeric_boolean default null
  , p_grantor_is_schema in t_numeric_boolean_nn default 0
  , p_schema_object_tab out nocopy oracle_tools.t_schema_object_tab
  );

  function get_schema_object
  ( p_schema in t_schema_nn default user
  , p_object_type in t_metadata_object_type default null
  , p_object_names in t_object_names default null
  , p_object_names_include in t_numeric_boolean default null
  , p_grantor_is_schema in t_numeric_boolean_nn default 0
  )
  return oracle_tools.t_schema_object_tab
  pipelined;

  procedure get_member_ddl
  ( p_schema_ddl in oracle_tools.t_schema_ddl
  , p_member_ddl_tab out nocopy oracle_tools.t_schema_ddl_tab
  );

  -- set checks for an object type
  procedure do_chk
  ( p_object_type in t_metadata_object_type -- null: all object types
  , p_value in boolean
  );

  function do_chk
  ( p_object_type in t_metadata_object_type
  )
  return boolean;

  /*
  -- Various super type check procedures
  -- Oracle 11g has a (object as supertype).chk() syntax but Oracle 10i not.
  -- So we invoke package procedure from the type bodies.
  */
  procedure chk_schema_object
  ( p_schema_object in oracle_tools.t_schema_object
  , p_schema in varchar2
  );

  procedure chk_schema_object
  ( p_dependent_or_granted_object in oracle_tools.t_dependent_or_granted_object
  , p_schema in varchar2
  );

  procedure chk_schema_object
  ( p_named_object in oracle_tools.t_named_object
  , p_schema in varchar2
  );

  procedure chk_schema_object
  ( p_constraint_object in oracle_tools.t_constraint_object
  , p_schema in varchar2
  );

  /*
  -- helper function
  */
  /**
   * Determine whether a schema object matches a filter.
   *
   * Rules:
   * <ol>
   * <li>A schema base object where is_exclude_name_expr() = 1: return 0</li>
   * <li>A schema object where is_exclude_name_expr() = 1: return 0</li>
   * <li>If p_metadata_object_type is not member of p_object_types_to_check: return 1</li>
   * <li>When p_object_type is empty or equal to the (base) object type and the combination of p_object_name and p_object_names_include matches p_object_names: return 1</li>
   * <li>Else: return 0</li>
   * </ol>
   *
   * @param p_object_type                 A metadata object type (from client).
   * @param p_object_names                A comma separated list of object names (from client).
   * @param p_object_names_include        How to treat the object name list: include (1), exclude (0) or don't care (null)?
   * @param p_object_types_to_check       A list of metadata object types to check for (null = check all).
   * @param p_metadata_object_type        The schema object type (metadata).
   * @param p_object_name                 The schema object name.
   * @param p_metadata_base_object_type   The schema base object type (metadata).
   * @param p_base_object_name            The schema base object name.
   *
   */
  function schema_object_matches_filter
  ( -- filter values
    p_object_type in t_metadata_object_type
  , p_object_names in t_object_names
  , p_object_names_include in t_numeric_boolean
  , p_object_types_to_check in oracle_tools.t_text_tab
    -- database values
  , p_metadata_object_type in t_metadata_object_type
  , p_object_name in t_object_name
  , p_metadata_base_object_type in t_metadata_object_type default null
  , p_base_object_name in t_object_name default null
  )
  return t_numeric_boolean_nn
  deterministic
  ;

  function is_dependent_object_type
  ( p_object_type in t_metadata_object_type
  )
  return t_numeric_boolean
  deterministic;

  procedure get_exclude_name_expr_tab
  ( p_object_type in varchar2
  , p_object_name in varchar2 default null
  , p_exclude_name_expr_tab out nocopy oracle_tools.t_text_tab
  );

  function is_exclude_name_expr
  ( p_object_type in t_metadata_object_type
  , p_object_name in t_object_name
  )
  return integer
  deterministic;

  /*
  -- Help function to get the DDL belonging to a list of allowed objects returned by get_schema_object()
  */
  function get_schema_ddl
  ( p_schema in t_schema_nn
  , p_object_type in t_metadata_object_type
  , p_object_names in t_object_names
  , p_object_names_include in t_numeric_boolean
  , p_use_schema_export in t_numeric_boolean_nn
  , p_schema_object_tab in oracle_tools.t_schema_object_tab
  , p_transform_param_list in varchar2 default c_transform_param_list
  )
  return oracle_tools.t_schema_ddl_tab
  pipelined;

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
  );

  /*
  -- Help procedure to retrieve the results of display_ddl_schema on a remote database.
  --
  -- Remark 1: Uses view v_display_ddl_schema2 because pipelined functions and a database link are not allowed.
  -- Remark 2: A call to display_ddl_schema() with a database linke will invoke set_display_ddl_schema() at the remote database.
  */
  function get_display_ddl_schema
  return oracle_tools.t_schema_ddl_tab
  pipelined;

  /*
  -- Sort objects on dependency order.
  */
  function sort_objects_by_deps
  ( p_schema_object_tab in oracle_tools.t_schema_object_tab
  , p_schema in t_schema_nn default user
  )
  return oracle_tools.t_schema_object_tab
  pipelined;

  procedure migrate_schema_ddl
  ( p_source in oracle_tools.t_schema_ddl
  , p_target in oracle_tools.t_schema_ddl
  , p_schema_ddl in out nocopy oracle_tools.t_schema_ddl
  );

$if oracle_tools.cfg_pkg.c_testing $then

  -- test functions

  procedure ut_cleanup_empty;

  --%suitepath(DDL)
  --%suite
  --%rollback(manual)

  --%beforeall
  procedure ut_setup;

  --%afterall
  procedure ut_teardown;

  --%test
  --%beforetest(oracle_tools.pkg_ddl_util.ut_cleanup_empty)
  procedure ut_display_ddl_schema;

  --%test
  --%beforetest(oracle_tools.pkg_ddl_util.ut_cleanup_empty)
  procedure ut_display_ddl_schema_diff;

  --%test
  procedure ut_object_type_order;

  --%test
  procedure ut_dict2metadata_object_type;

  --%test
  procedure ut_is_a_repeatable;

  --%test
  procedure ut_get_schema_object;

  --%test
  --%beforetest(oracle_tools.pkg_ddl_util.ut_cleanup_empty)
  procedure ut_synchronize;

  --%test
  procedure ut_sort_objects_by_deps;

  --%test
  procedure ut_modify_ddl_text;

$end -- $if oracle_tools.cfg_pkg.c_testing $then

end pkg_ddl_util;
/

