CREATE OR REPLACE PROCEDURE "MSG_NOTIFICATION_PRC" 
( context raw
, reginfo sys.aq$_reg_info
, descr sys.aq$_descriptor
, payload raw
, payloadl number
) 
authid current_user
is
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT);
$end

  msg_aq_pkg.dequeue_and_process
  ( p_context => context
  , p_reginfo => reginfo
  , p_descr => descr
  , p_payload => payload
  , p_payloadl => payloadl
  , p_commit => true
  );

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end msg_notification_prc;
/

