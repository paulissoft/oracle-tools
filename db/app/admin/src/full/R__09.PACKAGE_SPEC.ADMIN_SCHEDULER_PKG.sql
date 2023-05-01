CREATE OR REPLACE PACKAGE "ADMIN_SCHEDULER_PKG" AUTHID DEFINER AS 

/**
This package contains various DBMS_SCHEDULER stop and drop routines that:
- will only work for the current session (or for the package owner or a DBA) AND
- will really kill the attached job session as is not obvious when a session is waiting, for instance on DBMS_AQ.LISTEN.

The session user is the value of sys_context('USERENV', 'SESSION_USER').
Whether the session user is DBA is determined by sys_context('USERENV', 'ISDBA') = 'TRUE'.
The job session can be retrieved from:

```
select  r.session_id
from    all_scheduler_running_jobs r
where   r.owner = p_owner
and     ( sys_context('USERENV', 'SESSION_USER') in ( p_owner, $$PLSQL_UNIT_OWNER ) -- User may kill its own jobs, ADMIN may kill anything
          or
          sys_context('USERENV', 'ISDBA') = 'TRUE' -- DBA too
        ) 
and     r.job_name = p_job_name
``

See also [Killing Oracle Sessions (ALTER SYSTEM KILL / DISCONNECT SESSION)](https://oracle-base.com/articles/misc/killing-oracle-sessions).
**/

procedure stop_job 
( p_job_name in varchar2
, p_force in boolean default false
, p_commit_semantics in varchar2 default 'STOP_ON_FIRST_ERROR'
, p_owner in varchar2 default sys_context('USERENV', 'SESSION_USER')
);
/**
Invokes DBMS_SCHEDULER.STOP_JOB() when the job name is a running job for the session user.
It will also kill the session using ADMIN_SYSTEM_PKG.KILL_SESSION(), if any.
**/
   
procedure drop_job
( p_job_name in varchar2
, p_force in boolean default false
, p_defer in boolean default false
, p_commit_semantics in varchar2 default 'STOP_ON_FIRST_ERROR'
, p_owner in varchar2 default sys_context('USERENV', 'SESSION_USER')
);
/**
Invokes DBMS_SCHEDULER.DROP_JOB() when the job name is a job for the session user.
It will also kill the session using ADMIN_SYSTEM_PKG.KILL_SESSION(), if any.
**/

end admin_scheduler_pkg;
/
