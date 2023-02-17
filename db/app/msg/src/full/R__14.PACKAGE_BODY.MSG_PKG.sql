CREATE OR REPLACE PACKAGE BODY "MSG_PKG" AS

c_program_supervisor constant user_scheduler_programs.program_name%type := 'PROCESSING_SUPERVISOR';
c_program_worker constant user_scheduler_programs.program_name%type := 'PROCESSING';

"yyyy-mm-dd hh24:mi:ss" constant varchar2(100) := 'yyyy-mm-dd hh24:mi:ss';
"yyyy-mm-ddThh24:mi:ssZ" constant varchar2(100) := 'yyyy-mm-ddThh24:mi:ssZ'; -- ISO 8601 

c_max_size_vc constant simple_integer := 4000;
c_max_size_raw constant simple_integer := 2000;

c_session_id constant user_scheduler_running_jobs.session_id%type := to_number(sys_context('USERENV', 'SID'));

$if oracle_tools.cfg_pkg.c_debugging $then
 
subtype t_dbug_channel_active_tab is t_boolean_lookup_tab;

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
  l_dbug_channel_tab constant sys.odcivarchar2list := msg_constants_pkg.c_dbug_channel_tab;
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
             ( 'DBMS_OUTPUT'
$if not(oracle_tools.cfg_pkg.c_testing) $then
             , 'LOG4PLSQL'
$end  
             , 'PLSDBUG'
             )
        then false
        else true
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
    dbug.activate(l_dbug_channel, g_dbug_channel_active_tab(l_dbug_channel));
    
    l_dbug_channel := g_dbug_channel_active_tab.next(l_dbug_channel);
  end loop;
$end -- $if oracle_tools.cfg_pkg.c_debugging $then  
end done;

function job_name
( p_processing_package in varchar2
, p_program_name in varchar2
, p_job_name_suffix in varchar2
, p_worker_nr in positive default null
)
return varchar2
is
begin
  return
    p_processing_package ||
    '$' ||
    p_program_name ||
    case when p_job_name_suffix  is not null then '$' || p_job_name_suffix end ||
    case when p_worker_nr is not null then '#' || to_char(p_worker_nr) end;
end job_name;

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
      , number_of_arguments => 6
      , enabled => false
      , comments => 'Main program for processing messages that spawns other worker in-memory jobs and supervises them.'
      );

      for i_par_idx in 1..6
      loop
        dbms_scheduler.define_program_argument
        ( program_name => l_program_name
        , argument_name => case i_par_idx
                             when 1 then 'P_PROCESSING_PACKAGE'
                             when 2 then 'P_INCLUDE_GROUP_LIST'
                             when 3 then 'P_EXCLUDE_GROUP_LIST'
                             when 4 then 'P_NR_WORKERS_EACH_GROUP'
                             when 5 then 'P_NR_WORKERS_EXACT'
                             when 6 then 'P_TTL'
                           end
        , argument_position => i_par_idx
        , argument_type => case 
                             when i_par_idx <= 3
                             then 'VARCHAR2'
                             else 'NUMBER'
                           end
        , default_value => case i_par_idx
                             when 2 then '%'
                             when 3 then replace(web_service_response_typ.default_group, '_', '\_')
                             when 6 then to_char(c_one_day_minus_something)
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
                             when 2 then 'P_PROCESSING_GROUP_LIST'
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

procedure submit_processing
( p_processing_package in varchar2
, p_processing_group_list in varchar2
, p_worker_nr in positiven
, p_ttl in positiven
, p_job_name_supervisor in varchar2
)
is
  l_job_name_worker constant user_scheduler_jobs.job_name%type := p_job_name_supervisor || '#' || to_char(p_worker_nr);
  l_argument_value user_scheduler_program_args.default_value%type;
begin  
  if does_job_exist(l_job_name_worker)
  then
    raise too_many_rows; -- should not happen
  end if;
  
  if not(does_program_exist(c_program_worker))
  then
    create_program(c_program_worker);
  end if;
  
  dbms_scheduler.create_job
  ( job_name => l_job_name_worker
  , program_name => c_program_worker
  , start_date => null
    -- will never repeat
  , repeat_interval => null
  , end_date => sysdate + (p_ttl / (24 * 60 * 60)) -- as precaution
    -- ORA-27476: "SYS"."DEFAULT_IN_MEMORY_JOB_CLASS" does not exist
    -- Can not be granted neither, at least not by ADMIN
  -- , job_class => 'DEFAULT_IN_MEMORY_JOB_CLASS'
  , enabled => false -- so we can set job arguments
  , auto_drop => true -- one-off jobs
  , comments => 'Worker job for processing messages.'
  --, job_style => 'IN_MEMORY_FULL'
  --, job_style => 'IN_MEMORY_RUNTIME'
  , job_style => 'LIGHTWEIGHT'
  , credential_name => null
  , destination_name => null
  );
  
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
      when 'P_PROCESSING_GROUP_LIST'
      then l_argument_value := p_processing_group_list;
      when 'P_WORKER_NR'
      then l_argument_value := to_char(p_worker_nr);
      when 'P_TTL'
      then l_argument_value := to_char(p_ttl);
      when 'P_JOB_NAME_SUPERVISOR'
      then l_argument_value := p_job_name_supervisor;
    end case;
    
    dbms_scheduler.set_job_argument_value
    ( job_name => l_job_name_worker
    , argument_name => r.argument_name
    , argument_value => l_argument_value
    );
  end loop;
  
  dbms_scheduler.enable(l_job_name_worker);
end submit_processing;

-- PUBLIC

procedure submit_processing_supervisor
( p_processing_package in varchar2 default null -- if null utl_call_stack will be used to use the calling package as processing package
, p_include_group_list in varchar2 default '%' -- a comma separated list of (case sensitive) group names with wildcards allowed
, p_exclude_group_list in varchar2 default replace(web_service_response_typ.default_group, '_', '\_') -- these groups must be manually processed because the creator is interested in the result
, p_nr_workers_each_group in positive default null -- the total number of workers will be this number multiplied by the number of groups
, p_nr_workers_exact in positive default null -- the total number of workers will be this number
, p_ttl in positiven default c_one_day_minus_something -- time to live (in seconds)
, p_job_name_suffix in varchar2 default null -- to have other jobs
, p_start_date in timestamp with time zone default null
, p_repeat_interval in varchar2 default null
)
is
  l_processing_package constant all_objects.object_name%type :=
    trim('"' from dbms_assert.enquote_name(nvl(p_processing_package, utl_call_stack.subprogram(2)(1)))); -- 2 is the index of the calling unit, 1 is the name of the unit
  l_job_name constant user_scheduler_jobs.job_name%type :=
    job_name
    ( l_processing_package
    , c_program_supervisor
    , p_job_name_suffix
    );
  l_argument_value user_scheduler_program_args.default_value%type;
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.SUBMIT_PROCESSING_SUPERVISOR');
  dbug.print
  ( dbug."input"
  , 'p_processing_package: %s; p_include_group_list: %s; p_exclude_group_list: %s; p_nr_workers_each_group: %s; p_nr_workers_exact: %s'
  , p_processing_package
  , p_include_group_list
  , p_exclude_group_list
  , p_nr_workers_each_group
  , p_nr_workers_exact
  );
  dbug.print
  ( dbug."input"
  , 'p_ttl: %s; p_job_name_suffix: %s; p_start_date: %s; p_repeat_interval: %s'
  , p_ttl
  , p_job_name_suffix
  , to_char(p_start_date, "yyyy-mm-dd hh24:mi:ss")
  , p_repeat_interval
  );
$end

  if not(does_job_exist(l_job_name))
  then
    if not(does_program_exist(c_program_supervisor))
    then
      create_program(c_program_supervisor);
    end if;
    
    dbms_scheduler.create_job
    ( job_name => l_job_name
    , program_name => c_program_supervisor
    , start_date => p_start_date
    , repeat_interval => p_repeat_interval
    , end_date => null
    , job_class => 'DEFAULT_JOB_CLASS'
    , enabled => false -- so we can set job arguments
    , auto_drop => false
    , comments => 'Main job for processing messages.'
    , job_style => 'REGULAR'
    , credential_name => null
    , destination_name => null
    );
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
      when 'P_INCLUDE_GROUP_LIST'
      then l_argument_value := p_include_group_list;
      when 'P_EXCLUDE_GROUP_LIST'
      then l_argument_value := p_exclude_group_list;
      when 'P_NR_WORKERS_EACH_GROUP'
      then l_argument_value := to_char(p_nr_workers_each_group);
      when 'P_NR_WORKERS_EXACT'
      then l_argument_value := to_char(p_nr_workers_exact);
      when 'P_TTL'
      then l_argument_value := to_char(p_ttl);
    end case;
    
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
( p_processing_package in varchar2 default null -- if null utl_call_stack will be used to use the calling package as processing package
, p_include_group_list in varchar2 default '%' -- a comma separated list of (case sensitive) group names with wildcards allowed
, p_exclude_group_list in varchar2 default replace(web_service_response_typ.default_group, '_', '\_') -- these groups must be manually processed because the creator is interested in the result
, p_nr_workers_each_group in positive default null -- the total number of workers will be this number multiplied by the number of groups
, p_nr_workers_exact in positive default null -- the total number of workers will be this number
, p_ttl in positiven default c_one_day_minus_something -- time to live (in seconds)
)
is
  l_processing_package constant all_objects.object_name%type :=
    trim('"' from dbms_assert.enquote_name(nvl(p_processing_package, utl_call_stack.subprogram(2)(1)))); -- 2 is the index of the calling unit, 1 is the name of the unit
  l_job_name_supervisor user_scheduler_jobs.job_name%type;
  l_job_name_tab sys.odcivarchar2list := sys.odcivarchar2list();
  l_include_group_tab sys.odcivarchar2list;
  l_exclude_group_tab sys.odcivarchar2list;
  l_processing_group_tab sys.odcivarchar2list;
  l_processing_group_list varchar2(4000 char);
  l_start constant number := dbms_utility.get_time;
  l_elapsed_time number;

  procedure check_input_and_state
  is
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
        job_name
        ( l_processing_package
        , c_program_supervisor
        , to_char(sysdate, 'yyyymmddhh24miss')
        );
    end if;

    select  ig.column_value
    bulk collect
    into    l_include_group_tab
    from    table(oracle_tools.api_pkg.list2collection(p_value_list => p_include_group_list, p_sep => ',', p_ignore_null => 1)) ig;
    
    select  eg.column_value
    bulk collect
    into    l_exclude_group_tab
    from    table(oracle_tools.api_pkg.list2collection(p_value_list => p_exclude_group_list, p_sep => ',', p_ignore_null => 1)) eg;

    execute immediate utl_lms.format_message
                      ( 'call %s.get_groups_for_processing(p_include_group_tab => :1, p_exclude_group_tab => :2, p_processing_group_tab => :3)'
                      , l_processing_package
                      )
      using in l_include_group_tab, in l_exclude_group_tab, out l_processing_group_tab;                      

    if l_processing_group_tab.count = 0
    then
      raise_application_error
      ( -20000
      , utl_lms.format_message
        ( 'Could not find groups for processing with included list (%s) and excluded list (%s).'
        , p_include_group_list
        , p_exclude_group_list
        )
      );
    end if;

    select  listagg(column_value, ',') within group (order by column_value)
    into    l_processing_group_list
    from    table(l_processing_group_tab);
  end check_input_and_state;

  procedure start_worker
  ( p_job_name_worker in varchar2
  )
  is
    l_worker_nr constant positiven := to_number(substr(p_job_name_worker, instr(p_job_name_worker, '#')+1));
  begin
    submit_processing
    ( p_processing_package => p_processing_package
    , p_processing_group_list => l_processing_group_list
    , p_worker_nr => l_worker_nr
    , p_ttl => p_ttl
    , p_job_name_supervisor => l_job_name_supervisor
    );
  end start_worker;

  procedure define_workers
  is
  begin
    -- Create the workers
    for i_worker in 1 .. nvl(p_nr_workers_exact, p_nr_workers_each_group * l_processing_group_tab.count)
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
      l_elapsed_time := msg_pkg.elapsed_time(l_start, dbms_utility.get_time);

$if oracle_tools.cfg_pkg.c_debugging $then
      dbug.print(dbug."info", 'elapsed time: %s seconds', to_char(l_elapsed_time));
$end

      exit when l_elapsed_time >= p_ttl;

      -- get the status from the pipe

      recv_worker_status
      ( p_job_name_supervisor => l_job_name_supervisor
      , p_timeout => greatest(1, trunc(p_ttl - l_elapsed_time)) -- don't use 0 but 1 second as minimal timeout since 0 seconds may kill your server
      , p_worker_nr => l_worker_nr 
      , p_sqlcode => l_sqlcode
      , p_sqlerrm => l_sqlerrm
      , p_session_id => l_session_id
      );

      l_elapsed_time := msg_pkg.elapsed_time(l_start, dbms_utility.get_time);

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
begin
  init;
  
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.DEQUEUE_AND_PROCESS_SUPERVISOR');
  dbug.print
  ( dbug."input"
  , utl_lms.format_message
    ( 'p_processing_package: %s; p_include_group_list: %s; p_exclude_group_list: %s; p_nr_workers_each_group: %d; p_nr_workers_exact: %d; p_ttl: %d'
    , p_processing_package
    , p_include_group_list
    , p_exclude_group_list
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
end processing_supervisor;

procedure processing
( p_processing_package in varchar2 
, p_processing_group_list in varchar2
, p_worker_nr in positiven
, p_ttl in positiven
, p_job_name_supervisor in varchar2
)
is
  l_processing_package constant all_objects.object_name%type :=
    trim('"' from dbms_assert.enquote_name(nvl(p_processing_package, utl_call_stack.subprogram(2)(1)))); -- 2 is the index of the calling unit, 1 is the name of the unit  
  l_job_name_worker constant user_scheduler_jobs.job_name%type := session_job_name();
  l_processing_group_tab sys.odcivarchar2list;
begin
  init;

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.PROCESSING');
  dbug.print
  ( dbug."input"
  , 'p_processing_group_list: %s; p_worker_nr: %s; p_ttl: %s; p_job_name_supervisor: %s'
  , p_processing_group_list
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
    into    l_processing_group_tab
    from    table(oracle_tools.api_pkg.list2collection(p_value_list => p_processing_group_list, p_sep => ',', p_ignore_null => 1)) pg;
  
    execute immediate utl_lms.format_message
                      ( 'call %s.processing(p_processing_group_tab => :1, p_worker_nr => :2, p_ttl => :3, p_job_name_supervisor => :4)'
                      , l_processing_package
                      )
      using in l_processing_group_tab, in p_worker_nr, in p_ttl, in p_job_name_supervisor;
  end if;

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
$end  

  done;  
exception
  when others
  then
$if oracle_tools.cfg_pkg.c_debugging $then  
    dbug.leave_on_error;
$end    
    done;
    raise;
end processing;

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
    commit;
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

procedure data2msg
( p_data_clob in clob
, p_msg_vc out nocopy varchar2
, p_msg_clob out nocopy clob
)
is
begin
  if p_data_clob is not null and
     ( dbms_lob.getlength(lob_loc => p_data_clob) > c_max_size_vc or
       lengthb(dbms_lob.substr(lob_loc => p_data_clob, amount => c_max_size_vc)) > c_max_size_vc )
  then
    p_msg_vc := null;
    p_msg_clob := p_data_clob;
  else
    p_msg_vc := dbms_lob.substr(lob_loc => p_data_clob, amount => c_max_size_vc);
    p_msg_clob := null;
  end if;
end data2msg;

procedure msg2data
( p_msg_vc in varchar2
, p_msg_clob in clob
, p_data_json out nocopy json_element_t
)
is
begin
  p_data_json :=
    case
      when p_msg_vc is not null
      then json_element_t.parse(p_msg_vc)
      when p_msg_clob is not null
      then json_element_t.parse(p_msg_clob)
    end;
end msg2data;

procedure data2msg
( p_data_blob in blob
, p_msg_raw out nocopy raw
, p_msg_blob out nocopy blob
)
is
begin
  if p_data_blob is not null and
     ( dbms_lob.getlength(lob_loc => p_data_blob) > c_max_size_raw or
       utl_raw.length(dbms_lob.substr(lob_loc => p_data_blob, amount => c_max_size_raw)) > c_max_size_raw )
  then
    p_msg_raw := null;
    p_msg_blob := p_data_blob;
  else
    p_msg_raw := dbms_lob.substr(lob_loc => p_data_blob, amount => c_max_size_raw);
    p_msg_blob := null;
  end if;
end data2msg;

procedure msg2data
( p_msg_raw in raw
, p_msg_blob in blob
, p_data_json out nocopy json_element_t
)
is
begin
  p_data_json :=
    case
      when p_msg_raw is not null
      then json_element_t.parse(to_blob(p_msg_raw))
      when p_msg_blob is not null
      then json_element_t.parse(p_msg_blob)
    end;
end msg2data;

function elapsed_time
( p_start in number
, p_end in number
)
return number -- in seconds with fractions (not hundredths!)
is
  l_min constant number := -2147483648;
  l_max constant number :=  2147483647;
/**
Determines the elapsed time in fractional seconds (not hundredths!) between two measure points taken by dbms_utility.get_time, the start (earlier) and the end (later).

The function dbms_utility.get_time returns the number of hundredths of a second from the point in time at which the subprogram is invoked.

Numbers are returned in the range -2147483648 to 2147483647 depending on
platform and machine, and your application must take the sign of the number
into account in determining the interval. For instance, in the case of two
negative numbers, application logic must allow that the first (earlier) number
will be larger than the second (later) number which is closer to zero. By the
same token, your application should also allow that the first (earlier) number
be negative and the second (later) number be positive.
**/
begin
  -- EXAMPLES
  --
  --    p_start |       p_end | result
  --    ======= |       ===== | ======
  --          1 |           2 |  1/100
  --         -3 |          -1 |  1/100
  -- 2147483646 | -2147483647 |  3/100
  --         -1 |           3 |  4/100
  return case
           when p_start >= 0 and p_end >= 0 then (p_end - p_start)
           -- both p_start and p_end went thru l_max
           when p_start <  0 and p_end <  0 then (p_end - p_start)
           -- p_end went thru l_max
           when p_start >= 0 and p_end <  0 then (l_max - p_start) + (p_end - l_min) + 1
           -- count p_start till 0 and 0 till p_end
           when p_start <  0 and p_end >= 0 then (p_end + -1 * p_start)
         end / 100;
end elapsed_time;

function does_job_supervisor_exist
( p_processing_package in varchar2 default null
)
return boolean
is
  l_processing_package constant all_objects.object_name%type :=
    trim('"' from dbms_assert.enquote_name(nvl(p_processing_package, utl_call_stack.subprogram(2)(1)))); -- 2 is the index of the calling unit, 1 is the name of the unit
begin
  return does_job_exist
         ( job_name
           ( p_processing_package => p_processing_package
           , p_program_name => c_program_supervisor
           , p_job_name_suffix => null
           , p_worker_nr => null
           )
         );
end does_job_supervisor_exist;

procedure send_worker_status
( p_job_name_supervisor in varchar2
, p_worker_nr in integer
, p_sqlcode in integer
, p_sqlerrm in varchar2
, p_timeout in integer
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

end msg_pkg;
/

