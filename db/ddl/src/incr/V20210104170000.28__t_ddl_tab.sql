begin
  execute immediate q'[
create type t_ddl_tab as table of t_ddl]';
end;
/
