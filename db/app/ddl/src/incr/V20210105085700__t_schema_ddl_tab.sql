begin
  execute immediate q'[
create type oracle_tools.t_schema_ddl_tab as table of oracle_tools.t_schema_ddl]';
end;
/
