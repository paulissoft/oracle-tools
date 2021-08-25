CREATE OR REPLACE PACKAGE "ORACLE_TOOLS"."PKG_DDL_UTIL" AUTHID CURRENT_USER IS

  /**
  * Dit package bevat DDL utilities gebaseerd op DBMS_METADATA en DBMS_METADATA_DIFF.
  *
  * <p>
  * De volgende functionaliteit wordt beschikbaar gemaakt:
  * <ul>
  * <li>Tonen van DDL van een object</li>
  * <li>Tonen van DDL van een schema</li>
  * <li>Tonen van verschillen van DDL tussen twee schema's</li>
  * <li>Uitvoeren van DDL</li>
  * </ul>
  * </p>
  *
  * <p>
  * De documentatie is in PL/SQL Developer plsqldoc formaat.
  * </p>
  *
  */

  /* CONSTANTS */
  -- see 11g / 12c licensing
  c_use_sqlterminator constant boolean := false; -- pkg_dd_util v4/v5

  c_debugging constant naturaln := 1; -- 0: none, 1: standard, 2: verbose, 3: even more verbose
  c_testing constant boolean := true; -- 0: none, 1: standard, 2: verbose, 3: even more verbose

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

  /* EXCEPTIONS */
  c_schema_does_not_exist        constant integer := -20100;
  e_schema_does_not_exist        exception;
  pragma exception_init(e_schema_does_not_exist, -20100);

  c_numeric_boolean_wrong   constant integer := -20101;
  e_numeric_boolean_wrong   exception;
  pragma exception_init(e_numeric_boolean_wrong, -20101);

  c_database_link_does_not_exist constant integer := -20102;
  e_database_link_does_not_exist exception;
  pragma exception_init(e_database_link_does_not_exist, -20102);

  c_schema_wrong                 constant integer := -20103;
  e_schema_wrong                 exception;
  pragma exception_init(e_schema_wrong, -20103);

  c_source_and_target_equal      constant integer := -20104;
  e_source_and_target_equal      exception;
  pragma exception_init(e_source_and_target_equal, -20104);

  c_object_names_wrong  constant integer := -20105;
  e_object_names_wrong  exception;
  pragma exception_init(e_object_names_wrong, -20105);

  c_object_type_wrong  constant integer := -20106;
  e_object_type_wrong  exception;
  pragma exception_init(e_object_type_wrong, -20106);

  /* TYPES */
  subtype t_dict_object_type is all_objects.object_type%type; 
  subtype t_dict_object_type_nn is t_dict_object_type not null;

  subtype t_metadata_object_type is varchar2(30 char); -- langer dan all_objects.object_type%type
  subtype t_metadata_object_type_nn is t_metadata_object_type not null;

  subtype t_object_name is varchar2(4000 char); -- standaard maximaal 30 maar langer kan nodig zijn voor lange synoniemnamen (zie  SYS.KU$_SYNONYM_VIEW) of XML schema's
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
  *
  * Get a sorted dependency list sorted by the least number of dependencies first.
  *
  * <p>
  * When there is a circular dependency, the function will just pick one: it will not abort.
  * May be used to determine the best installation order for several schemas.
  * </p>
  *
  * <code>
  * select  t.column_value
  * from    table
  *         ( pkg_ddl_util.get_sorted_dependency_list
  *           ( oracle_tools.t_text_tab
  *             ( 'APEX_050000'
  *             , '<owner>'
  *             )
  *           , cursor(select owner, referenced_owner from all_dependencies)
  *           )
  *         ) t
  * </code>
  *
  * @param p_object_tab            A list of dependencies to resolve.
  * @param p_object_refcursor      An openend cursor with one column: the object.
  *                                Example: select username from all_users.
  * @param p_dependency_refcursor  An opened cursor with two columns where the first column depends on the second column.
  *                                Example: select owner, referenced_owner from all_dependencies.
  */  
  function get_sorted_dependency_list
  ( p_object_tab in t_text_tab
  , p_dependency_refcursor in sys_refcursor -- query with two columns: object1 depends on object2, i.e. select owner, referenced_owner from all_dependencies ...
  )
  return t_text_tab pipelined;

  function get_sorted_dependency_list
  ( p_object_refcursor in sys_refcursor
  , p_dependency_refcursor in sys_refcursor -- query with two columns: object1 depends on object2, i.e. select owner, referenced_owner from all_dependencies ...
  )
  return t_text_tab pipelined;

  /**
  * Deze functie toont DDL van een of meerdere objecten van een schema.
  *
  * <p>
  * Op basis van p_object_type kun je filteren welke objecttypen van belang zijn:
  * <ul>
  * <li>Indien leeg dan alle objecttypen genoemd in documentatie van DBMS_METADATA.</li>
  * <li>Indien niet leeg dan alle objecttypen die matchen (LIKE) met p_object_type.</li>
  * </ul>
  * </p>
  *
  * <p>
  * Op basis van p_object_names en p_object_names_include kun je filteren op objectnamen:
  * <ul>
  * <li>Indien p_object_names_include leeg is, dan zijn er geen beperkingen aan objectnamen.</li>
  * <li>Indien p_object_names_include 1 is, dan zullen alle namen in p_object_names gebruikt worden in een filter zoals in DBMS_METADATA.SET_FILTER(name=>'NAME_EXPR', value=>'IN (...)').</li>
  * <li>Indien p_object_names_include 0 is, dan zullen alle namen in p_object_names gebruikt worden in een filter zoals in DBMS_METADATA.SET_FILTER(name=>'EXCLUDE_NAME_EXPR', value=>'IN (...)').</li>
  * </ul>
  * </p>
  *
  * <p>
  * Parameters p_schema, p_new_schema en p_object_names worden niet geconverteerd naar bijvoorbeeld hoofdletters.
  * </p>
  *
  * @param p_schema                De naam van het schema
  * @param p_new_schema            De naam van het nieuwe te remappen schema
  * @param p_sort_objects_by_deps  Sorteer objecten in volgorde van afhankelijkheden opdat er zo min mogelijk compilatiefouten optreden vanwege ontbrekende objecten.
  * @param p_object_type           Filter op objecttype.
  * @param p_object_names          Een lijst van namen van het (basis-)object gescheiden door komma's.
  * @param p_object_names_include  Wat er moet gebeuren met de lijst van namen: include de lijst (1), exclude de lijst (0) of niet gebruiken en dus geen beperking opleggen (null)
  * @param p_network_link          De netwerk link
  * @param p_grantor_is_schema     An extra filter for grants. If the value is 1, only grants with grantor equal to p_schema will be chosen.
  * @param p_transform_param_list  A comma separated list of transform parameters, see dbms_metadata.set_transform_param().
  *
  * @return Een lijst van DDL text plus informatie over object.
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
  return t_schema_ddl_tab
  pipelined;

  procedure create_schema_ddl
  ( p_source_schema_ddl in t_schema_ddl
  , p_target_schema_ddl in t_schema_ddl
  , p_skip_repeatables in t_numeric_boolean
  , p_schema_ddl out nocopy t_schema_ddl
  );

  /**
  * Deze functie toont DDL om van een source schema naar target schema te migreren.
  *
  * <p>
  * Zie display_ddl_schema() voor een beschrijving van het gebruik van p_object_type, p_object_names en p_object_names_include.
  * </p>
  *
  * @param p_object_type             Filter op objecttype.
  * @param p_object_names            Een lijst van namen van het (basis-)object gescheiden door komma's.
  * @param p_object_names_include    Wat er moet gebeuren met de lijst van namen: include de lijst (1), exclude de lijst (0) of niet gebruiken en dus geen beperking opleggen (null)
  * @param p_schema_source           De naam van het bronschema (mag leeg zijn voor uninstall)
  * @param p_schema_target           De naam van het doelschema
  * @param p_network_link_source     De netwerk link van het bronschema
  * @param p_network_link_target     De netwerk link van het doelschema
  * @param pi_skip_repeatables       Skip repeatables objects (1) or check all objects (0)
  * @param p_transform_param_list    A comma separated list of transform parameters, see dbms_metadata.set_transform_param().
  *
  * @return Een lijst van DDL text plus informatie over object.
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
  return t_schema_ddl_tab
  pipelined;

  procedure execute_ddl
  ( p_id in varchar2
  , p_text in varchar2
  );

  procedure execute_ddl
  ( p_ddl_text_tab in t_text_tab
  , p_network_link in varchar2 default null
  );

  procedure execute_ddl
  ( p_schema_ddl_tab in t_schema_ddl_tab
  , p_network_link in varchar2 default null
  );

  /**
  * Deze procedure synchroniseert een target schema aan de hand van een source schema.
  *
  * <p>
  * Zie display_ddl_schema() voor een beschrijving van het gebruik van p_object_type, p_object_names en p_object_names_include.
  * </p>
  *
  * @param p_object_type           Filter op objecttype.
  * @param p_object_names          Een lijst van namen van het (basis-)object gescheiden door komma's.
  * @param p_object_names_include  Wat er moet gebeuren met de lijst van namen: include de lijst (1), exclude de lijst (0) of niet gebruiken en dus geen beperking opleggen (null)
  * @param p_schema_source         De naam van het bronschema
  * @param p_schema_target         De naam van het doelschema
  * @param p_network_link_source   De netwerk link van het bronschema
  * @param p_network_link_target   De netwerk link van het doelschema
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
  * Deze procedure de-installeert een target schema.
  *
  * <p>
  * Zie display_ddl_schema() voor een beschrijving van het gebruik van p_object_type, p_object_names en p_object_names_include.
  * </p>
  *
  * @param p_object_type           Filter op objecttype.
  * @param p_object_names          Een lijst van namen van het (basis-)object gescheiden door komma's.
  * @param p_object_names_include  Wat er moet gebeuren met de lijst van namen: include de lijst (1), exclude de lijst (0) of niet gebruiken en dus geen beperking opleggen (null)
  * @param p_schema_target         De naam van het doelschema
  * @param p_network_link_target   De netwerk link van het doelschema
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
  * @param p_schema                Schema name
  * @param p_object_type           Filter for object type
  * @param p_object_names          A list of object names separated by a comma
  * @param p_object_names_include  Either include the list (1), exclude the list (0) or do not use the list (null)
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
  , p_schema_object_tab out nocopy t_schema_object_tab
  );

  function get_schema_object
  ( p_schema in t_schema_nn default user
  , p_object_type in t_metadata_object_type default null
  , p_object_names in t_object_names default null
  , p_object_names_include in t_numeric_boolean default null
  , p_grantor_is_schema in t_numeric_boolean_nn default 0
  )
  return t_schema_object_tab
  pipelined;

  procedure get_member_ddl
  ( p_schema_ddl in t_schema_ddl
  , p_member_ddl_tab out nocopy t_schema_ddl_tab
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
  ( p_schema_object in t_schema_object
  , p_schema in varchar2
  );

  procedure chk_schema_object
  ( p_dependent_or_granted_object in t_dependent_or_granted_object
  , p_schema in varchar2
  );

  procedure chk_schema_object
  ( p_named_object in t_named_object
  , p_schema in varchar2
  );

  procedure chk_schema_object
  ( p_constraint_object in t_constraint_object
  , p_schema in varchar2
  );

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
  ;

  function is_dependent_object_type
  ( p_object_type in t_metadata_object_type
  )
  return t_numeric_boolean
  deterministic;

  procedure get_exclude_name_expr_tab
  ( p_object_type in varchar2
  , p_object_name in varchar2 default null
  , p_exclude_name_expr_tab out nocopy t_text_tab
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
  , p_new_schema in t_schema
  , p_use_schema_export in t_numeric_boolean_nn
  , p_schema_object_tab in t_schema_object_tab
  , p_transform_param_list in varchar2 default c_transform_param_list
  )
  return t_schema_ddl_tab
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
  return t_schema_ddl_tab
  pipelined;

  /*
  -- Sorteer objecten op volgorde van afhankelijkheden.
  */
  function sort_objects_by_deps
  ( p_cursor in sys_refcursor
  , p_schema in t_schema_nn default user
  )
  return t_sort_objects_by_deps_tab
  pipelined;

  procedure init_clob;

  procedure append_clob(p_line in varchar2);

  function get_clob return clob;

  procedure migrate_schema_ddl
  ( p_source in t_schema_ddl
  , p_target in t_schema_ddl
  , p_schema_ddl in out nocopy t_schema_ddl
  );

  function modify_ddl_text
  ( p_ddl_text in clob
  , p_schema in t_schema_nn
  , p_new_schema in t_schema
  , p_object_type in t_metadata_object_type default null
  )
  return clob;

$if cfg_pkg.c_testing $then

  -- test functions
  
  --%suitepath(DDL)
  --%suite

  --%beforeall
  procedure ut_setup;
  
  --%afterall
  procedure ut_teardown;

  --%test
  procedure ut_display_ddl_schema;

  --%test
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
  procedure ut_synchronize;

  --%test
  procedure ut_sort_objects_by_deps;

$end -- $if cfg_pkg.c_testing $then

end pkg_ddl_util;
/

