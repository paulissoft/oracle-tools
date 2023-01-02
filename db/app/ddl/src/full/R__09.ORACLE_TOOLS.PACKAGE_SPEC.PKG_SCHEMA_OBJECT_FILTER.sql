CREATE OR REPLACE PACKAGE "ORACLE_TOOLS"."PKG_SCHEMA_OBJECT_FILTER" AUTHID CURRENT_USER IS

c_debugging constant boolean := oracle_tools.pkg_ddl_util.c_debugging >= 3;

subtype t_schema_object_filter is oracle_tools.t_schema_object_filter;

/**
 *
 * How does filtering work?
 * First of all it is important to mention that Oracle's DBMS_METADATA distinguishes between:
 * <ul>
 * <li>named objects whose metadata can be returned by DBMS_METADATA.GET_DDL for instance</li>
 * <li>dependent objects (DBMS_METADATA.GET_DEPENDENT_DDL) that have as base object a named object</li>
 * <li>granted objects (DBMS_METADATA.GET_GRANTED_DDL) that have as base object a named object</li>
 * </ul>
 *
 * There are two methods:
 * <ol>
 * <li>the original PARTIAL method where you can specify an OBJECT TYPE and a list of OBJECT NAMEs. The OBJECT NAMEs should be the names of named objects, not dependent nor granted objects. So you can get DDL for a DEPENDENT or GRANTED object ONLY by specifying its BASE OBJECT NAME in the list of OBJECT NAMEs. The method is named PARTIAL since only (BASE) OBJECT TYPE and (BASE) OBJECT NAME are used to match.</li>
 * <li>the new COMPLETE method is more fine grained and works by specifying a unique identification for each named, dependent or granted object you want. So now you can just retrieve one constraint, not all constraints for a table. The unique identification is the static object type T_SCHEMA_OBJECT.ID() function. This method is named COMPLETE since all fields of an identification can be used, like COLUMN of a COMMENT, GRANTEE of an OBJECT_GRANT and so on.</li>
 * </ol>
 *
 * Currently the two methods can not be combined, although in principle it should be possible provided the include flags have the same value (when not empty).
 */

-- return objects like dbms_metadata.get_ddl would
function get_named_objects
( p_schema in varchar2
)
return oracle_tools.t_schema_object_tab
pipelined;

procedure default_match_perc_threshold
( p_match_perc_threshold in integer default 50
);

/**
 * The constructor for an oracle_tools.t_schema_object_filter object.
 *
 * @param p_schema                The schema to filter
 * @param p_object_type           The object type to filter (PARTIAL)
 * @param p_object_names          The object names to filter (PARTIAL)
 * @param p_object_names_include  Do we include (1) or exclude (0) objects for PARTIAL filtering? 
 *                                Must be NULL when there is no PARTIAL filtering.
 * @param p_grantor_is_schema     Must the grantor be equal to the schema, yes (1) or no (0)?
 * @param p_exclude_objects       A list of unique identification expressions to exclude where you can use O/S wild cards (* and ?).
 * @param p_include_objects       A list of unique identification expressions to include where you can use O/S wild cards (* and ?).
 * @param p_schema_object_filter  The object that stores all relevant info.
 */
procedure construct
( p_schema in varchar2 default user
, p_object_type in varchar2 default null
, p_object_names in varchar2 default null
, p_object_names_include in integer default null
, p_grantor_is_schema in integer default 0
, p_exclude_objects in clob default null
, p_include_objects in clob default null
, p_schema_object_filter in out nocopy t_schema_object_filter
);

procedure print
( p_schema_object_filter in t_schema_object_filter
);

/**
 * Determine whether a schema object matches a filter (2).
 *
 * This is used for PARTIALLY or COMPLETE matching. It depends on whether the
 * p_schema_object_id equals the T_SCHEMA_OBJECT.ID() of its part. If so it is
 * COMPLETE else PARTIAL.
 *
 * For a further description see the first overloaded function (but no SWITCH).
 *
 * @param p_schema_object_filter
 * @param p_schema_object_id         The schema object id
 */
function matches_schema_object
( p_schema_object_filter in t_schema_object_filter
, p_schema_object_id in varchar2
)
return integer
deterministic;

/**
* Get all the object info from several dictionary views.
* 
* These are the dictionary views:
* <ul>
* <li>ALL_QUEUE_TABLES</li>
* <li>ALL_MVIEWS</li>
* <li>ALL_TABLES</li>
* <li>ALL_OBJECTS</li>
* <li>ALL_TAB_PRIVS</li>
* <li>ALL_SYNONYMS</li>
* <li>ALL_TAB_COMMENTS</li>
* <li>ALL_MVIEW_COMMENTS</li>
* <li>ALL_COL_COMMENTS</li>
* <li>ALL_CONS_COLUMNS</li>
* <li>ALL_CONSTRAINTS</li>
* <li>ALL_TAB_COLUMNS</li>
* <li>ALL_TRIGGERS</li>
* <li>ALL_INDEXES</li>
* </ul>
*
* @param p_schema_object_filter  The schema object filter.
* @param p_schema_object_tab     Only applicable for the procedure variant. See the description for return.
*
* @return A list of object info records where every object will have p_schema as its object_schema except for public synonyms to objects of this schema since they will have object_schema PUBLIC.
*/
procedure get_schema_objects
( p_schema_object_filter in out nocopy oracle_tools.t_schema_object_filter 
, p_schema_object_tab out nocopy oracle_tools.t_schema_object_tab
);

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

