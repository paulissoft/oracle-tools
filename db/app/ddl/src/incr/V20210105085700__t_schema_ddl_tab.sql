begin
  execute immediate q'[
create type t_schema_ddl_tab as table of t_schema_ddl]';
end;
/
