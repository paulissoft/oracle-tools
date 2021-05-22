prompt (prepare_import.sql)

whenever sqlerror exit failure
whenever oserror exit failure

var workspace_name varchar2(100)
var application_id number

declare
  l_workspace_id number;
begin
  :workspace_name := '&1';
  :application_id := to_number('&2');

  select  workspace_id
  into    l_workspace_id
  from    apex_workspaces
  where   workspace = :workspace_name;
  
  apex_application_install.set_workspace_id(l_workspace_id);
  apex_application_install.set_application_id(:application_id);
  apex_application_install.generate_offset;
  apex_application_install.set_schema(user);
end;
/
