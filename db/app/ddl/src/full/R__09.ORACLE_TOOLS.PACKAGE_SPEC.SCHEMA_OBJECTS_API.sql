CREATE OR REPLACE PACKAGE "ORACLE_TOOLS"."SCHEMA_OBJECTS_API" AUTHID DEFINER IS /* -*-coding: utf-8-*- */

c_tracing constant boolean := oracle_tools.pkg_ddl_util.c_debugging >= 1;
c_debugging constant boolean := oracle_tools.pkg_ddl_util.c_debugging >= 3;

type t_schema_object_rec is record
( obj oracle_tools.t_schema_object
);

type t_schema_object_cursor is ref cursor return t_schema_object_rec;
   
function get_last_schema_object_filter_id
return number;

procedure add
( p_schema_object_filter in oracle_tools.schema_object_filters.obj%type
, p_add_schema_objects in boolean default true
, p_schema_object_filter_id out nocopy oracle_tools.schema_object_filters.id%type
);
/** Add a record to table schema_object_filters and optionally all schema objects. **/

procedure add
( p_schema_object in oracle_tools.all_schema_objects.obj%type -- The schema object to add to ALL_SCHEMA_OBJECTS
, p_must_exist in boolean default null -- p_must_exist: TRUE - must exist (UPDATE); FALSE - must NOT exist (INSERT); NULL - don't care (UPSERT)
, p_schema_object_filter_id in oracle_tools.all_schema_objects.schema_object_filter_id%type default null -- If null, the last from schema_object_filters for this session is used
);
/** Add a schema object to ALL_SCHEMA_OBJECTS, meaning INSERT, UPDATE OR UPSERT. */

procedure add
( p_schema_object_cursor in t_schema_object_cursor -- The schema objects to add to ALL_SCHEMA_OBJECTS
, p_must_exist in boolean default null -- p_must_exist: TRUE - must exist (UPDATE); FALSE - must NOT exist (INSERT); NULL - don't care (UPSERT)
, p_schema_object_filter_id in oracle_tools.all_schema_objects.schema_object_filter_id%type default null -- If null, the last from schema_object_filters for this session is used
);
/** Add schema objects to ALL_SCHEMA_OBJECTS, meaning INSERT, UPDATE OR UPSERT. */

function find_by_seq
( p_seq in all_schema_objects.seq%type default 1 -- Find schema object in ALL_SCHEMA_OBJECTS by (schema_object_filter_id, seq)
, p_schema_object_filter_id in oracle_tools.all_schema_objects.schema_object_filter_id%type default null -- If null, the last from schema_object_filters for this session is used
)
return all_schema_objects%rowtype;
/** Find the schema object in ALL_SCHEMA_OBJECTS by seq. **/

function find_by_object_id
( p_id in varchar2 -- Find schema object in ALL_SCHEMA_OBJECTS by (schema_object_filter_id, obj.id())
, p_schema_object_filter_id in oracle_tools.all_schema_objects.schema_object_filter_id%type default null -- If null, the last from schema_object_filters for this session is used
)
return all_schema_objects%rowtype;
/** Find the schema object in ALL_SCHEMA_OBJECTS by obj.id(). **/

function get_named_objects
( p_schema in varchar2
, p_schema_object_filter_id in number
)
return oracle_tools.t_schema_object_tab
pipelined;

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

function get_schema_objects
( p_schema_object_filter_id in number default null -- If null, the last from schema_object_filters for this session is used
)
return varchar2 sql_macro;
/**

Get all rows from ALL_SCHEMA_OBJECTS with schema_object_filter_id equal to p_schema_object_filter_id (if not null) or the last for this session (if null).

Usage: select * from schema_objects_api.get_schema_objects(null)

**/

procedure default_match_perc_threshold
( p_match_perc_threshold in integer
);

function match_perc
( p_schema_object_filter_id in number default null
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

