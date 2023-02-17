CREATE OR REPLACE PACKAGE "MSG_PKG" AS 

type t_boolean_lookup_tab is table of boolean index by varchar2(4000 char);

c_one_day_minus_something constant positiven := (24 * 60 * 60 - 5);

e_dbms_pipe_error exception;
c_dbms_pipe_error constant integer := -20100;

pragma exception_init(e_dbms_pipe_error, -20100);

procedure submit_processing_supervisor
( p_processing_package in varchar2 default null -- if null utl_call_stack will be used to use the calling package as processing package
, p_include_group_list in varchar2 default '%' -- a comma separated list of (case sensitive) group names with wildcards allowed
, p_exclude_group_list in varchar2 default replace(web_service_response_typ.default_group, '_', '\_') -- these groups must be manually processed because the creator is interested in the result
, p_nr_workers_each_group in positive default null -- the total number of workers will be this number multiplied by the number of groups
, p_nr_workers_exact in positive default null -- the total number of workers will be this number
, p_ttl in positiven default c_one_day_minus_something -- time to live (in seconds)
, p_job_name_suffix in varchar2 default null -- to have other jobs
, p_start_date in timestamp with time zone default null
, p_repeat_interval in varchar2 default null
);
/**
Submits the supervisor, processing_supervisor() below, that will submit its workers.

The administrator MAY create a job by calling this procedure, although that
will already be done implicitly by the processing package (for instance
msg_aq_pkg.enqueue(p_force => true)).
**/

procedure processing_supervisor
( p_processing_package in varchar2 default null -- if null utl_call_stack will be used to use the calling package as processing package
, p_include_group_list in varchar2 default '%' -- a comma separated list of (case sensitive) group names with wildcards allowed
, p_exclude_group_list in varchar2 default replace(web_service_response_typ.default_group, '_', '\_') -- these groups must be manually processed because the creator is interested in the result
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
procedure get_groups_for_processing
( p_include_group_tab in sys.odcivarchar2list
, p_exclude_group_tab in sys.odcivarchar2list
, p_processing_group_tab out nocopy sys.odcivarchar2list
);
```

This will determine the groups for processing, after which the workers will do
the actual work based on that information.

See also [Scheduler Enhancements in Oracle 10g Database Release 2, https://oracle-base.com](https://oracle-base.com/articles/10g/scheduler-enhancements-10gr2).
**/

procedure processing
( p_processing_package in varchar2 default null -- if null utl_call_stack will be used to use the calling package as processing package
, p_processing_group_list in varchar2 -- a comma separated list of groups to process
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
( p_processing_group_tab in sys.odcivarchar2list
, p_worker_nr in positiven
, p_ttl in positiven
, p_job_name_supervisor in varchar2
);
```

This will do the processing of all messages till the end is reached or an exception occurs.
Then it will signal the status to the supervisor via DBMS_PIPE and stop.

**/

-- dedicated procedure to enable profiling
procedure process_msg
( p_msg in msg_typ
, p_commit in boolean
);

procedure data2msg
( p_data_clob in clob
, p_msg_vc out nocopy varchar2
, p_msg_clob out nocopy clob
);
/** Copy the input CLOB to either p_msg_vc if small enough or otherwise to p_msg_clob. **/

procedure msg2data
( p_msg_vc in varchar2
, p_msg_clob in clob
, p_data_json out nocopy json_element_t
);
/** Copy either p_msg_vc if not null, otherwise p_msg_clob to the output CLOB. **/

procedure data2msg
( p_data_blob in blob
, p_msg_raw out nocopy raw
, p_msg_blob out nocopy blob
);
/** Copy the input BLOB to either p_msg_raw if small enough or otherwise to p_msg_blob **/

procedure msg2data
( p_msg_raw in raw
, p_msg_blob in blob
, p_data_json out nocopy json_element_t
);
/** Copy either p_msg_raw if not null, otherwise p_msg_blob to the output BLOB. **/

function elapsed_time
( p_start in number
, p_end in number
)
return number; -- in seconds with fractions (not hundredths!)
/**
Determines the elapsed time in fractional seconds (not hundredths!) between two measure points taken by dbms_utility.get_time, the start (earlier) and the end (later).

The function dbms_utility.get_time returns the number of hundredths of a second from the point in time at which the subprogram is invoked.

Numbers are returned in the range -2147483648 to 2147483647 depending on
platform and machine, and your application must take the sign of the number
into account in determining the interval. For instance, in the case of two
negative numbers, application logic must allow that the first (earlier) number
will be larger than the second (later) number which is closer to zero. By the
same token, your application should also allow that the first (earlier) number
be negative and the second (later) number be positive.
**/

function does_job_supervisor_exist
( p_processing_package in varchar2 default null
)
return boolean;

procedure send_worker_status
( p_job_name_supervisor in varchar2
, p_worker_nr in integer
, p_sqlcode in integer default 0
, p_sqlerrm in varchar2 default null
, p_timeout in integer default 0
);

end msg_pkg;
/

