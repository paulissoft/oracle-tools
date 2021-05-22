begin
  execute immediate q'[
create type t_schema_object_tab as table of t_schema_object]';
end;
/
