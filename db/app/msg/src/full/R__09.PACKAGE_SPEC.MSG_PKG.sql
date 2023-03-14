CREATE OR REPLACE PACKAGE "MSG_PKG" AUTHID DEFINER AS 

type t_boolean_lookup_tab is table of boolean index by varchar2(4000 char);

type msg_tab_t is table of msg_typ;

--subtype timestamp_tz_t is timestamp with time zone;
subtype timestamp_tz_t is oracle_tools.api_time_pkg.timestamp_t;
subtype timestamp_tz_str_t is varchar2(40);

c_timestamp_tz_format constant timestamp_tz_str_t := 'YYYY-MM-DD"T"HH24:MI:SS.FF6"Z"';

c_heartbeat_failure constant pls_integer := -20100;

e_heartbeat_failure exception;
pragma exception_init(e_heartbeat_failure, -20100);

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

function timestamp_tz2timestamp_tz_str
( p_val in timestamp_tz_t
)
return timestamp_tz_str_t;
/** Return the timestamp value in 'YYYY-MM-DD"T"HH24:MI:SS.FF6"Z"' format. */

function timestamp_tz_str2timestamp_tz
( p_val in timestamp_tz_str_t
)
return timestamp_tz_t;
/** Return the timestamp string value (in 'YYYY-MM-DD"T"HH24:MI:SS.FF6"Z"' format) as a timestamp with time zone. */

procedure send_heartbeat
( p_controlling_package in varchar2
, p_recv_timeout in naturaln -- receive timeout in seconds
, p_worker_nr in positiven -- the worker number
, p_timestamp out nocopy timestamp_tz_t
);
/**
Send a heartbeat to the request pipe (p_controlling_package) with a timeout of 0 seconds.
The contents of the message will be:
1. the response pipe (p_controlling_package || '#' || p_worker_nr)
2. the worker number
3. the current time (current_timestamp)

Then receive a response on the response pipe (p_controlling_package || '#' || p_worker_nr) while waiting for p_recv_timeout seconds, see recv_heartbeat() below.

In case of problems: raise an e_heartbeat_failure exception.
*/

procedure recv_heartbeat
( p_controlling_package in varchar2
, p_recv_timeout in naturaln -- receive timeout in seconds
, p_worker_nr out nocopy positive -- the worker number
, p_timestamp out nocopy timestamp_tz_t
);
/**
Receive a heartbeat from the request pipe (p_controlling_package) with a timeout of p_recv_timeout seconds.

The receiver will check whether the message is conform described above.
If so, it will respond (timeout 0) to the response pipe (p_controlling_package || '#' || p_worker_nr) with the same timestamp.

In case of problems: raise an e_heartbeat_failure exception.
*/

end msg_pkg;
/

