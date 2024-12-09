CREATE OR REPLACE PACKAGE "ORACLE_TOOLS"."SCHEMA_OBJECTS_API" AUTHID CURRENT_USER IS /* -*-coding: utf-8-*- */

/**
This package is used to get objects from the dictionary with current user authentication.

[This documentation is in PLOC format](https://github.com/ogobrecht/ploc)
**/

c_tracing constant boolean := oracle_tools.pkg_ddl_util.c_debugging >= 1;
c_debugging constant boolean := oracle_tools.pkg_ddl_util.c_debugging >= 3;
c_use_ddl_batch_process constant boolean := true;

-- Some duplicate code, see DDL_CRUD_API but for the time being okay.
subtype t_session_id is integer;
subtype t_session_id_nn is t_session_id not null;  

procedure add
( p_schema_object_filter in oracle_tools.t_schema_object_filter -- the schema object filter
, p_generate_ddl_configuration_id in integer -- the GENERATE_DDL_CONFIGURATIONS.ID
, p_add_schema_objects in boolean default true -- create records for table GENERATE_DDL_SESSION_SCHEMA_OBJECTS (and its parent tables SCHEMA_OBJECTS and SCHEMA_OBJECT_FILTER_RESULTS)?
);
/**

Steps:
1. invoke DDL_CRUD_API.ADD(p_schema_object_filter, p_generate_ddl_configuration_id)
2. add schema objects (when the parameter is true) matching the schema object filter using DDL_CRUD_API.ADD(p_schema_object_tab, p_schema_object_filter_id, p_schema_object_filter) for:
   a. named objects -- no base object
   b. object grants -- base object (using named objects from step 2a)
   c. synonyms      -- base object (idem)
   d. comments      -- base object (idem)
   e. constraints   -- base object (idem)
   f. triggers      -- base object (idem)
   g. indexes       -- base object (idem)

**/

procedure get_schema_objects
( p_schema_object_filter in oracle_tools.t_schema_object_filter
, p_generate_ddl_configuration_id in integer -- the GENERATE_DDL_CONFIGURATIONS.ID
, p_schema_object_tab out nocopy oracle_tools.t_schema_object_tab
);
/**
Get the schema objects and return them as a table.

Steps:
1. invoke ADD(p_schema_object_filter, p_generate_ddl_configuration_id, p_add_schema_objects)
2. get all rows from V_MY_SCHEMA_OBJECTS and put them in p_schema_object_tab
**/

function get_schema_objects
( p_schema in varchar2 default user
, p_object_type in varchar2 default null
, p_object_names in varchar2 default null
, p_object_names_include in integer default null
, p_grantor_is_schema in integer default 0
, p_exclude_objects in clob default null
, p_include_objects in clob default null
, p_transform_param_list in varchar2 default null
)
return oracle_tools.t_schema_object_tab
pipelined;
/**
Get the schema objects and return them as a pipelined function.

Steps:
1. Invoke DDL_CRUD_API.ADD(p_schema, p_object_type, p_object_names, p_object_names_include, p_grantor_is_schema, p_exclude_objects, p_include_objects, p_transform_param_list, p_schema_object_filter, p_generate_ddl_configuration_id)
2. invoke ADD(p_schema_object_filter, p_generate_ddl_configuration_id, p_add_schema_objects)
3. get all rows from V_MY_SCHEMA_OBJECTS and output them

**/

function get_schema_objects
( p_session_id in t_session_id_nn
)
return oracle_tools.t_schema_object_tab
pipelined;
/** Returns information about schema objects (to generate DDL for) for this session. Will **NOT** generate, just read from cache. **/

procedure ddl_batch_process
( p_session_id in t_session_id_nn -- The current session id.
, p_start_id in number -- The start number (V_DEPENDENT_OR_GRANTED_OBJECT_TYPES.NR).
, p_end_id in number -- The end number (V_DEPENDENT_OR_GRANTED_OBJECT_TYPES.NR).
);
/** Get schema objects for entries in V_DEPENDENT_OR_GRANTED_OBJECT_TYPES. **/

$if oracle_tools.cfg_pkg.c_testing $then

-- test functions

--%suitepath(DDL)
--%suite

--%test
procedure ut_get_schema_objects;

--%test
procedure ut_get_schema_object_filter;

$end -- $if oracle_tools.cfg_pkg.c_testing $then

END SCHEMA_OBJECTS_API;
/

