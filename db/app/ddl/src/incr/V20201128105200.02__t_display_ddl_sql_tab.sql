begin
  execute immediate q'[
create type oracle_tools.t_display_ddl_sql_tab as table of oracle_tools.t_display_ddl_sql_rec]';
end;
/
