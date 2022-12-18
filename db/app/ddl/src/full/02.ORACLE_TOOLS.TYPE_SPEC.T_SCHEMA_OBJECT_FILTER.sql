CREATE TYPE "ORACLE_TOOLS"."T_SCHEMA_OBJECT_FILTER" authid current_user as object
( schema$ varchar2(30 char)
, object_type$ varchar2(30 char)
, object_names$ varchar2(4000 char)
, object_names_include$ integer
, grantor_is_schema$ integer
, schema_object_info_include$ integer
-- set in constructor
, object_name_tab$ oracle_tools.t_text_tab
, schema_object_info_tab$ oracle_tools.t_text_tab
, constructor function t_schema_object_filter
  ( self in out nocopy oracle_tools.t_schema_object_filter
  , p_schema in varchar2 default user
  , p_object_type in varchar2 default null
  , p_object_names in varchar2 default null
  , p_object_names_include in integer default null
  , p_grantor_is_schema in integer default 0
  , p_schema_object_info in clob default null
  , p_schema_object_info_include in integer default null
  )
  return self as result
, member function schema return varchar2 deterministic
, member function object_type return varchar2 deterministic
, member function object_names return varchar2 deterministic
, member function object_names_include return integer deterministic
, member function grantor_is_schema return integer deterministic
, member function schema_object_info_include return integer deterministic
, member function object_name_tab return oracle_tools.t_text_tab deterministic
, member function schema_object_info_tab return oracle_tools.t_text_tab deterministic
, member procedure print
  ( self in oracle_tools.t_schema_object_filter
  )
  /**
   * Determine whether a schema object id matches a filter.
   *
   * The metadata object type is encoded as part 2 in the schema object id (colon separated list).
   * The object name is encoded as part 3 in the schema object id.
   * The metadata base object type is encoded as part 5 in the schema object id.
   * The base object name is encoded as part 6 in the schema object id.
   *
   * Rules:
   * <ol>
   * <li>A schema base object where is_exclude_name_expr() = 1: return 0</li>
   * <li>A schema object where is_exclude_name_expr() = 1: return 0</li>
   * <li>If metadata object type is not member of p_object_types_to_check: return 1</li>
   * <li>When schema_object_info_include$ is null and object_type$ is empty or equal to the metadata (base) object type and object_names_include$ is null or ((base) object name part of object_names$) = (object_names_include$): return 1</li>
   * <li>When schema_object_info_include$ is NOT null and (schema object id part of schema_object_info_tab$) = (schema_object_info_include$): return 1</li>
   * <li>Else: return 0</li>
   * </ol>
   *
   * @param p_object_types_to_check       A list of metadata object types to check for (null = check all).
   * @param p_schema_object_id            The schema object id.
   *
   */
, member function matches_schema_object
  ( p_object_types_to_check in oracle_tools.t_text_tab
  , p_schema_object_id in varchar2
  )
  return integer
  deterministic
, member function matches_schema_object
  ( p_object_types_to_check in oracle_tools.t_text_tab
    -- database values
  , p_schema_object in oracle_tools.t_schema_object
  )
  return integer
  deterministic
)
instantiable
final;
/

