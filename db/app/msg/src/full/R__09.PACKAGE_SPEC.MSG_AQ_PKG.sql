CREATE OR REPLACE PACKAGE "MSG_AQ_PKG" AUTHID DEFINER AS 

c_testing constant boolean := oracle_tools.cfg_pkg.c_testing;
c_buffered_messaging constant boolean := true; -- not(c_testing); -- buffered messaging enabled?

c_queue_table constant user_queues.queue_table%type := '"MSG_QT"';
c_multiple_consumers constant boolean := false; -- single consumer is the fastest option
c_default_subscriber constant varchar2(30 char) := case when c_multiple_consumers then 'DEFAULT_SUBSCRIBER' end;
c_default_plsql_callback constant varchar(128 char) := $$PLSQL_UNIT_OWNER || '.' || 'MSG_NOTIFICATION_PRC';
c_subscriber_delivery_mode constant binary_integer := case when c_buffered_messaging then dbms_aqadm.persistent_or_buffered else dbms_aqadm.persistent end;

c_one_day_minus_something constant positiven := (24 * 60 * 60 - 5);

-- ORA-24002: QUEUE_TABLE does not exist
e_queue_table_does_not_exist exception;
pragma exception_init(e_queue_table_does_not_exist, -24002);

-- ORA-24010: QUEUE does not exist
e_queue_does_not_exist exception;
pragma exception_init(e_queue_does_not_exist, -24010);

-- ORA-24033: no recipients for message
e_no_recipients_for_message exception;
pragma exception_init(e_no_recipients_for_message, -24033);

-- ORA-25207: enqueue failed, queue is disabled from enqueueing
e_enqueue_disabled exception;
pragma exception_init(e_enqueue_disabled, -25207);

-- ORA-25253: dequeue failed
e_dequeue_disabled exception;
pragma exception_init(e_dequeue_disabled, -25253);

-- ORA-24034: application ... is already a subscriber for queue ...
e_subscriber_already_exists exception;
pragma exception_init(e_subscriber_already_exists, -24034);

-- ORA-24035: AQ agent ... is not a subscriber for queue ...
e_subscriber_does_not_exist exception;
pragma exception_init(e_subscriber_does_not_exist, -24035);

-- ORA-25228: timeout or end-of-fetch during message dequeue from ...
e_dequeue_timeout exception;
pragma exception_init(e_dequeue_timeout, -25228);

/**

This package is used as a wrapper around Oracle Advanced Queueing.

Its main usage is to enqueue messages (object type MSG_TYP or one of its sub types).

Next they can be dequeued by another process or by asynchronous PL/SQL notifications.

The default functionality is:
- single consumers and PL/SQL notifications
- message delivery is BUFFERED MESSAGES, i.e. storage in memory and not in the tables (not possible if the data contains non-empty LOBs)

**/

function queue_name
( p_msg in msg_typ
)
return varchar2;
/** Returns the enquoted simple SQL queue name, i.e. replace(p_msg.group$, '.', '$') (enquoted via DBMS_ASSERT.ENQUOTE_NAME). **/

procedure create_queue_table;
/** Create the queue table c_queue_table. **/

procedure drop_queue_table
( p_force in boolean default false -- Must we drop queues first?
);
/** Drop the queue table c_queue_table. **/

procedure create_queue
( p_queue_name in varchar2 -- Must be a simple SQL name
, p_comment in varchar2
);
/** Create the queue with queue table c_queue_table. When the queue table does not exist, it is created too. **/

procedure drop_queue
( p_queue_name in varchar2 -- Must be a simple SQL name
, p_force in boolean default false -- Must we stop enqueueing / dequeueing first?
);
/** Drop the queue. Does not drop the queue table. **/

procedure start_queue
( p_queue_name in varchar2 -- Must be a simple SQL name
);
/** Start the queue with enqueue and dequeue enabled. **/

procedure stop_queue
( p_queue_name in varchar2 -- Must be a simple SQL name
, p_wait in boolean default true
);
/** Stop the queue with enqueue and dequeue disabled. **/

procedure add_subscriber
( p_queue_name in varchar2
, p_subscriber in varchar2 default c_default_subscriber
, p_rule in varchar2 default null
, p_delivery_mode in binary_integer default c_subscriber_delivery_mode
);
/** Add a subscriber to a queue. The subscriber name will be ignored for a single consumer queue table. **/
   
procedure remove_subscriber
( p_queue_name in varchar2
, p_subscriber in varchar2 default c_default_subscriber
);
/** Remove a subscriber from a queue. The subscriber name will be ignored for a single consumer queue table. **/

procedure register
( p_queue_name in varchar2
, p_subscriber in varchar2 default c_default_subscriber -- the name of the subscriber already added via add_subscriber (for multi-consumer queues only)
, p_plsql_callback in varchar default c_default_plsql_callback -- In the format schema.procedure
);
/** Register a PL/SQL callback for a queue and subscriber. **/

procedure unregister
( p_queue_name in varchar2
, p_subscriber in varchar2 default c_default_subscriber -- the name of the subscriber already added via add_subscriber (for multi-consumer queues only)
, p_plsql_callback in varchar default c_default_plsql_callback -- In the format schema.procedure
);
/** Unregister a PL/SQL callback for a queue and subscriber. **/

procedure enqueue
( p_msg in msg_typ -- the message
, p_delivery_mode in binary_integer default null -- when null the message payload will determine this
, p_visibility in binary_integer default null -- when null the message payload will determine this
, p_correlation in varchar2 default null
, p_force in boolean default true -- When true, queue tables, queues, subscribers and notifications will be created/added if necessary
, p_plsql_callback in varchar2 default c_default_plsql_callback -- When not null that callback will e registered, other you must dequeue yourself
, p_msgid out nocopy raw
);
/**

Enqueue the message to the queue queue_name(p_msg).

For AQ there are tree valid combinations for delivery mode and visibility:
1. delivery mode equal to dbms_aq.persistent and visibility equal to dbms_aq.on_commit
2. delivery mode equal to dbms_aq.buffered and visibility equal to dbms_aq.immediate (buffered message)
3. delivery mode equal to dbms_aq.persistent and visibility equal to dbms_aq.immediate

When the input is not one of these combination the message payload will determine one of the first two combinations.
When the message has a not null lob (p_msg.has_not_null_lob() != 0), AQ does not allow visibility to be immediate hence not a buffered message.
So in that case the first combination will be used.
Otherwise, when there is NOT an empty lob, the second combination.

**/

procedure dequeue
( p_queue_name in varchar2 -- Can be fully qualified (including schema).
, p_delivery_mode in binary_integer -- dbms_aq.persistent or dbms_aq.buffered
, p_visibility in binary_integer -- dbms_aq.on_commit (persistent delivery mode only) or dbms_aq.immediate (all delivery modes)
, p_subscriber in varchar2 default c_default_subscriber
, p_dequeue_mode in binary_integer default dbms_aq.remove
, p_navigation in binary_integer default dbms_aq.next_message
, p_wait in binary_integer default dbms_aq.forever
, p_correlation in varchar2 default null
, p_deq_condition in varchar2 default null
, p_force in boolean default false -- When true, queue tables, queues will be created/added if necessary
, p_msgid in out nocopy raw
, p_message_properties out nocopy dbms_aq.message_properties_t
, p_msg out nocopy msg_typ
);
/**

Dequeue the message (of base type msg_typ) from the queue. The caller must process it (use <message>.process(0)).

For AQ there are four valid combinations for delivery mode and visibility:
1. delivery mode equal to dbms_aq.persistent and visibility equal to dbms_aq.on_commit
2. delivery mode equal to dbms_aq.buffered and visibility equal to dbms_aq.immediate (buffered message)
3. delivery mode equal to dbms_aq.persistent and visibility equal to dbms_aq.immediate
4. delivery mode equal to dbms_aq.persistent_or_buffered and visibility equal to dbms_aq.immediate (persistent or buffered message)

When the input is not one of these combinations:
* if p_delivery_mode equals dbms_aq.buffered or dbms_aq.persistent_or_buffered, the visibility will become dbms_aq.immediate
* if p_visibility equals dbms_aq.on_commit, the delivery mode will become dbms_aq.persistent
* otherwise delivery mode will become dbms_aq.persistent and visibility will be dbms_aq.on_commit

**/

procedure dequeue_and_process
( p_queue_name in varchar2 -- Can be fully qualified (including schema).
, p_delivery_mode in binary_integer
, p_visibility in binary_integer
, p_subscriber in varchar2 default c_default_subscriber
, p_dequeue_mode in binary_integer default dbms_aq.remove
, p_navigation in binary_integer default dbms_aq.next_message
, p_wait in binary_integer default dbms_aq.forever
, p_correlation in varchar2 default null
, p_deq_condition in varchar2 default null
, p_force in boolean default false -- When true, queue tables, queues will be created/added if necessary
, p_commit in boolean default true
);
/** Dequeue a message (of base type msg_typ) from the queue and process it using <message>.process(0). **/

procedure dequeue
( p_context in raw
, p_reginfo in sys.aq$_reg_info
, p_descr in sys.aq$_descriptor
, p_payload in raw
, p_payloadl in number
, p_msgid out nocopy raw
, p_message_properties out nocopy dbms_aq.message_properties_t
, p_msg out nocopy msg_typ
);
/**
Dequeue a message (of base type msg_typ) as a result of a PL/SQL notification. The caller must process it (use <message>.process(0)). 
The first 5 parameters are mandated from the PL/SQL callback definition.

Some notes:
-- The message id to dequeue is p_descr.msg_id
-- The subscriber is p_descr.consumer_name
-- The dequeue mode is dbms_aq.remove
-- The navigation is dbms_aq.next_message
-- The delivery mode p_descr.msg_prop.delivery_mode (dbms_aq.buffered or dbms_aq.persistent)
-- The visibility will be dbms_aq.immediate for delivery mode dbms_aq.buffered, otherwise dbms_aq.on_commit
-- No dequeue condition
-- No wait since the message is supposed to be there
**/

procedure dequeue_and_process
( p_context in raw
, p_reginfo in sys.aq$_reg_info
, p_descr in sys.aq$_descriptor
, p_payload in raw
, p_payloadl in number
, p_commit in boolean default true
);
/**
Dequeue a message (of base type msg_typ) from the queue as a result of a PL/SQL notification and process it using <message>.process(0).
The first 5 parameters are mandated from the PL/SQL callback definition.

See also the dequeue(p_context...) procedure documentation.
**/

procedure dequeue_and_process
( p_include_queue_name_list in varchar2 default '%' -- a comma separated list of (case sensitive) queue names with wildcards allowed
, p_exclude_queue_name_list in varchar2 default replace(web_service_response_typ.default_group, '_', '\_') -- these queues must be manually dequeued because the creator is interested in the result
, p_nr_workers_multiply_per_q in positive default null -- supervisor parameter: the total number of workers will be this number multiplied by the number of queues
, p_nr_workers_exact in positive default null -- supervisor parameter: the total number of workers will be this number
, p_ttl in positiven default c_one_day_minus_something -- time to live (in seconds)
);
/**
This procedure is meant to be used by DBMS_SCHEDULER jobs.

The administrator MAY create a job based on this procedure, although such a job is created implicitly by enqueue(p_force => true).

It is a supervisor routine that just launches other jobs, the workers.  The
supervisor also surveys them using events.  When worker jobs complete before
the end (defined by start time + time to live), they will be restarted.  A job
completes when it failed, succeeded, or was stopped
(DBMS_SCHEDULER.job_run_completed).  The supervisor will actively kill the
worker jobs when he finishes.  Now the recurring schedule of the job (for
instance each day) will start this process all over again.  The idea is to be
use resources efficient by running for a long period with some concurrent
worker jobs but not to exhaust system resources due to processes that run
forever and that do not correctly clean up resources.

Exactly one of the following parameters must be set:
1. p_nr_workers_multiply_per_q - the number of workers is then the number of queues found multiplied by this number
2. p_nr_workers_exact - the number of workers is this number

See also [Scheduler Enhancements in Oracle 10g Database Release 2, https://oracle-base.com](https://oracle-base.com/articles/10g/scheduler-enhancements-10gr2).
**/

procedure dequeue_and_process_worker
( p_queue_name_tab in anydata -- a list of queue names to listen to (type sys.odcivarchar2list)
, p_worker_nr in positiven
, p_start_date_str in varchar2 -- start date converted to YYYY-MM-DD HH24:MI:SS
, p_end_date_str in varchar2 -- end date converted to YYYY-MM-DD HH24:MI:SS
);
/**
This procedure is meant to be used (indirectly) by DBMS_SCHEDULER jobs.

The administrator does NOT need to create a job based on this procedure.

This is the worker job, started by
dequeue_and_process(p_include_queue_name_list, ...).  They start first to
create an agent list for DBMS_AQ.listen where worker 1 must have queue 1 as
the first agent queue, worker 2 must have queue 2 as the first agent
queue. This is necessary since DBMS_AQ.listen returns the FIRST agent that is
ready and so if all workers have the same first agent queues, the last queues
may be dequeued less frequently.  When the end has been reached, each
individual worker job is supposed to stop (let the dequeue timeout be the time
left with a minimum of 0). When the listen procedure has a ready queue, the
procedure dequeue_and_process(p_queue_name, p_delivery_mode, ...) must be
invoked to do the job, where you must take care to ignore any error and
rollback to a savepoint like in procedure dequeue_and_process(p_context, ...).
**/

procedure create_job
( p_job_name in varchar2 -- (1) like 'MSG\_PROCESS%#%' escape '\' or (2) like 'MSG\_PROCESS%' escape '\'
, p_start_date in timestamp with time zone default null
, p_repeat_interval in varchar2 default null
, p_end_date in timestamp with time zone default null
);
/**
Create a job that is disabled to allow you to define actual job arguments and then to enable it (to run).

Depending on the job name, one of these job programs are used:
1. DEQUEUE_AND_PROCESS_WORKER
2. DEQUEUE_AND_PROCESS

See also:

```
DBMS_SCHEDULER.CREATE_JOB (
   job_name             IN VARCHAR2,
   program_name         IN VARCHAR2,
   start_date           IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
   repeat_interval      IN VARCHAR2                 DEFAULT NULL,
   end_date             IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
...
```
**/

procedure create_program
( p_program_name in varchar2 -- either DEQUEUE_AND_PROCESS or DEQUEUE_AND_PROCESS_WORKER
);
/**
Create an (enabled) program to be used by jobs created by create_job(p_job_name).
**/

end msg_aq_pkg;
/

