CREATE OR REPLACE PACKAGE "DATA_DML_EVENT_MGR_PKG" AUTHID DEFINER AS 

c_queue_table constant user_queues.queue_table%type := 'DML_EVENTS_QT';

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

function queue_table_name
( p_schema in varchar2
)
return varchar2;
/** Returns the fully qualified queue table name, i.e. p_schema || '.' || c_queue_table (enquoted via DBMS_ASSERT). **/

function queue_name
( p_schema in varchar2
, p_data_row in oracle_tools.data_row_t
)
return varchar2;
/** Returns the fully qualified queue name, i.e. p_schema || '.' || p_data_row.table_owner || '$' || p_data_row.table_name (enquoted via DBMS_ASSERT). **/

procedure create_queue_table
( p_schema in varchar2
);
/** Create the queue table queue_table_name(p_schema). **/

procedure drop_queue_table
( p_schema in varchar2
, p_force in boolean default false -- Must we drop queues first?
);
/** Drop the queue table queue_table_name(p_schema). **/

procedure create_queue
( p_schema in varchar2
, p_queue_name in varchar2 -- Must be a qualified SQL name
, p_comment in varchar2
);
/** Create the queue with a comment with queue table queue_table_name(p_schema). When the queue table does not exist, it is created. **/

procedure drop_queue
( p_schema in varchar2
, p_queue_name in varchar2 -- Must be a qualified SQL name
, p_force in boolean default false -- Must we stop enqueueing / dequeueing first?
);
/** Drop the queue. **/

procedure start_queue
( p_schema in varchar2
, p_queue_name in varchar2 -- Must be a qualified SQL name
);
/** Start the queue with enqueue and dequeue enabled. **/

procedure stop_queue
( p_schema in varchar2
, p_queue_name in varchar2 -- Must be a qualified SQL name
, p_wait in boolean default true
);
/** Stop the queue with enqueue and dequeue disabled. **/

procedure dml
( p_schema in varchar2
, p_data_row in oracle_tools.data_row_t
, p_force in boolean default true -- Must we create/start queues if the operation fails due to such and event?
);
/** Add the data row to the queue queue_name(p_schema, p_data_row). **/

end data_dml_event_mgr_pkg;
/

