CREATE OR REPLACE PACKAGE "MSG_SCHEDULER_PKG" AUTHID DEFINER AS 

c_one_day_minus_something constant positiven := (24 * 60 * 60 - 5);

/**
Package to (re)start the process that will process the groups for which the default processing method is "package://<schema>.MSG_SCHEDULER_PKG"
and whose queue is NOT registered as a PL/SQL callback "plsql://<schema>.MSG_NOTIFICATION_PRC".
**/

procedure restart
( p_processing_package in varchar2 default null -- if null utl_call_stack will be used to use the calling package as processing package
);
/**
Runs in an autononous transaction.

If there is no processing job yet, it will create and start it.
If there is a running job, it will stop and restart it.
If there is a processing job but not running (stopped by a DBA?), nothing happens.
**/

procedure submit_processing_supervisor
( p_processing_package in varchar2 default null -- if null utl_call_stack will be used to use the calling package as processing package
, p_nr_workers_each_group in positive default null -- the total number of workers will be this number multiplied by the number of groups
, p_nr_workers_exact in positive default null -- the total number of workers will be this number
, p_ttl in positiven default c_one_day_minus_something -- time to live (in seconds)
, p_start_date in timestamp with time zone default msg_constants_pkg.c_job_schedule_start_date -- for creating job schedule 
, p_repeat_interval in varchar2 default msg_constants_pkg.c_job_schedule_repeat_interval -- idem
, p_end_date in timestamp with time zone default msg_constants_pkg.c_job_schedule_end_date -- idem
);
/**
Submits the supervisor, processing_supervisor() below, that will submit its workers.

The administrator MAY create a job by calling this procedure, although that
will already be done implicitly by the processing package (for instance
msg_aq_pkg.enqueue(p_force => true)).
**/

procedure processing_supervisor
( p_processing_package in varchar2 default null -- if null utl_call_stack will be used to use the calling package as processing package
, p_nr_workers_each_group in positive default null -- the total number of workers will be this number multiplied by the number of groups
, p_nr_workers_exact in positive default null -- the total number of workers will be this number
, p_ttl in positiven default c_one_day_minus_something -- time to live (in seconds)
);
/**
This procedure is meant to be used by DBMS_SCHEDULER jobs or for test
purposes, never use it in application code: use 
submit_processing_supervisor() above!

So the administrator should NEVER create a job based on this procedure.

It is a supervisor routine that just launches other jobs, the workers.  The
supervisor also surveys them via DBMS_PIPE.  When worker jobs complete before
the end (defined by start time + time to live), they will be restarted by the
supervisor.  The supervisor will NOT actively kill the worker jobs when he
finishes since DBMS_SCHEDULER is supposed to do that.  Now the recurring
schedule of the job (for instance each day) will start this supervisor process
all over again.  The idea is to be use resources efficient by running for a
long period with some concurrent worker jobs but not to exhaust system
resources due to processes that run forever and that do not correctly clean up
resources.

Exactly one of the following parameters must be set:
1. p_nr_workers_each_group - the number of workers is then the number of groups found to be processed multiplied by this number
2. p_nr_workers_exact - the number of workers is this number

The processing package must have this routine that will be invoked by dynamic SQL:

```
function get_groups_to_process
return sys.odcivarchar2list;
```

This will determine the groups for processing, after which the workers will do
the actual work based on that information.

See also [Scheduler Enhancements in Oracle 10g Database Release 2, https://oracle-base.com](https://oracle-base.com/articles/10g/scheduler-enhancements-10gr2).
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
Then it will signal the status to the supervisor via DBMS_PIPE and stop.

**/

function does_job_supervisor_exist
( p_processing_package in varchar2 default null
)
return boolean;

end msg_scheduler_pkg;
/

