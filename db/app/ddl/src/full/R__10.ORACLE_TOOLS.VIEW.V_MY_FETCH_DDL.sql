CREATE OR REPLACE VIEW "ORACLE_TOOLS"."V_MY_FETCH_DDL" ("DDL#", "DDLTEXT", "ITEM", "VALUE", "OBJECT_ROW")  BEQUEATH CURRENT_USER AS 
  with src as (
  select  rownum as ddl#
  ,       t.*
  from    table
          ( oracle_tools.pkg_ddl_util.fetch_ddl
            ( p_schema_object_filter =>
                oracle_tools.t_schema_object_filter
                ( p_schema => user
                , p_object_type => null
                , p_object_names => null
                , p_object_names_include => null
                )
            , p_use_schema_export => 1
            , p_schema_object_tab => null
            , p_transform_param_list => null
            )
          ) t
)
select  t.ddl#
,       t.ddltext
,       o.item
,       o.value
,       o.object_row
from    src t
,       table(t.parseditems) o;

