CREATE OR REPLACE FORCE VIEW "ORACLE_TOOLS"."V_MY_OBJECT_GRANTS_DICT" BEQUEATH CURRENT_USER AS 
  select  p.table_schema as base_object_schema
,       p.table_name as base_object_name
,       p.grantee
,       p.privilege
        -- several grantors may have executed the same grant statement
,       max(p.grantable) as grantable -- YES comes after NO
from    all_tab_privs p
        inner join oracle_tools.v_my_schema_object_filter sof
        on sof.schema = p.table_schema and ( sof.grantor_is_schema = 0 or p.grantor = sof.schema )
group by
        p.table_schema
,       p.table_name
,       p.grantee
,       p.privilege;
