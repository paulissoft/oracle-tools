CREATE OR REPLACE PACKAGE BODY "ADMIN_SYSTEM_PKG" AS

procedure kill_session
( p_sid in number
, p_serial# in number
, p_immediate in boolean
)
is
begin
  for r in
  ( select  s.sid
    ,       s.serial#
    from    v$session s
    where   s.sid = p_sid
    and     ( p_serial# is null or s.serial# = p_serial# )
    and     sys_context('USERENV', 'SESSION_USER') in ( s.username, $$PLSQL_UNIT_OWNER ) -- ADMIN may kill anything
  )
  loop
    execute immediate utl_lms.format_message
                      ( q'[ALTER SYSTEM KILL SESSION '%s,%s' %s]'
                      , to_char(r.sid)
                      , to_char(r.serial#)
                      , case when p_immediate then 'IMMEDIATE' end
                      );
  end loop;                   
end kill_session;

procedure disconnect_session
( p_sid in number
, p_serial# in number
, p_immediate in boolean
)
is
begin
  for r in
  ( select  s.sid
    ,       s.serial#
    from    v$session s
    where   s.sid = p_sid
    and     ( p_serial# is null or s.serial# = p_serial# )
    and     sys_context('USERENV', 'SESSION_USER') in ( s.username, $$PLSQL_UNIT_OWNER ) -- ADMIN may kill anything
  )
  loop
    execute immediate utl_lms.format_message
                      ( q'[ALTER SYSTEM DISCONNECT SESSION '%s,%s' %s]'
                      , to_char(r.sid)
                      , to_char(r.serial#)
                      , case when p_immediate then 'IMMEDIATE' else 'POST_TRANSACTION' end
                      );
  end loop;   
end disconnect_session;

procedure cancel_sql
( p_sid in number
, p_serial# in number
, p_sql_id in varchar2
)
is
begin
  for r in
  ( select  s.sid
    ,       s.serial#
    ,       s.sql_id
    from    v$session s
    where   s.sid = p_sid
    and     ( p_serial# is null or s.serial# = p_serial# )
    and     s.sql_id = p_sql_id
    and     sys_context('USERENV', 'SESSION_USER') in ( s.username, $$PLSQL_UNIT_OWNER ) -- ADMIN may kill anything
  )
  loop
    execute immediate utl_lms.format_message
                      ( q'[ALTER SYSTEM CANCEL SQL '%s,%s,%s']'
                      , to_char(p_sid)
                      , to_char(p_serial#)
                      , r.sql_id
                      );
  end loop;
end cancel_sql;

function show_locked_objects
return t_object_tab
pipelined
is
begin
  for r in 
  ( select  o.owner
    ,       o.name as object_name
    ,       o.type as object_type
    from    v$db_object_cache o
    where   sys_context('USERENV', 'SESSION_USER') in ( o.owner, $$PLSQL_UNIT_OWNER ) -- ADMIN may see anything
    and     o.locks > 0
  )
  loop
    pipe row (r);
  end loop;
  return;
end show_locked_objects;  

function does_session_exist
( p_sid in number -- the session id
, p_serial# in number default null -- the serial number
)
return integer -- 0 (false) or 1 (true)
is
  l_found pls_integer;
begin
  select  1
  into    l_found
  from    v$session s
  where   s.sid = p_sid
  and     s.serial# = p_serial#;
  return 1;
exception
  when no_data_found
  then return 0;
end does_session_exist;  

function does_session_exist
( p_audsid in number -- the v$session.audsid value as returned by sys_context('USERENV', 'SESSIONID')
)
return integer -- 0 (false) or 1 (true)
is
  l_found pls_integer;
begin
  select  1
  into    l_found
  from    v$session s
  where   s.audsid = p_audsid;
  return 1;
exception
  when no_data_found
  then return 0;
end does_session_exist;  


end admin_system_pkg;
/
