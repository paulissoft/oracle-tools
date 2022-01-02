prompt (pre_import.sql)

set define on

whenever sqlerror exit failure
whenever oserror exit failure

prompt Set application status for id &&1

REMARK set by import.sql
-- set verify off

prompt call ui_apex_synchronize.pre_import(to_number('&&1'))

begin
  ui_apex_synchronize.pre_import(to_number('&&1'));
end;
/

prompt ...done

undefine 1
