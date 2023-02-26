CREATE OR REPLACE PACKAGE BODY "MSG_AQ_PKG" AS

-- private stuff

e_dbms_pipe_error exception;
c_dbms_pipe_error constant integer := -20100;

pragma exception_init(e_dbms_pipe_error, -20100);

c_session_id constant user_scheduler_running_jobs.session_id%type := to_number(sys_context('USERENV', 'SID'));

c_schema constant all_objects.owner%type := $$PLSQL_UNIT_OWNER;

"yyyy-mm-dd hh24:mi:ss" constant varchar2(100) := 'yyyy-mm-dd hh24:mi:ss';

c_program_supervisor constant user_scheduler_programs.program_name%type := 'DEQUEUE_AND_PROCESS_SUPERVISOR';
c_job_supervisor constant user_scheduler_jobs.job_name%type := 'MSG_PROCESS';
c_job_supervisor_expr constant user_scheduler_jobs.job_name%type := replace(c_job_supervisor, '_', '\_') || '%'; -- for like

c_program_worker constant user_scheduler_programs.program_name%type := 'DEQUEUE_AND_PROCESS_WORKER';
c_job_worker_expr constant user_scheduler_jobs.job_name%type := c_job_supervisor_expr || '#%';

$if oracle_tools.cfg_pkg.c_debugging $then
 
type t_dbug_channel_active_tab is table of boolean index by all_objects.object_name%type;

g_dbug_channel_active_tab t_dbug_channel_active_tab;

$end -- $if oracle_tools.cfg_pkg.c_debugging $then

g_longops_rec oracle_tools.api_longops_pkg.t_longops_rec :=
  oracle_tools.api_longops_pkg.longops_init
  ( p_target_desc => $$PLSQL_UNIT
  , p_totalwork => 0
  , p_op_name => 'process'
  , p_units => 'messages'
  );

procedure init
is
$if oracle_tools.cfg_pkg.c_debugging $then
  l_dbug_channel_tab constant sys.odcivarchar2list :=
    sys.odcivarchar2list
    ( 'BC_LOG'
    , 'DBMS_APPLICATION_INFO'
    , 'DBMS_OUTPUT'
    , 'LOG4PLSQL'
    , 'PROFILER'
    , 'PLSDBUG'
    );
$end    
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  for i_idx in l_dbug_channel_tab.first .. l_dbug_channel_tab.last
  loop
    g_dbug_channel_active_tab(l_dbug_channel_tab(i_idx)) := dbug.active(l_dbug_channel_tab(i_idx));

    dbug.activate
    ( l_dbug_channel_tab(i_idx)
    , case 
        when l_dbug_channel_tab(i_idx) in
             ( 'BC_LOG'
             , 'DBMS_APPLICATION_INFO'
$if oracle_tools.cfg_pkg.c_testing $then
             , 'LOG4PLSQL'
$end  
             , 'PROFILER'
             )
        then true -- to be able to use select * from table(dbug_profiler.show)
        else false
      end
    );
  end loop;
$end

  null;
end init;

$if oracle_tools.cfg_pkg.c_debugging $then

procedure profiler_report
is
  l_dbug_channel all_objects.object_name%type := g_dbug_channel_active_tab.first;
begin
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'PROFILER_REPORT');

  for r in
  ( select  t.module_name
    ,       t.nr_calls
    ,       t.elapsed_time
    ,       t.avg_time
    from    table(dbug_profiler.show) t
  )
  loop
    dbug.print
    ( dbug."info"
    , 'module: %s; # calls: %s, elapsed time: %s; avg_time: %s'
    , r.module_name
    , r.nr_calls
    , r.elapsed_time
    , r.avg_time
    );
  end loop;

  dbug.leave;
end profiler_report;

$end -- $if oracle_tools.cfg_pkg.c_debugging $then

procedure done
is
$if oracle_tools.cfg_pkg.c_debugging $then
  l_dbug_channel all_objects.object_name%type := g_dbug_channel_active_tab.first;
$end  
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  profiler_report;
$end  

  oracle_tools.api_longops_pkg.longops_done(g_longops_rec);

$if oracle_tools.cfg_pkg.c_debugging $then
  while l_dbug_channel is not null
  loop
    dbug.activate('BC_LOG', g_dbug_channel_active_tab(l_dbug_channel));
    
    l_dbug_channel := g_dbug_channel_active_tab.next(l_dbug_channel);
  end loop;
$end -- $if oracle_tools.cfg_pkg.c_debugging $then  
end done;

function visibility_descr
( p_visibility in binary_integer
)
return varchar2
is
begin
  return case p_visibility
           when dbms_aq.on_commit then 'ON_COMMIT'
           when dbms_aq.immediate then 'IMMEDIATE'
           else 'UNKNOWN visibility (' || to_char(p_visibility) || ')'
         end;
end visibility_descr;

function delivery_mode_descr
( p_delivery_mode in binary_integer
)
return varchar2
is
begin
  return case p_delivery_mode
           when dbms_aq.persistent then 'PERSISTENT'
           when dbms_aq.buffered then 'BUFFERED'
           when dbms_aq.persistent_or_buffered then 'PERSISTENT_OR_BUFFERED'
           else 'UNKNOWN delivey mode (' || to_char(p_delivery_mode) || ')'
         end;
end delivery_mode_descr;

function dequeue_mode_descr
( p_dequeue_mode in binary_integer
)
return varchar2
is
begin
  return case p_dequeue_mode
           when dbms_aq.browse then 'BROWSE'
           when dbms_aq.locked then 'LOCKED'
           when dbms_aq.remove then 'REMOVE'
           when dbms_aq.remove_nodata then 'REMOVE_NODATA'
           else 'UNKNOWN dequeue mode (' || to_char(p_dequeue_mode) || ')'
         end;
end dequeue_mode_descr;

function navigation_descr
( p_navigation in binary_integer
)
return varchar2
is
begin
  return case p_navigation
           when dbms_aq.next_message then 'NEXT_MESSAGE'
           when dbms_aq.next_transaction then 'NEXT_TRANSACTION'
           when dbms_aq.first_message then 'FIRST_MESSAGE'
           when dbms_aq.first_message_multi_group then 'FIRST_MESSAGE_MULTI_GROUP'
           when dbms_aq.next_message_multi_group then 'NEXT_MESSAGE_MULTI_GROUP'
           else 'UNKNOWN navigation (' || to_char(p_navigation) || ')'
         end;
end navigation_descr;

function state_descr
( p_state in binary_integer
)
return varchar2
is
begin
  return case p_state
           when dbms_aq.ready then 'READY'
           when dbms_aq.waiting then 'WAITING'
           when dbms_aq.processed then 'PROCESSED'
           when dbms_aq.expired then 'EXPIRED'
           else 'UNKNOWN state (' || to_char(p_state) || ')'
         end;
end state_descr;

function sql_object_name
( p_schema in varchar2
, p_object_name in varchar2
)
return varchar2
is
begin
  return p_schema || '.' || p_object_name;
end sql_object_name;

procedure create_queue_at
( p_queue_name in varchar2
, p_comment in varchar2
)
is
  pragma autonomous_transaction;
begin
  create_queue
  ( p_queue_name => p_queue_name
  , p_comment => p_comment
  );
  commit;
end create_queue_at;

procedure start_queue_at
( p_queue_name in varchar2
)
is
  pragma autonomous_transaction;
begin
  start_queue
  ( p_queue_name => p_queue_name
  );
  commit;
end start_queue_at;

$if msg_aq_pkg.c_multiple_consumers $then

procedure add_subscriber_at
( p_queue_name in varchar2
, p_subscriber in varchar2 default c_default_subscriber
, p_rule in varchar2 default null
, p_delivery_mode in binary_integer default c_subscriber_delivery_mode
)
is
  pragma autonomous_transaction;
begin
  add_subscriber
  ( p_queue_name => p_queue_name
  , p_subscriber => p_subscriber
  , p_rule => p_rule
  , p_delivery_mode => p_delivery_mode
  );
  commit;
end add_subscriber_at;  

$end

procedure register_at
( p_queue_name in varchar2
, p_subscriber in varchar2 default c_default_subscriber -- the name of the subscriber already added via add_subscriber (for multi-consumer queues only)
, p_plsql_callback in varchar -- schema.procedure
)
is
  pragma autonomous_transaction;
begin
  register
  ( p_queue_name => p_queue_name
  , p_subscriber => p_subscriber
  , p_plsql_callback => p_plsql_callback
  );
  commit;
end register_at;  

function does_job_exist
( p_job_name in varchar2
)
return boolean
is
  l_found pls_integer;
begin
  select  1
  into    l_found
  from    user_scheduler_jobs j
  where   j.job_name = p_job_name;

  return true;
exception
  when no_data_found
  then
    return false;
end does_job_exist;

function does_program_exist
( p_program_name in varchar2
)
return boolean
is
  l_found pls_integer;
begin
  select  1
  into    l_found
  from    user_scheduler_programs p
  where   p.program_name = p_program_name;

  return true;
exception
  when no_data_found
  then
    return false;
end does_program_exist;

function session_job_name
( p_session_id in varchar2 default c_session_id
)
return varchar2
is
  l_job_name user_scheduler_running_jobs.job_name%type;
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.SESSION_JOB_NAME');
  dbug.print(dbug."input", 'p_session_id: %s', p_session_id);
$end

  -- Is this session running as a job?
  -- If not, just create a job name supervisor to be used by the worker jobs.
  begin
    select  j.job_name
    into    l_job_name
    from    user_scheduler_running_jobs j
    where   j.session_id = p_session_id;
  exception
    when no_data_found
    then
      l_job_name := null;
  end;

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.print(dbug."output", 'return: %s', l_job_name);
  dbug.leave;
$end

  return l_job_name;
end session_job_name;

procedure create_program
( p_program_name in varchar2
)
is
  l_program_name constant all_objects.object_name%type := upper(p_program_name);
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.CREATE_PROGRAM');
  dbug.print
  ( dbug."input"
  , 'p_program_name: %s'
  , p_program_name
  );
$end

  case l_program_name
    when c_program_supervisor
    then
      dbms_scheduler.create_program
      ( program_name => l_program_name
      , program_type => 'STORED_PROCEDURE'
      , program_action => $$PLSQL_UNIT || '.' || p_program_name -- program name is the same as module name
      , number_of_arguments => 5
      , enabled => false
      , comments => 'Main program for dequeueing and processing that spawns other worker in-memory jobs and supervises them.'
      );

      for i_par_idx in 1..5
      loop
        dbms_scheduler.define_program_argument
        ( program_name => l_program_name
        , argument_name => case i_par_idx
                             when 1 then 'P_INCLUDE_QUEUE_NAME_LIST'
                             when 2 then 'P_EXCLUDE_QUEUE_NAME_LIST'
                             when 3 then 'P_NR_WORKERS_MULTIPLY_PER_Q'
                             when 4 then 'P_NR_WORKERS_EXACT'
                             when 5 then 'P_TTL'
                           end
        , argument_position => i_par_idx
        , argument_type => case 
                             when i_par_idx <= 2
                             then 'VARCHAR2'
                             else 'NUMBER'
                           end
        , default_value => case i_par_idx
                             when 1 then '%'
                             when 2 then replace(web_service_response_typ.default_group, '_', '\_')
                             when 3 then null
                             when 4 then null
                             when 5 then to_char(c_one_day_minus_something)
                           end
        );
      end loop;

    when c_program_worker
    then
      dbms_scheduler.create_program
      ( program_name => l_program_name
      , program_type => 'STORED_PROCEDURE'
      , program_action => $$PLSQL_UNIT || '.' || p_program_name -- program name is the same as module name
      , number_of_arguments => 4
      , enabled => false
      , comments => 'Worker program for dequeueing and processing spawned by the main job as an in-memory job.'
      );
  
      for i_par_idx in 1..4
      loop
        dbms_scheduler.define_program_argument
        ( program_name => l_program_name
        , argument_name => case i_par_idx
                             when 1 then 'P_QUEUE_NAME_LIST'
                             when 2 then 'P_WORKER_NR'
                             when 3 then 'P_START_DATE_STR'
                             when 4 then 'P_END_DATE_STR'
                           end
        , argument_position => i_par_idx
        , argument_type => case 
                             when i_par_idx = 2
                             then 'NUMBER'
                             else 'VARCHAR2'
                           end
        , default_value => null
        );
      end loop;
  end case;
      
  dbms_scheduler.enable(name => l_program_name);

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
$end
end create_program;

procedure create_job
( p_job_name in varchar2
, p_start_date in timestamp with time zone default null
, p_repeat_interval in varchar2 default null
, p_end_date in timestamp with time zone default null -- will this be used?
)
is
  l_job_name constant user_scheduler_jobs.job_name%type := upper(p_job_name);
  l_program_name user_scheduler_programs.program_name%type;
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.CREATE_JOB');
  dbug.print
  ( dbug."input"
  , 'p_job_name: %s; p_start_date: %s; p_repeat_interval: %s; p_end_date: %s'
  , p_job_name
  , to_char(p_start_date, "yyyy-mm-dd hh24:mi:ss")
  , p_repeat_interval
  , to_char(p_end_date, "yyyy-mm-dd hh24:mi:ss")
  );
$end

  case 
    when l_job_name like c_job_worker_expr escape '\' -- c_job_worker_expr is longer than c_job_supervisor_expr so start here
    then
      /*
      -- See https://oracle-base.com/articles/12c/scheduler-enhancements-12cr2#in-memory-jobs
      --
      -- IN_MEMORY_FULL: A job that must be associated with a program,
      -- can't have a repeat interval and persists nothing to
      -- disk. These jobs use a little more memory, but since they
      -- persist nothing to disk they have reduced overheard and zero
      -- redo generation as a result of the job mechanism itself. As
      -- nothing is persisted to disk they are only present on the
      -- instance that created them.
      */
      l_program_name := c_program_worker;
      if not(does_program_exist(l_program_name))
      then
        create_program(l_program_name);
      end if;
      
      dbms_scheduler.create_job
      ( job_name => l_job_name
      , program_name => l_program_name
      , start_date => p_start_date
        -- will never repeat
      , repeat_interval => null
      , end_date => p_end_date
        -- ORA-27476: "SYS"."DEFAULT_IN_MEMORY_JOB_CLASS" does not exist
        -- Can not be granted neither, at least not by ADMIN
      -- , job_class => 'DEFAULT_IN_MEMORY_JOB_CLASS'
      , enabled => false -- so we can set job arguments
      , auto_drop => true -- one-off jobs
      , comments => 'Worker job for dequeueing and processing.'
      --, job_style => 'IN_MEMORY_FULL'
      --, job_style => 'IN_MEMORY_RUNTIME'
      , job_style => 'LIGHTWEIGHT'
      , credential_name => null
      , destination_name => null
      );
  
    when l_job_name like c_job_supervisor_expr escape '\'
    then
      l_program_name := c_program_supervisor;
      if not(does_program_exist(l_program_name))
      then
        create_program(l_program_name);
      end if;
      
      dbms_scheduler.create_job
      ( job_name => l_job_name
      , program_name => l_program_name
      , start_date => p_start_date
      , repeat_interval => p_repeat_interval
      , end_date => p_end_date
      , job_class => 'DEFAULT_JOB_CLASS'
      , enabled => false -- so we can set job arguments
      , auto_drop => false
      , comments => 'Main job for dequeueing and processing.'
      , job_style => 'REGULAR'
      , credential_name => null
      , destination_name => null
      );
  end case;
  
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
$end
end create_job;

procedure run_job_to_dequeue_at
( p_fq_queue_name in varchar2
)
is
  pragma autonomous_transaction;

  l_job_name all_objects.object_name%type;
begin
  -- Does job MSG_PROCESS exist?
  -- a) If true, we must create a one-off job to dequeue the new queue.
  --    When that one-off job finishes, subsequent runs of the normal MSG_PROCESS job will take over.
  -- b) If not, we just create MSG_PROCESS that will dequeue all queues.
  if does_job_exist(c_job_supervisor)
  then
    -- Case a
    l_job_name := c_job_supervisor || '_' || trim('"' from p_fq_queue_name);
  else
    -- Case b
    l_job_name := c_job_supervisor;
  end if;

  dequeue_and_process_supervisor
  ( p_include_queue_name_list => case
                                   when l_job_name <> c_job_supervisor
                                   then replace(p_fq_queue_name, '_', '\_')
                                   else '%'
                                 end
  , p_nr_workers_multiply_per_q => 1
    -- job parameters
  , p_job_name => l_job_name
  , p_repeat_interval => case when l_job_name = c_job_supervisor then 'FREQ=DAILY' end
  );
end run_job_to_dequeue_at;

-- dedicated procedure to enable profiling
procedure process_msg
( p_msg in msg_typ
, p_commit in boolean
)
is
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter('PROCESS ' || p_msg.group$);
  dbug.print(dbug."input", 'p_commit: %s', dbug.cast_to_varchar2(p_commit));
$end

  savepoint spt;
  
  p_msg.process(p_maybe_later => 0);

  oracle_tools.api_longops_pkg.longops_show(g_longops_rec);
  
  if p_commit
  then
    commit; -- remove message from the queue
  end if;

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
$end
exception
  when others
  then
$if oracle_tools.cfg_pkg.c_debugging $then
    dbug.on_error;
$end

    rollback to spt;

$if oracle_tools.cfg_pkg.c_debugging $then
    dbug.leave;
$end

    -- raise; -- no reraise
end process_msg;

procedure send_worker_status
( p_job_name_supervisor in varchar2
, p_worker_nr in integer
, p_sqlcode in integer default 0
, p_sqlerrm in varchar2 default null
, p_timeout in integer default 0
)
is
  l_result pls_integer;
begin
  dbms_pipe.reset_buffer;
  dbms_pipe.pack_message(p_worker_nr);
  dbms_pipe.pack_message(p_sqlcode);
  dbms_pipe.pack_message(p_sqlerrm);
  dbms_pipe.pack_message(c_session_id);
  
  l_result := dbms_pipe.send_message(pipename => p_job_name_supervisor, timeout => p_timeout);

  /*
  == 0 - Success. If the pipe already exists and the user attempting to create it is authorized to use it, then Oracle returns 0, indicating success, and any data already in the pipe remains. If a user connected as SYSDBS/SYSOPER re-creates a pipe, then Oracle returns status 0, but the ownership of the pipe remains unchanged.
  == 1 - Timed out. This procedure can timeout either because it cannot get a lock on the pipe, or because the pipe remains too full to be used. If the pipe was implicitly-created and is empty, then it is removed.
  == 3 - An interrupt occurred. If the pipe was implicitly created and is empty, then it is removed.
  == ORA-23322 - Insufficient privileges. If a pipe with the same name exists and was created by a different user, then Oracle signals error ORA-23322, indicating the naming conflict.
  */

  case l_result
    when 0 -- OK
    then null;
    when 1 -- Timeout
    then raise_application_error(c_dbms_pipe_error, 'Timeout while sending to pipe "' || p_job_name_supervisor || '"');
    when 3 -- Interrupt
    then raise_application_error(c_dbms_pipe_error, 'Interrupt while sending to pipe "' || p_job_name_supervisor || '"');
  end case;  
end send_worker_status;

procedure recv_worker_status
( p_job_name_supervisor in varchar2
, p_timeout in integer
, p_worker_nr out nocopy integer
, p_sqlcode out nocopy integer
, p_sqlerrm out nocopy varchar2
, p_session_id out nocopy user_scheduler_running_jobs.session_id%type
)
is
  l_result pls_integer;
begin
  dbms_pipe.reset_buffer;

  l_result := dbms_pipe.receive_message(pipename => p_job_name_supervisor, timeout => p_timeout);

  /*
  == 0 - Success
  == 1 - Timed out. If the pipe was implicitly-created and is empty, then it is removed.
  == 2 - Record in the pipe is too large for the buffer. (This should not happen.)
  == 3 - An interrupt occurred.
  == ORA-23322 - User has insufficient privileges to read from the pipe.
  */
  case l_result
    when 0
    then
      dbms_pipe.unpack_message(p_worker_nr);
      dbms_pipe.unpack_message(p_sqlcode);
      dbms_pipe.unpack_message(p_sqlerrm);
      dbms_pipe.unpack_message(p_session_id);
    when 1
    then raise_application_error(c_dbms_pipe_error, 'Timeout while receiving from pipe "' || p_job_name_supervisor || '"');
    when 2 -- Too large
    then raise_application_error(c_dbms_pipe_error, 'Record too large while receiving from pipe "' || p_job_name_supervisor || '"');
    when 3 -- Interrupt
    then raise_application_error(c_dbms_pipe_error, 'Interrupt while receiving from pipe "' || p_job_name_supervisor || '"');
  end case;
end recv_worker_status;

-- public routines

function queue_name
( p_msg in msg_typ
)
return varchar2
is
begin
  return oracle_tools.data_api_pkg.dbms_assert$enquote_name(replace(p_msg.group$, '.', '$'), 'queue');
end queue_name;

procedure create_queue_table
is
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.CREATE_QUEUE_TABLE');
$end

  dbms_aqadm.create_queue_table
  ( queue_table => c_queue_table
  , queue_payload_type => sql_object_name(c_schema, 'MSG_TYP')
--, storage_clause       IN      VARCHAR2        DEFAULT NULL
--, sort_list            IN      VARCHAR2        DEFAULT NULL
  , multiple_consumers => c_multiple_consumers
  , message_grouping => dbms_aqadm.none
  , comment => 'Queue table containing messages'
--, auto_commit          IN      BOOLEAN         DEFAULT TRUE
--, primary_instance     IN      BINARY_INTEGER  DEFAULT 0
--, secondary_instance   IN      BINARY_INTEGER  DEFAULT 0
--, compatible           IN      VARCHAR2        DEFAULT NULL
--, secure               IN      BOOLEAN         DEFAULT FALSE
--, replication_mode     IN      BINARY_INTEGER  DEFAULT NONE
  );

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
$end
end create_queue_table;

procedure drop_queue_table
( p_force in boolean
)
is
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.DROP_QUEUE_TABLE');
  dbug.print(dbug."input", 'p_force: %s', dbug.cast_to_varchar2(p_force));
$end

  if p_force
  then
    for rq in
    ( select  q.name as queue_name
      from    all_queues q
      where   q.owner = trim('"' from c_schema)
      and     q.queue_table = trim('"' from c_queue_table)
      and     'NO' in ( trim(q.enqueue_enabled), trim(q.dequeue_enabled) )
    )
    loop
      for rsr in
      ( select  location_name
        from    user_subscr_registrations sr
        where   sr.subscription_name = c_schema || '.' || oracle_tools.data_api_pkg.dbms_assert$enquote_name(rq.queue_name, 'queue')
      )
      loop
        unregister
        ( p_queue_name => rq.queue_name
        , p_plsql_callback => rsr.location_name
        );
      end loop;
/*      
      if c_multiple_consumers
      then
        remove_subscriber
        ( p_queue_name => rq.queue_name
        );
      end if;
*/      
      drop_queue
      ( p_queue_name => rq.queue_name
      , p_force => p_force
      );
    end loop;
  end if;

  dbms_aqadm.drop_queue_table
  ( queue_table => c_queue_table
  , force => p_force
  );

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
$end
end drop_queue_table;

procedure create_queue
( p_queue_name in varchar2
, p_comment in varchar2
)
is
  l_queue_name constant all_queues.name%type := oracle_tools.data_api_pkg.dbms_assert$simple_sql_name(p_queue_name, 'queue');
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.CREATE_QUEUE');
  dbug.print(dbug."input", 'p_queue_name: %s; p_comment: %s', p_queue_name, p_comment);
$end

  <<try_loop>>
  for i_try in 1..2
  loop
    begin
      dbms_aqadm.create_queue
      ( queue_name => l_queue_name
      , queue_table => c_queue_table
      , queue_type => dbms_aqadm.normal_queue
      , max_retries => 0 -- no retries
      , retry_delay => 0
      , retention_time => 0
      , comment => p_comment
      );
      exit try_loop;
    exception
      when e_queue_table_does_not_exist
      then
        if i_try = 1
        then
          create_queue_table;
        else
          raise;
        end if;      
    end;
  end loop try_loop;

  start_queue
  ( p_queue_name => p_queue_name
  );

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
$end
end create_queue;

procedure drop_queue
( p_queue_name in varchar2
, p_force in boolean
)
is
  l_queue_name constant all_queues.name%type := oracle_tools.data_api_pkg.dbms_assert$simple_sql_name(p_queue_name, 'queue');
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.DROP_QUEUE');
  dbug.print
  ( dbug."input"
  , 'p_queue_name: %s; p_force: %s'
  , p_queue_name
  , dbug.cast_to_varchar2(p_force)
  );
$end

  if p_force
  then
    stop_queue
    ( p_queue_name => p_queue_name
    , p_wait => true
    );
  end if;

  dbms_aqadm.drop_queue
  ( queue_name => l_queue_name
  );

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
$end
end drop_queue;

procedure start_queue
( p_queue_name in varchar2
)
is
  l_queue_name constant all_queues.name%type := oracle_tools.data_api_pkg.dbms_assert$simple_sql_name(p_queue_name, 'queue');
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.START_QUEUE');
  dbug.print(dbug."input", 'p_queue_name: %s', p_queue_name);
$end

  dbms_aqadm.start_queue
  ( queue_name => l_queue_name
  , enqueue => true
  , dequeue => true
  );

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
$end
end start_queue;

procedure stop_queue
( p_queue_name in varchar2
, p_wait in boolean
)
is
  l_queue_name constant all_queues.name%type := oracle_tools.data_api_pkg.dbms_assert$simple_sql_name(p_queue_name, 'queue');
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.STOP_QUEUE');
  dbug.print
  ( dbug."input"
  , 'p_queue_name: %s; p_waits: %s'
  , p_queue_name
  , dbug.cast_to_varchar2(p_wait)
  );
$end

  dbms_aqadm.stop_queue
  ( queue_name => l_queue_name
  , enqueue => true
  , dequeue => true
  , wait => p_wait
  );

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
$end
end stop_queue;

procedure add_subscriber
( p_queue_name in varchar2
, p_subscriber in varchar2
, p_rule in varchar2
, p_delivery_mode in binary_integer
)
is
  l_queue_name constant all_queues.name%type := oracle_tools.data_api_pkg.dbms_assert$simple_sql_name(p_queue_name, 'queue');
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.ADD_SUBSCRIBER');
  dbug.print
  ( dbug."input"
  , 'p_queue_name: %s; p_subscriber: %s; p_rule: %s; p_delivery_mode: %s'
  , p_queue_name
  , p_subscriber
  , p_rule
  , delivery_mode_descr(p_delivery_mode)
  );
$end

  dbms_aqadm.add_subscriber
  ( queue_name => l_queue_name
  , subscriber => sys.aq$_agent(p_subscriber, null, null)
  , rule => p_rule
  , delivery_mode => p_delivery_mode
  );
  
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
$end
end add_subscriber;

procedure remove_subscriber
( p_queue_name in varchar2
, p_subscriber in varchar2
)
is
  l_queue_name constant all_queues.name%type := oracle_tools.data_api_pkg.dbms_assert$simple_sql_name(p_queue_name, 'queue');
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.REMOVE_SUBSCRIBER');
  dbug.print
  ( dbug."input"
  , 'p_queue_name: %s; p_subscriber: %s'
  , p_queue_name
  , p_subscriber
  );
$end

  dbms_aqadm.remove_subscriber
  ( queue_name => l_queue_name
  , subscriber => sys.aq$_agent(p_subscriber, null, null)
  );
  
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
$end
end remove_subscriber;

procedure register
( p_queue_name in varchar2
, p_subscriber in varchar2
, p_plsql_callback in varchar
)
is
  l_queue_name constant all_queues.name%type := oracle_tools.data_api_pkg.dbms_assert$simple_sql_name(p_queue_name, 'queue');
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.REGISTER');
  dbug.print
  ( dbug."input"
  , 'p_queue_name: %s; p_subscriber: %s; p_plsql_callback: %s'
  , p_queue_name
  , p_subscriber
  , p_plsql_callback
  );
$end

  dbms_aq.register
  ( reg_list => sys.aq$_reg_info_list
                ( sys.aq$_reg_info
                  ( name => sql_object_name(c_schema, l_queue_name) || case when p_subscriber is not null then ':' || p_subscriber end
                  , namespace => dbms_aq.namespace_aq
                  , callback => 'plsql://' || p_plsql_callback
                  , context => hextoraw('FF')
                  )
                )
  , reg_count => 1
  );

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
$end
end register;

procedure unregister
( p_queue_name in varchar2
, p_subscriber in varchar2
, p_plsql_callback in varchar
)
is
  l_queue_name constant all_queues.name%type := oracle_tools.data_api_pkg.dbms_assert$simple_sql_name(p_queue_name, 'queue');
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.UNREGISTER');
  dbug.print
  ( dbug."input"
  , 'p_queue_name: %s; p_subscriber: %s; p_plsql_callback: %s'
  , p_queue_name
  , p_subscriber
  , p_plsql_callback
  );
$end

  dbms_aq.unregister
  ( reg_list => sys.aq$_reg_info_list
                ( sys.aq$_reg_info
                  ( name => sql_object_name(c_schema, l_queue_name) || case when p_subscriber is not null then ':' || p_subscriber end
                  , namespace => dbms_aq.namespace_aq
                  , callback => 'plsql://' || p_plsql_callback
                  , context => hextoraw('FF')
                  )
                )
  , reg_count => 1
  );

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
$end
end unregister;

procedure enqueue
( p_msg in msg_typ
, p_delivery_mode in binary_integer
, p_visibility in binary_integer
, p_correlation in varchar2
, p_force in boolean
, p_plsql_callback in varchar2
, p_msgid out nocopy raw
)
is
  l_queue_name constant user_queues.name%type := queue_name(p_msg);
  l_enqueue_enabled user_queues.enqueue_enabled%type;
  l_dequeue_enabled user_queues.dequeue_enabled%type;
  l_enqueue_options dbms_aq.enqueue_options_t;
  l_message_properties dbms_aq.message_properties_t;
  c_max_tries constant simple_integer := case when p_force then 2 else 1 end;
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.ENQUEUE');
  dbug.print
  ( dbug."input"  
  , 'queue name: %s; p_delivery_mode: %s; p_visibility: %s; p_correlation: %s; p_force: %s'
  , l_queue_name
  , delivery_mode_descr(p_delivery_mode)
  , visibility_descr(p_visibility)
  , p_correlation
  , dbug.cast_to_varchar2(p_force)
  );
  dbug.print
  ( dbug."input"  
  , 'p_plsql_callback: %s'
  , p_plsql_callback
  );
  p_msg.print();
$end

  if ( p_delivery_mode = dbms_aq.persistent and p_visibility = dbms_aq.on_commit ) -- option 1 from the spec
$if msg_aq_pkg.c_buffered_messaging $then
  or ( p_delivery_mode = dbms_aq.buffered   and p_visibility = dbms_aq.immediate ) -- option 2 from the spec
$end     
  or ( p_delivery_mode = dbms_aq.persistent and p_visibility = dbms_aq.immediate ) -- option 3 from the spec
  then 
    l_enqueue_options.delivery_mode := p_delivery_mode;
    l_enqueue_options.visibility := p_visibility;
  else
    l_enqueue_options.delivery_mode := dbms_aq.persistent;
    l_enqueue_options.visibility := dbms_aq.on_commit;

$if msg_aq_pkg.c_buffered_messaging $then
    if p_msg.has_not_null_lob() = 0
    then
      -- prefer buffered messages
      l_enqueue_options.delivery_mode := dbms_aq.buffered;
      l_enqueue_options.visibility := dbms_aq.immediate;
    end if;
$end    

    -- give a warning when the input parameters were not default and not a correct combination

$if oracle_tools.cfg_pkg.c_debugging $then
    if ( p_delivery_mode is not null or p_visibility is not null )
    then
      dbug.print
      ( dbug."warning"
      , 'delivery mode: %s => %s; visibility: %s => %s'
      , delivery_mode_descr(p_delivery_mode)
      , delivery_mode_descr(l_enqueue_options.delivery_mode)
      , visibility_descr(p_visibility)
      , visibility_descr(l_enqueue_options.visibility)
      );
    end if;
$end

  end if;

  l_message_properties.delay := dbms_aq.no_delay;
  l_message_properties.correlation := p_correlation;

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.print
  ( dbug."info"
  , 'l_enqueue_options.visibility: %s; l_enqueue_options.delivery_mode: %s; l_message_properties.delay: %s'
  , visibility_descr(l_enqueue_options.visibility)
  , delivery_mode_descr(l_enqueue_options.delivery_mode)
  , l_message_properties.delay
  );
$end

  l_message_properties.expiration := dbms_aq.never;

  <<try_loop>>
  for i_try in 1 .. c_max_tries
  loop
    begin
      dbms_aq.enqueue
      ( queue_name => l_queue_name
      , enqueue_options => l_enqueue_options
      , message_properties => l_message_properties
      , payload => p_msg
      , msgid => p_msgid
      );
      exit try_loop; -- enqueue succeeded
    exception
      when e_queue_does_not_exist
      then
        if i_try != c_max_tries
        then
          create_queue_at
          ( p_queue_name => l_queue_name
          , p_comment => 'Queue for table ' || replace(l_queue_name, '$', '.')
          );
          if p_plsql_callback is not null
          then
$if msg_aq_pkg.c_multiple_consumers $then
            add_subscriber_at
            ( p_queue_name => l_queue_name
            );
$end
            register_at
            ( p_queue_name => l_queue_name
            , p_plsql_callback => p_plsql_callback
            );
          else
            -- Create and run a job to process this queue.
            run_job_to_dequeue_at
            ( p_fq_queue_name => l_queue_name
            );
          end if;
        else
          raise;
        end if;
      when e_enqueue_disabled
      then
        if i_try != c_max_tries
        then
          start_queue_at
          ( p_queue_name => l_queue_name
          );
        else
          raise;
        end if;
      when others
      then raise;
    end;
  end loop try_loop;  

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.print(dbug."output", 'p_msgid: %s', rawtohex(p_msgid));
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end enqueue;

procedure dequeue
( p_queue_name in varchar2 -- Can be fully qualified (including schema).
, p_delivery_mode in binary_integer
, p_visibility in binary_integer
, p_subscriber in varchar2
, p_dequeue_mode in binary_integer
, p_navigation in binary_integer
, p_wait in binary_integer
, p_correlation in varchar2
, p_deq_condition in varchar2
, p_force in boolean
, p_msgid in out nocopy raw
, p_message_properties out nocopy dbms_aq.message_properties_t
, p_msg out nocopy msg_typ
)
is
  l_queue_name constant user_queues.name%type := nvl(p_queue_name, queue_name(p_msg));
  l_dequeue_options dbms_aq.dequeue_options_t;
  c_max_tries constant simple_integer := case when p_force then 2 else 1 end;
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.DEQUEUE (1)');
  dbug.print
  ( dbug."input"
  , 'queue name: %s; p_delivery_mode: %s; p_visibility: %s; p_subscriber: %s; p_dequeue_mode: %s'
  , l_queue_name
  , delivery_mode_descr(p_delivery_mode)
  , visibility_descr(p_visibility)
  , p_subscriber
  , dequeue_mode_descr(p_dequeue_mode)
  );
  dbug.print
  ( dbug."input"
  , 'p_navigation: %s; p_wait: %s; p_correlation: %s; p_deq_condition: %s; p_force: %s'
  , navigation_descr(p_navigation)
  , p_wait
  , p_correlation
  , p_deq_condition
  , dbug.cast_to_varchar2(p_force)
  );
  dbug.print
  ( dbug."input"
  , 'p_msgid: %s'
  , hextoraw(p_msgid)
  );
$end

  l_dequeue_options.consumer_name := p_subscriber;
  l_dequeue_options.dequeue_mode := p_dequeue_mode;
  l_dequeue_options.navigation := p_navigation;
  l_dequeue_options.wait := p_wait;
  l_dequeue_options.correlation := p_correlation;
  l_dequeue_options.deq_condition := p_deq_condition;
  l_dequeue_options.msgid := p_msgid;

  if ( p_delivery_mode = dbms_aq.persistent             and p_visibility = dbms_aq.on_commit ) -- option 1 from the spec
$if msg_aq_pkg.c_buffered_messaging $then
  or ( p_delivery_mode = dbms_aq.buffered               and p_visibility = dbms_aq.immediate ) -- option 2 from the spec
$end     
  or ( p_delivery_mode = dbms_aq.persistent             and p_visibility = dbms_aq.immediate ) -- option 3 from the spec
$if msg_aq_pkg.c_buffered_messaging $then
  or ( p_delivery_mode = dbms_aq.persistent_or_buffered and p_visibility = dbms_aq.immediate ) -- option 4 from the spec
$end     
  then 
    l_dequeue_options.delivery_mode := p_delivery_mode;
    l_dequeue_options.visibility := p_visibility;
  else
    -- Visibility must always be IMMEDIATE when dequeuing messages with delivery mode DBMS_AQ.BUFFERED or DBMS_AQ.PERSISTENT_OR_BUFFERED
    case
$if msg_aq_pkg.c_buffered_messaging $then
      -- try to preserve at least one of the input settings
      when p_delivery_mode in (dbms_aq.buffered, dbms_aq.persistent_or_buffered)
      then
        l_dequeue_options.delivery_mode := p_delivery_mode;
        l_dequeue_options.visibility := dbms_aq.immediate;
$end

      when p_visibility = dbms_aq.on_commit
      then
        l_dequeue_options.delivery_mode := dbms_aq.persistent;
        l_dequeue_options.visibility := p_visibility;
      
      else
        l_dequeue_options.delivery_mode := dbms_aq.persistent;
        l_dequeue_options.visibility := dbms_aq.on_commit;
    end case;

    -- give a warning when the input parameters were not default and not a correct combination

$if oracle_tools.cfg_pkg.c_debugging $then
    if ( p_delivery_mode is not null or p_visibility is not null )
    then
      dbug.print
      ( dbug."warning"
      , 'delivery mode: %s => %s; visibility: %s => %s'
      , delivery_mode_descr(p_delivery_mode)
      , delivery_mode_descr(l_dequeue_options.delivery_mode)
      , visibility_descr(p_visibility)
      , visibility_descr(l_dequeue_options.visibility)
      );
    end if;
$end
  end if;  

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.print
  ( dbug."info"
  , 'l_dequeue_options.visibility: %s; l_dequeue_options.delivery_mode: %s'
  , visibility_descr(l_dequeue_options.visibility)
  , delivery_mode_descr(l_dequeue_options.delivery_mode)
  );
$end

  <<try_loop>>
  for i_try in 1 .. c_max_tries
  loop
    begin
      dbms_aq.dequeue
      ( queue_name => l_queue_name
      , dequeue_options => l_dequeue_options
      , message_properties => p_message_properties
      , payload => p_msg
      , msgid => p_msgid
      );
      exit try_loop; -- enqueue succeeded
    exception
      when e_queue_does_not_exist
      then
        if i_try != c_max_tries
        then
          create_queue_at
          ( p_queue_name => l_queue_name
          , p_comment => 'Queue for table ' || replace(l_queue_name, '$', '.')
          );
        else
          raise;
        end if;
      when e_dequeue_disabled
      then
        if i_try != c_max_tries
        then
          start_queue_at
          ( p_queue_name => l_queue_name
          );
        else
          raise;
        end if;
    end;
  end loop try_loop;  

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.print(dbug."output", 'p_msgid: %s', rawtohex(p_msgid));
  p_msg.print();
  dbug.leave;
$end
end dequeue;

procedure dequeue_and_process
( p_queue_name in varchar2 -- Can be fully qualified (including schema).
, p_delivery_mode in binary_integer
, p_visibility in binary_integer
, p_subscriber in varchar2
, p_dequeue_mode in binary_integer
, p_navigation in binary_integer
, p_wait in binary_integer
, p_correlation in varchar2
, p_deq_condition in varchar2
, p_force in boolean
, p_commit in boolean
)
is
  l_msgid raw(16) := null;
  l_message_properties dbms_aq.message_properties_t;
  l_msg msg_typ;
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.DEQUEUE_AND_PROCESS (1)');
  dbug.print(dbug."input", 'p_commit: %s', p_commit);
$end

  dequeue
  ( p_queue_name => p_queue_name
  , p_delivery_mode => p_delivery_mode
  , p_visibility => p_visibility
  , p_subscriber => p_subscriber
  , p_dequeue_mode => p_dequeue_mode
  , p_navigation => p_navigation
  , p_wait => p_wait
  , p_correlation => p_correlation
  , p_deq_condition => p_deq_condition
  , p_force => p_force
  , p_msgid => l_msgid
  , p_message_properties => l_message_properties
  , p_msg => l_msg
  );

  process_msg
  ( p_msg => l_msg
  , p_commit => p_commit
  );

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
$end
end dequeue_and_process;

procedure dequeue
( p_context in raw
, p_reginfo in sys.aq$_reg_info
, p_descr in sys.aq$_descriptor
, p_payload in raw
, p_payloadl in number
, p_msgid out nocopy raw
, p_message_properties out nocopy dbms_aq.message_properties_t
, p_msg out nocopy msg_typ
)
is
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.DEQUEUE (2)');
  dbug.print
  ( dbug."input"
  , 'p_context: %s; p_descr.msg_id: %s; p_descr.consumer_name: %s; p_descr.queue_name: %s; p_payloadl: %s'
  , p_context
  , rawtohex(p_descr.msg_id)
  , p_descr.consumer_name
  , p_descr.queue_name
  , p_payloadl
  );
  dbug.print
  ( dbug."input"
  , 'p_descr.msg_prop.state: %s; p_descr.msg_prop.delivery_mode: %s'
  , state_descr(p_descr.msg_prop.state)
  , delivery_mode_descr(p_descr.msg_prop.delivery_mode)
  );
$end

  p_msgid := p_descr.msg_id;

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.print
  ( dbug."info"
  , 'USERENV: SESSIONID: %s; APEX$SESSION.APP_SESSION|CLIENT_IDENTIFIER: %s; CURRENT_USER: %s; SESSION_USER: %s; PROXY_USER: %s'
  , sys_context('USERENV', 'SESSIONID') ||
      case
        when sys_context('USERENV', 'BG_JOB_ID') is not null
        then ' (BG_JOB_ID=' || sys_context('USERENV', 'BG_JOB_ID') || ')'
        when sys_context('USERENV', 'FG_JOB_ID') is not null
        then ' (FG_JOB_ID=' || sys_context('USERENV', 'FG_JOB_ID') || ')'
      end
  , nvl(sys_context('APEX$SESSION', 'APP_SESSION'), sys_context('USERENV', 'CLIENT_IDENTIFIER'))
  , sys_context('USERENV', 'CURRENT_USER')
  , sys_context('USERENV', 'SESSION_USER')
  , sys_context('USERENV', 'PROXY_USER')
  );
$end

  dequeue
  ( p_queue_name => p_descr.queue_name
  , p_delivery_mode => p_descr.msg_prop.delivery_mode
  , p_visibility =>
      -- to suppress a warning
$if msg_aq_pkg.c_buffered_messaging $then
      case
        when p_descr.msg_prop.delivery_mode in ( dbms_aq.buffered, dbms_aq.persistent_or_buffered )
        then dbms_aq.immediate
        else dbms_aq.on_commit
      end
$else
      dbms_aq.on_commit
$end        
  , p_subscriber => p_descr.consumer_name 
  , p_dequeue_mode => dbms_aq.remove
  , p_navigation => dbms_aq.next_message
  , p_wait => dbms_aq.no_wait -- message is there
  , p_correlation => null
  , p_deq_condition => null
  , p_msgid => p_msgid
  , p_message_properties => p_message_properties
  , p_msg => p_msg
  );

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.print(dbug."output", 'p_msgid: %s', rawtohex(p_msgid));
  dbug.leave;
$end
end dequeue;

procedure dequeue_and_process
( p_context in raw
, p_reginfo in sys.aq$_reg_info
, p_descr in sys.aq$_descriptor
, p_payload in raw
, p_payloadl in number
, p_commit in boolean
)
is
  l_msgid raw(16);
  l_message_properties dbms_aq.message_properties_t;
  l_msg msg_typ;
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.DEQUEUE_AND_PROCESS (2)');
  dbug.print(dbug."input", 'p_commit: %s', p_commit);
$end

  msg_aq_pkg.dequeue
  ( p_context => p_context
  , p_reginfo => p_reginfo
  , p_descr => p_descr
  , p_payload => p_payload
  , p_payloadl => p_payloadl
  , p_msgid => l_msgid
  , p_message_properties => l_message_properties
  , p_msg => l_msg
  );

  process_msg
  ( p_msg => l_msg
  , p_commit => p_commit
  );

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end dequeue_and_process;

procedure dequeue_and_process_supervisor
( p_include_queue_name_list in varchar2
, p_exclude_queue_name_list in varchar2
, p_nr_workers_multiply_per_q in positive
, p_nr_workers_exact in positive
, p_ttl in positiven
, p_job_name in varchar2
, p_start_date in timestamp with time zone
, p_repeat_interval in varchar2
)
is
  c_start_date constant date := nvl(cast(p_start_date as date), sysdate);
  c_end_date constant date := c_start_date + p_ttl / ( 24 * 60 * 60 );
  l_queue_name_tab sys.odcivarchar2list;
  l_queue_name_list varchar2(4000 char);
  l_job_name_supervisor all_objects.object_name%type;
  l_job_name_tab sys.odcivarchar2list := sys.odcivarchar2list();

  function submit_job
  ( p_job_name in varchar2
  )
  return boolean
  is
    l_argument_value user_scheduler_program_args.default_value%type;
  begin
    if p_job_name is null
    then
      return false;
    end if;

    if not(does_job_exist(p_job_name))
    then
      create_job
      ( p_job_name => p_job_name
      , p_start_date => p_start_date
      , p_repeat_interval => p_repeat_interval
      );
    end if;

    for r in
    ( select  a.argument_name
      from    user_scheduler_jobs j
              inner join user_scheduler_program_args a
              on a.program_name = j.program_name
      where   job_name = p_job_name
    )
    loop
      case r.argument_name
        when 'P_INCLUDE_QUEUE_NAME_LIST'
        then l_argument_value := p_include_queue_name_list;
        when 'P_EXCLUDE_QUEUE_NAME_LIST'
        then l_argument_value := p_exclude_queue_name_list;
        when 'P_NR_WORKERS_MULTIPLY_PER_Q'
        then l_argument_value := to_char(p_nr_workers_multiply_per_q);
        when 'P_NR_WORKERS_EXACT'
        then l_argument_value := to_char(p_nr_workers_exact);
        when 'P_TTL'
        then l_argument_value := to_char(p_ttl);
      end case;
      
      dbms_scheduler.set_job_argument_value
      ( job_name => p_job_name
      , argument_name => r.argument_name
      , argument_value => l_argument_value
      );
    end loop;
    
    dbms_scheduler.enable(p_job_name); -- start the job

    return true;
  end submit_job;

  procedure check_input_and_state
  is
  begin
    case
      when ( p_nr_workers_multiply_per_q is not null and p_nr_workers_exact is null ) or
           ( p_nr_workers_multiply_per_q is null and p_nr_workers_exact is not null )
      then null; -- ok
      else
        raise_application_error
        ( -20000
        , utl_lms.format_message
          ( 'Exactly one of the following parameters must be set: p_nr_workers_multiply_per_q (%d), p_nr_workers_exact (%d).'
          , p_nr_workers_multiply_per_q -- since the type is positive %d should work
          , p_nr_workers_exact -- idem
          )
        );
    end case;

    -- Is this session running as a job?
    -- If not, just create a job name supervisor to be used by the worker jobs.
    
    l_job_name_supervisor := session_job_name();
    
    if l_job_name_supervisor is null
    then
$if oracle_tools.cfg_pkg.c_debugging $then
      dbug.print
      ( dbug."warning"
      , utl_lms.format_message
        ( 'This session (SID=%s) does not appear to be a running job (for this user), see also column SESSION_ID from view USER_SCHEDULER_RUNNING_JOBS.'
        , to_char(c_session_id)
        )
      );
$end
        
      l_job_name_supervisor := c_job_supervisor || '_' || to_char(sysdate, 'yyyymmddhh24miss');        
    end if;

    -- determine the normal queues matching one of the input queues (that may have wildcards)
    select  distinct
            dbms_assert.enquote_name($$PLSQL_UNIT_OWNER) || '.' || dbms_assert.enquote_name(q.name) as fq_queue_name
    bulk collect
    into    l_queue_name_tab
    from    user_queues q
            inner join table(oracle_tools.api_pkg.list2collection(p_value_list => p_include_queue_name_list, p_sep => ',', p_ignore_null => 1)) qni
            on q.name like qni.column_value escape '\'
            inner join table(oracle_tools.api_pkg.list2collection(p_value_list => p_exclude_queue_name_list, p_sep => ',', p_ignore_null => 1)) qne
            on q.name not like qne.column_value escape '\'
    where   q.queue_type = 'NORMAL_QUEUE'
    and     trim(q.dequeue_enabled) = 'YES'
    minus
    select  sr.subscription_name as fq_queue_name -- "OWNER"."QUEUE"
    from    user_subscr_registrations sr
    order by
            fq_queue_name;

    if l_queue_name_tab.count = 0
    then
      raise_application_error
      ( -20000
      , utl_lms.format_message
        ( 'Could not find normal queues with included list (%s) and excluded list (%s), or they are already handled by registrations / notifications (USER_SUBSCR_REGISTRATIONS).'
        , p_include_queue_name_list
        , p_exclude_queue_name_list
        )
      );
    end if;

    select  listagg(column_value, ',') within group (order by column_value)
    into    l_queue_name_list
    from    table(l_queue_name_tab);
  end check_input_and_state;

  procedure start_worker
  ( p_job_name_worker in varchar2
  )
  is
    l_worker_nr constant positiven := to_number(substr(p_job_name_worker, instr(p_job_name_worker, '#')+1));
  begin
    dequeue_and_process_worker
    ( p_queue_name_list => l_queue_name_list
    , p_worker_nr => l_worker_nr
    , p_start_date_str => to_char(c_start_date, "yyyy-mm-dd hh24:mi:ss")
    , p_end_date_str => to_char(c_end_date, "yyyy-mm-dd hh24:mi:ss")
    , p_job_name_supervisor => l_job_name_supervisor
    );
  end start_worker;

  procedure define_workers
  is
  begin
    -- Create the workers
    for i_worker in 1 .. nvl(p_nr_workers_exact, p_nr_workers_multiply_per_q * l_queue_name_tab.count)
    loop
      l_job_name_tab.extend(1);
      l_job_name_tab(l_job_name_tab.last) := l_job_name_supervisor || '#' || to_char(i_worker); -- the # indicates a worker job
    end loop;  
  end define_workers;

  procedure start_workers
  is
  begin
    if l_job_name_tab.count > 0
    then
      for i_worker in l_job_name_tab.first .. l_job_name_tab.last
      loop
        start_worker(p_job_name_worker => l_job_name_tab(i_worker));
      end loop;
    end if;
  end start_workers;

  procedure supervise_workers
  is
    l_now date;
    l_worker_nr integer;
    l_sqlcode integer;
    l_sqlerrm varchar2(4000 char);
    l_session_id user_scheduler_running_jobs.session_id%type;
  begin
    loop
      l_now := sysdate;

      exit when l_now >= c_end_date;

      -- get the status from the pipe

      recv_worker_status
      ( p_job_name_supervisor => l_job_name_supervisor
      , p_timeout => greatest(1, (c_end_date - l_now) * (24 * 60 * 60)) -- don't use 0 but 1 second as minimal timeout since 0 seconds may kill your server
      , p_worker_nr => l_worker_nr 
      , p_sqlcode => l_sqlcode
      , p_sqlerrm => l_sqlerrm
      , p_session_id => l_session_id
      );

      exit when l_now >= c_end_date;
      
$if oracle_tools.cfg_pkg.c_debugging $then
      dbug.print
      ( case when l_sqlerrm is null then dbug."info" else dbug."error" end
      , 'Worker %s (SID=%s) stopped with error code %s'
      , l_worker_nr
      , l_session_id
      , l_sqlcode
      );
      if l_sqlerrm is not null
      then
        dbug.print(dbug."error", l_sqlerrm);
      end if;
$end

      start_worker(p_job_name_worker => l_job_name_supervisor || '#' || l_worker_nr);
    end loop;
$if oracle_tools.cfg_pkg.c_debugging $then
    dbug.print(dbug."info", 'Stopped supervising workers at %s', to_char(l_now, "yyyy-mm-dd hh24:mi:ss"));
$end
  exception
    when e_dequeue_timeout
    then
      null;
  end supervise_workers;
begin
  init;
  
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.DEQUEUE_AND_PROCESS_SUPERVISOR');
  dbug.print
  ( dbug."input"
  , 'p_include_queue_name_list: %s; p_exclude_queue_name_list: %s; p_nr_workers_multiply_per_q: %s; p_nr_workers_exact: %s; p_ttl: %s'
  , p_include_queue_name_list
  , p_exclude_queue_name_list
  , p_nr_workers_multiply_per_q
  , p_nr_workers_exact
  , p_ttl
  );
  dbug.print
  ( dbug."input"
  , 'p_job_name: %s; p_start_date: %s; p_repeat_interval: %s'
  , p_job_name
  , to_char(p_start_date, "yyyy-mm-dd hh24:mi:ss")
  , p_repeat_interval
  );
$end

  if not(submit_job(upper(p_job_name)))
  then
    check_input_and_state;
    define_workers;
    start_workers;
    supervise_workers;
  end if;

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
$end

  done;
exception
  when e_dbms_pipe_error
  then
$if oracle_tools.cfg_pkg.c_debugging $then  
    dbug.leave_on_error;
$end
    done;
    -- no reraise necessary
    
  when others
  then
$if oracle_tools.cfg_pkg.c_debugging $then  
    dbug.leave_on_error;
$end
    done;
    raise;
end dequeue_and_process_supervisor;

procedure dequeue_and_process_worker
( p_queue_name_list in varchar2
, p_worker_nr in positiven
, p_start_date_str in varchar2
, p_end_date_str in varchar2
, p_job_name_supervisor in varchar2
)
is
  l_job_name_worker constant user_scheduler_jobs.job_name%type := session_job_name();
  
  function submit_job
  ( p_job_name_worker in varchar2
  )
  return boolean
  is
    l_argument_value user_scheduler_program_args.default_value%type;
  begin
    if does_job_exist(p_job_name_worker)
    then
      raise too_many_rows; -- should not happen
    else
      create_job(p_job_name => p_job_name_worker);
    end if;

    -- set the actual arguments

    for r in
    ( select  a.argument_name
      from    user_scheduler_jobs j
              inner join user_scheduler_program_args a
              on a.program_name = j.program_name
      where   j.job_name = p_job_name_worker
    )
    loop
      case r.argument_name
        when 'P_QUEUE_NAME_LIST'
        then l_argument_value := p_queue_name_list;
        when 'P_WORKER_NR'
        then l_argument_value := to_char(p_worker_nr);
        when 'P_START_DATE_STR'
        then l_argument_value := p_start_date_str;
        when 'P_END_DATE_STR'
        then l_argument_value := p_end_date_str;
      end case;
      
      dbms_scheduler.set_job_argument_value
      ( job_name => p_job_name_worker
      , argument_name => r.argument_name
      , argument_value => l_argument_value
      );
    end loop;
    
    dbms_scheduler.enable(p_job_name_worker);

    return true;
  end submit_job;

  procedure process
  is
    l_job_name_supervisor constant user_scheduler_jobs.job_name%type := 
      substr(l_job_name_worker, 1, instr(l_job_name_worker, '#')-1);    
    l_start_date constant date := to_date(p_start_date_str, "yyyy-mm-dd hh24:mi:ss");
    l_end_date constant date := to_date(p_end_date_str, "yyyy-mm-dd hh24:mi:ss");
    l_queue_name_tab sys.odcivarchar2list;
    l_agent_list dbms_aq.aq$_agent_list_t;
    l_queue_name_idx positiven := 1;
    l_agent sys.aq$_agent;
    l_message_delivery_mode pls_integer;
    l_now date;
  begin
    select  qn.column_value
    bulk collect
    into    l_queue_name_tab
    from    table(oracle_tools.api_pkg.list2collection(p_value_list => p_queue_name_list, p_sep => ',', p_ignore_null => 1)) qn;

    if l_queue_name_tab is not null and l_queue_name_tab.first = 1
    then
      null;
    else
      raise value_error;
    end if;

    if l_start_date is null or l_end_date is null
    then
      raise value_error;
    end if;

    -- i_idx can be from
    -- a) 1 .. l_queue_name_tab.count     (<=> 1 .. l_queue_name_tab.count + (1) - 1)
    -- b) 2 .. l_queue_name_tab.count + 1 (<=> 2 .. l_queue_name_tab.count + (2) - 1)
    -- z) l_queue_name_tab.count .. l_queue_name_tab.count + (l_queue_name_tab.count) - 1
    for i_idx in mod(p_worker_nr - 1, l_queue_name_tab.count) + 1 ..
                 mod(p_worker_nr - 1, l_queue_name_tab.count) + l_queue_name_tab.count
    loop
      l_queue_name_idx := mod(i_idx - 1, l_queue_name_tab.count) + 1; -- between 1 and l_queue_name_tab.count
    
$if oracle_tools.cfg_pkg.c_debugging $then
      dbug.print(dbug."input", 'i_idx: %s; l_queue_name_tab(%s): %s', i_idx, l_queue_name_idx, l_queue_name_tab(l_queue_name_idx));
$end

      if l_queue_name_tab(l_queue_name_idx) is null
      then
        raise program_error;
      end if;
      
      l_agent_list(l_agent_list.count+1) :=
        sys.aq$_agent(null, l_queue_name_tab(l_queue_name_idx), null);
      l_queue_name_tab(l_queue_name_idx) := null;
    end loop;

    loop
      l_now := sysdate;
      
      exit when l_now >= l_end_date;

      -- to be able to profile this call
      dbms_aq.listen
      ( agent_list => l_agent_list
      , wait => greatest(1, (l_end_date - l_now) * (24 * 60 * 60)) -- don't use 0 but 1 second as minimal timeout since 0 seconds may kill your server
      , listen_delivery_mode => dbms_aq.persistent_or_buffered
      , agent => l_agent
      , message_delivery_mode => l_message_delivery_mode
      );

      msg_aq_pkg.dequeue_and_process
      ( p_queue_name => l_agent.address
      , p_delivery_mode => l_message_delivery_mode
      , p_visibility => dbms_aq.immediate
      , p_subscriber => l_agent.name
      , p_dequeue_mode => dbms_aq.remove
      , p_navigation => dbms_aq.first_message -- may be better for performance when concurrent messages arrive
      , p_wait => 0 -- message should be there so there is no need to wait
      , p_correlation => null
      , p_deq_condition => null
      , p_force => false -- queue should be there
      , p_commit => true
      );
    end loop;

$if oracle_tools.cfg_pkg.c_debugging $then
    dbug.print(dbug."info", 'Stopped working at %s', to_char(l_now, "yyyy-mm-dd hh24:mi:ss"));
$end

    -- OK
    send_worker_status
    ( p_job_name_supervisor => l_job_name_supervisor
    , p_worker_nr => p_worker_nr
    , p_sqlcode => 0
    , p_sqlerrm => null
    , p_timeout => 0
    );
  exception
    when e_dbms_pipe_error
    then raise;
    when others
    then
      send_worker_status
      ( p_job_name_supervisor => l_job_name_supervisor
      , p_worker_nr => p_worker_nr
      , p_sqlcode => sqlcode
      , p_sqlerrm => sqlerrm
      , p_timeout => 0
      );
  end process;
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  init;

  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.DEQUEUE_AND_PROCESS_WORKER');
  dbug.print
  ( dbug."input"
  , 'p_queue_name_list: %s; p_worker_nr: %s; p_start_date_str: %s; p_end_date_str: %s; p_job_name_supervisor: %s'
  , p_queue_name_list
  , p_worker_nr
  , p_start_date_str
  , p_end_date_str
  , p_job_name_supervisor
  );
$end

  if l_job_name_worker is null
  then
    if p_job_name_supervisor is null
    then
      raise program_error;
    end if;
    
    if not(submit_job(p_job_name_supervisor || '#' || p_worker_nr))
    then
      raise program_error;
    end if;    
  else
    process;
  end if;

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;

  done;
exception
  when others
  then
    dbug.leave_on_error;

    done;
    raise;
$end
end dequeue_and_process_worker;

end msg_aq_pkg;
/

