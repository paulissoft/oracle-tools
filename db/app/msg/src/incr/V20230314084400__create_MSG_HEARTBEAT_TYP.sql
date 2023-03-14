create or replace type msg_heartbeat_typ under msg_typ
( 
/**

This type is used to send heartbeats to the supervisor.

**/
  constructor function msg_heartbeat_typ
  ( self in out nocopy msg_heartbeat_typ
  , p_controlling_package in varchar2 default null -- sets attribute group$ to this plus a dot and default_group() from below
  , p_worker_nr in integer default null -- sets attribute context$ to the worker number
  )
  return self as result

, overriding
  member function must_be_processed
  ( self in msg_heartbeat_typ
  , p_maybe_later in integer -- True (1) or false (0)
  )
  return integer -- True (1) or false (0)
/** Will return p_maybe_later so it will only invoke process$later() (i.e. enqueue) and never process$now(). **/

, overriding
  member function default_processing_method
  ( self in msg_heartbeat_typ
  )
  return varchar2
/** Returns NULL to indicate that a custom routine will dequeue and process the response. **/  

, static function default_group
  return varchar2
/** The default group will be HEARTBEAT. **/  

)
not final;
/
