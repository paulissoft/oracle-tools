-- &1 workspace name
-- &2 application id
-- &3 update language mapping (optional, defaults to 0 - false)
-- &4 seed and publish (optional, defaults to 1 - true)

prompt (pre_export_no_connect.sql)

whenever sqlerror exit failure

prompt call ui_apex_synchronize.pre_export(upper('&&1'), to_number('&2'), to_number(nvl('&3', '0')) != 0, to_number(nvl('&4', '0')) != 0)

begin
  ui_apex_synchronize.pre_export(upper('&&1'), to_number('&2'), to_number(nvl('&3', '0')) != 0, to_number(nvl('&4', '1')) != 0);
end;
/

prompt ...done

undefine 1 2
