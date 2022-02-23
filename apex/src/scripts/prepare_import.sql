prompt (prepare_import.sql)

whenever sqlerror exit failure
whenever oserror exit failure

prompt call ui_apex_synchronize.prepare_import(upper('&1'), to_number('&2'))

begin
  ui_apex_synchronize.prepare_import(upper('&1'), to_number('&2'));
end;
/

prompt ...done
