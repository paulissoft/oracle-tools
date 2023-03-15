CREATE OR REPLACE PACKAGE "MSG_SCHEDULER_PKG" AUTHID DEFINER AS 

c_job_already_running simple_integer := -20200;
e_job_already_running exception;
pragma exception_init(e_job_already_running, -20200);
c_job_already_running_msg constant varchar2(2000 char) := 'Job "%s" is already running.';

c_there_are_running_jobs simple_integer := c_job_already_running - 1;
e_there_are_running_jobs exception;
pragma exception_init(e_there_are_running_jobs, -20201);
c_there_are_running_jobs_msg constant varchar2(2000 char) := 'There should be no running jobs matching "%s" but these are running:%s';

c_unexpected_job_state simple_integer := c_job_already_running - 2;
e_unexpected_job_state exception;
pragma exception_init(e_unexpected_job_state, -20202);
c_unexpected_job_state_msg constant varchar2(2000 char) := 'Unexpected state for job "%s": "%s"';

c_unexpected_command simple_integer := c_job_already_running - 3;
e_unexpected_command exception;
pragma exception_init(e_unexpected_command, -20203);
c_unexpected_command_msg constant varchar2(2000 char) := 'Unexpected command: "%s"';

c_one_parameter_not_null simple_integer := c_job_already_running - 4;
e_one_parameter_not_null exception;
pragma exception_init(e_one_parameter_not_null, -20204);
c_one_parameter_not_null_msg constant varchar2(2000 char) := 'Exactly one of the following parameters must be set: p_nr_workers_each_group (%d), p_nr_workers_exact (%d).';

c_no_groups_to_process simple_integer := c_job_already_running - 5;
e_no_groups_to_process exception;
pragma exception_init(e_no_groups_to_process, -20205);
c_no_groups_to_process_msg constant varchar2(2000 char) := 'Could not find groups to process.';

c_session_not_running_job simple_integer := c_job_already_running - 6;
e_session_not_running_job exception;
pragma exception_init(e_session_not_running_job, -20206);
c_session_not_running_job_msg constant varchar2(2000 char) := 'This session (SID=%s) does not appear to be a running job (for this user), see also column SESSION_ID from view USER_SCHEDULER_RUNNING_JOBS.';

/**
Package to (re)start, stop or drop the process that will process the groups for which the default processing method is "package://<schema>.MSG_SCHEDULER_PKG"
and whose queue is NOT registered as a PL/SQL callback "plsql://<schema>.MSG_NOTIFICATION_PRC".
**/

procedure do
( p_command in varchar2 -- check_jobs_not_running / start / stop / restart / drop
, p_processing_package in varchar2 default '%' -- find packages like this paramater that have both a routine get_groups_to_process() and processing()
);
/**
Runs in an autonomous transaction.

This procedure should be used to manage the jobs instead of directly calling DBMS_SCHEDULER.

p_command = check_jobs_not_running:
- Check that there are no running jobs that have been started by this package. If so, an error is raised.

p_command = start:
- Check that there are no jubs running (equivalent to do('check_jobs_not_running')).
- Start the launcher job (submit_launcher_processing()) if it does not exist,
  otherwise disable and enable (i.e. start).

p_command = stop:
- Stop all the running jobs launched by this package.
  Worker jobs will disappear due to the auto_drop parameter in DBMS_SCHEDULER.CREATE_JOB being true,
  the launcher job will be disabled.
- Check that there are no jubs running (equivalent to do('check_jobs_not_running')).

p_command = restart:
- Stop and start, equivalent to do('stop') followed by do('start').

p_command = drop:
- Stop the running jobs, equivalent to do('stop').
- Drop the jobs, first with force false, next with force true if necessary.
**/

procedure submit_do
( p_command in varchar2 -- check_jobs_not_running / start / stop / restart / drop
, p_processing_package in varchar2 default '%' -- find packages like this paramater that have both a routine get_groups_to_process() and processing()
);
/**
Submits do() as a non-repeating job, starting immediately.
*/

procedure submit_launcher_processing
( p_processing_package in varchar2
, p_nr_workers_each_group in positive default msg_constants_pkg.c_nr_workers_each_group -- the total number of workers will be this number multiplied by the number of groups
, p_nr_workers_exact in positive default msg_constants_pkg.c_nr_workers_exact -- the total number of workers will be this number
, p_repeat_interval in varchar2 default msg_constants_pkg.c_repeat_interval -- used to create a schedule if not null (a repeating job)
);
/**
Submits the launcher, see launcher_processing() below, that will submit its workers and then finish.

The administrator MAY create a job by calling this procedure, although that
will already be done implicitly by the processing package (for instance
msg_aq_pkg.enqueue(p_force => true)).

A repeating job (p_repeat_interval not null) will create the schedule first and then submit it.
It may not run immediately due to the schedule: do('start') will then run a temporary non-repeating job till the next run time of the repeating job.

A non-repeating job (p_repeat_interval null) will just create a job that will be auto dropped.
**/

procedure launcher_processing
( p_processing_package in varchar2
, p_nr_workers_each_group in positive default msg_constants_pkg.c_nr_workers_each_group -- the total number of workers will be this number multiplied by the number of groups
, p_nr_workers_exact in positive default msg_constants_pkg.c_nr_workers_exact -- the total number of workers will be this number
);
/**
This procedure is meant to be used by DBMS_SCHEDULER jobs or for test
purposes, never use it in application code: use 
submit_launcher_processing() above!

So the administrator should NEVER create a job based on this procedure.

It is a launcher routine that just launches other jobs, the workers and a
supervisor.  The launcher then finishes since the supervisor restarts failing
or stopped workers. Now the recurring schedule of the launcher job (for
instance each day) will start this launcher process again and again just
launching the supervisor and workers.  The idea is to use resources efficient
by running for a long period with some concurrent worker jobs but not to
exhaust system resources due to processes that run forever and that do not
correctly clean up resources.

Exactly one of the following parameters must be set:
1. p_nr_workers_each_group: the number of workers is then the number of groups found to be processed multiplied by this number
2. p_nr_workers_exact: the number of workers is this number

The processing package must have this routine that will be invoked by dynamic SQL:

```
function get_groups_to_process
( p_processing_method in varchar2
)
return sys.odcivarchar2list;
```

This will determine the groups to process, after which the supervisor and workers will do the
actual work based on that information.
**/

procedure processing
( p_processing_package in varchar2
, p_groups_to_process_list in varchar2 -- a comma separated list of groups to process
, p_nr_workers in positiven -- the number of workers
, p_worker_nr in positive -- the worker number: null for supervisor
, p_end_date in varchar2 -- the end date (as string)
);
/**
This procedure is meant to be used by (indirectly) DBMS_SCHEDULER jobs, not by YOU!

So the administrator should NEVER create a job based on this procedure.

This is the worker routine, started as a job by launcher_processing(). 

The processing package must have this routine that will be invoked by dynamic SQL:

```
procedure processing
( p_controlling_package in varchar2 -- the controlling package, i.e. the one who invoked this procedure
, p_groups_to_process_tab in sys.odcivarchar2list -- the groups to process
, p_worker_nr in positiven -- the worker number: null for supervisor
, p_end_date in timestamp with time zone -- the end date
, p_silence_threshold in number
);
```

This will do the processing of all messages till the end is reached or an exception occurs.

**/

end msg_scheduler_pkg;
/

