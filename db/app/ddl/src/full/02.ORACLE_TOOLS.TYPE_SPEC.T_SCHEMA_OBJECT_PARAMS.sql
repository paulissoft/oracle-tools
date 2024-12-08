CREATE TYPE "ORACLE_TOOLS"."T_SCHEMA_OBJECT_PARAMS" AUTHID CURRENT_USER UNDER "ORACLE_TOOLS"."T_OBJECT_JSON"
( schema_object_filter_id integer
, overriding
  member procedure serialize
  ( self in oracle_tools.t_schema_object_params
  , p_json_object in out nocopy json_object_t
  )
)
instantiable
final;
/

