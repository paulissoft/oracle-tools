CREATE TYPE "ORACLE_TOOLS"."T_SCHEMA_OBJECT_FILTER" AUTHID CURRENT_USER UNDER T_OBJECT_JSON
( schema$ varchar2(30 char)
, grantor_is_schema$ integer
, op_object_id_expr_tab$ oracle_tools.t_text_tab
  /** Each entry a combination of a compare operator (first two characters) and an object id expression (from position 4 onwards). **/
, nr_objects_to_exclude$ integer
  /** The first N entries in op_object_id_expr_tab$ are exclude operators. **/
, constructor function t_schema_object_filter
  ( self in out nocopy oracle_tools.t_schema_object_filter
  , p_schema in varchar2 default user
  , p_object_type in varchar2 default null
  , p_object_names in varchar2 default null
  , p_object_names_include in integer default null
  , p_grantor_is_schema in integer default 0
  , p_exclude_objects in clob default null
  , p_include_objects in clob default null
  )
  return self as result
  -- getters/setters
, member function schema return varchar2 deterministic
, member function grantor_is_schema return integer deterministic
, member function nr_objects_to_exclude return integer deterministic
, member function nr_objects return integer deterministic
, member function op(p_idx in integer) return varchar2 deterministic
  /** Returns substr(op_object_id_expr_tab$(p_idx), 1, 2). **/
, member function object_id_expr(p_idx in integer) return varchar2 deterministic
  /** Returns substr(op_object_id_expr_tab$(p_idx), 4). **/
  -- end of getters/setters
, static function ops return oracle_tools.t_text_tab deterministic
  /** Returns oracle_tools.t_text_tab('!~', '!=', ' ~', ' ='). **/
, member function op_order(p_idx in integer) return integer deterministic
  /** Returns case op(p_idx) when '!~' then 1 when '!=' then 2 when ' ~' then 3 when ' =' then 4 end. **/
, member function matches_schema_object
  ( self in oracle_tools.t_schema_object_filter
  , p_schema_object_id in varchar2
  )
  return integer
  deterministic
, member procedure chk
  ( self in oracle_tools.t_schema_object_filter
  )
, overriding  
  member procedure serialize
  ( self in oracle_tools.t_schema_object_filter
  , p_json_object in out nocopy json_object_t
  )
)
instantiable
final;
/

