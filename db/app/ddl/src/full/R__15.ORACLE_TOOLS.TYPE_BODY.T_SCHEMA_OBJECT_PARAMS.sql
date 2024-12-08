CREATE OR REPLACE TYPE BODY "ORACLE_TOOLS"."T_SCHEMA_OBJECT_PARAMS" AS

overriding
member procedure serialize
( self in oracle_tools.t_schema_object_params
, p_json_object in out nocopy json_object_t
)
is
begin
  p_json_object.put('SCHEMA_OBJECT_FILTER_ID', self.schema_object_filter_id);
end serialize;

end;
/

