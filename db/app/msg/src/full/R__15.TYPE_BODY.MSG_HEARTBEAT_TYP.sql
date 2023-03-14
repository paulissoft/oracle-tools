CREATE OR REPLACE TYPE BODY "MSG_HEARTBEAT_TYP" AS

constructor function msg_heartbeat_typ
( self in out nocopy msg_heartbeat_typ
, p_controlling_package in varchar2
, p_worker_nr in integer
)
return self as result
is
begin
  self.construct
  ( p_group$ => p_controlling_package || '.' || msg_heartbeat_typ.default_group()
  , p_context$ => to_char(p_worker_nr)
  );
  return;
end msg_heartbeat_typ;  

overriding
member function must_be_processed
( self in msg_heartbeat_typ
, p_maybe_later in integer -- True (1) or false (0)
)
return integer
is
begin
  return p_maybe_later; -- never invoke process$now
end must_be_processed;

overriding
member function default_processing_method
( self in msg_heartbeat_typ
)
return varchar2
is
begin
  return null;
end default_processing_method;

static function default_group
return varchar2
is
begin
  return 'HEARTBEAT';
end default_group;

end;
/

