CREATE PACKAGE MSG_CONSTANTS_PKG AUTHID DEFINER
is

c_buffered_messaging constant boolean := true; -- buffered messaging enabled?
c_multiple_consumers constant boolean := false; -- single consumer is the fastest option
c_default_subscriber constant varchar2(30 char) := case when c_multiple_consumers then 'DEFAULT_SUBSCRIBER' end;
c_default_plsql_callback constant varchar(128 char) := $$PLSQL_UNIT_OWNER || '.' || 'MSG_NOTIFICATION_PRC';

c_dbug_channel_tab constant sys.odcivarchar2list :=
  sys.odcivarchar2list
  ( 'DBMS_APPLICATION_INFO'
  , 'DBMS_OUTPUT'
  , 'LOG4PLSQL'
  , 'PROFILER'
  , 'PLSDBUG'
  );

/**
This package just defines constants to be used by the MSG subsystem.
It will never be separately published as a repeatable Flyway object since this package
actually allows you to tweak the MSG subsystem without changing the (other) code.

So it will be installed only once (no CREATE OR REPLACE, just CREATE)
after which YOU can modify it.
**/
end;
/
