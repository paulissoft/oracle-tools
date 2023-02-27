CREATE PACKAGE MSG_CONSTANTS_PKG AUTHID DEFINER
is

c_buffered_messaging constant boolean := true; -- buffered messaging enabled?
c_multiple_consumers constant boolean := false; -- single consumer is the fastest option
c_default_subscriber constant varchar2(30 char) := case when c_multiple_consumers then 'DEFAULT_SUBSCRIBER' end;
-- can be:
-- 1) 'plsql://' || $$PLSQL_UNIT_OWNER || '.' || 'MSG_NOTIFICATION_PRC'
-- 2) 'package://' || $$PLSQL_UNIT_OWNER || '.' || 'MSG_SCHEDULER_PKG'
c_default_processing_method constant varchar(128 char) := 'plsql://' || $$PLSQL_UNIT_OWNER || '.' || 'MSG_NOTIFICATION_PRC';

-- job scheduler schedule
c_job_schedule_start_date constant timestamp with time zone := null;
c_job_schedule_repeat_interval constant varchar2(100) := 'FREQ=DAILY; BYHOUR=0; BYMINUTE=0; BYSECOND=0'; -- start every day at 00:00:00
c_job_schedule_end_date constant timestamp with time zone := null;

c_dbug_channel_active_tab constant sys.odcivarchar2list :=
  sys.odcivarchar2list
  ( 'DBMS_APPLICATION_INFO'
$if oracle_tools.cfg_pkg.c_testing $then
  , 'LOG4PLSQL'
$end  
  , 'PROFILER'
  );

c_dbug_channel_inactive_tab constant sys.odcivarchar2list :=
  sys.odcivarchar2list
  ( 'DBMS_OUTPUT'
$if not(oracle_tools.cfg_pkg.c_testing) $then
  , 'LOG4PLSQL'
$end  
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
