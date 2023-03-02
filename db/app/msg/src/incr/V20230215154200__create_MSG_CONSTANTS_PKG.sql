CREATE OR REPLACE PACKAGE MSG_CONSTANTS_PKG AUTHID DEFINER
is

/*
-- for MSG_AQ_PKG
*/

c_buffered_messaging constant boolean := true; -- buffered messaging enabled?
c_multiple_consumers constant boolean := false; -- single consumer is the fastest option
c_default_subscriber constant varchar2(30 char) := 'DEFAULT_SUBSCRIBER';
-- can be:
-- 1) 'plsql://' || $$PLSQL_UNIT_OWNER || '.' || 'MSG_NOTIFICATION_PRC'
-- 2) 'package://' || $$PLSQL_UNIT_OWNER || '.' || 'MSG_SCHEDULER_PKG'
c_default_processing_method constant varchar(128 char) := 'plsql://' || $$PLSQL_UNIT_OWNER || '.' || 'MSG_NOTIFICATION_PRC';

/*
-- for MSG_SCHEDULER_PKG
*/

/*
-- worker job attributes
-- It seemed that in in memory was useful, however:
-- 1) you can not use job events to signal to the supervisor that a job has completed
-- 2) the necessary job class DEFAULT_IN_MEMORY_JOB_CLASS does not seem to exist in the Oracle Cloud:
--
--      ORA-27476: "SYS"."DEFAULT_IN_MEMORY_JOB_CLASS" does not exist
--      Can not be granted neither, at least not by ADMIN
*/
c_job_style_worker constant varchar2(20 char) := 'LIGHTWEIGHT'; -- IN_MEMORY_FULL / IN_MEMORY_RUNTIME / LIGHTWEIGHT / REGULAR
c_job_class_worker constant varchar2(40 char) := 'DEFAULT_JOB_CLASS'; -- DEFAULT_IN_MEMORY_JOB_CLASS (first two styles)  / DEFAULT_JOB_CLASS (last two styles)

c_use_job_events_for_status constant boolean := true; -- c_job_style_worker in ('LIGHTWEIGHT', 'REGULAR');

-- job scheduler schedule
c_repeat_interval constant varchar2(100) := 'FREQ=DAILY; BYHOUR=0; BYMINUTE=0; BYSECOND=0'; -- start every day at 00:00:00

-- exactly one of the following two parameters must be not null
c_nr_workers_each_group constant positive := 1; -- the total number of workers will be this number multiplied by the number of groups
c_nr_workers_exact constant positive := null; -- the total number of workers will be this number

-- job duration
c_time_between_runs constant positiven := 5; -- seconds between subsequent runs
c_ttl constant positiven := (24 * 60 * 60 - c_time_between_runs); -- time to live: 24 hours minus 5 seconds

-- these DBUG channels will be activated by msg_scheduler_pkg.init
c_dbug_channel_active_tab constant sys.odcivarchar2list :=
  sys.odcivarchar2list
  ( 'DBMS_APPLICATION_INFO'
$if oracle_tools.cfg_pkg.c_testing $then
  , 'LOG4PLSQL'
$end  
  , 'PROFILER'
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

/**
This package just defines constants to be used by the MSG subsystem.
It will never be separately published as a repeatable Flyway object since this package
actually allows you to tweak the MSG subsystem without changing the (other) code.

So it will be installed only once (no CREATE OR REPLACE, just CREATE)
after which YOU can modify it.
**/
end;
/