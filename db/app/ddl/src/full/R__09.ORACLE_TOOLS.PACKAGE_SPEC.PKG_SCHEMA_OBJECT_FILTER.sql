CREATE OR REPLACE PACKAGE "ORACLE_TOOLS"."PKG_SCHEMA_OBJECT_FILTER" AUTHID DEFINER IS

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

/**
 * The constructor for an oracle_tools.t_schema_object_filter object.
 *
 * @param p_schema                The schema to filter
 * @param p_object_type           The object type to filter (PARTIAL)
 * @param p_object_names          The object names to filter (PARTIAL)
 * @param p_object_names_include  Do we include (1) or exclude (0) objects for PARTIAL filtering? 
 *                                Must be NULL when there is no PARTIAL filtering.
 * @param p_grantor_is_schema     Must the grantor be equal to the schema, yes (1) or no (0)?
 * @param p_include_objects               A list of unique identification expressions where you can use O/S wild cards (* and ?).
 *                                To be used by COMPLETE matching.
 * @param p_exclude_objects       Do we include (1) or exclude (0) objects for COMPLETE filtering? 
 * @param p_schema_object_filter  The object that stores all relevant info.
 */
procedure construct
( p_schema in varchar2 default user
, p_object_type in varchar2 default null
, p_object_names in varchar2 default null
, p_object_names_include in integer default null
, p_grantor_is_schema in integer default 0
, p_include_objects in clob default null
, p_exclude_objects in clob default null
, p_schema_object_filter in out nocopy t_schema_object_filter
);

procedure print
( p_schema_object_filter in t_schema_object_filter
);

/**
 * Determine whether a schema object matches a filter (1).
 *
 * This is only used for PARTIALLY matching.
 *
 * Rules:
 * <ol>
 * <li>A schema base object where ORACLE_TOOLS.PKG_DDL_UTIL.IS_EXCLUDE_NAME_EXPR() = 1: result is 0 (but see SWITCH below)</li>
 * <li>A schema object where ORACLE_TOOLS.PKG_DDL_UTIL.IS_EXCLUDE_NAME_EXPR() = 1: result is 0 (but see SWITCH below)</li>
 * <li>When p_schema_object_filter.objects_include$ is null: result is 1</li>
 * <li>When (the schema object id constructed from its four object parameters matches an element of p_schema_object_filter.objects_tab$) = (p_schema_object_filter.objects_include$): result is 1</li>
 * <li>Else: result is 0 (but see SWITCH below)</li>
 * </ol>
 *
 * Note SWITCH.
 * When the matching result is 0 and both p_metadata_base_object_type and
 * p_base_object_name are empty, the matching is tried again but now with the
 * base object name set to the original object name and all other object
 * parameters null.  This switch is necessary to find dependent or granted
 * objects whose base object matches one of the filters. If the switch result
 * is 1, it is marked (by setting
 * p_schema_object_filter.match_partial_eq_complete$ to 0) that the matching
 * for named objects must be re-executed (since it may have just been used to
 * get base objects for dependent/granted objects). That functionality is part
 * of COMBINE_NAMED_OTHER_OBJECTS().
 *
 * Please note that when the filter rules for PARTIAL and COMPLETE differ,
 * p_schema_object_filter.match_partial_eq_complete$ is already set to 0 in
 * the constructor. That implicates that all named objects in
 * COMBINE_NAMED_OTHER_OBJECTS() will be re-evaluated.
 *
 * @param p_schema_object_filter       The object that stores all relevant info.
 * @param p_metadata_object_type       The metadata object type (PACKAGE_BODY instead of PACKAGE BODY).
 * @param p_object_name                The object name.
 * @param p_metadata_base_object_type  The metadata base object type (PACKAGE_BODY instead of PACKAGE BODY).
 * @param p_base_object_name           The base object name.
 *
 */
function matches_schema_object
( p_schema_object_filter in out nocopy t_schema_object_filter
, p_metadata_object_type in varchar2
, p_object_name in varchar2
, p_metadata_base_object_type in varchar2 default null
, p_base_object_name in varchar2 default null
)
return integer
deterministic;

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
 * Determine whether a schema object matches a filter (3).
 *
 * For a further description see the first overloaded function (but no SWITCH,
 * nor checks for ORACLE_TOOLS.PKG_DDL_UTIL.IS_EXCLUDE_NAME_EXPR()).
 *
 * @param p_schema_object_filter
 * @param p_schema_object            The schema object
 */
function matches_schema_object
( p_schema_object_filter in t_schema_object_filter
, p_schema_object in oracle_tools.t_schema_object
)
return integer
deterministic;

/**
 * Combine named and other (dependent/granted) objects.
 *
 * In ORACLE_TOOLS.PKG_DDL_UTIL.GET_SCHEMA_OBJECT() there are two phases:
 * <ol>
 * <li>getting named objects that match the criteria (1a) or that can be used as base objects for dependent/granted objects (1b)</li>
 * <li>getting dependent/granted objects based on the named objects found</li>
 * </ol>
 *
 * In certain situations (1b for instance) but also when the filters for
 * COMPLETE matching are different from those for PARTIAL matching, we need to
 * re-evaluate the filtering for NAMED objects.
 * 
 * The union of the (re-evaluated) named objects and dependent/granted objects
 * is written to the output parameter.
 *
 * @param p_schema_object_filter
 * @param p_named_object_tab
 * @param p_other_object_tab
 * @param p_schema_object_tab
 */
procedure combine_named_other_objects
( p_schema_object_filter in t_schema_object_filter
, p_named_object_tab in oracle_tools.t_schema_object_tab
, p_other_object_tab in oracle_tools.t_schema_object_tab
, p_schema_object_tab out nocopy oracle_tools.t_schema_object_tab
);

$if oracle_tools.cfg_pkg.c_testing $then

-- test functions

--%suitepath(DDL)
--%suite

--%test
procedure ut_construct;

--%test
procedure ut_matches_schema_object;

--%test
procedure ut_compatible_le_oracle_11g;

$end -- $if oracle_tools.cfg_pkg.c_testing $then

end pkg_schema_object_filter;
/

