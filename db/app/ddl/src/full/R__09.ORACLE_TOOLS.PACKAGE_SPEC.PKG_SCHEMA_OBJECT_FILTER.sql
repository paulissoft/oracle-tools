CREATE OR REPLACE PACKAGE "ORACLE_TOOLS"."PKG_SCHEMA_OBJECT_FILTER" AUTHID CURRENT_USER IS

c_debugging constant boolean := oracle_tools.pkg_ddl_util.c_debugging >= 3;

subtype t_schema_object_filter is oracle_tools.t_schema_object_filter;

/**

This package is used to filter the schema objects. With the resulting list DDL can be retrieved by PKG_DDL_UTIL.

How does filtering work? 

First of all it is important to mention that Oracle's DBMS_METADATA distinguishes between:
- named objects whose metadata can be returned by DBMS_METADATA.GET_DDL for instance
- dependent objects (DBMS_METADATA.GET_DEPENDENT_DDL) that have as base object a named object
- granted objects (DBMS_METADATA.GET_GRANTED_DDL) that have as base object a named object

There are two methods:
1. the original PARTIAL method where you can specify an OBJECT TYPE and a list of OBJECT NAMEs. 
The OBJECT NAMEs should be the names of named objects, not dependent nor granted objects. 
So you can get DDL for a DEPENDENT or GRANTED object ONLY by specifying its BASE OBJECT TYPE and/or BASE OBJECT NAME in the list of OBJECT NAMEs.
The method is named PARTIAL since only (BASE) OBJECT TYPE and (BASE) OBJECT NAME are used to match.
2. the new COMPLETE method is more fine grained and works by specifying a unique identification for each named, dependent or granted object you want to include or exclude.
So now you can just retrieve one constraint, not all constraints for a table.
The unique identification is the static object type T_SCHEMA_OBJECT.ID() function.
This method is named COMPLETE since all fields of an identification can be used, like COLUMN of a COMMENT, GRANTEE of an OBJECT_GRANT and so on.

These two methods can be combined.

**/

function get_named_objects
( p_schema in varchar2
)
return oracle_tools.t_schema_object_tab
pipelined;

/**

Return objects like dbms_metadata.get_ddl() would.

**/

procedure default_match_perc_threshold
( p_match_perc_threshold in integer default 50
);

procedure construct
( p_schema in varchar2 default user -- The schema to filter
, p_object_type in varchar2 default null -- The object type to filter (PARTIAL)
, p_object_names in varchar2 default null -- The object names to filter (PARTIAL)
, p_object_names_include in integer default null -- Do we include (1) or exclude (0) objects for PARTIAL filtering? NULL when there is no PARTIAL filtering.
, p_grantor_is_schema in integer default 0 -- Must the grantor be equal to the schema, yes (1) or no (0)?
, p_exclude_objects in clob default null -- A list of unique identification expressions to exclude where you can use O/S wild cards (* and ?).
, p_include_objects in clob default null -- A list of unique identification expressions to include where you can use O/S wild cards (* and ?).
, p_schema_object_filter in out nocopy t_schema_object_filter -- The object that stores all relevant info.
);

/**
 
The constructor for an oracle_tools.t_schema_object_filter object.

**/

procedure print
( p_schema_object_filter in t_schema_object_filter
);

/**

Print the JSON representation of a schema object filter using the DBUG package.

**/

function matches_schema_object
( p_schema_object_filter in t_schema_object_filter
, p_schema_object_id in varchar2
)
return integer
deterministic;

/**

Determine whether a schema object matches a filter.

**/

procedure get_schema_objects
( p_schema_object_filter in out nocopy oracle_tools.t_schema_object_filter -- The schema object filter.
, p_schema_object_tab out nocopy oracle_tools.t_schema_object_tab
);

/**

Get all the object info from several dictionary views.

A list of object info records where every object will have p_schema as its object_schema except for public synonyms to objects of this schema since they will have object_schema PUBLIC.
 
These are the dictionary views:

- ALL_QUEUE_TABLES
- ALL_MVIEWS
- ALL_TABLES
- ALL_OBJECTS
- ALL_TAB_PRIVS
- ALL_SYNONYMS
- ALL_TAB_COMMENTS
- ALL_MVIEW_COMMENTS
- ALL_COL_COMMENTS
- ALL_CONS_COLUMNS
- ALL_CONSTRAINTS
- ALL_TAB_COLUMNS
- ALL_TRIGGERS
- ALL_INDEXES

**/

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

/**

Constructs a schema object filter based on the input parameters, then invokes the procedure get_schema_objects and returns the objects found.

**/

$if oracle_tools.cfg_pkg.c_testing $then

-- test functions

--%suitepath(DDL)
--%suite

--%test
procedure ut_construct;

--%test
procedure ut_matches_schema_object;

--%test
procedure ut_get_schema_objects;

--%test
procedure ut_get_schema_object_filter;

--%test
procedure ut_compatible_le_oracle_11g;

$end -- $if oracle_tools.cfg_pkg.c_testing $then

end pkg_schema_object_filter;
/

