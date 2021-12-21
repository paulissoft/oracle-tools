begin
  execute immediate q'[
create type oracle_tools.t_argument_object_tab as table of oracle_tools.t_argument_object]';
end;
/
