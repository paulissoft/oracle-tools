begin
  execute immediate q'[
create type t_index_ddl authid current_user under t_schema_ddl
( overriding member procedure migrate
  ( self in out nocopy t_index_ddl
  , p_source in t_schema_ddl
  , p_target in t_schema_ddl
  )
, overriding
  member procedure execute_ddl
  ( self in t_index_ddl
  )
)
final]';
end;
/
