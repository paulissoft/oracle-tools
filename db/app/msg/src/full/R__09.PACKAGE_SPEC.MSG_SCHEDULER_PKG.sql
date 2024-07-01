CREATE OR REPLACE PACKAGE "MSG_SCHEDULER_PKG" AUTHID DEFINER AS 

c_debugging constant naturaln := 1; -- can be 0, 1, 2, ...

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
c_no_groups_to_process_msg constant varchar2(2000 char) := 'Could not find groups to process for package %s.';

c_session_not_running_job simple_integer := c_job_already_running - 6;
e_session_not_running_job exception;
pragma exception_init(e_session_not_running_job, -20206);
c_session_not_running_job_msg constant varchar2(2000 char) := 'This session (SID=%s) does not appear to be a running job (for this user), see also column SESSION_ID from view USER_SCHEDULER_RUNNING_JOBS.';

c_there_are_no_running_jobs simple_integer := c_job_already_running - 7;
e_there_are_no_running_jobs exception;
pragma exception_init(e_there_are_no_running_jobs, -20207);
c_there_are_no_running_jobs_msg constant varchar2(2000 char) := 'There should be running jobs matching "%s" but there are none';

c_unexpected_program simple_integer := c_job_already_running - 8;
e_unexpected_program exception;
pragma exception_init(e_unexpected_program, -20208);
c_unexpected_program_msg constant varchar2(2000 char) := 'Unexpected program: "%s"';

c_end_date_not_in_the_future simple_integer := c_job_already_running - 9;
e_end_date_not_in_the_future exception;
pragma exception_init(e_end_date_not_in_the_future, -20209);
c_end_date_not_in_the_future_msg constant varchar2(2000 char) := 'The end date ("%s") should be in the future (current system timestamp = "%s")';

/**
Package to (re)start, stop or drop the process that will process the groups for which the default processing method is "package://<schema>.MSG_SCHEDULER_PKG"
and whose queue is NOT registered as a PL/SQL callback "plsql://<schema>.MSG_NOTIFICATION_PRC".
**/

type job_info_rec_t is record
( job_name user_scheduler_jobs.job_name%type
, program_name user_scheduler_jobs.program_name%type
, schedule_owner user_scheduler_jobs.schedule_owner%type
, schedule_name user_scheduler_jobs.schedule_name%type
, start_date user_scheduler_jobs.start_date%type
, repeat_interval user_scheduler_jobs.repeat_interval%type
, end_date user_scheduler_jobs.end_date%type
, enabled user_scheduler_jobs.enabled%type
, state user_scheduler_jobs.state%type
, last_start_date user_scheduler_jobs.last_start_date%type
, last_run_duration user_scheduler_jobs.last_run_duration%type
, next_run_date user_scheduler_jobs.next_run_date%type
, run_count user_scheduler_jobs.run_count%type
, failure_count user_scheduler_jobs.failure_count%type
, retry_count user_scheduler_jobs.retry_count%type
-- procedure call is constructed from user_scheduler_programs.program_action and the job arguments
, procedure_call varchar2(1000 byte)
-- running job info (user_scheduler_running_jobs)
, log_id user_scheduler_running_jobs.log_id%type
, session_id user_scheduler_running_jobs.session_id%type
, elapsed_time user_scheduler_running_jobs.elapsed_time%type
-- (last) job run details (user_scheduler_job_run_details)
, req_start_date user_scheduler_job_run_details.req_start_date%type
, actual_start_date user_scheduler_job_run_details.actual_start_date%type
, additional_info user_scheduler_job_run_details.additional_info%type
, output user_scheduler_job_run_details.output%type
, error# user_scheduler_job_run_details.error#%type
, errors user_scheduler_job_run_details.errors%type
);

type job_info_tab_t is table of job_info_rec_t;

function show_job_info
( p_processing_package in varchar2 default '%'
)
return job_info_tab_t
pipelined;

procedure do
( p_command in varchar2 -- create / drop / start / shutdown / stop / restart / check-jobs-running / check-jobs-not-running
, p_processing_package in varchar2 default '%' -- find packages like this paramater that have both a routine get_groups_to_process() and processing()
);
/**
Runs in an autonomous transaction.

This procedure should be used to manage the jobs instead of directly calling DBMS_SCHEDULER.

p_command = create / drop:
- Create or drop all the scheduler objects like jobs, programs, schedules.
- Worker jobs are not created though since they need to be created by the launcher job.

p_command = start:
- Check that there are no jubs running (equivalent to do('check-jobs-not-running')).
- Start the launcher job (submit_processing_launcher()) if it does not exist,
  otherwise disable and enable (i.e. start).

p_command = shutdown:
- Gracefuly stop all the running jobs launched by this package.
- Check that there are no jubs running (equivalent to do('check-jobs-not-running')).

p_command = stop:
- Stop all the running jobs launched by this package.
- Check that there are no jubs running (equivalent to do('check-jobs-not-running')).

p_command = restart:
- Stop and start, equivalent to do('stop') followed by do('start').

p_command = check-jobs-not-running/ check-jobs-not-running:
- Check that there are (no) running jobs that have been started by this package. If so, an error is raised.

**/

function show_do
( p_commands in varchar2 -- comma separated list of: create / drop / start / shutdown / stop / restart / check-jobs-running / check-jobs-not-running
, p_processing_package in varchar2 default '%' -- find packages like this paramater that have both a routine get_groups_to_process() and processing()
, p_read_initial_state in natural default null -- read info from USER_SCHEDULER_* dictionary views at the beginning to constitute an ininitial state
, p_show_initial_state in natural default null -- show the initial state: set to false (0) when you want to have what-if scenarios
, p_show_comments in natural default null -- show comments with each command in p_commands and the program
)
return sys.odcivarchar2list
pipelined;

procedure submit_do
( p_command in varchar2 -- same as for do() above
, p_processing_package in varchar2 default '%' -- same as for do() above
);
/**
Submits do() as a non-repeating job, starting immediately.
*/

procedure submit_processing_launcher
( p_processing_package in varchar2
, p_nr_workers_each_group in positive default msg_constants_pkg.get_nr_workers_each_group
, p_nr_workers_exact in positive default msg_constants_pkg.get_nr_workers_exact
);
/**
Submits the launcher, see processing_launcher() below, that will submit the supervisor and its workers and then finish.
**/

procedure processing_launcher
( p_processing_package in varchar2
, p_nr_workers_each_group in positive default msg_constants_pkg.get_nr_workers_each_group
, p_nr_workers_exact in positive default msg_constants_pkg.get_nr_workers_exact
);
/**
This procedure is meant to be used by DBMS_SCHEDULER jobs or for test
purposes, never use it in application code: use 
submit_processing_launcher() above!

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

This is the worker routine, started as a job by processing_launcher(). 

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

