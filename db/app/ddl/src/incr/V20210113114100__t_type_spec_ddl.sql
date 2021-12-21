begin
  execute immediate q'[
create type oracle_tools.t_type_spec_ddl authid current_user under oracle_tools.t_schema_ddl
( overriding member procedure migrate
  ( self in out nocopy oracle_tools.t_type_spec_ddl
  , p_source in oracle_tools.t_schema_ddl
  , p_target in oracle_tools.t_schema_ddl
  )
)
final]';
end;
/
