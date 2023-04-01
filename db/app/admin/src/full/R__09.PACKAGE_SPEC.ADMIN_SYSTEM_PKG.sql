CREATE OR REPLACE PACKAGE "ADMIN_SYSTEM_PKG" AUTHID DEFINER AS 

/**
This package contains various kill session and kill sql routines that will only be invoked for the session user in order to make it more safe to use.
The session user is the value of sys_context('USERENV', 'SESSION_USER').
See also [Killing Oracle Sessions (ALTER SYSTEM KILL / DISCONNECT SESSION)](https://oracle-base.com/articles/misc/killing-oracle-sessions).
**/

procedure kill_session
( p_sid in number -- filter on user sessions with sid equal to p_sid 
, p_serial# in number default null -- when not null the session serial# must also match p_serial#
, p_immediate in boolean default false -- return immediate or wait for the kill to complete
);
/**
Invokes something like this but only for current user sessions:

```
ALTER SYSTEM KILL SESSION 'sid,serial#' [ IMMEDIATE ]
```
**/

procedure disconnect_session
( p_sid in number -- filter on user sessions with sid equal to p_sid 
, p_serial# in number default null -- when not null the session serial# must also match p_serial#
, p_immediate in boolean default false -- return immediate or wait for the kill to complete
);
/**
Invokes something like this but only for current user sessions:

```
ALTER SYSTEM DISCONNECT SESSION 'sid,serial#' [ IMMEDIATE | POST_TRANSACTION ]
```
**/

procedure cancel_sql
( p_sid in number -- filter on user sessions with sid equal to p_sid 
, p_serial# in number default null -- when not null the session serial# must also match p_serial#
, p_sql_id in varchar2 -- the SQL id
);
/**
Invokes something like this but only for current user sessions:

```
ALTER SYSTEM CANCEL SQL 'SID, SERIAL[, @INST_ID][, SQL_ID]'
```
**/

END ADMIN_SYSTEM_PKG;
/
