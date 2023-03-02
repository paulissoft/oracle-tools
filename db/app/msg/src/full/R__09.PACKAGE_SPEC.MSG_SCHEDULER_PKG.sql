CREATE OR REPLACE PACKAGE "MSG_SCHEDULER_PKG" AUTHID DEFINER AS 

/**
Package to (re)start or stop the process that will process the groups for which the default processing method is "package://<schema>.MSG_SCHEDULER_PKG"
and whose queue is NOT registered as a PL/SQL callback "plsql://<schema>.MSG_NOTIFICATION_PRC".
**/

procedure do
( p_command in varchar2 -- start / restart / stop
, p_processing_package in varchar2 default null -- if null utl_call_stack will be used to use the calling package as processing package 
);
/**
Runs in an autonomous transaction.

p_command = start:
- Start the supervisor job (submit_processing_supervisor())
- If the delta between now and the next run date is too far away, start a temporary supervisor job (submit_processing_supervisor(p_ttl => delta - time between runs, p_repeat_interval => null)).

p_command = restart:
- If there is no processing job yet, it will create and start it (do('start')).
- If there is a running job, it will stop and restart it (do('stop') followed by do('start')).
- If there is a processing job but not running (stopped by a DBA?), nothing happens.

p_command = stop: stop all the running supervisor jobs (and their workers).
**/

procedure submit_processing_supervisor
( p_processing_package in varchar2 default null -- if null utl_call_stack will be used to use the calling package as processing package
, p_nr_workers_each_group in positive default msg_constants_pkg.c_nr_workers_each_group -- the total number of workers will be this number multiplied by the number of groups
, p_nr_workers_exact in positive default msg_constants_pkg.c_nr_workers_exact -- the total number of workers will be this number
, p_ttl in positiven default msg_constants_pkg.c_ttl -- time to live (in seconds)
, p_repeat_interval in varchar2 default msg_constants_pkg.c_repeat_interval -- used to create a schedule if not null (a repeating job)
);
/**
Submits the supervisor, see processing_supervisor() below, that will submit its workers.

The administrator MAY create a job by calling this procedure, although that
will already be done implicitly by the processing package (for instance
msg_aq_pkg.enqueue(p_force => true)).

A repeating job (p_repeat_interval not null) will create the schedule first and then submit it.
It may not run immediately due to the schedule: do('start') will then run a temporary non-repeating job till the next run time of the repeating job.

A non-repeating job (p_repeat_interval null) will just create a job that will be auto dropped.
**/

procedure processing_supervisor
( p_processing_package in varchar2 default null -- if null utl_call_stack will be used to use the calling package as processing package
, p_nr_workers_each_group in positive default msg_constants_pkg.c_nr_workers_each_group -- the total number of workers will be this number multiplied by the number of groups
, p_nr_workers_exact in positive default msg_constants_pkg.c_nr_workers_exact -- the total number of workers will be this number
, p_ttl in positiven default msg_constants_pkg.c_ttl -- time to live (in seconds)
);
/**
This procedure is meant to be used by DBMS_SCHEDULER jobs or for test
purposes, never use it in application code: use 
submit_processing_supervisor() above!

So the administrator should NEVER create a job based on this procedure.

It is a supervisor routine that just launches other jobs, the workers.  The
supervisor also surveys them.  When worker jobs complete before
the end (defined by start time + time to live), they will be restarted by the
supervisor.  The supervisor will actively kill the worker jobs when he
finishes.  Now the recurring schedule of the job (for instance each day) will
start this supervisor process all over again.  The idea is to be use resources
efficient by running for a long period with some concurrent worker jobs but
not to exhaust system resources due to processes that run forever and that do
not correctly clean up resources.

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

This will determine the groups to process, after which the workers will do
the actual work based on that information.
**/

procedure processing
( p_processing_package in varchar2 default null -- if null utl_call_stack will be used to use the calling package as processing package
, p_groups_to_process_list in varchar2 -- a comma separated list of groups to process
, p_worker_nr in positiven
, p_ttl in positiven
, p_job_name_supervisor in varchar2
);
/**
This procedure is meant to be used by (indirectly) DBMS_SCHEDULER jobs, not by YOU!

So the administrator should NEVER create a job based on this procedure.

This is the worker routine, started as a job by processing_supervisor(). 

The processing package must have this routine that will be invoked by dynamic SQL:

```
procedure processing
( p_groups_to_process_tab in sys.odcivarchar2list
, p_worker_nr in positiven
, p_ttl in positiven
, p_job_name_supervisor in varchar2
);
```

This will do the processing of all messages till the end is reached or an exception occurs.

**/

end msg_scheduler_pkg;
/

