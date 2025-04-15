declare
  -- ORA-00955: name is already used by an existing object
  e_object_already_exists exception;
  pragma exception_init(e_object_already_exists, -955);
begin
  execute immediate '
create global temporary table oracle_tools.tmp_export_apex (
  id           number,
  name         varchar2(1000),
  contents     clob
)
on commit preserve rows';
exception
  when e_object_already_exists
  then null;
end;
/
