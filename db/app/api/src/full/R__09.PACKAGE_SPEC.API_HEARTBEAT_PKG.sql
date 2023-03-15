CREATE OR REPLACE PACKAGE "API_HEARTBEAT_PKG" AUTHID DEFINER
is

c_use_package constant all_objects.object_name%type := 'DBMS_PIPE'; -- package to implement this: you need execute privileges on it

c_heartbeat_silent_workers constant pls_integer := -20100;

e_heartbeat_silent_workers exception;
pragma exception_init(e_heartbeat_silent_workers, -20100);

subtype supervisor_channel_t is varchar2(128 char); -- a database pipe when DBMS_PIPE is used
subtype timestamp_tab_t is dbms_sql.timestamp_with_time_zone_table;
subtype silent_worker_tab_t is sys.odcinumberlist;

/**
This package implements the heartbeats between a supervisor and its regular
worker(s), numbered 1 or higher (positive).  The supervisor is also considered
a worker however with an empty worker number.

The happy flow:
1. a worker sends a heartbeat message with its current timestamp to the supervisor channel.
2. the supervisor receives the message.
3. the supervisor responds by sending its own current timestamp to the worker channel (workers do not share channels).
4. the worker receives the supervisor answer.

However, often this happy flow will not work since the worker does not want to
wait.  But the next time the worker sends a heartbeat it will pick up the
previous answer so it will not be lagging behind too much.

The supervisor will not wait forever too, since it must process all the
messages from its workers and then decide to do something with silent workers.

The same is true for a worker who will normally will not be blocking. But he
must identify too that the supervisor is not responding. The solution
proposed should help with that.

So both the worker and supervisor will try to receive a first message (possibly
waiting) and if that succeeds, they will continue to receive more messages but
without waiting. Every time an operation succeeds the timestamp received will
be recorded. And at the end a list of silent workers will be determined based
on the difference (delta) between the response timestamp and the current
timestamp becoming too old.

Please note that this is a valid, probably even preferred, WAY of WORKING for the SUPERVISOR:
1.  receive the heartbeats (recv() below) with a timeout equal to the worker heartbeat interval.
2.  for all silent workers check whether their session are still there.
3a. start sessions when they are missing.
3b. when all the sessions are still there but not responding,
    increase the silence threshold for the next run.
4.  when that threshold is above some limit,
    stop the supervisor and workers and restart the whole process (supervisor and workers).

Please note that this is a valid, probably even preferred, WAY of WORKING for the regular WORKER:
1.  send a heartbeat (send() below) without blocking (timeout 0).
2.  if there is a silent worker (must be the supervisor) check whether its session is still there.
3a. start the supervisor session when they are missing.
3b. when the supervisor session is still there but not responding,
    increase the silence threshold for the next run.
4.  when that threshold is above some limit,
    stop the supervisor and workers and restart the whole process (supervisor and workers).
*/

procedure init
( p_supervisor_channel in supervisor_channel_t
, p_worker_nr in positive -- null for the supervisor
, p_max_worker_nr in naturaln -- 0 for the worker initialisation; the number of workers for the supervisor
, p_timestamp_tab out nocopy timestamp_tab_t
);
/** Initialize the channel for a worker or supervisor. */

procedure done
( p_supervisor_channel in supervisor_channel_t
, p_worker_nr in positive default null -- null for the supervisor
);
/** Cleanup the channel for a worker or supervisor. */

procedure send
( p_supervisor_channel in supervisor_channel_t
, p_worker_nr in positiven -- the worker number
, p_silence_threshold in api_time_pkg.seconds_t -- the number of seconds the supervisor may be silent before being added to the silent workers
, p_first_recv_timeout in naturaln default 0 -- first receive timeout in seconds
, p_timestamp_tab in out nocopy timestamp_tab_t
, p_silent_worker_tab out nocopy silent_worker_tab_t
);
/**
The actions:
1. send a heartbeat to the supervisor channel with a timeout of 0 seconds.
2. if that fails, stop processing and go to the last step.
3. receive a response on the response channel while waiting for p_first_recv_timeout seconds the first time.
4. if that fails, stop processing and go to the last step.
5. record the timestamp in the timestamp table (index 0 since it is the supervisor).
6. go back to 3 for another message to receive.
7. determine the silent workers (just one, the supervisor).

The contents of the message sent to the supervisor:
- the worker number
- the current timestamp of the worker

The contents of the response message received from the supervisor:
- the current timestamp of the supervisor

See also recv() below.
*/

procedure recv
( p_supervisor_channel in supervisor_channel_t
, p_silence_threshold in api_time_pkg.seconds_t -- the number of seconds the supervisor may be silent before being added to the silent workers
, p_first_recv_timeout in naturaln default 0 -- first receive timeout in seconds
, p_timestamp_tab in out nocopy timestamp_tab_t
, p_silent_worker_tab out nocopy silent_worker_tab_t
);
/**
The actions:
1. receive a worker heartbeat message on the supervisor channel with a timeout of p_first_recv_timeout seconds the first time.
2. if that fails, stop processing and go to the last step.
3. the rest of the operations will be non-blocking.
4. send a response with the current timestamp of the supervisor.
5. if that fails, stop processing and go to the last step.
6. record the timestamp in the timestamp table.
7. go back to 1 for another message to receive.
8. determine the silent workers.

The contents of the messages received from the worker:
- the worker number
- the current timestamp of the worker

The contents of the response message sent to the worker:
- the current timestamp of the supervisor

See also send() above.
*/

end api_heartbeat_pkg;
/

