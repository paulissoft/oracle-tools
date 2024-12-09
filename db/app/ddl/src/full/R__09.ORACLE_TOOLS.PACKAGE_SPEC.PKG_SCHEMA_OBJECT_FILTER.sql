CREATE OR REPLACE PACKAGE "ORACLE_TOOLS"."PKG_SCHEMA_OBJECT_FILTER" AUTHID CURRENT_USER IS

c_debugging constant boolean := oracle_tools.pkg_ddl_util.c_debugging >= 3;

-- subtype t_schema_object_filter is oracle_tools.t_schema_object_filter;

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
The unique identification is the static object type T_SCHEMA_OBJECT.GET_ID() function.
This method is named COMPLETE since all fields of an identification can be used, like COLUMN of a COMMENT, GRANTEE of an OBJECT_GRANT and so on.

These two methods can be combined.

**/

procedure construct
( p_schema in varchar2 default user -- The schema to filter
, p_object_type in varchar2 default null -- The object type to filter (PARTIAL)
, p_object_names in varchar2 default null -- The object names to filter (PARTIAL)
, p_object_names_include in integer default null -- Do we include (1) or exclude (0) objects for PARTIAL filtering? NULL when there is no PARTIAL filtering.
, p_grantor_is_schema in integer default 0 -- Must the grantor be equal to the schema, yes (1) or no (0)?
, p_exclude_objects in clob default null -- A list of unique identification expressions to exclude where you can use O/S wild cards (* and ?).
, p_include_objects in clob default null -- A list of unique identification expressions to include where you can use O/S wild cards (* and ?).
, p_schema_object_filter in out nocopy oracle_tools.t_schema_object_filter -- The object that stores all relevant info.
);

/**
 
The constructor for an oracle_tools.t_schema_object_filter object.

**/

procedure matches_schema_object
( p_schema_object_filter in oracle_tools.t_schema_object_filter -- The schema object filter
, p_schema_object_id in varchar2 -- The schema object id
, p_result out nocopy integer -- The result (null = ignore object, 0 = false, 1 = true)
, p_details out nocopy varchar2 -- A varchar2(1000 char) should be enough
);

function matches_schema_object
( p_schema_object_filter in oracle_tools.t_schema_object_filter -- The schema object filter
, p_schema_object_id in varchar2 -- The schema object id
)
return integer -- The result (null = ignore object, 0 = false, 1 = true)
deterministic;
/** Does the schema object id match the schema object filter? **/

procedure serialize
( p_schema_object_filter in oracle_tools.t_schema_object_filter
, p_json_object in out nocopy json_object_t
);
/** Serialize the schema object filter to a JSON object. **/

procedure chk
( p_schema_object_filter in oracle_tools.t_schema_object_filter
);

procedure print
( p_schema_object_filter in oracle_tools.t_schema_object_filter
);
/**

Print the JSON representation of a schema object filter using the DBUG package.

**/

$if oracle_tools.cfg_pkg.c_testing $then

-- test functions

--%suitepath(DDL)
--%suite

--%test
procedure ut_construct;

--%test;
procedure ut_matches_schema_object;

$end -- $if oracle_tools.cfg_pkg.c_testing $then

end pkg_schema_object_filter;
/

