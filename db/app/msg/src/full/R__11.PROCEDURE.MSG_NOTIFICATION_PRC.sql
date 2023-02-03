CREATE OR REPLACE PROCEDURE "MSG_NOTIFICATION_PRC" 
( context raw
, reginfo sys.aq$_reg_info
, descr sys.aq$_descriptor
, payload raw
, payloadl number
) 
authid current_user
is
  l_message_properties dbms_aq.message_properties_t;
  l_msg msg_typ;
  l_msgid raw(16);
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT);
$end

  msg_aq_pkg.dequeue_notification
  ( p_context => context
  , p_reginfo => reginfo
  , p_descr => descr
  , p_payload => payload
  , p_payloadl => payloadl
  , p_msgid => l_msgid
  , p_message_properties => l_message_properties
  , p_msg => l_msg
  );

  begin
    savepoint spt;
    
    l_msg.process(p_msg_just_created => 0);
  exception
    when others
    then
      rollback to spt;
  end;
  
  commit; -- remove message from the queue

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

