CREATE OR REPLACE PACKAGE "MSG_PKG" AUTHID DEFINER AS 

type t_boolean_lookup_tab is table of boolean index by varchar2(4000 char);

type msg_tab_t is table of msg_typ;

e_dbms_pipe_timeout exception;
c_dbms_pipe_timeout constant integer := -20100;

pragma exception_init(e_dbms_pipe_timeout, -20100);

e_dbms_pipe_record_too_large exception;
c_dbms_pipe_record_too_large constant integer := -20101;

pragma exception_init(e_dbms_pipe_record_too_large, -20101);

e_dbms_pipe_interrupted exception;
c_dbms_pipe_interrupted constant integer := -20102;

pragma exception_init(e_dbms_pipe_interrupted, -20102);

subtype event_t is varchar2(20 char);

"WORKER_STATUS"   constant event_t := 'WORKER_STATUS';
"STOP_SUPERVISOR" constant event_t := 'STOP_SUPERVISOR';

/**
A package with some generic definitions, exceptions, functions and procedures.
**/

procedure init;

procedure done;

function get_object_name
( p_object_name in varchar2 -- the object name part
, p_what in varchar2 -- the kind of object: used in error message
, p_schema_name in varchar2 default $$PLSQL_UNIT_OWNER -- the schema part name
, p_fq in integer default 1 -- return fully qualified name, yes (1) or no (0)
, p_qq in integer default 1 -- return double quoted name, yes (1) or no (0)
, p_uc in integer default 1 -- return name in upper case, yes (1) or no (0)
)
return varchar2;
/** A function to return the object name in some kind of format. **/

function get_msg_tab
return msg_tab_t;
/** Return a list of subtype instances having as final supertype MSG_TYP. MSG_TYP is not part of the list. **/

procedure process_msg
( p_msg in msg_typ
, p_commit in boolean
);
/** Dedicated procedure to process a message, especially interesting since it enables profiling. **/

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
/** Copy the input BLOB to either p_msg_raw if small enough or otherwise to p_msg_blob. **/

procedure msg2data
( p_msg_raw in raw
, p_msg_blob in blob
, p_data_json out nocopy json_element_t
);
/** Copy either p_msg_raw if not null, otherwise p_msg_blob to the output BLOB. **/

procedure send_worker_status
( p_job_name_supervisor in varchar2
, p_worker_nr in integer
, p_sqlcode in integer
, p_sqlerrm in varchar2
, p_timeout in integer
);
/** Send the status of a worker. **/

procedure send_stop_supervisor
( p_job_name_supervisor in varchar2
, p_timeout in integer
);
/** Send the supervisor a signal to stop. **/

procedure recv_event
( p_job_name_supervisor in varchar2
, p_timeout in integer
, p_event out nocopy event_t -- WORKER_STATUS / STOP_SUPERVISOR
, p_worker_nr out nocopy integer -- Only relevant when the event is WORKER_STATUS
, p_sqlcode out nocopy integer -- Idem
, p_sqlerrm out nocopy varchar2 -- Idem
, p_session_id out nocopy user_scheduler_running_jobs.session_id%type -- Idem
);
/** Used by the supervisor to receive events, either the worker status or a signal to stop. **/

end msg_pkg;
/

