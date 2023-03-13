CREATE OR REPLACE PACKAGE "MSG_AQ_PKG" AUTHID DEFINER AS 

-- You can tweak the constants thru MSG_CONSTANTS_PKG, you are not supposed to do it here.
c_buffered_messaging constant boolean := msg_constants_pkg.c_buffered_messaging;
c_multiple_consumers constant boolean := msg_constants_pkg.c_multiple_consumers;
c_default_subscriber constant varchar2(30 char) := msg_constants_pkg.c_default_subscriber;

c_testing constant boolean := oracle_tools.cfg_pkg.c_testing;
c_queue_table constant user_queues.queue_table%type := '"MSG_QT"';
c_subscriber_delivery_mode constant binary_integer := case when c_buffered_messaging then dbms_aqadm.persistent_or_buffered else dbms_aqadm.persistent end;

/* Some definitions for the job event queue. */

/* A user-defined exception, see also MSG_SCHEDULER_PKG. */
e_job_event_signal exception;
pragma exception_init(e_job_event_signal, -20300);

c_job_event_queue_name constant all_queues.name%type := '"SYS"."SCHEDULER$_EVENT_QUEUE"';

/* The following exceptions are all defined by Oracle. */

-- ORA-24002: QUEUE_TABLE does not exist
e_queue_table_does_not_exist exception;
pragma exception_init(e_queue_table_does_not_exist, -24002);

-- ORA-25205/ORA-24010 on Executing PL/SQL which is invoking DBMS_AQ and DBMS_AQADM procedures (Doc ID 220477.1)

-- ORA-24010: QUEUE does not exist
e_queue_does_not_exist exception;
pragma exception_init(e_queue_does_not_exist, -24010);

-- ORA-25205: the QUEUE %s.%s does not exist
e_fq_queue_does_not_exist exception;
pragma exception_init(e_fq_queue_does_not_exist, -25205);

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

-- ORA-25254: time-out in LISTEN while waiting for a message
e_listen_timeout exception;
pragma exception_init(e_listen_timeout, -25254);

/**

This package is used as a wrapper around Oracle Advanced Queueing.

Its main usage is to enqueue messages (object type MSG_TYP or one of its sub types).

Next they can be dequeued by another process or by asynchronous PL/SQL notifications.

The default functionality is:
- single consumers and PL/SQL notifications
- message delivery is BUFFERED MESSAGES, i.e. storage in memory and not in the tables (not possible if the data contains non-empty LOBs)

**/

function get_queue_name
( p_group_name in varchar2
)
return varchar2;
/** Returns the enquoted simple SQL queue name, i.e. replace(p_group_name, '.', '$') (enquoted via DBMS_ASSERT.ENQUOTE_NAME). **/

function get_queue_name
( p_msg in msg_typ
)
return varchar2;
/** Just invokes get_queue_name(p_msg.group$). **/

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
, p_subscriber in varchar2
, p_rule in varchar2 default null
, p_delivery_mode in binary_integer default c_subscriber_delivery_mode
);
/** Add a subscriber to a queue. The subscriber name will be ignored for a single consumer queue table. **/
   
procedure remove_subscriber
( p_queue_name in varchar2
, p_subscriber in varchar2
);
/** Remove a subscriber from a queue. The subscriber name will be ignored for a single consumer queue table. **/

procedure register
( p_queue_name in varchar2
, p_subscriber in varchar2 -- the name of the subscriber already added via add_subscriber (for multi-consumer queues only)
, p_plsql_callback in varchar2 -- In the format schema.procedure or schema.package.procedure
);
/** Register a PL/SQL callback for a queue and subscriber. **/

procedure unregister
( p_queue_name in varchar2
, p_subscriber in varchar2 -- the name of the subscriber already added via add_subscriber (for multi-consumer queues only)
, p_plsql_callback in varchar2 default '%' -- In the format schema.procedure or schema.package.procedure, but wildcards allowed with escape backslash
);
/** Unregister a PL/SQL callback for a queue and subscriber. **/

procedure enqueue
( p_msg in msg_typ -- the message
, p_delivery_mode in binary_integer default null -- when null the message payload will determine this
, p_visibility in binary_integer default null -- when null the message payload will determine this
, p_correlation in varchar2 default null
, p_force in boolean default true -- When true, queue tables, queues, subscribers and notifications will be created/added if necessary
, p_msgid out nocopy raw
);
/**

Enqueue the message to the queue get_queue_name(p_msg).

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
, p_subscriber in varchar2
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
, p_subscriber in varchar2
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

function get_groups_to_process
( p_processing_method in varchar2
)
return sys.odcivarchar2list;
/**
Will be invoked by MSG_SCHEDULER_PKG (or alternatives).
Must return the message groups whose queue is not serviced by a PL/SQL callback and
whose default processing method is either p_processing_method or something like 'plsql://%'.
The latter case indicates that dbms_aq.unregister() has been invoked so someone needs to take care of such a queue.
**/

procedure processing
( p_groups_to_process_tab in sys.odcivarchar2list
, p_worker_nr in positiven
, p_end_date in timestamp with time zone
);
/**
Will be invoked by MSG_SCHEDULER_PKG (or alternatives).
Performs the processing of a worker job.
As soon as a DBMS_SCHEDULER job event occurs, exception E_JOB_EVENT_SIGNAL wil be raised.
**/

end msg_aq_pkg;
/

