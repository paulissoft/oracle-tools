begin
  dbms_scheduler.drop_job('MSG_AQ_PKG$PROCESSING_SUPERVISOR', force => true);
exception
  when others
  then null;
end;
/

begin
  dbms_scheduler.drop_job('DEQUEUE_AND_PROCESS', force => true);
exception
  when others
  then null;
end;
/

begin
  dbms_scheduler.drop_program(program_name => 'PROCESSING', force => true);
exception
  when others
  then null;
end;
/

begin
  dbms_scheduler.drop_program(program_name => 'PROCESSING_SUPERVISOR', force => true);
exception
  when others
  then null;
end;
/

begin
  dbms_scheduler.drop_schedule(schedule_name => 'SCHEDULE_SUPERVISOR', force => true);
exception
  when others
  then null;
end;
/
