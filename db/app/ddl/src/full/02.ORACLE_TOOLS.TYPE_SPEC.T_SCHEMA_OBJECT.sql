CREATE TYPE "ORACLE_TOOLS"."T_SCHEMA_OBJECT" authid current_user as object
( network_link$ varchar2(128 char)
, object_schema$ varchar2(128 char)
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
-- end of getter(s)/setter(s)
, static function object_type_order
  ( p_object_type in varchar2
  )
  return integer deterministic
, final member function object_type_order return integer deterministic
, static function id
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
  return varchar2 deterministic
, member function id return varchar2 deterministic
, map member function signature return varchar2 deterministic
, static function dict2metadata_object_type
  ( p_dict_object_type in varchar2
  )
  return varchar2
  deterministic
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
  deterministic
, member function is_a_repeatable return integer deterministic
, final member function fq_object_name return varchar2 deterministic
, member function dict_object_type return varchar2 deterministic
, member procedure chk
  ( self in oracle_tools.t_schema_object
  , p_schema in varchar2
  )
, member function base_dict_object_type return varchar2 deterministic
)
not instantiable
not final
 alter type "ORACLE_TOOLS"."T_SCHEMA_OBJECT" add member function XYZ return varchar2 deterministic CASCADE
 alter type "ORACLE_TOOLS"."T_SCHEMA_OBJECT" DROP member function XYZ return varchar2 deterministic CASCADE
 alter type "ORACLE_TOOLS"."T_SCHEMA_OBJECT" add member function schema_object_info return varchar2 deterministic cascade;
/

