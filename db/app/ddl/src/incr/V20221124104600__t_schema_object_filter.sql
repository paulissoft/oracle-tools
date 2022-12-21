begin
  execute immediate q'[
CREATE TYPE "ORACLE_TOOLS"."T_SCHEMA_OBJECT_FILTER" authid current_user as object
( schema$ varchar2(30 char)
, grantor_is_schema$ integer
, objects_tab$ oracle_tools.t_text_tab
, objects_include$ integer
, objects_cmp_tab$ oracle_tools.t_text_tab
, constructor function t_schema_object_filter
  ( self in out nocopy oracle_tools.t_schema_object_filter
  , p_schema in varchar2 default user
  , p_object_type in varchar2 default null
  , p_object_names in varchar2 default null
  , p_object_names_include in integer default null
  , p_grantor_is_schema in integer default 0
  , p_objects in clob default null
  , p_objects_include in integer default null
  )
  return self as result
, member function schema return varchar2 deterministic
, member function grantor_is_schema return integer deterministic
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
   * <li>When objects_include$ is null: return 1</li>
   * <li>When (schema object id equals or matches an element of objects_tab$) = (objects_include$): return 1</li>
   * <li>Else: return 0</li>
   * </ol>
   *
   * @param p_object_types_to_check       A list of metadata object types to check for (null = check all).
   * @param p_schema_object_id            The schema object id.
   *
   */
, member function matches_schema_object
  ( p_object_types_to_check in oracle_tools.t_text_tab
    -- database values
  , p_metadata_object_type in varchar2
  , p_object_name in varchar2
  , p_metadata_base_object_type in varchar2 default null
  , p_base_object_name in varchar2 default null
  )
  return integer
  deterministic
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
final]';
end;
/
