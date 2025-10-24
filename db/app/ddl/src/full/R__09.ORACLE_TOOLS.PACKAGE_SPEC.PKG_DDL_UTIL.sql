CREATE OR REPLACE PACKAGE "ORACLE_TOOLS"."PKG_DDL_UTIL" AUTHID CURRENT_USER IS

/**

This package contains DDL utilities based on `DBMS_METADATA` and `DBMS_METADATA_DIFF`.

The idea is to be able to easily extract DDL from schemas and only for the objects you want.

The output can then be written to DDL scripts.

To get to know more about filtering works please consult the `PKG_SCHEMA_OBJECT_FILTER` documentation.

It is possible to change the way the DDL is extracted by `DBMS_METADATA` by using transformations as set by `DBMS_METADATA.SET_TRANSFORM_PARAM()`.

This is the table of possible transformations used by this package:

|NAME|OBJECT TYPE|
|:---|:----------| 
|CONSTRAINTS_AS_ALTER|TABLE|
|CONSTRAINTS|TABLE, VIEW|
|FORCE|VIEW|
|OID|TYPE_SPEC|
|PRETTY||
|REF_CONSTRAINTS|TABLE|
|SEGMENT_ATTRIBUTES|TABLE, INDEX, CLUSTER, CONSTRAINT, ROLLBACK_SEGMENT, TABLESPACE|
|SIZE_BYTE_KEYWORD|TABLE|
|STORAGE|TABLE, INDEX, CLUSTER, CONSTRAINT, ROLLBACK_SEGMENT, TABLESPACE|
|TABLESPACE|TABLE, INDEX, CLUSTER, CONSTRAINT, ROLLBACK_SEGMENT, TABLESPACE|

They will all be set to FALSE unless you specify names in parameter `p_transform_param_list` from the various routines below. 

That parameter often defaults to constant `c_transform_param_list` which includes:
- CONSTRAINTS
- CONSTRAINTS_AS_ALTER
- FORCE
- PRETTY
- REF_CONSTRAINTS
- SEGMENT_ATTRIBUTES
- TABLESPACE

**/

/* CONSTANTS */

c_test_empty constant boolean := false;

c_err_pipelined_no_data_found constant boolean := true; -- false: no exception for no_data_found in  pipelined functions

/* (SUB)TYPES */

subtype t_transform_param_tab is oracle_tools.pkg_ddl_defs.t_transform_param_tab;
subtype t_metadata_object_type is oracle_tools.pkg_ddl_defs.t_metadata_object_type;
subtype t_schema_nn is oracle_tools.pkg_ddl_defs.t_schema_nn;
subtype t_schema is oracle_tools.pkg_ddl_defs.t_schema;
subtype t_object_names is oracle_tools.pkg_ddl_defs.t_object_names;
subtype t_numeric_boolean is oracle_tools.pkg_ddl_defs.t_numeric_boolean;
subtype t_numeric_boolean_nn is oracle_tools.pkg_ddl_defs.t_numeric_boolean_nn;
subtype t_network_link is oracle_tools.pkg_ddl_defs.t_network_link;
subtype t_network_link_nn is oracle_tools.pkg_ddl_defs.t_network_link_nn;
subtype t_objects is oracle_tools.pkg_ddl_defs.t_objects;
subtype t_session_id is oracle_tools.pkg_ddl_defs.t_session_id;
subtype t_session_id_nn is oracle_tools.pkg_ddl_defs.t_session_id_nn;
subtype t_object_name is oracle_tools.pkg_ddl_defs.t_object_name;

/* ROUTINES */

procedure get_transform_param_tab
( p_transform_param_list in varchar2
, p_transform_param_tab out nocopy t_transform_param_tab
);

procedure md_open
( p_object_type in t_metadata_object_type
, p_object_schema in varchar2
, p_object_name_tab in oracle_tools.t_text_tab
, p_base_object_schema in varchar2
, p_base_object_name_tab in oracle_tools.t_text_tab
, p_transform_param_tab in t_transform_param_tab
, p_transform_to_ddl in boolean default true
, p_handle out number
);

procedure md_fetch_ddl
( p_handle in number
, p_split_grant_statement in boolean
, p_ddl_tab out nocopy sys.ku$_ddls
);

procedure md_close
( p_handle in out number
);

procedure determine_schema_ddl
( p_schema in t_schema_nn default sys_context('USERENV', 'CURRENT_SCHEMA') -- The schema name.
, p_new_schema in t_schema default null -- The new schema name.
, p_object_type in t_metadata_object_type default null -- Filter for object type.
, p_object_names in t_object_names default null -- A comma separated list of (base) object names.
, p_object_names_include in t_numeric_boolean default null -- How to treat the object name list: include (1), exclude (0) or don't care (null)?
, p_network_link in t_network_link default null -- The network link.
, p_grantor_is_schema in t_numeric_boolean_nn default 0 -- An extra filter for grants. If the value is 1, only grants with grantor equal to p_schema will be chosen.
, p_transform_param_list in varchar2 default oracle_tools.pkg_ddl_defs.c_transform_param_list -- A comma separated list of transform parameters, see dbms_metadata.set_transform_param().
, p_exclude_objects in t_objects default null -- A newline separated list of objects to exclude (their schema object id actually).
, p_include_objects in t_objects default null -- A newline separated list of objects to include (their schema object id actually).
);

function display_ddl_sql
( p_schema in t_schema_nn default sys_context('USERENV', 'CURRENT_SCHEMA') -- The schema name.
, p_new_schema in t_schema default null -- The new schema name.
, p_sort_objects_by_deps in t_numeric_boolean_nn default 0 -- Sort objects in dependency order to reduce the number of installation errors/warnings.
, p_object_type in t_metadata_object_type default null -- Filter for object type.
, p_object_names in t_object_names default null -- A comma separated list of (base) object names.
, p_object_names_include in t_numeric_boolean default null -- How to treat the object name list: include (1), exclude (0) or don't care (null)?
, p_network_link in t_network_link default null -- The network link.
, p_grantor_is_schema in t_numeric_boolean_nn default 0 -- An extra filter for grants. If the value is 1, only grants with grantor equal to p_schema will be chosen.
, p_transform_param_list in varchar2 default oracle_tools.pkg_ddl_defs.c_transform_param_list -- A comma separated list of transform parameters, see dbms_metadata.set_transform_param().
, p_exclude_objects in t_objects default null -- A newline separated list of objects to exclude (their schema object id actually).
, p_include_objects in t_objects default null -- A newline separated list of objects to include (their schema object id actually).
)
return oracle_tools.t_display_ddl_sql_tab
pipelined;

function display_ddl_schema
( p_schema in t_schema_nn default sys_context('USERENV', 'CURRENT_SCHEMA') -- The schema name.
, p_new_schema in t_schema default null -- The new schema name.
, p_sort_objects_by_deps in t_numeric_boolean_nn default 0 -- Sort objects in dependency order to reduce the number of installation errors/warnings.
, p_object_type in t_metadata_object_type default null -- Filter for object type.
, p_object_names in t_object_names default null -- A comma separated list of (base) object names.
, p_object_names_include in t_numeric_boolean default null -- How to treat the object name list: include (1), exclude (0) or don't care (null)?
, p_network_link in t_network_link default null -- The network link.
, p_grantor_is_schema in t_numeric_boolean_nn default 0 -- An extra filter for grants. If the value is 1, only grants with grantor equal to p_schema will be chosen.
, p_transform_param_list in varchar2 default oracle_tools.pkg_ddl_defs.c_transform_param_list -- A comma separated list of transform parameters, see dbms_metadata.set_transform_param().
, p_exclude_objects in t_objects default null -- A newline separated list of objects to exclude (their schema object id actually).
, p_include_objects in t_objects default null -- A newline separated list of objects to include (their schema object id actually).
)
return oracle_tools.t_schema_ddl_tab
pipelined;

/**

This function displays the DDL for one or more schema objects.

You can rename the schema p_schema in the DDL by using p_new_schema.

You can run this function over a database link too.

NOTE: parameters p_schema, p_object_names, p_exclude_objects and p_include_objects will NOT be converted to upper case.

This function will return a list of DDL text plus information about the object.

**/

function display_ddl_sql
( p_session_id in t_session_id_nn -- The session id from V_MY_GENERATE_DDL_SESSIONS, i.e. must belong to your USERNAME.
)
return oracle_tools.t_display_ddl_sql_tab
pipelined;
/** Returns information about generated DDL for this session. Will **NOT** generate, just read from cache. **/

function display_ddl_schema
( p_session_id in t_session_id_nn -- The session id from V_MY_GENERATE_DDL_SESSIONS, i.e. must belong to your USERNAME.
)
return oracle_tools.t_schema_ddl_tab
pipelined;
/** Returns information about generated DDL for this session. Will **NOT** generate, just read from cache. **/

procedure ddl_generate_report
( p_session_id in t_session_id default null -- The session id from V_MY_GENERATE_DDL_SESSIONS, i.e. must belong to your USERNAME.
, p_output in out nocopy clob -- the CLOB to append the report to
);
/**

Append a DDL generate report in Markdown format to the output CLOB.

When the output parameter is null, a temporary CLOB will be created for it that YOU must free afterwards.

The first line (if any) will start with:

```
# DDL generate report
```

This will be used by the procedure P_GENERATE_DDL, hence also by Perl script `generate_ddl.pl`.

**/

procedure create_schema_ddl
( p_source_schema_ddl in oracle_tools.t_schema_ddl
, p_target_schema_ddl in oracle_tools.t_schema_ddl
, p_skip_repeatables in t_numeric_boolean
, p_schema_ddl out nocopy oracle_tools.t_schema_ddl
);

function display_ddl_sql_diff
( p_object_type in t_metadata_object_type default null -- Filter for object type.
, p_object_names in t_object_names default null -- A comma separated list of (base) object names.
, p_object_names_include in t_numeric_boolean default null -- How to treat the object name list: include (1), exclude (0) or don't care (null)?
, p_schema_source in t_schema default sys_context('USERENV', 'CURRENT_SCHEMA') -- Source schema (may be empty for uninstall).
, p_schema_target in t_schema_nn default sys_context('USERENV', 'CURRENT_SCHEMA') -- Target schema.
, p_network_link_source in t_network_link default null -- Source network link.
, p_network_link_target in t_network_link default null -- Target network link.
, p_skip_repeatables in t_numeric_boolean_nn default 1 -- Skip repeatables objects (1) or check all objects (0) with 1 the default for Flyway with repeatable migrations
, p_transform_param_list in varchar2 default oracle_tools.pkg_ddl_defs.c_transform_param_list -- A comma separated list of transform parameters, see dbms_metadata.set_transform_param().
, p_exclude_objects in t_objects default null -- A newline separated list of objects to exclude (their schema object id actually).
, p_include_objects in t_objects default null -- A newline separated list of objects to include (their schema object id actually).
)
return oracle_tools.t_display_ddl_sql_tab
pipelined;

function display_ddl_schema_diff
( p_object_type in t_metadata_object_type default null -- Filter for object type.
, p_object_names in t_object_names default null -- A comma separated list of (base) object names.
, p_object_names_include in t_numeric_boolean default null -- How to treat the object name list: include (1), exclude (0) or don't care (null)?
, p_schema_source in t_schema default sys_context('USERENV', 'CURRENT_SCHEMA') -- Source schema (may be empty for uninstall).
, p_schema_target in t_schema_nn default sys_context('USERENV', 'CURRENT_SCHEMA') -- Target schema.
, p_network_link_source in t_network_link default null -- Source network link.
, p_network_link_target in t_network_link default null -- Target network link.
, p_skip_repeatables in t_numeric_boolean_nn default 1 -- Skip repeatables objects (1) or check all objects (0) with 1 the default for Flyway with repeatable migrations
, p_transform_param_list in varchar2 default oracle_tools.pkg_ddl_defs.c_transform_param_list -- A comma separated list of transform parameters, see dbms_metadata.set_transform_param().
, p_exclude_objects in t_objects default null -- A newline separated list of objects to exclude (their schema object id actually).
, p_include_objects in t_objects default null -- A newline separated list of objects to include (their schema object id actually).
)
return oracle_tools.t_schema_ddl_tab
pipelined;

/**

Display DDL (script plus info) to migrate from source to target.

**/

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

procedure synchronize
( p_object_type in t_metadata_object_type default null -- Filter for object type.
, p_object_names in t_object_names default null -- A comma separated list of (base) object names.
, p_object_names_include in t_numeric_boolean default null -- How to treat the object name list: include (1), exclude (0) or don't care (null)?
, p_schema_source in t_schema default sys_context('USERENV', 'CURRENT_SCHEMA') -- Source schema (may be empty for uninstall).
, p_schema_target in t_schema_nn default sys_context('USERENV', 'CURRENT_SCHEMA') -- Target schema.
, p_network_link_source in t_network_link default null -- Source network link.
, p_network_link_target in t_network_link default null -- Target network link.
, p_exclude_objects in t_objects default null -- A newline separated list of objects to exclude (their schema object id actually).
, p_include_objects in t_objects default null -- A newline separated list of objects to include (their schema object id actually).
);

/** Synchronize a target schema based on a source schema. **/

procedure uninstall
( p_object_type in t_metadata_object_type default null -- Filter for object type.
, p_object_names in t_object_names default null -- A comma separated list of (base) object names.
, p_object_names_include in t_numeric_boolean default null -- How to treat the object name list: include (1), exclude (0) or don't care (null)?
, p_schema_target in t_schema_nn default sys_context('USERENV', 'CURRENT_SCHEMA') -- Target schema.
, p_network_link_target in t_network_link default null -- Target network link.
, p_exclude_objects in t_objects default null -- A newline separated list of objects to exclude (their schema object id actually).
, p_include_objects in t_objects default null -- A newline separated list of objects to include (their schema object id actually).
);

/** This one uninstalls a target schema. **/

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

/**

Various super type check procedures.

Oracle 11g has a (object as supertype).chk() syntax but Oracle 10i not.

So we invoke package procedure from the type bodies.

**/

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

procedure get_schema_ddl
( p_schema in varchar2
, p_transform_param_list in varchar2
, p_object_type in varchar2 -- dbms_metadata filter for metadata object type
, p_object_schema in varchar2 -- metadata object schema
, p_base_object_schema in varchar2 -- dbms_metadata filter for base object schema
, p_object_name_tab in oracle_tools.t_text_tab -- dbms_metadata filter for object names
, p_base_object_name_tab in oracle_tools.t_text_tab -- dbms_metadata filter for base object names
, p_nr_objects in integer -- dbms_metadata filter for number of objects
, p_add_no_ddl_retrieved in boolean
);

/** Get the schema DDL. **/

procedure set_parallel_level
( p_parallel_level in natural default null
);
/**
Set the number of parallel jobs; zero if run in serial; NULL uses the default parallelism.
See also DBMS_PARALLEL_EXECUTE.RUN_TASK.
**/

procedure ddl_batch_process;
/** Invokes DBMS_PARALLEL_EXECUTE to process GENERATE_DDL_SESSION_BATCHES for the current session. **/

procedure ddl_batch_process
( p_session_id in t_session_id_nn
, p_start_id in number
, p_end_id in number
);
/** Processes GENERATE_DDL_SESSION_BATCHES for this session within this range. **/

/**
Help functions to get the DDL belonging to a list of allowed objects returned by schema_objects_api.get_schema_objects().
**/

procedure get_schema_ddl
( p_schema_object_filter in oracle_tools.t_schema_object_filter
, p_transform_param_list in varchar2 default oracle_tools.pkg_ddl_defs.c_transform_param_list
);

procedure set_display_ddl_sql_args
( p_exclude_objects in clob
, p_include_objects in clob
);

procedure get_display_ddl_sql_args
( p_exclude_objects out nocopy dbms_sql.varchar2a
, p_include_objects out nocopy dbms_sql.varchar2a
);

procedure set_display_ddl_sql_args
( p_schema in t_schema_nn
, p_new_schema in t_schema
, p_sort_objects_by_deps in t_numeric_boolean_nn
, p_object_type in t_metadata_object_type
, p_object_names in t_object_names
, p_object_names_include in t_numeric_boolean /* OK (remote no copying of types) */
, p_network_link in t_network_link_nn
, p_grantor_is_schema in t_numeric_boolean_nn
, p_transform_param_list in varchar2
, p_exclude_objects in clob
, p_include_objects in clob
);

procedure set_display_ddl_sql_args_r
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
);

/**

Help procedure to store the results of display_ddl_schema on a remote database.
Must convert clob into dbms_sql.varchar2a since lobs can not be transferred via a database link.

**/

function get_display_ddl_sql
return oracle_tools.t_display_ddl_sql_tab
pipelined;

/**

Help procedure to retrieve the results of display_ddl_schema on a remote database.

Remark 1: Uses view v_display_ddl_sql because pipelined functions and a database link are not allowed.
Remark 2: A call to display_ddl_schema() with a database linke will invoke set_display_ddl_schema() at the remote database.

**/

procedure migrate_schema_ddl
( p_source in oracle_tools.t_schema_ddl
, p_target in oracle_tools.t_schema_ddl
, p_schema_ddl in out nocopy oracle_tools.t_schema_ddl
);

subtype t_md_object_type_tab is oracle_tools.t_text_tab;

/**

Return a list of DBMS_METADATA object types.

**/

procedure check_schema
( p_schema in t_schema
, p_network_link in t_network_link
, p_description in varchar2 default 'Schema'
);

procedure check_numeric_boolean
( p_numeric_boolean in pls_integer
, p_description in varchar2 
);

$if oracle_tools.cfg_pkg.c_testing $then

-- test functions
procedure get_source
( p_owner in varchar2
, p_object_type in varchar2
, p_object_name in varchar2
, p_line_tab out nocopy dbms_sql.varchar2a
, p_first out pls_integer
, p_last out pls_integer
);

procedure ut_cleanup_empty;

--%suitepath(DDL)
--%suite
--%rollback(manual)

--%beforeall
procedure ut_setup;

--%afterall
procedure ut_teardown;

--%test
--%disabled
procedure ut_display_ddl_schema_chk;

--%test
--%beforetest(oracle_tools.pkg_ddl_util.ut_cleanup_empty)
--%beforetest(oracle_tools.pkg_ddl_util.ut_disable_schema_export)
--%aftertest(oracle_tools.pkg_ddl_util.ut_enable_schema_export)
--%disabled
procedure ut_display_ddl_schema;

--%test
--%disabled
procedure ut_display_ddl_schema_diff_chk;

--%test
--%beforetest(oracle_tools.pkg_ddl_util.ut_cleanup_empty)
--%beforetest(oracle_tools.pkg_ddl_util.ut_disable_schema_export)
--%aftertest(oracle_tools.pkg_ddl_util.ut_enable_schema_export)
--%disabled
procedure ut_display_ddl_schema_diff;

--%test
procedure ut_object_type_order;

--%test
procedure ut_dict2metadata_object_type;

--%test
procedure ut_is_a_repeatable;

--%test
--%beforetest(oracle_tools.pkg_ddl_util.ut_cleanup_empty)
--%beforetest(oracle_tools.pkg_ddl_util.ut_disable_schema_export)
--%aftertest(oracle_tools.pkg_ddl_util.ut_enable_schema_export)
--%disabled
procedure ut_synchronize;

$if false $then

--%test
procedure ut_sort_objects_by_deps;

$end -- $if false $then

--%test
procedure ut_modify_ddl_text;

$end -- $if oracle_tools.cfg_pkg.c_testing $then

end pkg_ddl_util;
/

