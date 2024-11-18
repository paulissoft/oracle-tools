CREATE OR REPLACE PACKAGE "ORACLE_TOOLS"."SCHEMA_OBJECTS_API" AUTHID CURRENT_USER IS /* -*-coding: utf-8-*- */

c_tracing constant boolean := oracle_tools.pkg_ddl_util.c_debugging >= 1;
c_debugging constant boolean := oracle_tools.pkg_ddl_util.c_debugging >= 3;

type t_schema_object_rec is record
( obj oracle_tools.t_schema_object
);

type t_schema_object_cursor is ref cursor return t_schema_object_rec;

type t_schema_ddl_rec is record
( session_id generate_ddl_session_schema_objects.session_id%type -- key #1 from GENERATE_DDL_SESSION_SCHEMA_OBJECTS$UK$1 
, schema_object_id generate_ddl_session_schema_objects.schema_object_id%type -- key #2 from GENERATE_DDL_SESSION_SCHEMA_OBJECTS$UK$1 
, ddl oracle_tools.t_schema_ddl
);

type t_schema_ddl_cursor is ref cursor return t_schema_ddl_rec;

subtype t_session_id is generate_ddl_session_schema_objects.session_id%type;
   
procedure set_session_id
( p_session_id in t_session_id
);
/** Set the session id for saving/retrieving on GENERATE_DDL_SESSIONS and GENERATE_DDL_SESSION_SCHEMA_OBJECTS. **/

function get_session_id
return t_session_id;
/** Get the session id for saving/retrieving on GENERATE_DDL_SESSIONS and GENERATE_DDL_SESSION_SCHEMA_OBJECTS. **/

procedure add
( p_schema_object_filter in oracle_tools.t_schema_object_filter -- the schema object filter
, p_add_schema_objects in boolean default true -- create records for table GENERATE_DDL_SESSION_SCHEMA_OBJECTS (and its parent tables SCHEMA_OBJECTS and SCHEMA_OBJECT_FILTER_RESULTS)?
, p_session_id in t_session_id default get_session_id
);
/** Add a record to table GENERATE_DDL_SESSIONS (and its parent SCHEMA_OBJECT_FILTERS). **/

procedure add
( p_schema_object in oracle_tools.t_schema_object -- The schema object to add to GENERATE_DDL_SESSION_SCHEMA_OBJECTS
, p_session_id in t_session_id default get_session_id
, p_ignore_dup_val_on_index in boolean default true
);
/** Add a schema object to GENERATE_DDL_SESSION_SCHEMA_OBJECTS, meaning INSERT, UPDATE OR UPSERT. */

procedure add
( p_schema_object_cursor in t_schema_object_cursor -- The schema objects to add to GENERATE_DDL_SESSION_SCHEMA_OBJECTS
, p_session_id in t_session_id default get_session_id
, p_ignore_dup_val_on_index in boolean default true
);
/** Add schema objects to GENERATE_DDL_SESSION_SCHEMA_OBJECTS, meaning INSERT, UPDATE OR UPSERT. */

procedure add
( p_schema_ddl in oracle_tools.t_schema_ddl
, p_session_id in t_session_id default get_session_id
);
/** Update the record in table GENERATE_DDL_SESSION_SCHEMA_OBJECTS. **/

procedure add
( p_schema_ddl_tab in oracle_tools.t_schema_ddl_tab
, p_session_id in t_session_id default get_session_id
);
/** Update the record in table GENERATE_DDL_SESSION_SCHEMA_DDLS. **/

procedure add
( p_schema in varchar2
, p_transform_param_list in varchar2
, p_object_schema in varchar2
, p_object_type in varchar2
, p_base_object_schema in varchar2
, p_base_object_type in varchar2
, p_object_name_tab in oracle_tools.t_text_tab
, p_base_object_name_tab in oracle_tools.t_text_tab
, p_nr_objects in integer
, p_session_id in t_session_id default get_session_id
);
/** Update the record in table GENERATE_DDL_SESSION_SCHEMA_DDL_BATCHES. **/

function find_schema_object_by_seq
( p_seq in integer default 1 -- Find schema object in GENERATE_DDL_SESSION_SCHEMA_OBJECTS by (schema_object_filter_id, seq)
, p_session_id in t_session_id default get_session_id
)
return generate_ddl_session_schema_objects%rowtype;
/** Find the schema object in GENERATE_DDL_SESSION_SCHEMA_OBJECTS by seq. **/

function find_schema_object_by_object_id
( p_schema_object_id in varchar2 -- Find schema object in GENERATE_DDL_SESSION_SCHEMA_OBJECTS by (schema_object_filter_id, obj.id())
, p_session_id in t_session_id default get_session_id
)
return generate_ddl_session_schema_objects%rowtype;
/** Find the schema object in GENERATE_DDL_SESSION_SCHEMA_OBJECTS by obj.id(). **/

function get_schema_objects
( p_schema in varchar2 default user
, p_object_type in varchar2 default null
, p_object_names in varchar2 default null
, p_object_names_include in integer default null
, p_grantor_is_schema in integer default 0
, p_exclude_objects in clob default null
, p_include_objects in clob default null
)
return oracle_tools.t_schema_object_tab
pipelined;

procedure get_schema_objects
( p_schema_object_filter in oracle_tools.t_schema_object_filter
, p_schema_object_tab out nocopy oracle_tools.t_schema_object_tab
);

procedure default_match_perc_threshold
( p_match_perc_threshold in integer
);

function match_perc
( p_session_id in t_session_id default get_session_id
)
return integer
deterministic;

function match_perc_threshold
return integer
deterministic;

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

