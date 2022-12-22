CREATE OR REPLACE PACKAGE "ORACLE_TOOLS"."PKG_SCHEMA_OBJECT_FILTER" AUTHID DEFINER IS

c_debugging constant boolean := oracle_tools.pkg_ddl_util.c_debugging >= 1;

subtype t_schema_object_filter is oracle_tools.t_schema_object_filter;

/*
type t_schema_object_filter is record
( schema$ varchar2(30 char)
, grantor_is_schema$ integer
, objects_tab$ oracle_tools.t_text_tab
, objects_include$ integer
, objects_cmp_tab$ oracle_tools.t_text_tab
, match_partial_eq_complete integer
, match_count integer
, match_count_ok integer
);
*/

procedure construct
( p_schema in varchar2 default user
, p_object_type in varchar2 default null
, p_object_names in varchar2 default null
, p_object_names_include in integer default null
, p_grantor_is_schema in integer default 0
, p_objects in clob default null
, p_objects_include in integer default null
, p_schema_object_filter in out nocopy t_schema_object_filter
);

procedure print
( p_schema_object_filter in t_schema_object_filter
);

/**
 * Determine whether a schema object matches a filter (1).
 *
 * Rules:
 * <ol>
 * <li>A schema base object where is_exclude_name_expr() = 1: return 0</li>
 * <li>A schema object where is_exclude_name_expr() = 1: return 0</li>
 * <li>When p_schema_object_filter.objects_include$ is null: return 1</li>
 * <li>When (schema object PARTIALLY, e.g. just (BASE) TYPE and NAME fields, matches an element of p_schema_object_filter.objects_tab$) = (p_schema_object_filter.objects_include$): return 1</li>
 * <li>Else: return 0</li>
 * </ol>
 *
 * @param p_schema_object_filter
 * @param p_metadata_object_type
 * @param p_object_name
 * @param p_metadata_base_object_type
 * @param p_base_object_name
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
 * Determine whether a schema object matches a filter (1).
 *
 * Rules:
 * <ol>
 * <li>A schema base object where is_exclude_name_expr() = 1: return 0</li>
 * <li>A schema object where is_exclude_name_expr() = 1: return 0</li>
 * <li>When p_schema_object_filter.objects_include$ is null: return 1</li>
 * <li>When (schema object PARTIALLY or COMPLETELY matches an element of p_schema_object_filter.objects_tab$) = (p_schema_object_filter.objects_include$): return 1</li>
 * <li>Else: return 0</li>
 * </ol>
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
 * Rules:
 * <ol>
 * <li>A schema base object where is_exclude_name_expr() = 1: return 0</li>
 * <li>A schema object where is_exclude_name_expr() = 1: return 0</li>
 * <li>When p_schema_object_filter.objects_include$ is null: return 1</li>
 * <li>When (schema object COMPLETELY, i.e. all fields, matches an element of p_schema_object_filter.objects_tab$) = (p_schema_object_filter.objects_include$): return 1</li>
 * <li>Else: return 0</li>
 * </ol>
 *
 * @param p_schema_object_filter
 * @param p_schema_object            The schema object
 *
 */
function matches_schema_object
( p_schema_object_filter in t_schema_object_filter
, p_schema_object in oracle_tools.t_schema_object
)
return integer
deterministic;

procedure combine_named_dependent_objects
( p_schema_object_filter in t_schema_object_filter
, p_named_object_tab in oracle_tools.t_schema_object_tab
, p_dependent_object_tab in oracle_tools.t_schema_object_tab
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

$end -- $if oracle_tools.cfg_pkg.c_testing $then

end pkg_schema_object_filter;
/

