begin
  execute immediate q'[
create type oracle_tools.t_synonym_ddl authid current_user under oracle_tools.t_schema_ddl
( overriding member procedure uninstall
  ( self in out nocopy oracle_tools.t_synonym_ddl
  , p_target in oracle_tools.t_schema_ddl
  )
)
final]';
end;
/
