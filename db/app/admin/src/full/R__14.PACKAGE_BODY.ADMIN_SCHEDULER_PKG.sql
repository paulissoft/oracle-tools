CREATE OR REPLACE PACKAGE BODY "ADMIN_SCHEDULER_PKG" AS

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
  and     ( sys_context('USERENV', 'SESSION_USER') in ( p_owner, $$PLSQL_UNIT_OWNER ) -- User may kill its own jobs, ADMIN may kill anything
            or
            sys_context('USERENV', 'ISDBA') = 'TRUE' -- DBA too
          ) 
  and     j.job_name = p_job_name;

exception
  when no_data_found
  then
    raise_application_error
    ( -20000
    , utl_lms.format_message
      ( 'Could not find job %s.%s for unit owner %s, context SESSION_USER %s and ISDBA %s'
      , p_owner
      , p_job_name
      , $$PLSQL_UNIT_OWNER
      , sys_context('USERENV', 'SESSION_USER')
      , sys_context('USERENV', 'ISDBA')
      )
    , true
    );
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
  get_session_id(p_owner, p_job_name, l_session_id);

  dbms_scheduler.stop_job(job_name => '"' || p_owner || '"."' || p_job_name || '"', force => p_force, commit_semantics => p_commit_semantics);

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
  l_session_id all_scheduler_running_jobs.session_id%type;
begin
  get_session_id(p_owner, p_job_name, l_session_id);

  dbms_scheduler.drop_job(job_name => '"' || p_owner || '"."' || p_job_name || '"', force => p_force, defer => p_defer, commit_semantics => p_commit_semantics);

  if l_session_id is not null
  then
    admin_system_pkg.kill_session(p_sid => l_session_id);
  end if;
end drop_job;

end admin_scheduler_pkg;
/
