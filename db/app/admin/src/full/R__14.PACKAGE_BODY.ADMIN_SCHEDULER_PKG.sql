CREATE OR REPLACE PACKAGE BODY "ADMIN_SCHEDULER_PKG" AS

procedure check_current_user_has_privileges
( p_owner in varchar2
)
is
begin
  if ( sys_context('USERENV', 'SESSION_USER') in ( p_owner, $$PLSQL_UNIT_OWNER ) -- User may kill its own jobs, ADMIN may kill anything
       or
       sys_context('USERENV', 'ISDBA') = 'TRUE' -- DBA too
     )
  then null;
  else raise_application_error
       ( c_current_user_has_no_privileges
       , utl_lms.format_message
         ( 'This user (%s) has only privileges to manager jobs in schemas %s or %s (context ISDBA: %s)'
         , sys_context('USERENV', 'SESSION_USER')
         , p_owner
         , $$PLSQL_UNIT_OWNER
         , sys_context('USERENV', 'ISDBA')
         )
       );
  end if;     
end check_current_user_has_privileges;

procedure get_session_id
( p_owner in varchar2
, p_job_name in varchar2
, p_session_id out nocopy all_scheduler_running_jobs.session_id%type
)
is
begin
  select  r.session_id
  into    p_session_id
  from    all_scheduler_jobs j
          left outer join all_scheduler_running_jobs r -- need not be there
          on r.owner = j.owner and r.job_name = j.job_name
  where   j.owner = p_owner
  and     j.job_name = p_job_name;
end;

-- PUBLIC

function get_session_id
( p_owner in varchar2
, p_job_name in varchar2
)
return all_scheduler_running_jobs.session_id%type
is
  l_session_id all_scheduler_running_jobs.session_id%type;
begin
  get_session_id
  ( p_owner
  , p_job_name
  , l_session_id
  );
  return l_session_id;
end;

procedure stop_job 
( p_job_name in varchar2
, p_force in boolean
, p_commit_semantics in varchar2
, p_owner in varchar2
)
is
  l_session_id all_scheduler_running_jobs.session_id%type;
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  oracle_tools.dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'STOP_JOB');
  oracle_tools.dbug.print
  ( oracle_tools.dbug."info"
  , 'p_job_name: %s; p_force: %s; p_commit_semantics: %s; p_owner: %s'
  , p_job_name
  , oracle_tools.dbug.cast_to_varchar2(p_force)
  , p_commit_semantics
  , p_owner
  );
$end

  check_current_user_has_privileges(p_owner);

  begin
    dbms_scheduler.stop_job(job_name => '"' || p_owner || '"."' || p_job_name || '"', force => p_force, commit_semantics => p_commit_semantics);
$if oracle_tools.cfg_pkg.c_debugging $then
  exception
    when others
    then
      for r in
      ( select  j.state
        from    all_scheduler_jobs j      
        where   j.owner = p_owner
        and     j.job_name = p_job_name
      )
      loop
        oracle_tools.dbug.print(oracle_tools.dbug."warning", 'job: "%s"."%s"; state: "%s"', p_owner, p_job_name, r.state); 
      end loop;
      raise;
$end      
  end;

  begin
    get_session_id(p_owner, p_job_name, l_session_id);

    if l_session_id is not null
    then
      admin_system_pkg.kill_session(p_sid => l_session_id);
    end if;
  exception
    when no_data_found
    then null;
  end;  

$if oracle_tools.cfg_pkg.c_debugging $then
  oracle_tools.dbug.leave;
exception
  when others
  then
    oracle_tools.dbug.leave_on_error;
    raise;
$end  
end stop_job;

procedure drop_job
( p_job_name in varchar2
, p_force in boolean
, p_defer in boolean
, p_commit_semantics in varchar2
, p_owner in varchar2
)
is
  l_session_id all_scheduler_running_jobs.session_id%type;
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  oracle_tools.dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'DROP_JOB');
  oracle_tools.dbug.print
  ( oracle_tools.dbug."info"
  , 'p_job_name: %s; p_force: %s; p_defer: %s; p_commit_semantics: %s; p_owner: %s'
  , p_job_name
  , oracle_tools.dbug.cast_to_varchar2(p_force)
  , oracle_tools.dbug.cast_to_varchar2(p_defer)
  , p_commit_semantics
  , p_owner
  );
$end

  check_current_user_has_privileges(p_owner);

  begin
    dbms_scheduler.drop_job(job_name => '"' || p_owner || '"."' || p_job_name || '"', force => p_force, defer => p_defer, commit_semantics => p_commit_semantics);
$if oracle_tools.cfg_pkg.c_debugging $then
  exception
    when others
    then
      for r in
      ( select  j.state
        from    all_scheduler_jobs j      
        where   j.owner = p_owner
        and     j.job_name = p_job_name
      )
      loop
        oracle_tools.dbug.print(oracle_tools.dbug."warning", 'job: "%s"."%s"; state: "%s"', p_owner, p_job_name, r.state); 
      end loop;
      raise;
$end
  end;

  begin
    get_session_id(p_owner, p_job_name, l_session_id);

    if l_session_id is not null
    then
      admin_system_pkg.kill_session(p_sid => l_session_id);
    end if;
  exception
    when no_data_found
    then null;
  end;  

$if oracle_tools.cfg_pkg.c_debugging $then
  oracle_tools.dbug.leave;
exception
  when others
  then
    oracle_tools.dbug.leave_on_error;
    raise;
$end  
end drop_job;

end admin_scheduler_pkg;
/
