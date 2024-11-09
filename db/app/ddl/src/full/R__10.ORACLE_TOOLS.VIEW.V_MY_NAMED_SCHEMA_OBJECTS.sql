CREATE OR REPLACE FORCE /* v_my_schema_objects will be created later */ VIEW "ORACLE_TOOLS"."V_MY_NAMED_SCHEMA_OBJECTS" BEQUEATH CURRENT_USER AS
select  treat(t.obj as oracle_tools.t_named_object) as obj
from    oracle_tools.v_my_schema_objects t
where   t.obj is of (oracle_tools.t_named_object);

