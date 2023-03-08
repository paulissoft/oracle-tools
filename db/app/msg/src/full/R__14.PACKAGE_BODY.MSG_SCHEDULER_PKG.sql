CREATE OR REPLACE PACKAGE BODY "MSG_SCHEDULER_PKG" AS

subtype job_name_t is user_scheduler_jobs.job_name%type;
subtype job_suffix_t is varchar2(14 char); -- to_char(sysdate, "yyyymmddhh24miss")

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
  dbug.print(dbug."info", 'get_job_name: %s', l_job_name);
$end

  return l_job_name;
end get_job_name;

procedure split_job_name
( p_job_name in job_name_t
, p_processing_package out nocopy varchar2
, p_program_name out nocopy varchar2
, p_job_suffix out nocopy job_suffix_t
, p_worker_nr out nocopy positive
)
is
  l_pos$ pls_integer;
  l_pos# pls_integer;
begin
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
  ( dbug."info"
  , q'[split_job_name(p_job_name => '%s', p_processing_package => '%s', p_program_name => '%s', p_job_suffix => '%s', p_worker_nr => %s)]'
  , p_job_name
  , p_processing_package
  , p_program_name
  , p_job_suffix
  , p_worker_nr
  );
$end  

end split_job_name;

function get_jobs
( p_job_name_expr in varchar2
, p_state in user_scheduler_jobs.state%type default null
, p_only_workers in integer default null -- 0: only supervisors; 1: only workers; null: any
)
return sys.odcivarchar2list
is
  l_job_names sys.odcivarchar2list;
begin
  select  j.job_name
  bulk collect
  into    l_job_names
  from    user_scheduler_jobs j
  where   j.job_name like replace(replace(p_job_name_expr, '_', '\_'), '\\', '\') escape '\'
  and     ( p_state is null or j.state = p_state )
  and     ( p_only_workers is null or p_only_workers = sign(instr(j.job_name, '#')) )
  order by
          job_name -- permanent supervisor first, then its workers jobs, next temporary supervisors and their workers
  ;
  return l_job_names;
end get_jobs;

function does_job_exist
( p_job_name in job_name_t
)
return boolean
is
begin
  PRAGMA INLINE (get_jobs, 'YES');
  return get_jobs(p_job_name).count = 1;
end does_job_exist;

function is_job_running
( p_job_name in job_name_t
)
return boolean
is
begin
  PRAGMA INLINE (get_jobs, 'YES');
  return get_jobs(p_job_name, 'RUNNING').count = 1;
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
    raise_application_error
    ( c_job_already_running
    , utl_lms.format_message
      ( c_job_already_running_msg
      , l_job_name_worker
      )
    );
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
      -- GJP 2023-03-07 Due to failing ORA-27483: "BC_API"."MSG_AQ_PKG$PROCESSING_SUPERVISOR$20230307111848#1" has an invalid END_DATE 
      -- , end_date => sysdate + (p_ttl / (24 * 60 * 60)) -- as precaution
    , end_date => null
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
begin
  if p_processing_package is not null
  then
    return msg_pkg.get_object_name(p_object_name => p_processing_package, p_what => 'package', p_fq => 0, p_qq => 0);
  else
    raise program_error;
  end if;
end determine_processing_package;

procedure job_event_send_init
( p_job_name_supervisor in varchar2
, p_worker_nr in positive
)
is
begin
  dbms_scheduler.set_attribute
  ( name => p_job_name_supervisor || '#' || to_char(p_worker_nr)
  , attribute => 'raise_events'
  , value => dbms_scheduler.job_run_completed
  );
end job_event_send_init;

procedure job_event_recv_init
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
end job_event_recv_init;

-- Receive a job event for this supervisor.
procedure job_event_recv
( p_job_name_supervisor in varchar2
, p_timeout in integer
, p_worker_nr out nocopy positive
, p_sqlcode out nocopy integer
, p_sqlerrm out nocopy varchar2
)
is
  pragma autonomous_transaction;
  
  l_dequeue_options     dbms_aq.dequeue_options_t;
  l_message_properties  dbms_aq.message_properties_t;
  l_message_handle      raw(16);
  l_queue_msg           sys.scheduler$_event_info;

  -- for split_job_name on the supervisor
  l_processing_package_supervisor all_objects.object_name%type;
  l_program_name_supervisor user_scheduler_programs.program_name%type;
  l_job_suffix_supervisor job_suffix_t;
  l_worker_nr_supervisor positive;
  
  -- for split_job_name on the completed job
  l_job_name_worker job_name_t;
  l_processing_package_worker all_objects.object_name%type;
  l_program_name_worker user_scheduler_programs.program_name%type;
  l_job_suffix_worker job_suffix_t;

  l_our_worker boolean := false;
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT || '.JOB_EVENT_RECV');
  dbug.print
  ( dbug."input"
  , 'p_job_name_supervisor: %s; p_timeout: %s'
  , p_job_name_supervisor
  , p_timeout
  );
$end

  p_worker_nr := null;
  p_sqlcode := null;
  p_sqlerrm := null;

  pragma inline (split_job_name, 'YES');
  split_job_name
  ( p_job_name => p_job_name_supervisor
  , p_processing_package => l_processing_package_supervisor
  , p_program_name => l_program_name_supervisor
  , p_job_suffix => l_job_suffix_supervisor
  , p_worker_nr => l_worker_nr_supervisor
  );

  -- some sanity checks
  if l_program_name_supervisor = c_program_supervisor
  then
    null;
  else
    raise value_error;
  end if;

  if l_worker_nr_supervisor is null
  then
    null;
  else
    raise value_error;
  end if;

  -- The message dequeued may need to be processed by another process,
  -- since we receive all job status events in this schema.
  -- But since there should be only ONE supervisor running for the SAME processing package (for now there is just one: MSG_AQ_PKG),
  -- we can REMOVE all messages for the same processing package.
  --
  -- The best way to ignore job events from OTHER processing packages is
  -- to LOCK and inspect whether the concerning job is one of the workers for this processing package.
  -- If it is one of our workers, REMOVE the message with the msgid just retrieved and COMMIT.
  -- Otherwise, just ignore the message and ROLLBACK.

  l_dequeue_options.consumer_name := $$PLSQL_UNIT_OWNER;

  <<step_loop>>
  for i_step in 1..2
  loop
$if oracle_tools.cfg_pkg.c_debugging $then
    dbug.print(dbug."info", 'i_step: %s', i_step);
$end

    if i_step = 1
    then
      l_dequeue_options.dequeue_mode := dbms_aq.locked;
      l_dequeue_options.wait := p_timeout;
    else
      l_dequeue_options.dequeue_mode := dbms_aq.remove;
      l_dequeue_options.wait := dbms_aq.no_wait; -- no need to wait since we alreay locked the message
      l_dequeue_options.msgid := l_message_handle;
    end if;
    
    dbms_aq.dequeue
    ( queue_name => 'SYS.SCHEDULER$_EVENT_QUEUE'
    , dequeue_options => l_dequeue_options
    , message_properties => l_message_properties
    , payload => l_queue_msg
    , msgid => l_message_handle
    );

    exit step_loop when i_step = 2;
    
    l_job_name_worker := l_queue_msg.object_name;

$if oracle_tools.cfg_pkg.c_debugging $then
    dbug.print
    ( dbug."info"
    , 'job name: %s; event type: %s; event timestamp: %s; one of my / our workers: %s / %s'
    , l_job_name_worker
    , l_queue_msg.event_type
    , to_char(l_queue_msg.event_timestamp, "yyyymmddhh24miss")
    , dbug.cast_to_varchar2(l_job_name_worker like p_job_name_supervisor || '#%')
    , dbug.cast_to_varchar2(l_job_name_worker like l_processing_package_supervisor || '#%')
    );
$end

    if l_job_name_worker like p_job_name_supervisor || '#%'
    then
      -- my (and our) worker
      l_our_worker := true;
      
      pragma inline (split_job_name, 'YES');
      split_job_name
      ( p_job_name => l_job_name_worker
      , p_processing_package => l_processing_package_worker
      , p_program_name => l_program_name_worker
      , p_job_suffix => l_job_suffix_worker
      , p_worker_nr => p_worker_nr 
      );

      if p_worker_nr is not null
      then
        p_sqlcode := l_queue_msg.error_code;
        p_sqlerrm := l_queue_msg.error_msg;
      end if;
    elsif l_job_name_worker like l_processing_package_supervisor || '#%'
    then
      l_our_worker := true;
    end if;
  end loop step_loop;

  if l_our_worker
  then
    commit;
  else
    rollback; -- give another processing package supervisor a chance to process it
  end if;

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.print
  ( dbug."output"
  , 'p_worker_nr: %s; p_sqlcode: %s; p_sqlerrm: %s'
  , p_worker_nr
  , p_sqlcode
  , p_sqlerrm
  );  
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end job_event_recv;

-- PUBLIC

procedure do
( p_command in varchar2
, p_processing_package in varchar2
)
is
  pragma autonomous_transaction;

  l_command_tab constant sys.odcivarchar2list :=
    case lower(p_command)
      when 'start'
      then sys.odcivarchar2list('check_jobs_not_running', p_command)
      when 'stop'
      then sys.odcivarchar2list(p_command, 'check_jobs_not_running')
      when 'restart'
      then sys.odcivarchar2list('stop', 'check_jobs_not_running', 'start')
      when 'drop'
      then sys.odcivarchar2list('stop', 'check_jobs_not_running', 'drop')
      else sys.odcivarchar2list(p_command)
    end;    
  l_processing_package all_objects.object_name%type := trim('"' from replace(replace(upper(p_processing_package), '_', '\_'), '\\', '\'));
  l_processing_package_tab sys.odcivarchar2list;
  l_job_name_supervisor job_name_t;
  l_job_names sys.odcivarchar2list;
  l_state user_scheduler_jobs.state%type;
  l_ttl oracle_tools.api_time_pkg.seconds_t;

  -- for split job name
  l_processing_package_dummy all_objects.object_name%type;
  l_program_name_dummy user_scheduler_programs.program_name%type;
  l_job_suffix job_suffix_t;
  l_worker_nr positive;
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.DO');
  dbug.print(dbug."input", 'p_command: %s; p_processing_package: %s', p_command, p_processing_package);
$end

  select  p.package_name
  bulk collect
  into    l_processing_package_tab
  from    user_arguments p
  where   p.object_name = 'GET_GROUPS_TO_PROCESS'
  and     ( l_processing_package is null or p.package_name like l_processing_package escape '\' )
  intersect
  select  p.package_name
  from    user_arguments p
  where   p.object_name = 'PROCESSING'
  and     ( l_processing_package is null or p.package_name like l_processing_package escape '\' )
  ;

  if l_processing_package_tab.count = 0
  then
    raise no_data_found;
  end if;

  <<processing_package_loop>>
  for i_package_idx in l_processing_package_tab.first .. l_processing_package_tab.last
  loop
    l_processing_package := l_processing_package_tab(i_package_idx);

$if oracle_tools.cfg_pkg.c_debugging $then
    dbug.print(dbug."info", 'l_processing_package_tab(%s): %s', i_package_idx, l_processing_package_tab(i_package_idx));
$end

    l_job_name_supervisor :=
      get_job_name
      ( p_processing_package => l_processing_package 
      , p_program_name => c_program_supervisor
      , p_job_suffix => null
      , p_worker_nr => null
      );

    <<command_loop>>
    for i_command_idx in l_command_tab.first .. l_command_tab.last
    loop
$if oracle_tools.cfg_pkg.c_debugging $then
      dbug.print(dbug."info", 'l_command_tab(%s): %s', i_command_idx, l_command_tab(i_command_idx));
$end
      case l_command_tab(i_command_idx)
        when 'check_jobs_not_running'
        then
          l_job_names := get_jobs(l_job_name_supervisor || '%', 'RUNNING');
          if l_job_names.count > 0
          then
            raise_application_error
            ( c_there_are_running_jobs
            , utl_lms.format_message
              ( c_there_are_running_jobs_msg
              , l_job_name_supervisor || '%'
              , chr(10) || oracle_tools.api_pkg.collection2list(p_value_tab => l_job_names, p_sep => chr(10), p_ignore_null => 1)
              )
            );
          end if;
          
        when 'start'
        then
          begin
            -- respect the fact that the job is there with its current job arguments (maybe a DBA did that)
            dbms_scheduler.disable(l_job_name_supervisor);
            dbms_scheduler.enable(l_job_name_supervisor);
          exception
            when others
            then
$if oracle_tools.cfg_pkg.c_debugging $then
              dbug.on_error;
$end
              submit_processing_supervisor(p_processing_package => l_processing_package);
          end;

          select  j.state
          ,       oracle_tools.api_time_pkg.delta(oracle_tools.api_time_pkg.get_timestamp, j.next_run_date) as ttl
          into    l_state
          ,       l_ttl
          from    user_scheduler_jobs j
          where   j.job_name = l_job_name_supervisor;
          
          if l_state = 'SCHEDULED'
          then
            l_ttl := trunc(l_ttl) - msg_constants_pkg.c_time_between_runs;
            if l_ttl > 0
            then
              submit_processing_supervisor
              ( p_processing_package => l_processing_package
              , p_ttl => l_ttl
              , p_repeat_interval => null
              );
            end if;
          elsif l_state = 'RUNNING'
          then
            null; -- OK
          else
            raise_application_error
            ( c_unexpected_job_state
            , utl_lms.format_message
              ( c_unexpected_job_state_msg
              , l_job_name_supervisor
              , l_state
              )
            );
          end if;

        when 'stop'
        then
          -- This is a bit tricky: when you stop supervisors and workers in one run, there may be new workers stopped during that process.
          -- So, just stop all supervisors first, next the workers.
          -- And: always get a fresh list!
          <<supervisors_then_workers_loop>>
          for i_only_workers in 0..1
          loop
            l_job_names :=
              get_jobs
              ( p_job_name_expr => l_job_name_supervisor || '%'
              , p_state => case i_only_workers when 0 then 'RUNNING' else null end -- only running supervisors but all workers to get rid of left-overs
              , p_only_workers => i_only_workers
              );

            if l_job_names.count > 0
            then
              <<job_loop>>
              for i_job_idx in l_job_names.first .. l_job_names.last
              loop
                pragma inline (split_job_name, 'YES');
                split_job_name
                ( p_job_name => l_job_names(i_job_idx)
                , p_processing_package => l_processing_package_dummy
                , p_program_name => l_program_name_dummy
                , p_job_suffix => l_job_suffix
                , p_worker_nr => l_worker_nr
                );

$if oracle_tools.cfg_pkg.c_debugging $then
                dbug.print
                ( dbug."info"
                , 'trying to stop %s%s job %s'
                , case when l_job_suffix is not null then 'temporary 'end
                , case when l_worker_nr is null then 'supervisor' else 'worker' end
                , l_job_names(i_job_idx)
                );
$end

                -- kill
                begin
                  if l_job_suffix is null and l_worker_nr is null
                  then
                    -- stop and disable supervisors
                    dbms_scheduler.stop_job(job_name => l_job_names(i_job_idx), force => false);
                    if is_job_running(l_job_names(i_job_idx)) -- strange, but anyhow
                    then
                      dbms_scheduler.stop_job(job_name => l_job_names(i_job_idx), force => true);
                    end if;                    
                    dbms_scheduler.disable(l_job_names(i_job_idx));
                  else
                    -- drop temporary and/or worker jobs
                    dbms_scheduler.drop_job(job_name => l_job_names(i_job_idx), force => true);
                  end if;
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
              end loop job_loop;
            end if;
          end loop supervisors_then_workers_loop;

        when 'drop'
        then
          <<force_loop>>
          for i_force in 0..1 -- 0: force false
          loop
            l_job_names := get_jobs(p_job_name_expr => l_job_name_supervisor || '%');

            if l_job_names.count > 0
            then
              <<job_loop>>
              for i_job_idx in l_job_names.first .. l_job_names.last
              loop
$if oracle_tools.cfg_pkg.c_debugging $then
                dbug.print
                ( dbug."info"
                , 'trying to drop job %s'
                , l_job_names(i_job_idx)
                );
$end

                begin
                  dbms_scheduler.drop_job(job_name => l_job_names(i_job_idx), force => (i_force = 1));
                exception
                  when others
                  then
$if oracle_tools.cfg_pkg.c_debugging $then
                    dbug.on_error;
$end
                    null;
                end;
              end loop job_loop;
            end if;
          end loop force_loop;

        else
          raise_application_error
          ( c_unexpected_command
          , utl_lms.format_message
            ( c_unexpected_command_msg
            , l_command_tab(i_command_idx)
            )
          );

      end case;
    end loop command_loop;
  end loop processing_package_loop;

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
  l_job_name_supervisor job_name_t;
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
$end

  l_job_name_supervisor :=
    get_job_name
    ( p_processing_package => l_processing_package
    , p_program_name => c_program_supervisor
    , p_job_suffix => case when p_repeat_interval is null then to_char(sysdate, "yyyymmddhh24miss") end
    );

  if is_job_running(l_job_name_supervisor)
  then
    raise too_many_rows;
  end if;

  if not(does_job_exist(l_job_name_supervisor))
  then
    if not(does_program_exist(c_program_supervisor))
    then
      create_program(c_program_supervisor);
    end if;

    if p_repeat_interval is null
    then
      -- a non-repeating job
      dbms_scheduler.create_job
      ( job_name => l_job_name_supervisor
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
      ( job_name => l_job_name_supervisor
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
    dbms_scheduler.disable(l_job_name_supervisor); -- stop the job so we can give it job arguments
  end if;

  -- set arguments
  for r in
  ( select  a.argument_name
    from    user_scheduler_jobs j
            inner join user_scheduler_program_args a
            on a.program_name = j.program_name
    where   job_name = l_job_name_supervisor
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
    ( job_name => l_job_name_supervisor
    , argument_name => r.argument_name
    , argument_value => l_argument_value
    );
  end loop;
  
  dbms_scheduler.enable(l_job_name_supervisor); -- start the job

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
        ( c_one_parameter_not_null
        , utl_lms.format_message
          ( c_one_parameter_not_null_msg
          , p_nr_workers_each_group -- since the type is positive, %d should work
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
      ( c_no_groups_to_process
      , c_no_groups_to_process_msg
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

  procedure stop_worker
  ( p_job_name_worker in varchar2
  )
  is
  begin
    if does_job_exist(p_job_name_worker)
    then
      dbms_scheduler.drop_job(job_name => p_job_name_worker, force => true);
    end if;
  exception
    when e_job_does_not_exist -- strange
    then null;
  end stop_worker;

  procedure start_worker
  ( p_job_name_worker in varchar2
  )
  is
    l_worker_nr constant positiven := to_number(substr(p_job_name_worker, instr(p_job_name_worker, '#') + 1));
  begin
    -- submit but when job already exists: stop it and retry
    <<try_loop>>
    for i_try in 1..2
    loop
      begin
        submit_processing
        ( p_processing_package => p_processing_package
        , p_groups_to_process_list => l_groups_to_process_list
        , p_worker_nr => l_worker_nr
        , p_ttl => p_ttl
        , p_job_name_supervisor => l_job_name_supervisor
        );
        exit try_loop; -- OK
      exception
        when e_job_already_running
        then
          if i_try = 1
          then
            stop_worker(p_job_name_worker);
          else
            raise;
          end if;
      end;
    end loop try_loop;
  end start_worker;
  
  procedure start_workers
  is
  begin
    job_event_recv_init(l_job_name_supervisor);
    
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
    l_worker_nr positive;
    l_sqlcode integer;
    l_sqlerrm varchar2(4000 char);
  begin    
    loop
      l_elapsed_time := oracle_tools.api_time_pkg.elapsed_time(l_start, oracle_tools.api_time_pkg.get_time);

$if oracle_tools.cfg_pkg.c_debugging $then
      dbug.print(dbug."info", 'elapsed time: %s seconds', to_char(l_elapsed_time));
$end

      exit when l_elapsed_time >= p_ttl;

      -- get the status

      job_event_recv
      ( p_job_name_supervisor => l_job_name_supervisor
      , p_timeout => greatest(1, trunc(p_ttl - l_elapsed_time)) -- don't use 0 but 1 second as minimal timeout since 0 seconds may kill your server
      , p_worker_nr => l_worker_nr 
      , p_sqlcode => l_sqlcode
      , p_sqlerrm => l_sqlerrm
      );

      l_elapsed_time := oracle_tools.api_time_pkg.elapsed_time(l_start, oracle_tools.api_time_pkg.get_time);

      exit when l_elapsed_time >= p_ttl;

      if l_worker_nr is not null
      then
$if oracle_tools.cfg_pkg.c_debugging $then
        dbug.print
        ( case when l_sqlerrm is null then dbug."info" else dbug."error" end
        , 'Worker %s stopped with error code %s'
        , l_worker_nr
        , l_sqlcode
        );
        if l_sqlerrm is not null
        then
          dbug.print(dbug."error", l_sqlerrm);
        end if;
$end

        start_worker(p_job_name_worker => l_job_name_supervisor || '#' || l_worker_nr);
      end if;
    end loop;
$if oracle_tools.cfg_pkg.c_debugging $then
    dbug.print(dbug."info", 'Stopped supervising workers after %s seconds', to_char(l_elapsed_time));
$end
  end supervise_workers;

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
  when msg_aq_pkg.e_dequeue_timeout
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
  end cleanup;
begin
  job_event_send_init
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
    ( c_session_not_running_job
    , utl_lms.format_message
      ( c_session_not_running_job_msg
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

