prompt (publish_application.sql)

whenever sqlerror exit failure

-- precondition: prepare_import.sql must have been called
set serveroutput on size unlimited format trunc
set feedback off termout on

prompt call ui_apex_synchronize.publish_application

begin
  ui_apex_synchronize.publish_application;
end;
/

prompt ...done
