prompt (post_import.sql)

set define on

whenever sqlerror exit failure
whenever oserror exit failure

prompt Set application status for id &&1

REMARK set by import.sql but maybe overwritten by the application script
set verify off

call ui_apex_synchronize.post_import(to_number('&1'));

undefine 1
