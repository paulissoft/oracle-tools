CREATE OR REPLACE FORCE EDITIONABLE VIEW "ORACLE_TOOLS"."V_MY_CONSTRAINT_OBJECTS" OF "ORACLE_TOOLS"."T_CONSTRAINT_OBJECT"
WITH OBJECT IDENTIFIER (network_link$, object_schema$, object_name$) AS 
select  treat(t.obj as t_constraint_object)
from    all_schema_objects t
where   t.audsid = sys_context('USERENV', 'SESSIONID')
and     t.obj is of (t_constraint_object);
