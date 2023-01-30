CREATE OR REPLACE PROCEDURE "DATA_ROW_NOTIFICATION_PRC" 
( context raw
, reginfo sys.aq$_reg_info
, descr sys.aq$_descriptor
, payload raw
, payloadl number
) 
authid current_user
is
  l_dequeue_options dbms_aq.dequeue_options_t;
  l_message_properties dbms_aq.message_properties_t;
  l_message_handle raw(16);
  l_message oracle_tools.data_row_t;
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT);
$end

  l_dequeue_options.msgid := descr.msg_id;
  l_dequeue_options.consumer_name := descr.consumer_name;
  dbms_aq.dequeue
  ( queue_name => descr.queue_name
  , dequeue_options => l_dequeue_options
  , message_properties => l_message_properties
  , payload => l_message
  , msgid => l_message_handle
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

