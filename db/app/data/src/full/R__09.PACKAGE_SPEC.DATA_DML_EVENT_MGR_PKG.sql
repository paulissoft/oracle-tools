CREATE OR REPLACE PACKAGE "DATA_DML_EVENT_MGR_PKG" AUTHID CURRENT_USER AS 

c_queue_table constant user_queues.queue_table%type := '"DML_EVENTS_QT"';

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

/**

This package is used as a wrapper around Oracle Advanced Queueing.

Its main usage is to enqueue DML events (via object type DATA_ROW_T or one of its sub types) in triggers.

Next they can be dequeued by another process or by asynchronous PL/SQL notifications.

The default functionality is:
- multiple consumers and PL/SQL notifications
- message delivery is BUFFERED MESSAGES, i.e. storage in memory and not in the tables (not possible if the data contains non-empty LOBs)

**/

function queue_name
( p_data_row in oracle_tools.data_row_t
)
return varchar2;
/** Returns the enquoted simple SQL queue name, i.e. p_data_row.table_owner || '$' || p_data_row.table_name (enquoted via DBMS_ASSERT.ENQUOTE_NAME). **/

procedure create_queue_table
( p_schema in varchar2
);
/** Create the queue table c_queue_table in schema p_schema. **/

procedure drop_queue_table
( p_schema in varchar2
, p_force in boolean default false -- Must we drop queues first?
);
/** Drop the queue table c_queue_table in schema p_schema. **/

procedure create_queue
( p_schema in varchar2
, p_queue_name in varchar2 -- Must be a simple SQL name
, p_comment in varchar2
);
/** Create the queue with queue table c_queue_table in schema p_schema. When the queue table does not exist, it is created too. **/

procedure drop_queue
( p_schema in varchar2
, p_queue_name in varchar2 -- Must be a simple SQL name
, p_force in boolean default false -- Must we stop enqueueing / dequeueing first?
);
/** Drop the queue. Does not drop the queue table. **/

procedure start_queue
( p_schema in varchar2
, p_queue_name in varchar2 -- Must be a simple SQL name
);
/** Start the queue with enqueue and dequeue enabled. **/

procedure stop_queue
( p_schema in varchar2
, p_queue_name in varchar2 -- Must be a simple SQL name
, p_wait in boolean default true
);
/** Stop the queue with enqueue and dequeue disabled. **/

procedure add_subscriber
( p_schema in varchar2
, p_queue_name in varchar2
, p_subscriber in varchar2
, p_rule in varchar2 default null
, p_delivery_mode in pls_integer default dbms_aqadm.persistent_or_buffered
);
/** Add a subscriber to a queue. The subscriber agent will not have an address. **/
   
procedure remove_subscriber
( p_schema in varchar2
, p_queue_name in varchar2
, p_subscriber in varchar2
);
/** Remove a subscriber from a queue. **/

procedure register
( p_schema in varchar2
, p_queue_name in varchar2
, p_subscriber in varchar2 -- the name of the subscriber already added via add_subscriber (for multi-consumer queues only)
, p_plsql_callback in varchar -- schema.procedure
);
/** Register a PL/SQL callback for a queue and subscriber. **/

procedure unregister
( p_schema in varchar2
, p_queue_name in varchar2
, p_subscriber in varchar2 -- the name of the subscriber already added via add_subscriber (for multi-consumer queues only)
, p_plsql_callback in varchar -- schema.procedure
);
/** Unregister a PL/SQL callback for a queue and subscriber. **/

procedure dml
( p_schema in varchar2
, p_data_row in oracle_tools.data_row_t
, p_force in boolean default true -- Must we create/start queues if the operation fails due to such an event?
);
/** Add the data row to the queue queue_name(p_data_row) in schema p_schema. **/

end data_dml_event_mgr_pkg;
/

