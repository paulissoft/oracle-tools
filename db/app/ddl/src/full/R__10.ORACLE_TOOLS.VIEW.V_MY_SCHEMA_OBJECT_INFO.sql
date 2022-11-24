CREATE OR REPLACE VIEW "ORACLE_TOOLS"."V_MY_SCHEMA_OBJECT_INFO" ("OBJECT_SCHEMA", "OBJECT_TYPE", "OBJECT_NAME", "BASE_OBJECT_SCHEMA", "BASE_OBJECT_TYPE", "BASE_OBJECT_NAME", "COLUMN_NAME", "GRANTEE", "PRIVILEGE", "GRANTABLE")  BEQUEATH CURRENT_USER AS 
  select  t.object_schema() as object_schema
,       t.object_type() as object_type
,       t.object_name() as object_name
,       t.base_object_schema() as base_object_schema
,       t.base_object_type() as base_object_type
,       t.base_object_name() as base_object_name
,       t.column_name() as column_name
,       t.grantee() as grantee
,       t.privilege() as privilege
,       t.grantable() as grantable
from    table
        ( oracle_tools.pkg_ddl_util.get_schema_object
          ( oracle_tools.t_schema_object_filter
            ( p_schema => user
            , p_object_type => null
            , p_object_names => null
            , p_object_names_include => null
            , p_grantor_is_schema => 0
            )
          )
        ) t;

