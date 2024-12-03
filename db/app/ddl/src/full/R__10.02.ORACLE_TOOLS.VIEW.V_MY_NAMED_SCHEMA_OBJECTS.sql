CREATE OR REPLACE FORCE VIEW "ORACLE_TOOLS"."V_MY_NAMED_SCHEMA_OBJECTS" OF "ORACLE_TOOLS"."T_NAMED_OBJECT"
  WITH OBJECT IDENTIFIER ("ID") BEQUEATH CURRENT_USER  AS 
  select  treat(value(t) as oracle_tools.t_named_object)
from    oracle_tools.v_my_schema_objects t
where   value(t) is of (oracle_tools.t_named_object);

