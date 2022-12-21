begin
  execute immediate q'[
create type oracle_tools.t_schema_object_filter authid current_user as object
( schema$ varchar2(30 char)
, object_type$ varchar2(30 char)
, object_names$ varchar2(4000 char)
, object_names_include$ integer
, grantor_is_schema$ integer
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
  )
  return self as result
, member function schema return varchar2 deterministic
, member function object_type return varchar2 deterministic
, member function object_names return varchar2 deterministic
, member function object_names_include return integer deterministic
, member function grantor_is_schema return integer deterministic
, member function object_name_tab return oracle_tools.t_text_tab deterministic
, member function schema_object_info_tab return oracle_tools.t_text_tab deterministic
, member procedure print
  ( self in oracle_tools.t_schema_object_filter
  )
  /**
   * Determine whether a schema object matches a filter.
   *
   * Rules:
   * <ol>
   * <li>A schema base object where is_exclude_name_expr() = 1: return 0</li>
   * <li>A schema object where is_exclude_name_expr() = 1: return 0</li>
   * <li>If p_metadata_object_type is not member of p_object_types_to_check: return 1</li>
   * <li>When object_type$ is empty or equal to the (base) object type and the combination of p_object_name and object_names_include$ matches object_names$: return 1</li>
   * <li>Else: return 0</li>
   * </ol>
   *
   * @param p_object_types_to_check       A list of metadata object types to check for (null = check all).
   * @param p_metadata_object_type        The schema object type (metadata).
   * @param p_object_name                 The schema object name.
   * @param p_metadata_base_object_type   The schema base object type (metadata).
   * @param p_base_object_name            The schema base object name.
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
