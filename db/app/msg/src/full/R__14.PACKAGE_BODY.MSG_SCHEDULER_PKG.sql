CREATE OR REPLACE PACKAGE BODY "MSG_SCHEDULER_PKG" AS

subtype job_name_t is user_scheduler_jobs.job_name%type;

"yyyymmddhh24miss" constant varchar2(16) := 'yyyymmddhh24miss';

c_program_supervisor constant user_scheduler_programs.program_name%type := 'PROCESSING_SUPERVISOR';
c_program_worker constant user_scheduler_programs.program_name%type := 'PROCESSING';

c_schedule_supervisor constant user_scheduler_programs.program_name%type := 'SCHEDULE_SUPERVISOR';

c_session_id constant user_scheduler_running_jobs.session_id%type := to_number(sys_context('USERENV', 'SID'));

-- ORA-27476: "MSG_AQ_PKG$PROCESSING_SUPERVISOR$20230301114922#1" does not exist
e_job_does_not_exist exception;
pragma exception_init(e_job_does_not_exist, -27476);

$if oracle_tools.cfg_pkg.c_debugging $then
 
subtype t_dbug_channel_tab is msg_pkg.t_boolean_lookup_tab;

g_dbug_channel_tab t_dbug_channel_tab;

$end -- $if oracle_tools.cfg_pkg.c_debugging $then

procedure init
is
$if oracle_tools.cfg_pkg.c_debugging $then
  l_dbug_channel_active_tab constant sys.odcivarchar2list := msg_constants_pkg.c_dbug_channel_active_tab;
  l_dbug_channel_inactive_tab constant sys.odcivarchar2list := msg_constants_pkg.c_dbug_channel_inactive_tab;
$end    
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  for i_idx in l_dbug_channel_active_tab.first .. l_dbug_channel_active_tab.last
  loop
    g_dbug_channel_tab(l_dbug_channel_active_tab(i_idx)) := dbug.active(l_dbug_channel_active_tab(i_idx));

    dbug.activate
    ( l_dbug_channel_active_tab(i_idx)
    , true
    );
  end loop;

  for i_idx in l_dbug_channel_inactive_tab.first .. l_dbug_channel_inactive_tab.last
  loop
    g_dbug_channel_tab(l_dbug_channel_inactive_tab(i_idx)) := dbug.active(l_dbug_channel_inactive_tab(i_idx));

    dbug.activate
    ( l_dbug_channel_inactive_tab(i_idx)
    , false
    );
  end loop;
$end

  msg_pkg.init;
end init;

$if oracle_tools.cfg_pkg.c_debugging $then

procedure profiler_report
is
  l_dbug_channel all_objects.object_name%type := g_dbug_channel_tab.first;
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
  l_dbug_channel all_objects.object_name%type := g_dbug_channel_tab.first;
$end  
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  profiler_report;
$end  

  msg_pkg.done;

$if oracle_tools.cfg_pkg.c_debugging $then
  while l_dbug_channel is not null
  loop
    dbug.activate(l_dbug_channel, g_dbug_channel_tab(l_dbug_channel));
    
    l_dbug_channel := g_dbug_channel_tab.next(l_dbug_channel);
  end loop;
$end -- $if oracle_tools.cfg_pkg.c_debugging $then  
end done;

function get_job_name
( p_processing_package in varchar2
, p_program_name in varchar2
, p_job_suffix in varchar2 default null
, p_worker_nr in positive default null
)
return job_name_t
is
  l_job_name job_name_t;
begin
  l_job_name :=
    p_processing_package ||
    '$' ||
    p_program_name ||
    case when p_job_suffix is not null then '$' || p_job_suffix end ||
    case when p_worker_nr is not null then '#' || to_char(p_worker_nr) end;

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.print(dbug."info", 'l_job_name: %s', l_job_name);
$end

  return l_job_name;
end get_job_name;

procedure split_job_name
( p_job_name in job_name_t
, p_processing_package out nocopy varchar2
, p_program_name out nocopy varchar2
, p_job_suffix out nocopy varchar2
, p_worker_nr out nocopy positive
)
is
  l_pos$ pls_integer;
  l_pos# pls_integer;
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'SPLIT_JOB_NAME');
  dbug.print(dbug."input", 'p_job_name: %s',  p_job_name);
$end  

  p_processing_package := null;
  p_program_name := null;
  p_job_suffix := null;
  p_worker_nr := null;
  
  l_pos$ := instr(p_job_name, '$'); -- first $
  if l_pos$ > 0
  then
    p_processing_package := substr(p_job_name, 1, l_pos$ - 1);
    p_program_name := substr(p_job_name, l_pos$ + 1); -- rest of the job name
    
    l_pos$ := instr(p_program_name, '$'); -- second $ ?
    l_pos# := instr(p_program_name, '#'); -- first #
    case
      when l_pos$ is null or l_pos# is null -- p_program_name is null
      then
        null;
        
      when l_pos$ = 0 and l_pos# = 0
      then
        null;
        
      when l_pos$ = 0 and l_pos# > 0
      then
        p_worker_nr := to_number(substr(p_program_name, l_pos# + 1));
        p_program_name := substr(p_program_name, 1, l_pos# - 1);
        
      when l_pos$ > 0 and l_pos# = 0
      then
        p_job_suffix := substr(p_program_name, l_pos$ + 1);
        p_program_name := substr(p_program_name, 1, l_pos$ - 1);
        
      when l_pos$ > 0 and l_pos# > l_pos$
      then
        p_job_suffix := substr(p_program_name, l_pos$ + 1, l_pos# - l_pos$ - 1);
        p_worker_nr := to_number(substr(p_program_name, l_pos# + 1));
        p_program_name := substr(p_program_name, 1, l_pos$ - 1);
        
      when l_pos$ > 0 and l_pos# <= l_pos$
      then
        raise value_error; -- strange job name
    end case;
  end if;

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.print
  ( dbug."output"
  , 'p_processing_package: %s; p_program_name: %s; p_job_suffix: %s; p_worker_nr: %s'
  , p_processing_package
  , p_program_name
  , p_job_suffix
  , p_worker_nr
  );
  dbug.leave;
$end  
end split_job_name;

function does_job_exist
( p_job_name in job_name_t
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

function is_job_running
( p_job_name in job_name_t
)
return boolean
is
  l_found pls_integer;
begin
  select  1
  into    l_found
  from    user_scheduler_running_jobs j
  where   j.job_name = p_job_name;

  return true;
exception
  when no_data_found
  then
    return false;
end is_job_running;

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

function does_schedule_exist
( p_schedule_name in varchar2
)
return boolean
is
  l_found pls_integer;
begin
  select  1
  into    l_found
  from    user_scheduler_schedules p
  where   p.schedule_name = p_schedule_name;

  return true;
exception
  when no_data_found
  then
    return false;
end does_schedule_exist;

function session_job_name
( p_session_id in varchar2 default c_session_id
)
return job_name_t
is
  l_job_name job_name_t;
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
      , number_of_arguments => 4
      , enabled => false
      , comments => 'Main program for processing messages that spawns other worker in-memory jobs and supervises them.'
      );

      for i_par_idx in 1..4
      loop
        dbms_scheduler.define_program_argument
        ( program_name => l_program_name
        , argument_name => case i_par_idx
                             when 1 then 'P_PROCESSING_PACKAGE'
                             when 2 then 'P_NR_WORKERS_EACH_GROUP'
                             when 3 then 'P_NR_WORKERS_EXACT'
                             when 4 then 'P_TTL'
                           end
        , argument_position => i_par_idx
        , argument_type => case 
                             when i_par_idx <= 1
                             then 'VARCHAR2'
                             else 'NUMBER'
                           end
        , default_value => case i_par_idx
                             when 2 then to_char(msg_constants_pkg.c_nr_workers_each_group)
                             when 3 then to_char(msg_constants_pkg.c_nr_workers_exact)
                             when 4 then to_char(msg_constants_pkg.c_ttl)
                             else null
                           end
        );
      end loop;

    when c_program_worker
    then
      dbms_scheduler.create_program
      ( program_name => l_program_name
      , program_type => 'STORED_PROCEDURE'
      , program_action => $$PLSQL_UNIT || '.' || p_program_name -- program name is the same as module name
      , number_of_arguments => 5
      , enabled => false
      , comments => 'Worker program for processing messages supervised by the main job.'
      );
  
      for i_par_idx in 1..5
      loop
        dbms_scheduler.define_program_argument
        ( program_name => l_program_name
        , argument_name => case i_par_idx
                             when 1 then 'P_PROCESSING_PACKAGE'
                             when 2 then 'P_GROUPS_TO_PROCESS_LIST'
                             when 3 then 'P_WORKER_NR'
                             when 4 then 'P_TTL'
                             when 5 then 'P_JOB_NAME_SUPERVISOR'
                           end
        , argument_position => i_par_idx
        , argument_type => case 
                             when i_par_idx between 3 and 4
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

procedure submit_processing
( p_processing_package in varchar2
, p_groups_to_process_list in varchar2
, p_worker_nr in positiven
, p_ttl in positiven
, p_job_name_supervisor in varchar2
)
is
  l_job_name_worker constant job_name_t := p_job_name_supervisor || '#' || to_char(p_worker_nr);
  l_argument_value user_scheduler_program_args.default_value%type;
begin  
  if is_job_running(l_job_name_worker)
  then
    raise too_many_rows;
  end if;
  
  if not(does_job_exist(l_job_name_worker))
  then  
    if not(does_program_exist(c_program_worker))
    then
      create_program(c_program_worker);
    end if;

    -- use inline schedule
    dbms_scheduler.create_job
    ( job_name => l_job_name_worker
    , program_name => c_program_worker
    , start_date => null
      -- will never repeat
    , repeat_interval => null
    , end_date => sysdate + (p_ttl / (24 * 60 * 60)) -- as precaution
    , job_class => msg_constants_pkg.c_job_class_worker
    , enabled => false -- so we can set job arguments
    , auto_drop => true -- one-off jobs
    , comments => 'Worker job for processing messages.'
    , job_style => msg_constants_pkg.c_job_style_worker
    , credential_name => null
    , destination_name => null
    );
  else
    dbms_scheduler.disable(l_job_name_worker);    
  end if;
  
  -- set the actual arguments

  for r in
  ( select  a.argument_name
    from    user_scheduler_jobs j
            inner join user_scheduler_program_args a
            on a.program_name = j.program_name
    where   j.job_name = l_job_name_worker
    order by
            a.argument_position
  )
  loop
    case r.argument_name
      when 'P_PROCESSING_PACKAGE'
      then l_argument_value := p_processing_package;
      when 'P_GROUPS_TO_PROCESS_LIST'
      then l_argument_value := p_groups_to_process_list;
      when 'P_WORKER_NR'
      then l_argument_value := to_char(p_worker_nr);
      when 'P_TTL'
      then l_argument_value := to_char(p_ttl);
      when 'P_JOB_NAME_SUPERVISOR'
      then l_argument_value := p_job_name_supervisor;
    end case;


$if oracle_tools.cfg_pkg.c_debugging $then
    dbug.print
    ( dbug."info"
    , 'argument name: %s; argument value: %s'
    , r.argument_name
    , l_argument_value
    );
$end

    dbms_scheduler.set_job_argument_value
    ( job_name => l_job_name_worker
    , argument_name => r.argument_name
    , argument_value => l_argument_value
    );
  end loop;
  
  dbms_scheduler.enable(l_job_name_worker);
end submit_processing;

function determine_processing_package
( p_processing_package in varchar2
)
return varchar2
is
  l_processing_package user_objects.object_name%type := null;
begin
  if p_processing_package is not null
  then
    l_processing_package := p_processing_package;
  else
    -- this private function is called from within this package so we can skip those two (top) items on the call stack
    for i_idx in 3..utl_call_stack.dynamic_depth
    loop
      -- utl_call_stack.subprogram(i_idx)(1) is the name of the unit
      if utl_call_stack.subprogram(i_idx)(1) <> $$PLSQL_UNIT
      then
        -- must be the calling unit
        l_processing_package := utl_call_stack.subprogram(i_idx)(1); -- is already not fully qualified nor enquoted
        exit;
      end if;
    end loop;
  end if;
  
  if l_processing_package is not null
  then
    return msg_pkg.get_object_name(p_object_name => l_processing_package, p_what => 'package', p_fq => 0, p_qq => 0);
  else
    raise program_error;
  end if;
end determine_processing_package;

$if msg_constants_pkg.c_use_job_events_for_status $then

procedure send_init
( p_job_name_supervisor in varchar2
, p_worker_nr in integer
)
is
begin
  dbms_scheduler.set_attribute
  ( name => p_job_name_supervisor || '#' || to_char(p_worker_nr)
  , attribute => 'raise_events'
  , value => dbms_scheduler.job_run_completed
  );
end send_init;

procedure send_done
( p_job_name_supervisor in varchar2
, p_worker_nr in integer
)
is
begin
  null;
end send_done;

procedure send_worker_status
( p_job_name_supervisor in varchar2
, p_worker_nr in integer
, p_sqlcode in integer
, p_sqlerrm in varchar2
, p_timeout in integer
)
is
begin
  null;
end send_worker_status;

procedure send_stop_supervisor
( p_job_name_supervisor in varchar2
, p_timeout in integer
)
is
begin
  null;
end send_stop_supervisor;

procedure recv_init
( p_job_name_supervisor in varchar2
)
is
  -- ORA-24034: application ORACLE_TOOLS is already a subscriber for queue SYS.SCHEDULER$_EVENT_QUEUE
  e_already_subscriber exception;  
  pragma exception_init(e_already_subscriber, -24034);
begin
  dbms_scheduler.add_event_queue_subscriber;
exception
  when e_already_subscriber
  then null;
end recv_init;

procedure recv_done
( p_job_name_supervisor in varchar2
)
is
begin
  -- Never remove this schema from the queue since other supervisors may be running too.
  -- dbms_scheduler.remove_event_queue_subscriber;
  null;
end recv_done;

procedure recv_event
( p_job_name_supervisor in varchar2
, p_timeout in integer
, p_event out nocopy msg_pkg.event_t -- WORKER_STATUS / STOP_SUPERVISOR
, p_worker_nr out nocopy integer -- Only relevant when the event is WORKER_STATUS
, p_sqlcode out nocopy integer -- Idem
, p_sqlerrm out nocopy varchar2 -- Idem
, p_session_id out nocopy user_scheduler_running_jobs.session_id%type -- Idem
)
is
  pragma autonomous_transaction;
  
  l_dequeue_options     dbms_aq.dequeue_options_t;
  l_message_properties  dbms_aq.message_properties_t;
  l_message_handle      raw(16);
  l_queue_msg           sys.scheduler$_event_info;

  -- for split job name
  l_processing_package all_objects.object_name%type;
  l_program_name user_scheduler_programs.program_name%type;
  l_job_suffix varchar2(20);
  l_job_name_worker job_name_t;
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT || '.RECV_EVENT');
  dbug.print
  ( dbug."input"
  , 'p_job_name_supervisor: %s; p_timeout: %s'
  , p_job_name_supervisor
  , p_timeout
  );
$end

  p_event := null;
  p_worker_nr := null;
  p_sqlcode := null;
  p_sqlerrm := null;
  p_session_id := null;

  l_dequeue_options.consumer_name := $$PLSQL_UNIT_OWNER;
  l_dequeue_options.wait := p_timeout;
  
  dbms_aq.dequeue
  ( queue_name => 'SYS.SCHEDULER$_EVENT_QUEUE'
  , dequeue_options => l_dequeue_options
  , message_properties => l_message_properties
  , payload => l_queue_msg
  , msgid => l_message_handle
  );

  l_job_name_worker := l_queue_msg.object_name;

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.print(dbug."info", 'l_job_name_worker: %s', l_job_name_worker);
$end

  if l_job_name_worker like p_job_name_supervisor || '%'
  then
    split_job_name
    ( p_job_name => l_job_name_worker
    , p_processing_package => l_processing_package
    , p_program_name => l_program_name 
    , p_job_suffix => l_job_suffix
    , p_worker_nr => p_worker_nr 
    );

    if p_worker_nr is not null
    then
      p_event := 'WORKER_STATUS';
      p_sqlcode := l_queue_msg.error_code;
      p_sqlerrm := l_queue_msg.error_msg;
      p_session_id := null;
    end if;

    commit;
  else
    rollback; -- give another supervisor the chance to process it
  end if;

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.print
  ( dbug."output"
  , 'p_event: %s; p_worker_nr: %s; p_sqlcode: %s; p_sqlerrm: %s; p_session_id: %s'
  , p_event
  , p_worker_nr
  , p_sqlcode
  , p_sqlerrm
  , p_session_id
  );  
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end recv_event;

$else -- $if msg_constants_pkg.c_use_job_events_for_status $then

procedure send_init
( p_job_name_supervisor in varchar2
, p_worker_nr in integer
)
is
begin
  null;
end send_init;

procedure send_done
( p_job_name_supervisor in varchar2
, p_worker_nr in integer
)
is
begin
  null;
end send_done;

procedure send_worker_status
( p_job_name_supervisor in varchar2
, p_worker_nr in integer
, p_sqlcode in integer
, p_sqlerrm in varchar2
, p_timeout in integer
)
is
begin
  msg_pkg.send_worker_status
  ( p_job_name_supervisor => p_job_name_supervisor
  , p_worker_nr => p_worker_nr
  , p_sqlcode => p_sqlcode
  , p_sqlerrm => p_sqlerrm
  , p_timeout => p_timeout
  );
end send_worker_status;

procedure send_stop_supervisor
( p_job_name_supervisor in varchar2
, p_timeout in integer
)
is
begin
  msg_pkg.send_stop_supervisor
  ( p_job_name_supervisor => p_job_name_supervisor
  , p_timeout => p_timeout
  );
end send_stop_supervisor;

procedure recv_init
( p_job_name_supervisor in varchar2
)
is
  l_dummy integer;
  -- ORA-23322 Failure due to naming conflict.
  e_pipe_naming_conflict exception;
  pragma exception_init(e_pipe_naming_conflict, -23322);
begin
  -- try to create a private pipe for maximum security
  begin
    l_dummy := dbms_pipe.create_pipe(pipename => p_job_name_supervisor, private => true);
  exception
    when e_pipe_naming_conflict
    then null;
  end;

  -- no old messages
  dbms_pipe.purge(pipename => p_job_name_supervisor);
end recv_init;

procedure recv_done
( p_job_name_supervisor in varchar2
)
is
begin
  null;
end recv_done;

procedure recv_event
( p_job_name_supervisor in varchar2
, p_timeout in integer
, p_event out nocopy msg_pkg.event_t -- WORKER_STATUS / STOP_SUPERVISOR
, p_worker_nr out nocopy integer -- Only relevant when the event is WORKER_STATUS
, p_sqlcode out nocopy integer -- Idem
, p_sqlerrm out nocopy varchar2 -- Idem
, p_session_id out nocopy user_scheduler_running_jobs.session_id%type -- Idem
)
is
begin
  msg_pkg.recv_event
  ( p_job_name_supervisor => p_job_name_supervisor
  , p_timeout => p_timeout
  , p_event => p_event
  , p_worker_nr => p_worker_nr
  , p_sqlcode => p_sqlcode
  , p_sqlerrm => p_sqlerrm
  , p_session_id => p_session_id
  );
end recv_event;

$end -- $if msg_constants_pkg.c_use_job_events_for_status $then

-- PUBLIC

procedure do
( p_command in varchar2
, p_processing_package in varchar2
)
is
  pragma autonomous_transaction;

  l_processing_package constant all_objects.object_name%type := determine_processing_package(p_processing_package);
  l_job_name constant job_name_t :=
    get_job_name
    ( p_processing_package => l_processing_package 
    , p_program_name => c_program_supervisor
    , p_job_suffix => null
    , p_worker_nr => null
    );
  l_state user_scheduler_jobs.state%type;
  l_ttl oracle_tools.api_time_pkg.seconds_t;
  l_start boolean := false;
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.DO');
  dbug.print(dbug."input", 'p_command: %s; p_processing_package: %s', p_command, p_processing_package);
$end

  case p_command
    when 'start'
    then
      submit_processing_supervisor
      ( p_processing_package => l_processing_package
      );

      -- the next run may take a while (midnight) so create a one-off job
      begin
        select  oracle_tools.api_time_pkg.delta(oracle_tools.api_time_pkg.get_timestamp, j.next_run_date) as ttl
        into    l_ttl
        from    user_scheduler_jobs j
        where   j.job_name = l_job_name
        and     j.state = 'SCHEDULED';

$if oracle_tools.cfg_pkg.c_debugging $then
        dbug.print(dbug."info", 'l_ttl: %s', l_ttl);
$end

        l_ttl := trunc(l_ttl) - msg_constants_pkg.c_time_between_runs;
        if l_ttl > 0
        then
          submit_processing_supervisor
          ( p_processing_package => l_processing_package
          , p_ttl => l_ttl
          , p_repeat_interval => null
          );
        end if;
      exception
        when no_data_found
        then null;          
      end;

    when 'restart'
    then
      begin
        select  j.state
        into    l_state
        from    user_scheduler_jobs j
        where   j.job_name = l_job_name;
      
        case l_state  
          when 'DISABLED'
          then l_start := false;
          when 'RETRY SCHEDULED'
          then l_start := false;
          when 'SCHEDULED' -- there may be a job running
          then do(p_command => 'stop', p_processing_package => l_processing_package); l_start := true;
          when 'BLOCKED'
          then l_start := false;
          when 'RUNNING'
          then do(p_command => 'stop', p_processing_package => l_processing_package); l_start := true;
          when 'COMPLETED'
          then l_start := false;
          when 'BROKEN'
          then l_start := false;
          when 'FAILED'
          then l_start := false;
          when 'REMOTE'
          then l_start := false;
          when 'RESOURCE_UNAVAILABLE'
          then l_start := false;
          when 'SUCCEEDED'
          then l_start := false;
          when 'CHAIN_STALLED'
          then l_start := false;
          else l_start := false;
        end case;
      exception
        when no_data_found
        then
          l_start := true;
      end;

      if l_start
      then
        do(p_command => 'start', p_processing_package => l_processing_package);
      end if;

    when 'stop'
    then
      for r in
      ( select  j.job_name
        ,       sign(instr(j.job_name, '#')) as is_worker
        from    user_scheduler_running_jobs j
        where   j.job_name like l_job_name || '%' -- repeating and non-repeating jobs, supervisors and workers
        order by
                is_worker asc -- supervisors first otherwise they may restart completed workers again
      )
      loop
$if oracle_tools.cfg_pkg.c_debugging $then
        dbug.print
        ( dbug."info"
        , 'trying to stop and disable %s job %s'
        , case when r.is_worker = 0 then 'supervisor' else 'worker' end
        , r.job_name
        );
$end
        -- try to stop gracefully
        if r.is_worker = 0
        then
          begin
            send_stop_supervisor
            ( p_job_name_supervisor => r.job_name
            , p_timeout => 0
            );
$if not(msg_constants_pkg.c_use_job_events_for_status) $then
          exception
            when msg_pkg.e_dbms_pipe_timeout or
                 msg_pkg.e_dbms_pipe_record_too_large or
                 msg_pkg.e_dbms_pipe_interrupted
            then
$if oracle_tools.cfg_pkg.c_debugging $then
              dbug.on_error;
$end -- $if oracle_tools.cfg_pkg.c_debugging $then
              null;
$end -- $if not(msg_constants_pkg.c_use_job_events_for_status) $then
          end;
        end if;

        -- kill
        begin
          dbms_scheduler.stop_job(r.job_name);
          dbms_scheduler.disable(r.job_name);
        exception
          when e_job_does_not_exist
          then null;
          
          when others
          then
$if oracle_tools.cfg_pkg.c_debugging $then
            dbug.on_error;
$end
            null;
        end;
      end loop;
  end case;
  
  commit;

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
$end
end do;

procedure submit_processing_supervisor
( p_processing_package in varchar2
, p_nr_workers_each_group in positive
, p_nr_workers_exact in positive
, p_ttl in positiven
, p_repeat_interval in varchar2
)
is
  l_processing_package constant all_objects.object_name%type := determine_processing_package(p_processing_package);
  l_job_name constant job_name_t :=
    get_job_name
    ( p_processing_package => l_processing_package
    , p_program_name => c_program_supervisor
    , p_job_suffix => case when p_repeat_interval is null then to_char(sysdate, "yyyymmddhh24miss") end
    );
  l_argument_value user_scheduler_program_args.default_value%type;
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.SUBMIT_PROCESSING_SUPERVISOR');
  dbug.print
  ( dbug."input"
  , 'p_processing_package: %s; p_nr_workers_each_group: %s; p_nr_workers_exact: %s; p_ttl: %s; p_repeat_interval: %s'
  , p_processing_package
  , p_nr_workers_each_group
  , p_nr_workers_exact
  , p_ttl
  , p_repeat_interval
  );
  dbug.print(dbug."info", 'l_job_name: %s', l_job_name);
$end

  if is_job_running(l_job_name)
  then
    raise too_many_rows;
  end if;

  if not(does_job_exist(l_job_name))
  then
    if not(does_program_exist(c_program_supervisor))
    then
      create_program(c_program_supervisor);
    end if;

    if p_repeat_interval is null
    then
      -- a non-repeating job
      dbms_scheduler.create_job
      ( job_name => l_job_name
      , program_name => c_program_supervisor
      , job_class => 'DEFAULT_JOB_CLASS'
      , enabled => false -- so we can set job arguments
      , auto_drop => true
      , comments => 'Temporary job for processing messages.'
      , job_style => 'REGULAR'
      , credential_name => null
      , destination_name => null
      );
    else
      -- a repeating job
      if not(does_schedule_exist(c_schedule_supervisor))
      then
        dbms_scheduler.create_schedule
        ( schedule_name => c_schedule_supervisor
        , start_date => null
        , repeat_interval => p_repeat_interval
        , end_date => null
        , comments => 'Supervisor job schedule'
        );
      end if;

      dbms_scheduler.create_job
      ( job_name => l_job_name
      , program_name => c_program_supervisor
      , schedule_name => c_schedule_supervisor
      , job_class => 'DEFAULT_JOB_CLASS'
      , enabled => false -- so we can set job arguments
      , auto_drop => false
      , comments => 'Repeating job for processing messages.'
      , job_style => 'REGULAR'
      , credential_name => null
      , destination_name => null
      );
    end if;
  else
    dbms_scheduler.disable(l_job_name); -- stop the job so we can give it job arguments
  end if;

  -- set arguments
  for r in
  ( select  a.argument_name
    from    user_scheduler_jobs j
            inner join user_scheduler_program_args a
            on a.program_name = j.program_name
    where   job_name = l_job_name
    order by
            a.argument_position 
  )
  loop
    case r.argument_name
      when 'P_PROCESSING_PACKAGE'
      then l_argument_value := p_processing_package;
      when 'P_NR_WORKERS_EACH_GROUP'
      then l_argument_value := to_char(p_nr_workers_each_group);
      when 'P_NR_WORKERS_EXACT'
      then l_argument_value := to_char(p_nr_workers_exact);
      when 'P_TTL'
      then l_argument_value := to_char(p_ttl);
    end case;

$if oracle_tools.cfg_pkg.c_debugging $then
    dbug.print
    ( dbug."info"
    , 'argument name: %s; argument value: %s'
    , r.argument_name
    , l_argument_value
    );
$end

    dbms_scheduler.set_job_argument_value
    ( job_name => l_job_name
    , argument_name => r.argument_name
    , argument_value => l_argument_value
    );
  end loop;
  
  dbms_scheduler.enable(l_job_name); -- start the job

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
$end
end submit_processing_supervisor;

procedure processing_supervisor
( p_processing_package in varchar2
, p_nr_workers_each_group in positive
, p_nr_workers_exact in positive
, p_ttl in positiven
)
is
  l_processing_package constant all_objects.object_name%type := determine_processing_package(p_processing_package);
  l_job_name_supervisor job_name_t := null;
  l_job_name_tab sys.odcivarchar2list := sys.odcivarchar2list();
  l_groups_to_process_tab sys.odcivarchar2list;
  l_groups_to_process_list varchar2(4000 char);
  l_start constant oracle_tools.api_time_pkg.time_t := oracle_tools.api_time_pkg.get_time;
  l_elapsed_time oracle_tools.api_time_pkg.seconds_t;

  procedure check_input_and_state
  is
    l_statement varchar2(32767 byte);
  begin
    case
      when ( p_nr_workers_each_group is not null and p_nr_workers_exact is null ) or
           ( p_nr_workers_each_group is null and p_nr_workers_exact is not null )
      then null; -- ok
      else
        raise_application_error
        ( -20000
        , utl_lms.format_message
          ( 'Exactly one of the following parameters must be set: p_nr_workers_each_group (%d), p_nr_workers_exact (%d).'
          , p_nr_workers_each_group -- since the type is positive %d should work
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
        
      l_job_name_supervisor := 
        get_job_name
        ( p_processing_package => l_processing_package
        , p_program_name => c_program_supervisor
        , p_job_suffix => to_char(sysdate, "yyyymmddhh24miss")
        );
    end if;

    l_statement := utl_lms.format_message
                   ( q'[begin :1 := %s.get_groups_to_process('package://%s.%s'); end;]'
                   , l_processing_package -- already checked by determine_processing_package
                   , $$PLSQL_UNIT_OWNER
                   , $$PLSQL_UNIT
                   );

    begin
      execute immediate l_statement using out l_groups_to_process_tab;      
$if oracle_tools.cfg_pkg.c_debugging $then
    exception
      when others
      then
        dbug.print(dbug."error", 'l_statement: %s', l_statement);
        dbug.on_error;
        raise;     
$end
    end;

    if l_groups_to_process_tab.count = 0
    then
      raise_application_error
      ( -20000
      , 'Could not find groups for processing.'
      );
    end if;

    l_groups_to_process_list := oracle_tools.api_pkg.collection2list(p_value_tab => l_groups_to_process_tab, p_sep => ',', p_ignore_null => 1);
  end check_input_and_state;

  procedure define_workers
  is
  begin
    -- Create the workers
    for i_worker in 1 .. nvl(p_nr_workers_exact, p_nr_workers_each_group * l_groups_to_process_tab.count)
    loop
      l_job_name_tab.extend(1);
      l_job_name_tab(l_job_name_tab.last) := l_job_name_supervisor || '#' || to_char(i_worker); -- the # indicates a worker job
    end loop;  
  end define_workers;

  procedure start_worker
  ( p_job_name_worker in varchar2
  )
  is
    l_worker_nr constant positiven := to_number(substr(p_job_name_worker, instr(p_job_name_worker, '#') + 1));
  begin
    submit_processing
    ( p_processing_package => p_processing_package
    , p_groups_to_process_list => l_groups_to_process_list
    , p_worker_nr => l_worker_nr
    , p_ttl => p_ttl
    , p_job_name_supervisor => l_job_name_supervisor
    );
  end start_worker;
  
  procedure start_workers
  is
  begin
    recv_init(l_job_name_supervisor);
    
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
    l_event msg_pkg.event_t;
    l_worker_nr integer;
    l_sqlcode integer;
    l_sqlerrm varchar2(4000 char);
    l_session_id user_scheduler_running_jobs.session_id%type;
  begin    
    loop
      l_elapsed_time := oracle_tools.api_time_pkg.elapsed_time(l_start, oracle_tools.api_time_pkg.get_time);

$if oracle_tools.cfg_pkg.c_debugging $then
      dbug.print(dbug."info", 'elapsed time: %s seconds', to_char(l_elapsed_time));
$end

      exit when l_elapsed_time >= p_ttl;

      -- get the status

      recv_event
      ( p_job_name_supervisor => l_job_name_supervisor
      , p_timeout => greatest(1, trunc(p_ttl - l_elapsed_time)) -- don't use 0 but 1 second as minimal timeout since 0 seconds may kill your server
      , p_event => l_event
      , p_worker_nr => l_worker_nr 
      , p_sqlcode => l_sqlcode
      , p_sqlerrm => l_sqlerrm
      , p_session_id => l_session_id
      );

$if oracle_tools.cfg_pkg.c_debugging $then
      dbug.print(dbug."info", 'l_event: %s', l_event);
$end      

      exit when l_event = msg_pkg."STOP_SUPERVISOR";

      l_elapsed_time := oracle_tools.api_time_pkg.elapsed_time(l_start, oracle_tools.api_time_pkg.get_time);

      exit when l_elapsed_time >= p_ttl;
      
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
    dbug.print(dbug."info", 'Stopped supervising workers after %s seconds', to_char(l_elapsed_time));
$end
  end supervise_workers;

  procedure stop_worker
  ( p_job_name_worker in varchar2
  )
  is
  begin
    if is_job_running(p_job_name_worker)
    then
      dbms_scheduler.stop_job(p_job_name_worker);
      dbms_scheduler.disable(p_job_name_worker);
    end if;
  end stop_worker;

  procedure stop_workers
  is
  begin
    if l_job_name_tab.count > 0
    then
      for i_worker in l_job_name_tab.first .. l_job_name_tab.last
      loop        
        stop_worker(p_job_name_worker => l_job_name_tab(i_worker));
      end loop;
    end if;
  end stop_workers;
  
  procedure cleanup
  is
  begin
    stop_workers;
    if l_job_name_supervisor is not null
    then
      recv_done(l_job_name_supervisor);
    end if;
    done;
  end cleanup;
begin
  init;
  
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.PROCESSING_SUPERVISOR');
  dbug.print
  ( dbug."input"
  , utl_lms.format_message
    ( 'p_processing_package: %s; p_nr_workers_each_group: %d; p_nr_workers_exact: %d; p_ttl: %d'
    , p_processing_package
    , p_nr_workers_each_group
    , p_nr_workers_exact
    , p_ttl
    )
  );
$end

  check_input_and_state;
  define_workers;
  start_workers;
  supervise_workers;

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
$end

  cleanup; -- after dbug.leave since the done inside will change dbug state

exception
$if msg_constants_pkg.c_use_job_events_for_status $then
  when msg_aq_pkg.e_dequeue_timeout
$else  
  when msg_pkg.e_dbms_pipe_timeout or
       msg_pkg.e_dbms_pipe_record_too_large or
       msg_pkg.e_dbms_pipe_interrupted
$end -- $if msg_constants_pkg.c_use_job_events_for_status $then
  then
$if oracle_tools.cfg_pkg.c_debugging $then  
    dbug.leave_on_error;
$end

    cleanup; -- after dbug.leave_on_error since the done inside will change dbug state
    -- no reraise necessary
    
  when others
  then
$if oracle_tools.cfg_pkg.c_debugging $then  
    dbug.leave_on_error;
$end

    cleanup; -- after dbug.leave_on_error since the done inside will change dbug state
    raise;
end processing_supervisor;

procedure processing
( p_processing_package in varchar2 
, p_groups_to_process_list in varchar2
, p_worker_nr in positiven
, p_ttl in positiven
, p_job_name_supervisor in varchar2
)
is
  l_processing_package constant all_objects.object_name%type := determine_processing_package(p_processing_package);
  l_job_name_worker constant job_name_t := session_job_name();
  l_statement varchar2(32767 byte);
  l_groups_to_process_tab sys.odcivarchar2list;

  procedure cleanup
  is
  begin
    done;
    send_done
    ( p_job_name_supervisor => p_job_name_supervisor
    , p_worker_nr => p_worker_nr
    );
  end cleanup;
begin
  send_init
  ( p_job_name_supervisor => p_job_name_supervisor
  , p_worker_nr => p_worker_nr
  );
  init;

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.PROCESSING');
  dbug.print
  ( dbug."input"
  , 'p_groups_to_process_list: %s; p_worker_nr: %s; p_ttl: %s; p_job_name_supervisor: %s'
  , p_groups_to_process_list
  , p_worker_nr
  , p_ttl
  , p_job_name_supervisor
  );
$end

  if l_job_name_worker is null
  then
    raise_application_error
    ( -20000
    , utl_lms.format_message
      ( 'This session (SID=%s) does not appear to be a running job (for this user), see also column SESSION_ID from view USER_SCHEDULER_RUNNING_JOBS.'
      , to_char(c_session_id)
      )
    );
  else
    select  pg.column_value
    bulk collect
    into    l_groups_to_process_tab
    from    table(oracle_tools.api_pkg.list2collection(p_value_list => p_groups_to_process_list, p_sep => ',', p_ignore_null => 1)) pg;

    l_statement := utl_lms.format_message
                   ( 'call %s.processing(p_groups_to_process_tab => :1, p_worker_nr => :2, p_ttl => :3, p_job_name_supervisor => :4)'
                   , l_processing_package -- already checked by determine_processing_package
                   );
    declare
      -- ORA-06550: line 1, column 18:
      -- PLS-00302: component 'PROCESING' must be declared
      e_compilation_error exception;
      pragma exception_init(e_compilation_error, -6550);
    begin
      execute immediate l_statement
        using in l_groups_to_process_tab, in p_worker_nr, in p_ttl, in p_job_name_supervisor;
        
      send_worker_status
      ( p_job_name_supervisor => p_job_name_supervisor
      , p_worker_nr => p_worker_nr
      , p_sqlcode => sqlcode
      , p_sqlerrm => sqlerrm
      , p_timeout => 0
      );  
    exception
      when e_compilation_error
      then
$if oracle_tools.cfg_pkg.c_debugging $then
        dbug.print(dbug."error", 'statement: %s', l_statement);
        dbug.on_error;
$end                  
        raise;
        
      when others
      then
$if oracle_tools.cfg_pkg.c_debugging $then
        dbug.on_error;
$end
        send_worker_status
        ( p_job_name_supervisor => p_job_name_supervisor
        , p_worker_nr => p_worker_nr
        , p_sqlcode => sqlcode
        , p_sqlerrm => sqlerrm
        , p_timeout => 0
        );
        raise;
    end;
  end if;

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
$end  

  cleanup;
exception
  when others
  then
$if oracle_tools.cfg_pkg.c_debugging $then  
    dbug.leave_on_error;
$end    
    cleanup;
    raise;
end processing;

end msg_scheduler_pkg;
/

