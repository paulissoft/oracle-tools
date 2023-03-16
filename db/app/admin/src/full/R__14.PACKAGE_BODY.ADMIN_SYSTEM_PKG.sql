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
    and     s.username = sys_context('USERENV', 'SESSION_USER')
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
    and     s.username = sys_context('USERENV', 'SESSION_USER')
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
    and     s.username = sys_context('USERENV', 'SESSION_USER')
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

end admin_system_pkg;
/
