CREATE OR REPLACE PACKAGE BODY "API_HEARTBEAT_PKG" -- -*-coding: utf-8-*-
is

-- private
subtype pipename_t is supervisor_channel_t;
subtype timestamp_str_t is api_time_pkg.timestamp_str_t;

"yyyy-mm-dd hh24:mi:ss" constant varchar2(30) := 'yyyy-mm-dd hh24:mi:ss';

c_process_heartbeats_since constant api_time_pkg.timestamp_t := api_time_pkg.get_timestamp;
c_shutdown_msg_int constant integer := -1;

function get_pipename
( p_supervisor_channel in supervisor_channel_t
, p_worker_nr in positive
)
return pipename_t
is
begin
  return p_supervisor_channel || case when p_worker_nr is not null then '#' || to_char(p_worker_nr) end;
end get_pipename;

procedure determine_silent_workers
( p_silence_threshold in api_time_pkg.seconds_t -- the number of seconds the supervisor may be silent before being added to the silent workers
, p_timestamp_tab in timestamp_tab_t
, p_silent_worker_tab out nocopy silent_worker_tab_t
)
is
  l_current_timestamp constant api_time_pkg.timestamp_t := api_time_pkg.get_timestamp;
  l_worker_nr natural; -- 0 (or null) is the supervisor
  l_delta api_time_pkg.seconds_t;
  l_silent_worker boolean;
begin
$if oracle_tools.api_heartbeat_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT || '.DETERMINE_SILENT_WORKERS');
  dbug.print
  ( dbug."input"
  , 'p_silence_threshold: %s; p_timestamp_tab.count: %s; current timestamp: %s'
  , p_silence_threshold
  , p_timestamp_tab.count
  , api_time_pkg.timestamp2str(l_current_timestamp)
  );
$end

  p_silent_worker_tab := sys.odcinumberlist();
  l_worker_nr := p_timestamp_tab.first;
  while l_worker_nr is not null
  loop
    l_delta := api_time_pkg.delta(p_timestamp_tab(l_worker_nr), l_current_timestamp);
    l_silent_worker := ( p_timestamp_tab(l_worker_nr) is null or l_delta > p_silence_threshold );
        
$if oracle_tools.api_heartbeat_pkg.c_debugging $then
    dbug.print
    ( dbug."info"
    , 'silent worker %s; last timestamp received: %s; delta: %s; add silent worker: %s'
    , l_worker_nr
    , api_time_pkg.timestamp2str(p_timestamp_tab(l_worker_nr))
    , l_delta
    , dbug.cast_to_varchar2(l_silent_worker)
    );
$end

    if l_silent_worker
    then
      p_silent_worker_tab.extend(1);
      p_silent_worker_tab(p_silent_worker_tab.last) := case when l_worker_nr > 0 then l_worker_nr end;
    end if;
    
    l_worker_nr := p_timestamp_tab.next(l_worker_nr);
  end loop;

$if oracle_tools.api_heartbeat_pkg.c_debugging $then
  dbug.print(dbug."output", 'p_silent_worker_tab.count: %s', p_silent_worker_tab.count);
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end determine_silent_workers;

function ignore_message
( p_send_timestamp_str in timestamp_str_t
, p_origin in pls_integer
)
return boolean
is
begin
  return not(p_send_timestamp_str is not null and api_time_pkg.str2timestamp(p_send_timestamp_str) > c_process_heartbeats_since);
end ignore_message;

procedure pack_message
( p_send_timestamp_str in timestamp_str_t
, p_origin in pls_integer default 0 -- the supervisor
)
is
begin
  dbms_pipe.pack_message(p_send_timestamp_str);
  dbms_pipe.pack_message(p_origin);
end pack_message;

procedure unpack_message
( p_recv_timestamp_str out nocopy timestamp_str_t
, p_origin out nocopy pls_integer
)
is
begin
  dbms_pipe.unpack_message(p_recv_timestamp_str);
  dbms_pipe.unpack_message(p_origin);
end unpack_message;

function send_shutdown
( p_supervisor_channel in supervisor_channel_t
, p_worker_nr in positive
, p_empty_channel in boolean
)
return pls_integer
is
  l_result pls_integer;
  pragma inline (get_pipename, 'YES');
  l_send_pipe constant pipename_t := get_pipename(p_supervisor_channel, p_worker_nr);
  l_send_timeout constant naturaln := 0;
  l_current_timestamp constant api_time_pkg.timestamp_t := api_time_pkg.get_timestamp;
  l_send_timestamp_str constant timestamp_str_t := api_time_pkg.timestamp2str(l_current_timestamp);
begin
$if oracle_tools.api_heartbeat_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT || '.SEND_SHUTDOWN');
  dbug.print
  ( dbug."input"
  , 'p_supervisor_channel: %s; p_worker_nr: %s; p_empty_channel: %s'
  , p_supervisor_channel
  , p_worker_nr
  , dbug.cast_to_varchar2(p_empty_channel)
  );
$end

  dbms_pipe.reset_buffer;
  pack_message(l_send_timestamp_str, c_shutdown_msg_int);
  if p_empty_channel
  then
    dbms_pipe.purge(pipename => l_send_pipe);
  end if;
  l_result := dbms_pipe.send_message(pipename => l_send_pipe, timeout => l_send_timeout);

$if oracle_tools.api_heartbeat_pkg.c_debugging $then
  dbug.print(dbug."info", 'current timestamp to send: %s', l_send_timestamp_str);
  dbug.print(dbug."info", 'dbms_pipe.send_message(pipename => %s, timeout => %s): %s', l_send_pipe, l_send_timeout, l_result);
  dbug.leave;
$end

  return l_result;
end send_shutdown;

procedure shutdown
( p_supervisor_channel in supervisor_channel_t
, p_nr_workers in positive
, p_empty_channel in boolean
)
is
  l_result pls_integer;
begin
$if oracle_tools.api_heartbeat_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT || '.SHUTDOWN');
  dbug.print
  ( dbug."input"
  , 'p_supervisor_channel: %s; p_empty_channel'
  , p_supervisor_channel
  , dbug.cast_to_varchar2(p_empty_channel)
  );
$end

  for i_worker_nr in 0 .. nvl(p_nr_workers, 0)
  loop
    l_result := send_shutdown(p_supervisor_channel, case when i_worker_nr > 0 then i_worker_nr end, p_empty_channel);
    if l_result = 0
    then
      null; -- OK
    else
      raise_application_error
      ( c_shutdown_request_failed
      , utl_lms.format_message
        ( q'[Failed to send shutdown request for %s. DBMS_PIPE.SEND_MESSAGE returned status %d.]'
        , case when i_worker_nr > 0 then 'worker #' || i_worker_nr else 'supervisor' end
        , l_result -- %d should work for pls_integer
        )
      );
    end if;
  end loop;

$if oracle_tools.api_heartbeat_pkg.c_debugging $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end shutdown;

-- public

procedure init
( p_supervisor_channel in supervisor_channel_t
, p_worker_nr in positive
, p_max_worker_nr in naturaln
, p_timestamp_tab out nocopy timestamp_tab_t
)
is
  pragma inline (get_pipename, 'YES');
  l_pipename constant pipename_t := get_pipename(p_supervisor_channel, p_worker_nr);
  l_current_timestamp constant api_time_pkg.timestamp_t := api_time_pkg.get_timestamp;
begin
$if oracle_tools.api_heartbeat_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT || '.INIT');
  dbug.print
  ( dbug."input"
  , 'p_supervisor_channel: %s; p_worker_nr: %s; p_max_worker_nr: %s; current timestamp: %s'
  , p_supervisor_channel
  , p_worker_nr
  , p_max_worker_nr
  , api_time_pkg.timestamp2str(l_current_timestamp)
  );
$end

  -- try to create a private pipe and if that fails purge it
  begin
    if dbms_pipe.remove_pipe(l_pipename) = 0 and
       dbms_pipe.create_pipe(pipename => l_pipename, private => true) = 0
    then
      null;
    else
      raise program_error; -- should not happen
    end if;
  exception
    when others
    then dbms_pipe.purge(l_pipename);
  end;

  p_timestamp_tab(p_max_worker_nr) := l_current_timestamp;
  for i_idx in 1 .. p_max_worker_nr
  loop
    p_timestamp_tab(i_idx) := l_current_timestamp;
  end loop;

$if oracle_tools.api_heartbeat_pkg.c_debugging $then
  dbug.print(dbug."output", 'p_timestamp_tab.count: %s', p_timestamp_tab.count);
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end init;
 
procedure done
( p_supervisor_channel in supervisor_channel_t
, p_worker_nr in positive
)
is
begin
  pragma inline (get_pipename, 'YES');
  if dbms_pipe.remove_pipe(get_pipename(p_supervisor_channel, p_worker_nr)) = 0
  then
    null;
  end if;
end done;
 
procedure shutdown
( p_supervisor_channel in supervisor_channel_t
, p_nr_workers in positive
)
is
begin
  shutdown(p_supervisor_channel => p_supervisor_channel, p_nr_workers => p_nr_workers, p_empty_channel => true);
end shutdown;

procedure send
( p_supervisor_channel in supervisor_channel_t
, p_worker_nr in positiven
, p_silence_threshold in api_time_pkg.seconds_t
, p_first_recv_timeout in naturaln
, p_timestamp_tab in out nocopy timestamp_tab_t
, p_silent_worker_tab out nocopy silent_worker_tab_t
)
is
  l_result pls_integer;
  l_current_timestamp constant api_time_pkg.timestamp_t := api_time_pkg.get_timestamp;
  l_send_timestamp_str constant timestamp_str_t := api_time_pkg.timestamp2str(l_current_timestamp);
  l_recv_timestamp_str timestamp_str_t := null;
  pragma inline (get_pipename, 'YES');
  l_send_pipe constant pipename_t := get_pipename(p_supervisor_channel, null);
  l_send_timeout constant naturaln := 0;
  pragma inline (get_pipename, 'YES');
  l_recv_pipe constant pipename_t := get_pipename(p_supervisor_channel, p_worker_nr);
  l_recv_timeout naturaln := p_first_recv_timeout;
  l_origin pls_integer;
begin  
$if oracle_tools.api_heartbeat_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT || '.SEND');
  dbug.print
  ( dbug."input"
  , 'p_supervisor_channel: %s; p_worker_nr: %s; p_silence_threshold: %s; p_first_recv_timeout: %s; current timestamp: %s'
  , p_supervisor_channel
  , p_worker_nr
  , p_silence_threshold
  , p_first_recv_timeout
  , api_time_pkg.timestamp2str(l_current_timestamp)  
  );
$end

  -- step 1 (see the package specification for the step description)
  dbms_pipe.reset_buffer;
  pack_message(l_send_timestamp_str, p_worker_nr);
  l_result := dbms_pipe.send_message(pipename => l_send_pipe, timeout => l_send_timeout);
$if oracle_tools.api_heartbeat_pkg.c_debugging $then
  dbug.print(dbug."info", 'current timestamp to send to supervisor: %s', l_send_timestamp_str);
  dbug.print(dbug."info", 'dbms_pipe.send_message(pipename => %s, timeout => %s): %s', l_send_pipe, l_send_timeout, l_result);
$end

  -- step 2
  if l_result = 0
  then
    -- step 3
    <<recv_loop>>
    loop
      dbms_pipe.reset_buffer;
      l_result := dbms_pipe.receive_message(pipename => l_recv_pipe, timeout => l_recv_timeout);
      
$if oracle_tools.api_heartbeat_pkg.c_debugging $then
      dbug.print(dbug."info", 'dbms_pipe.receive_message(pipename => %s, timeout => %s): %s', l_recv_pipe, l_recv_timeout, l_result);
$end
      -- step 4
      exit when nvl(l_result, -1) <> 0;

      -- step 5
      l_recv_timeout := 0;

      -- step 6
      unpack_message(l_recv_timestamp_str, l_origin);

      continue recv_loop when ignore_message(l_recv_timestamp_str, l_origin);

      -- step 7
      if l_origin = c_shutdown_msg_int
      then
        raise_application_error
        ( c_shutdown_request_received
        , utl_lms.format_message
          ( 'Shutdown request (dating from "%s") received at "%s".'
          , l_recv_timestamp_str
          , l_send_timestamp_str
          )
        );
      end if;
      
      -- step 8
$if oracle_tools.api_heartbeat_pkg.c_debugging $then
      dbug.print(dbug."info", 'timestamp received from supervisor: %s', l_recv_timestamp_str);
$end
      p_timestamp_tab(0) := api_time_pkg.str2timestamp(l_recv_timestamp_str);
$if oracle_tools.api_heartbeat_pkg.c_debugging $then
      dbug.print(dbug."info", 'p_timestamp_tab(0): %s', l_recv_timestamp_str);
$end

      -- step 9
    end loop recv_loop;
  end if;

  -- step 10
  determine_silent_workers(p_silence_threshold, p_timestamp_tab, p_silent_worker_tab);

$if oracle_tools.api_heartbeat_pkg.c_debugging $then
  dbug.print
  ( dbug."output"
  , 'p_timestamp_tab.count: %s; p_silent_worker_tab.count: %s'
  , p_timestamp_tab.count
  , p_silent_worker_tab.count
  );
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end send;    
  
procedure recv
( p_supervisor_channel in supervisor_channel_t
, p_silence_threshold in api_time_pkg.seconds_t -- the number of seconds the supervisor may be silent before being added to the silent workers
, p_first_recv_timeout in naturaln -- first receive timeout in seconds
, p_timestamp_tab in out nocopy timestamp_tab_t
, p_silent_worker_tab out nocopy silent_worker_tab_t
)
is
  l_result pls_integer;
  l_current_timestamp api_time_pkg.timestamp_t := null;
  l_send_timestamp_str timestamp_str_t := null;
  l_recv_timestamp_str timestamp_str_t := null;
  l_send_pipe pipename_t := null;
  l_send_timeout constant naturaln := 0; -- step 3
  pragma inline (get_pipename, 'YES');
  l_recv_pipe constant pipename_t := get_pipename(p_supervisor_channel, null);
  l_recv_timeout naturaln := p_first_recv_timeout;
  l_worker_nr positive;
  l_origin pls_integer;
  l_result_dummy pls_integer;
begin
$if oracle_tools.api_heartbeat_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT || '.RECV');
  dbug.print
  ( dbug."input"
  , 'p_supervisor_channel: %s; p_silence_threshold: %s; p_first_recv_timeout: %s'
  , p_supervisor_channel
  , p_silence_threshold
  , p_first_recv_timeout
  );
$end

  <<recv_loop>>
  loop
    -- step 1 (see the package specification for the step description)
    dbms_pipe.reset_buffer;
    l_result := dbms_pipe.receive_message(pipename => l_recv_pipe, timeout => l_recv_timeout);
$if oracle_tools.api_heartbeat_pkg.c_debugging $then
    dbug.print(dbug."info", 'dbms_pipe.receive_message(pipename => %s, timeout => %s): %s', l_recv_pipe, l_recv_timeout, l_result);
$end

    -- step 2
    exit recv_loop when nvl(l_result, -1) <> 0;

    -- step 3
    l_recv_timeout := 0;

    -- step 4
    unpack_message(l_recv_timestamp_str, l_origin);

    continue recv_loop when ignore_message(l_recv_timestamp_str, l_origin);

    -- step 5
    if l_origin = c_shutdown_msg_int
    then
      -- step 5a
      -- We have to send a shutdown request to all the workers, i.e. all the entries in p_timestamp_tab.
      -- Maybe some new workers have arrived after the init() leaving holes, so check all the indexes.
      l_worker_nr := p_timestamp_tab.first;
      while l_worker_nr is not null
      loop
        l_result_dummy := send_shutdown(p_supervisor_channel => p_supervisor_channel, p_worker_nr => l_worker_nr, p_empty_channel => true);
        l_worker_nr := p_timestamp_tab.next(l_worker_nr);
      end loop;
      raise_application_error
      ( c_shutdown_request_forwarded
      , utl_lms.format_message
        ( 'Shutdown request (dating from "%s") forwarded at "%s".'
        , l_recv_timestamp_str
        , api_time_pkg.timestamp2str(api_time_pkg.get_timestamp)
        )
      );
    else
      -- step 5b
      l_worker_nr := l_origin;

$if oracle_tools.api_heartbeat_pkg.c_debugging $then
      dbug.print(dbug."info", 'timestamp received from worker: %s', l_recv_timestamp_str);
$end
    end if;

    if l_worker_nr is null
    then
      raise program_error;
    end if;

    -- step 6
    dbms_pipe.reset_buffer;
    l_current_timestamp := api_time_pkg.get_timestamp;
    l_send_timestamp_str := api_time_pkg.timestamp2str(l_current_timestamp);

$if oracle_tools.api_heartbeat_pkg.c_debugging $then
    dbug.print(dbug."info", 'current timestamp to send to worker: %s', l_send_timestamp_str);
$end
    pack_message(l_send_timestamp_str);
    pragma inline (get_pipename, 'YES');
    l_send_pipe := get_pipename(p_supervisor_channel, l_worker_nr);
    l_result := dbms_pipe.send_message(pipename => l_send_pipe, timeout => l_send_timeout);
$if oracle_tools.api_heartbeat_pkg.c_debugging $then
    dbug.print(dbug."info", 'dbms_pipe.send_message(pipename => %s, timeout => %s): %s', l_send_pipe, l_send_timeout, l_result);
$end

    -- step 7
    exit recv_loop when nvl(l_result, -1) <> 0;

    -- step 8
    p_timestamp_tab(l_worker_nr) := api_time_pkg.str2timestamp(l_recv_timestamp_str);
$if oracle_tools.api_heartbeat_pkg.c_debugging $then
    dbug.print(dbug."info", 'p_timestamp_tab(%s): %s', l_worker_nr, l_recv_timestamp_str);
$end

    -- step 9
  end loop recv_loop;

  -- step 10
  determine_silent_workers(p_silence_threshold, p_timestamp_tab, p_silent_worker_tab);

$if oracle_tools.api_heartbeat_pkg.c_debugging $then
  dbug.print
  ( dbug."output"
  , 'p_timestamp_tab.count: %s; p_silent_worker_tab.count: %s'
  , p_timestamp_tab.count
  , p_silent_worker_tab.count
  );
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end recv;    

$if oracle_tools.cfg_pkg.c_testing $then

procedure ut_ping_pong
is
  l_supervisor_channel constant supervisor_channel_t := $$PLSQL_UNIT;
  l_timestamp_tab timestamp_tab_t;
  l_first_timestamp_tab timestamp_tab_t;
  l_silent_worker_tab silent_worker_tab_t;
  l_timeout constant integer := 5;
begin
$if oracle_tools.api_heartbeat_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT || '.UT_PING_PONG');
$end

  -- supervisor
  init
  ( p_supervisor_channel => l_supervisor_channel
  , p_worker_nr => null
  , p_max_worker_nr => 1
  , p_timestamp_tab => l_timestamp_tab
  );
  l_first_timestamp_tab(1) := l_timestamp_tab(1);
  -- worker
  init
  ( p_supervisor_channel => l_supervisor_channel
  , p_worker_nr => 1
  , p_max_worker_nr => 0
  , p_timestamp_tab => l_timestamp_tab
  );
  l_first_timestamp_tab(0) := l_timestamp_tab(0);
  
  l_timestamp_tab := l_first_timestamp_tab;

  -- send twice a heartbeat without a supervisor receiving it
  for i_case in 1..4
  loop
$if oracle_tools.api_heartbeat_pkg.c_debugging $then
    dbug.print(dbug."info", 'i_case: %s', i_case);
$end
    case
      when i_case in (1, 2)
      then
        send
        ( p_supervisor_channel => l_supervisor_channel
        , p_worker_nr => 1
        , p_silence_threshold => l_timeout
        , p_first_recv_timeout => case i_case when 1 then 0 else l_timeout end
        , p_timestamp_tab => l_timestamp_tab
        , p_silent_worker_tab => l_silent_worker_tab
        );
        ut.expect(l_timestamp_tab(0), 'last supervisor timestamp #' || i_case).to_equal(l_first_timestamp_tab(0));    
        ut.expect(l_timestamp_tab(1), 'last worker timestamp #' || i_case).to_equal(l_first_timestamp_tab(1));
        -- both the supervisor and worker are silent the second case
        ut.expect(l_silent_worker_tab.count, 'silent worker count #' || i_case).to_equal(case i_case when 1 then 0 else 2 end);
        
      when i_case = 3
      then
        recv
        ( p_supervisor_channel => l_supervisor_channel
        , p_silence_threshold => l_timeout
        , p_first_recv_timeout => l_timeout
        , p_timestamp_tab => l_timestamp_tab
        , p_silent_worker_tab => l_silent_worker_tab
        );
        ut.expect(l_timestamp_tab(0), 'last supervisor timestamp #' || i_case).to_equal(l_first_timestamp_tab(0));    
        ut.expect(l_timestamp_tab(1), 'last worker timestamp #' || i_case).to_be_greater_than(l_first_timestamp_tab(1));    
        ut.expect(l_silent_worker_tab.count, 'silent worker count #' || i_case).to_equal(2);
        
      when i_case = 4
      then
        send
        ( p_supervisor_channel => l_supervisor_channel
        , p_worker_nr => 1
        , p_silence_threshold => l_timeout
        , p_first_recv_timeout => 0
        , p_timestamp_tab => l_timestamp_tab
        , p_silent_worker_tab => l_silent_worker_tab
        );
        ut.expect(l_timestamp_tab(0), 'last supervisor timestamp #' || i_case).to_be_greater_than(l_first_timestamp_tab(0));    
        ut.expect(l_timestamp_tab(1), 'last worker timestamp #' || i_case).to_be_greater_than(l_first_timestamp_tab(1));    
        ut.expect(l_silent_worker_tab.count, 'silent worker count #' || i_case).to_equal(1); -- worker is too late
    end case;

    -- common checks
    ut.expect(l_timestamp_tab.count, 'timestamp count #' || i_case).to_equal(2);
    if l_silent_worker_tab.count = 2
    then
      ut.expect(l_silent_worker_tab(1), 'silent worker 1 #' || i_case).to_be_null;
      ut.expect(l_silent_worker_tab(2), 'silent worker 2 #' || i_case).to_equal(1);
    end if;
  end loop;

$if oracle_tools.api_heartbeat_pkg.c_debugging $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end ut_ping_pong;

procedure ut_shutdown_worker
is
  l_supervisor_channel constant supervisor_channel_t := $$PLSQL_UNIT;
  l_supervisor_timestamp_tab timestamp_tab_t;
  l_worker1_timestamp_tab timestamp_tab_t;
  l_worker2_timestamp_tab timestamp_tab_t;
  l_silent_worker_tab silent_worker_tab_t;
begin
$if oracle_tools.api_heartbeat_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT || '.UT_SHUTDOWN_WORKER');
$end

$if oracle_tools.api_heartbeat_pkg.c_debugging $then
  dbug.print(dbug."info", 'part 0');
$end

  -- supervisor
  init
  ( p_supervisor_channel => l_supervisor_channel
  , p_worker_nr => null
  , p_max_worker_nr => 2
  , p_timestamp_tab => l_supervisor_timestamp_tab
  );
  -- worker 1
  init
  ( p_supervisor_channel => l_supervisor_channel
  , p_worker_nr => 1
  , p_max_worker_nr => 0
  , p_timestamp_tab => l_worker1_timestamp_tab
  );
  -- worker 2
  init
  ( p_supervisor_channel => l_supervisor_channel
  , p_worker_nr => 2
  , p_max_worker_nr => 0
  , p_timestamp_tab => l_worker2_timestamp_tab
  );

$if oracle_tools.api_heartbeat_pkg.c_debugging $then
  dbug.print(dbug."info", 'part 1');
$end

  -- send two messages without any consequences
  send
  ( p_supervisor_channel => l_supervisor_channel
  , p_worker_nr => 1
  , p_silence_threshold => 10 -- a lot higher than the timeout
  , p_first_recv_timeout => 0
  , p_timestamp_tab => l_worker1_timestamp_tab
  , p_silent_worker_tab => l_silent_worker_tab
  );
  ut.expect(l_silent_worker_tab.count, 'supervisor not silent for worker 1').to_equal(0);
  
  send
  ( p_supervisor_channel => l_supervisor_channel
  , p_worker_nr => 2
  , p_silence_threshold => 10
  , p_first_recv_timeout => 0
  , p_timestamp_tab => l_worker2_timestamp_tab
  , p_silent_worker_tab => l_silent_worker_tab
  );
  ut.expect(l_silent_worker_tab.count, 'supervisor not silent for worker 2').to_equal(0);

  -- let the supervisor send shutdown messages
  shutdown(p_supervisor_channel => l_supervisor_channel);

  -- 1. the supervisor will receive first the two heartbeats
  -- 2. it will respond to them normally
  -- 3. next it will receive the shutdown request and forward it
  begin
    recv
    ( p_supervisor_channel => l_supervisor_channel
    , p_silence_threshold => 10
    , p_first_recv_timeout => 0
    , p_timestamp_tab => l_supervisor_timestamp_tab
    , p_silent_worker_tab => l_silent_worker_tab
    );
    -- should not come here
    raise program_error;
  exception
    when e_shutdown_request_forwarded
    then null;
  end;

  -- send again two messages: should fail with shutdown received
  begin
    send
    ( p_supervisor_channel => l_supervisor_channel
    , p_worker_nr => 1
    , p_silence_threshold => 10
    , p_first_recv_timeout => 0
    , p_timestamp_tab => l_worker1_timestamp_tab
    , p_silent_worker_tab => l_silent_worker_tab
    );
    -- should not come here
    raise program_error;
  exception
    when e_shutdown_request_received
    then null;
  end;
  
  begin
    send
    ( p_supervisor_channel => l_supervisor_channel
    , p_worker_nr => 2
    , p_silence_threshold => 1
    , p_first_recv_timeout => 0
    , p_timestamp_tab => l_worker2_timestamp_tab
    , p_silent_worker_tab => l_silent_worker_tab
    );
    -- should not come here
    raise program_error;
  exception
    when e_shutdown_request_received
    then null;
  end;

  -- shutdown message is gone
  recv
  ( p_supervisor_channel => l_supervisor_channel
  , p_silence_threshold => 10
  , p_first_recv_timeout => 0
  , p_timestamp_tab => l_supervisor_timestamp_tab
  , p_silent_worker_tab => l_silent_worker_tab
  );

$if oracle_tools.api_heartbeat_pkg.c_debugging $then
  dbug.print(dbug."info", 'part 2');
$end

  -- send shutdown messages to all
  shutdown(p_supervisor_channel => l_supervisor_channel, p_nr_workers => 2);

  -- send again two messages but receive in between: should fail with shutdown
  begin
    send
    ( p_supervisor_channel => l_supervisor_channel
    , p_worker_nr => 1
    , p_silence_threshold => 10
    , p_first_recv_timeout => 0
    , p_timestamp_tab => l_worker1_timestamp_tab
    , p_silent_worker_tab => l_silent_worker_tab
    );
    -- should not come here
    raise program_error;
  exception
    when e_shutdown_request_received
    then null;
  end;

  begin
    recv
    ( p_supervisor_channel => l_supervisor_channel
    , p_silence_threshold => 10
    , p_first_recv_timeout => 0
    , p_timestamp_tab => l_supervisor_timestamp_tab
    , p_silent_worker_tab => l_silent_worker_tab
    );
    -- should not come here
    raise program_error;
  exception
    when e_shutdown_request_forwarded
    then null;
  end;

  -- this one should also fail with e_shutdown_request_received and that is the outcome of the test
  send
  ( p_supervisor_channel => l_supervisor_channel
  , p_worker_nr => 2
  , p_silence_threshold => 1
  , p_first_recv_timeout => 0
  , p_timestamp_tab => l_worker2_timestamp_tab
  , p_silent_worker_tab => l_silent_worker_tab
  );

$if oracle_tools.api_heartbeat_pkg.c_debugging $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end ut_shutdown_worker;

procedure ut_shutdown_supervisor
is
  l_supervisor_channel constant supervisor_channel_t := $$PLSQL_UNIT;
  l_supervisor_timestamp_tab timestamp_tab_t;
  l_silent_worker_tab silent_worker_tab_t;
begin
$if oracle_tools.api_heartbeat_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT || '.UT_SHUTDOWN_SUPERVISOR');
$end

  -- supervisor
  init
  ( p_supervisor_channel => l_supervisor_channel
  , p_worker_nr => null
  , p_max_worker_nr => 2
  , p_timestamp_tab => l_supervisor_timestamp_tab
  );

  shutdown(p_supervisor_channel => l_supervisor_channel);

  recv
  ( p_supervisor_channel => l_supervisor_channel
  , p_silence_threshold => 10
  , p_first_recv_timeout => 0
  , p_timestamp_tab => l_supervisor_timestamp_tab
  , p_silent_worker_tab => l_silent_worker_tab
  );

$if oracle_tools.api_heartbeat_pkg.c_debugging $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end ut_shutdown_supervisor;

procedure ut_shutdown_multiple_times
is
  l_supervisor_channel constant supervisor_channel_t := $$PLSQL_UNIT;
  l_supervisor_timestamp_tab timestamp_tab_t;
  l_silent_worker_tab silent_worker_tab_t;
begin
$if oracle_tools.api_heartbeat_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT || '.UT_SHUTDOWN_MULTIPLE_TIMES');
$end

  -- supervisor
  init
  ( p_supervisor_channel => l_supervisor_channel
  , p_worker_nr => null
  , p_max_worker_nr => 2
  , p_timestamp_tab => l_supervisor_timestamp_tab
  );

  <<case_loop>>
  for i_case in 0..1 -- 0: do not empty; 1: do empty
  loop
    <<shutdown_loop>>
    for i_idx in 1..200 -- should stop after 179 times when i_case = 0
    loop
      begin
        shutdown(p_supervisor_channel => l_supervisor_channel, p_nr_workers => null, p_empty_channel => i_case = 1);
      exception
        when e_shutdown_request_failed
        then
          -- shutdown fails after 179 times when the channel is not emptied
          if i_idx = 179 and i_case = 0
          then
            continue case_loop; -- next case
          else
            raise;
          end if;
      end;
    end loop shutdown_loop;
    -- should not come here for case 0
    if i_case = 0
    then
      raise program_error;
    end if;
  end loop case_loop;

  raise no_data_found; -- utPLSQL must check this

$if oracle_tools.api_heartbeat_pkg.c_debugging $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end ut_shutdown_multiple_times;

$end

end API_HEARTBEAT_PKG;
/

