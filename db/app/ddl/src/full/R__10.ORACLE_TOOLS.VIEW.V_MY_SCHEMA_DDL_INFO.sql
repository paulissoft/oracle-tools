CREATE OR REPLACE FORCE VIEW "ORACLE_TOOLS"."V_MY_SCHEMA_DDL_INFO" ("OBJECT_SCHEMA", "OBJECT_TYPE", "OBJECT_NAME", "BASE_OBJECT_SCHEMA", "BASE_OBJECT_TYPE", "BASE_OBJECT_NAME", "COLUMN_NAME", "GRANTEE", "PRIVILEGE", "GRANTABLE", "DDL#", "VERB", "DDL_TEXT")  BEQUEATH CURRENT_USER AS 
  select  t.obj.object_schema() as object_schema
,       t.obj.object_type() as object_type
,       t.obj.object_name() as object_name
,       t.obj.base_object_schema() as base_object_schema
,       t.obj.base_object_type() as base_object_type
,       t.obj.base_object_name() as base_object_name
,       t.obj.column_name() as column_name
,       t.obj.grantee() as grantee
,       t.obj.privilege() as privilege
,       t.obj.grantable() as grantable
,       u.ddl#() as ddl#
,       u.verb() as verb
,       u.text as ddl_text
from    table
        ( oracle_tools.pkg_ddl_util.display_ddl_schema
          ( p_schema => user
          , p_new_schema => null
          , p_sort_objects_by_deps => 1
          , p_object_type => null
          , p_object_names => null
          , p_object_names_include => null
          , p_network_link => null
          , p_grantor_is_schema => 0
          , p_exclude_objects => null
          , p_include_objects => null
          )
        ) t
,       table(t.ddl_tab) u;

