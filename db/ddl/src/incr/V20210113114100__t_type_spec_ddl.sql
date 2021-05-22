begin
  execute immediate q'[
create type t_type_spec_ddl authid current_user under t_schema_ddl
( overriding member procedure migrate
  ( self in out nocopy t_type_spec_ddl
  , p_source in t_schema_ddl
  , p_target in t_schema_ddl
  )
)
final]';
end;
/
