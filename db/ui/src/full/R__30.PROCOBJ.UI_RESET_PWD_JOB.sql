declare
  l_job_name constant varchar2(100) := 'UI_RESET_PWD_JOB';
  
  -- ORA-27477: "TOOLS"."UI_RESET_PWD_JOB" already exists
  e_job_exists exception;
  pragma exception_init(e_job_exists, -27477);
begin
  <<try_loop>>
  for i_try in 1..2
  loop
    begin
      dbms_scheduler.create_job
      ( job_name => l_job_name -- this name is also used in UI_USER_MANAGEMENT_PKG
      , job_type => 'STORED_PROCEDURE'
      , job_action => 'UI_USER_MANAGEMENT_PKG.RESET_PASSWORD'
      , number_of_arguments => 4
      , enabled => false
      );
      exit try_loop;
    exception
      when e_job_exists
      then
        if i_try = 1
        then
          dbms_scheduler.drop_job( job_name => l_job_name );
        else
          raise;
        end if;
    end;
  end loop try_loop;
end;
/
