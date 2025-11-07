prompt (prepare_import.sql)

whenever sqlerror exit failure
whenever oserror exit failure

prompt call ui_apex_synchronize.prepare_import(p_workspace_name => upper('&1'), p_application_id => to_number('&2'), p_application_alias => '&3')

begin
  ui_apex_synchronize.prepare_import(p_workspace_name => upper('&1'), p_application_id => to_number('&2'), p_application_alias => '&3');
end;
/

prompt ...done
