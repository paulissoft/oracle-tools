begin
  execute immediate q'[
create type oracle_tools.t_schema_object authid current_user as object
( id varchar2(500 byte) /* the unique id, formerly the id() member function */
, last_ddl_time$ date
, network_link$ varchar2(128 byte)
, object_schema$ varchar2(128 byte)
-- begin of getter(s)/setter(s)
, final member function network_link return varchar2 deterministic
, final member procedure network_link
  ( self in out nocopy oracle_tools.t_schema_object
  , p_network_link in varchar2
  )
, final member function object_schema return varchar2 deterministic
, final member procedure object_schema
  ( self in out nocopy oracle_tools.t_schema_object
  , p_object_schema in varchar2
  )
, not instantiable member function object_type return varchar2 deterministic
, member function object_name return varchar2 deterministic
, member function base_object_schema return varchar2 deterministic
, member procedure base_object_schema
  ( self in out nocopy oracle_tools.t_schema_object
  , p_base_object_schema in varchar2
  )
, member function base_object_type return varchar2 deterministic
, member function base_object_name return varchar2 deterministic
, member function column_name return varchar2 deterministic
, member function grantee return varchar2 deterministic
, member function privilege return varchar2 deterministic
, member function grantable return varchar2 deterministic
, final member procedure last_ddl_time
  ( self in out nocopy oracle_tools.t_schema_object
  , p_last_ddl_time in date
  ) -- a setter for last_ddl_time$
, final member function last_ddl_time return date -- a getter for last_ddl_time$
-- end of getter(s)/setter(s)
, static function object_type_order
  ( p_object_type in varchar2
  )
  return integer deterministic /*result_cache*/
, final member function object_type_order return integer deterministic
, static function get_id
  ( p_object_schema in varchar2
  , p_object_type in varchar2
  , p_object_name in varchar2 default null
  , p_base_object_schema in varchar2 default null
  , p_base_object_type in varchar2 default null
  , p_base_object_name in varchar2 default null
  , p_column_name in varchar2 default null
  , p_grantee in varchar2 default null
  , p_privilege in varchar2 default null
  , p_grantable in varchar2 default null
  )
  return varchar2 deterministic /*result_cache*/
, static procedure normalize
  ( p_schema_object in out nocopy oracle_tools.t_schema_object
  ) -- sets id and last_ddl_time$
, map member function signature return varchar2 deterministic
, static function dict2metadata_object_type
  ( p_dict_object_type in varchar2
  )
  return varchar2
  deterministic /*result_cache*/
, final member function dict2metadata_object_type return varchar2 deterministic
, member procedure print
  ( self in oracle_tools.t_schema_object
  )
, static procedure create_schema_object
  ( p_object_schema in varchar2
  , p_object_type in varchar2
  , p_object_name in varchar2 default null
  , p_base_object_schema in varchar2 default null
  , p_base_object_type in varchar2 default null
  , p_base_object_name in varchar2 default null
  , p_column_name in varchar2 default null
  , p_grantee in varchar2 default null
  , p_privilege in varchar2 default null
  , p_grantable in varchar2 default null
  , p_schema_object out nocopy oracle_tools.t_schema_object
  )
, static function create_schema_object
  ( p_object_schema in varchar2
  , p_object_type in varchar2
  , p_object_name in varchar2 default null
  , p_base_object_schema in varchar2 default null
  , p_base_object_type in varchar2 default null
  , p_base_object_name in varchar2 default null
  , p_column_name in varchar2 default null
  , p_grantee in varchar2 default null
  , p_privilege in varchar2 default null
  , p_grantable in varchar2 default null
  )
  return oracle_tools.t_schema_object
, static function is_a_repeatable
  ( p_object_type in varchar2
  )
  return integer
  deterministic /*result_cache*/
, member function is_a_repeatable return integer deterministic
, final member function fq_object_name return varchar2 deterministic
, static function dict_object_type
  ( p_object_type in varchar2
  )
  return varchar2
  deterministic /*result_cache*/
, member function dict_object_type return varchar2 deterministic
, member procedure chk
  ( self in oracle_tools.t_schema_object
  , p_schema in varchar2
  )
, member function base_dict_object_type return varchar2 deterministic
, member function schema_object_info return varchar2 deterministic 
, static function split_id
  ( p_id in varchar2
  )
  return oracle_tools.t_text_tab deterministic
, static function join_id
  ( p_id_parts in oracle_tools.t_text_tab
  )
  return varchar2 deterministic
, final static function dict_last_ddl_time
  ( p_object_schema in varchar2
  , p_dict_object_type in varchar2
  , p_object_name in varchar2
  )
  return date
, member function dict_last_ddl_time return date -- get dictionary last_ddl_time, usually all_objects.last_ddl_time
, static function ddl_batch_order
  ( p_object_type in varchar2
  )
  return varchar2
  deterministic /*result_cache*/
, final member function ddl_batch_order return varchar2 deterministic /*result_cache*/
)
not instantiable
not final]';
end;
/
