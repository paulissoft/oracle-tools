CREATE OR REPLACE VIEW "ORACLE_TOOLS"."V_MY_FETCH_DDL" ("DDL#", "DDLTEXT", "ITEM", "VALUE", "OBJECT_ROW") AS 
with src as (
  select  rownum as ddl#
  ,       t.*
  from    table
          ( oracle_tools.pkg_ddl_util.fetch_ddl
            ( p_schema => user
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
