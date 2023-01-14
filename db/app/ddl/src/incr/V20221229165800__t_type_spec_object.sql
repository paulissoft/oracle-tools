begin
  for r in
  ( select  'drop type ' || object_name as cmd
    from    user_objects
    where   object_type = 'TYPE'
    and     object_name = 'T_TYPE_SPEC_DDL'
  )
  loop
    execute immediate r.cmd;
  end loop;

  execute immediate q'[
create type oracle_tools.t_type_spec_ddl authid current_user under oracle_tools.t_schema_ddl
( overriding member procedure migrate
  ( self in out nocopy oracle_tools.t_type_spec_ddl
  , p_source in oracle_tools.t_schema_ddl
  , p_target in oracle_tools.t_schema_ddl
  )
, overriding member procedure uninstall
  ( self in out nocopy oracle_tools.t_type_spec_ddl
  , p_target in oracle_tools.t_schema_ddl
  )
)
final]';

  execute immediate 'GRANT EXECUTE ON T_TYPE_SPEC_DDL TO PUBLIC';
end;
/
