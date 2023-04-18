CREATE OR REPLACE PACKAGE BODY "ADMIN_SCHEDULER_PKG" AS

procedure stop_job 
( p_job_name in varchar2
, p_force in boolean
, p_commit_semantics in varchar2
, p_owner in varchar2
)
is
  l_owner all_scheduler_running_jobs.owner%type;
  l_session_id all_scheduler_running_jobs.session_id%type;
begin
  begin
    select  r.owner
    ,       r.session_id
    into    l_owner
    ,       l_session_id
    from    all_scheduler_jobs j
            left outer join all_scheduler_running_jobs r -- need not be there
            on r.owner = j.owner and r.job_name = j.job_name
    where   r.owner = p_owner
    and     ( sys_context('USERENV', 'SESSION_USER') in ( p_owner, $$PLSQL_UNIT_OWNER ) -- User may kill its own jobs, ADMIN may kill anything
              or
              sys_context('USERENV', 'ISDBA') = 'TRUE' -- DBA too
            ) 
    and     j.job_name = p_job_name;
  exception
    when no_data_found
    then
      l_session_id := null;
  end;
  
  dbms_scheduler.stop_job(job_name => l_owner || '.' || p_job_name, force => p_force, commit_semantics => p_commit_semantics);

  if l_session_id is not null
  then
    admin_system_pkg.kill_session(p_sid => l_session_id);
  end if;
end stop_job;

procedure drop_job
( p_job_name in varchar2
, p_force in boolean
, p_defer in boolean
, p_commit_semantics in varchar2
, p_owner in varchar2
)
is
  l_owner all_scheduler_running_jobs.owner%type;
  l_session_id all_scheduler_running_jobs.session_id%type;
begin
  begin
    select  r.owner
    ,       r.session_id
    into    l_owner
    ,       l_session_id
    from    all_scheduler_jobs j
            left outer join all_scheduler_running_jobs r -- need not be there
            on r.owner = j.owner and r.job_name = j.job_name
    where   r.owner = p_owner
    and     ( sys_context('USERENV', 'SESSION_USER') in ( p_owner, $$PLSQL_UNIT_OWNER ) -- User may kill its own jobs, ADMIN may kill anything
              or
              sys_context('USERENV', 'ISDBA') = 'TRUE' -- DBA too
            ) 
    and     j.job_name = p_job_name;
  exception
    when no_data_found
    then
      l_session_id := null;
  end;    

  dbms_scheduler.drop_job(job_name => l_owner || '.' || p_job_name, force => p_force, defer => p_defer, commit_semantics => p_commit_semantics);

  if l_session_id is not null
  then
    admin_system_pkg.kill_session(p_sid => l_session_id);
  end if;
end drop_job;

end admin_scheduler_pkg;
/
