CREATE OR REPLACE PROCEDURE "DATA_ROW_NOTIFICATION_PRC" 
( context raw
, reginfo sys.aq$_reg_info
, descr sys.aq$_descriptor
, payload raw
, payloadl number
) 
authid current_user
is
  l_message_properties dbms_aq.message_properties_t;
  l_message oracle_tools.data_row_t;
  l_msgid raw(16);
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT);
$end

  oracle_tools.data_dml_event_mgr_pkg.dequeue_notification
  ( p_context => context
  , p_reginfo => reginfo
  , p_descr => descr
  , p_payload => payload
  , p_payloadl => payloadl
  , p_message_properties => l_message_properties
  , p_message => l_message
  , p_msgid => l_msgid
  );

  l_message.print;
  commit;

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end;
/

