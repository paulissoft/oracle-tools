CREATE OR REPLACE PACKAGE BODY "ADMIN_SCHEDULER_PKG" AS

procedure stop_job 
( p_job_name in varchar2
, p_force in boolean
, p_commit_semantics in varchar2
)
is
  l_session_id all_scheduler_running_jobs.session_id%type;
begin
  begin
    select  r.session_id
    into    l_session_id
    from    all_scheduler_jobs j
            left outer join all_scheduler_running_jobs r -- need not be there
            on r.owner = j.owner and r.job_name = j.job_name
    where   j.owner = sys_context('USERENV', 'SESSION_USER')
    and     j.job_name = p_job_name;
  exception
    when no_data_found
    then
      l_session_id := null;
  end;
  
  dbms_scheduler.stop_job(job_name => sys_context('USERENV', 'SESSION_USER') || '.' || p_job_name, force => p_force, commit_semantics => p_commit_semantics);

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
)
is
  l_session_id all_scheduler_running_jobs.session_id%type;
begin
  begin
    select  r.session_id
    into    l_session_id
    from    all_scheduler_jobs j
            left outer join all_scheduler_running_jobs r -- need not be there
            on r.owner = j.owner and r.job_name = j.job_name
    where   j.owner = sys_context('USERENV', 'SESSION_USER')
    and     j.job_name = p_job_name;
  exception
    when no_data_found
    then
      l_session_id := null;

  dbms_scheduler.drop_job(job_name => sys_context('USERENV', 'SESSION_USER') || '.' || p_job_name, force => p_force, defer => p_defer, commit_semantics => p_commit_semantics);

  if l_session_id is not null
  then
    admin_system_pkg.kill_session(p_sid => l_session_id);
  end if;
end drop_job;

end admin_scheduler_pkg;
/
