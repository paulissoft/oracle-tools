CREATE OR REPLACE VIEW "ORACLE_TOOLS"."V_FETCH_DDL" ("DDLTEXT", "ITEM", "VALUE", "OBJECT_ROW") AS 
select  t.ddltext
,       o.item
,       o.value
,       o.object_row
from    table(oracle_tools.pkg_ddl_util.fetch_ddl) t
,       table(t.parseditems) o;
