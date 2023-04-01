CREATE OR REPLACE PACKAGE MSG_CONSTANTS_PKG AUTHID DEFINER
is

/*
-- for MSG_AQ_PKG
*/

c_buffered_messaging constant boolean := false; -- buffered messaging enabled? true in production
c_multiple_consumers constant boolean := false; -- single consumer is the fastest option
c_default_subscriber constant varchar2(30 char) := 'DEFAULT_SUBSCRIBER';

-- c_default_processing_method can be:
-- 1) 'plsql://' || $$PLSQL_UNIT_OWNER || '.' || 'MSG_NOTIFICATION_PRC'
-- 2) 'package://' || $$PLSQL_UNIT_OWNER || '.' || 'MSG_SCHEDULER_PKG'
c_default_processing_method constant varchar(128 char) := 'plsql://' || $$PLSQL_UNIT_OWNER || '.' || 'MSG_NOTIFICATION_PRC';

/*
-- for MSG_SCHEDULER_PKG
*/

-- job scheduler schedule
-- job duration
c_time_between_runs constant positiven := 5; -- seconds between subsequent runs

-- c_repeat_interval constant varchar2(100) := 'FREQ=DAILY; BYHOUR=0; BYMINUTE=0; BYSECOND=0'; -- start every day at 00:00:00
c_repeat_interval constant varchar2(100) := 'FREQ=HOURLY; BYMINUTE=0; BYSECOND=0'; -- start every hour at 00:00

-- exactly one of the following two parameters must be not null
c_nr_workers_each_group constant positive := 1; -- the total number of workers will be this number multiplied by the number of groups
c_nr_workers_exact constant positive := null; -- the total number of workers will be this number

-- heartbeat section
c_time_between_heartbeats constant positiven := 10; -- seconds between subsequent heartbeats send/receive actions
c_max_silence_threshold constant oracle_tools.api_time_pkg.seconds_t := c_time_between_heartbeats * 6;

-- these DBUG channels will be activated by msg_scheduler_pkg.init
c_dbug_channel_active_tab constant sys.odcivarchar2list :=
  sys.odcivarchar2list
  ( 'DBMS_APPLICATION_INFO'
$if oracle_tools.cfg_pkg.c_testing $then
  , 'LOG4PLSQL'
$end  
  , 'PROFILER'
  --, 'BC_LOG' -- for BlueCurrent
  );

-- these DBUG channels will be de-activated by msg_scheduler_pkg.init
c_dbug_channel_inactive_tab constant sys.odcivarchar2list :=
  sys.odcivarchar2list
  ( 'DBMS_OUTPUT'
$if not(oracle_tools.cfg_pkg.c_testing) $then
  , 'LOG4PLSQL'
$end  
  , 'PLSDBUG'
  );

/*
-- for WEB_SERVICE_PKG
*/

c_prefer_to_use_utl_http constant boolean := false; -- utl_http versus apex_web_service

/**
This package just defines constants to be used by the MSG subsystem.
It will never be separately published as a repeatable Flyway object since this package
actually allows you to tweak the MSG subsystem without changing the (other) code.

So it will be installed only once (no CREATE OR REPLACE, just CREATE)
after which YOU can modify it.
**/
end;
/
