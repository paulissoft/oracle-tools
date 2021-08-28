CREATE OR REPLACE VIEW "ORACLE_TOOLS"."V_OBJECT_DEPENDENCIES" AS 
SELECT  t.owner
,       t.type
,       t.name
,       t.referenced_owner
,       t.referenced_type
,       t.referenced_name
from    table(oracle_tools.pkg_ddl_util.get_object_dependencies(user)) t;

