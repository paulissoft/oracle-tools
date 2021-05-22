begin
  execute immediate q'[
create type t_argument_object_tab as table of t_argument_object]';
end;
/
