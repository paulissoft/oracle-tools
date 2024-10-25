CREATE OR REPLACE FORCE EDITIONABLE VIEW "ORACLE_TOOLS"."V_MY_NAMED_OBJECTS" OF "ORACLE_TOOLS"."T_NAMED_OBJECT"
WITH OBJECT IDENTIFIER (network_link$, object_schema$, object_name$) AS 
select  treat(t.obj as t_named_object)
from    all_schema_objects t
where   t.audsid = sys_context('USERENV', 'SESSIONID')
and     t.obj is of (t_named_object);
