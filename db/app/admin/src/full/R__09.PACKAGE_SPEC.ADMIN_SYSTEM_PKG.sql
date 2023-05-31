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

type t_object_rec is record
( owner v$db_object_cache.owner%type
, object_name v$db_object_cache.name%type
, object_type v$db_object_cache.type%type
);

type t_object_tab is table of t_object_rec;

function show_locked_objects
return t_object_tab
pipelined;
/** Show locked objects (select * from v$db_object_cache where locks > 0) for the current session user or for the owner of this package. **/

END ADMIN_SYSTEM_PKG;
/
