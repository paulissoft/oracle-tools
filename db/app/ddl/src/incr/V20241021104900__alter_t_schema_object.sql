alter type oracle_tools.t_schema_object
  add final member function network_link_udf return varchar2 cascade;

alter type oracle_tools.t_schema_object
  add final member function object_schema_udf return varchar2 cascade;

alter type oracle_tools.t_schema_object
  add final member function object_type_udf return varchar2 cascade;

alter type oracle_tools.t_schema_object
  add final member function object_name_udf return varchar2 cascade;

alter type oracle_tools.t_schema_object
  add final member function base_object_schema_udf return varchar2 cascade;

alter type oracle_tools.t_schema_object
  add final member function base_object_type_udf return varchar2 cascade;

alter type oracle_tools.t_schema_object
  add final member function base_object_name_udf return varchar2 cascade;

alter type oracle_tools.t_schema_object
  add final member function column_name_udf return varchar2 cascade;

alter type oracle_tools.t_schema_object
  add final member function grantee_udf return varchar2 cascade;

alter type oracle_tools.t_schema_object
  add final member function privilege_udf return varchar2 cascade;

alter type oracle_tools.t_schema_object
  add final member function grantable_udf return varchar2 cascade;

alter type oracle_tools.t_schema_object
  add final member function object_type_order_udf return integer cascade;

alter type oracle_tools.t_schema_object
  add final member function id_udf return varchar2 cascade;

alter type oracle_tools.t_schema_object
  add final member function dict2metadata_object_type_udf return varchar2 cascade;

alter type oracle_tools.t_schema_object
  add final member function is_a_repeatable_udf return integer cascade;

alter type oracle_tools.t_schema_object
  add final member function fq_object_name_udf return varchar2 cascade;

alter type oracle_tools.t_schema_object
  add final member function dict_object_type_udf return varchar2 cascade;

alter type oracle_tools.t_schema_object
  add final member function base_dict_object_type_udf return varchar2 cascade;

alter type oracle_tools.t_schema_object
  add final member function schema_object_info_udf return varchar2 cascade;

