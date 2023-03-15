CREATE OR REPLACE PACKAGE BODY "API_HEARTBEAT_PKG" -- -*-coding: utf-8-*-
is

-- private
subtype pipename_t is supervisor_channel_t;
subtype timestamp_str_t is api_time_pkg.timestamp_str_t;

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
, p_timestamp_tab in out nocopy timestamp_tab_t
, p_silent_worker_tab out nocopy silent_worker_tab_t
)
is
  l_current_timestamp constant api_time_pkg.timestamp_t := api_time_pkg.get_timestamp;
  l_worker_nr natural; -- 0 (or null) is the supervisor
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT || '.DETERMINE_SILENT_WORKERS');
$end

  p_silent_worker_tab := sys.odcinumberlist();
  l_worker_nr := p_timestamp_tab.first;
  while l_worker_nr is not null
  loop
    if p_timestamp_tab(l_worker_nr) is null or
       api_time_pkg.delta(p_timestamp_tab(l_worker_nr), l_current_timestamp) > p_silence_threshold
    then
$if oracle_tools.cfg_pkg.c_debugging $then
      dbug.print
      ( dbug."info"
      , 'adding silent worker %s; last timestamp received: %s; current timestamp: %s'
      , l_worker_nr
      , api_time_pkg.timestamp2str(p_timestamp_tab(l_worker_nr))
      , api_time_pkg.timestamp2str(l_current_timestamp)
      );
$end      
      p_silent_worker_tab.extend(1);
      p_silent_worker_tab(p_silent_worker_tab.last) := case when l_worker_nr > 0 then l_worker_nr end;
    end if;
    
    l_worker_nr := p_timestamp_tab.next(l_worker_nr);
  end loop;

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end determine_silent_workers;

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
  l_send_pipe constant pipename_t := p_supervisor_channel;
  l_send_timeout constant naturaln := 0;
  l_recv_pipe constant pipename_t := get_pipename(p_supervisor_channel, p_worker_nr);
  l_recv_timeout naturaln := p_first_recv_timeout;
begin  
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT || '.SEND');
  dbug.print
  ( dbug."input"
  , 'p_supervisor_channel: %s; p_worker_nr: %s; p_silence_threshold: %s; p_first_recv_timeout: %s'
  , p_supervisor_channel
  , p_worker_nr
  , p_silence_threshold
  , p_first_recv_timeout
  );
$end

  -- step 1
  dbms_pipe.reset_buffer;
  dbms_pipe.pack_message(p_worker_nr);
  dbms_pipe.pack_message(l_send_timestamp_str);
  l_result := dbms_pipe.send_message(pipename => l_send_pipe, timeout => l_send_timeout);
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.print(dbug."info", 'timestamp sent to receiver: %s', l_send_timestamp_str);
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
      l_recv_timeout := 0;
      
$if oracle_tools.cfg_pkg.c_debugging $then
      dbug.print(dbug."info", 'dbms_pipe.receive_message(pipename => %s, timeout => %s): %s', l_recv_pipe, l_recv_timeout, l_result);
$end
      -- step 4
      exit when nvl(l_result, -1) <> 0;
      
      dbms_pipe.unpack_message(l_recv_timestamp_str);
$if oracle_tools.cfg_pkg.c_debugging $then
      dbug.print(dbug."info", 'timestamp received from receiver: %s', l_recv_timestamp_str);
$end
      -- step 5
      p_timestamp_tab(0) := api_time_pkg.str2timestamp(l_recv_timestamp_str);

      -- step 6
    end loop;
  end if;

  -- step 7
  determine_silent_workers(p_silence_threshold, p_timestamp_tab, p_silent_worker_tab);

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.print
  ( dbug."output"
  , 'p_timestamp_tab.count: %s; p_silent_worker_tab).count: %s'
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
, p_first_recv_timeout in naturaln default 0 -- first receive timeout in seconds
, p_timestamp_tab in out nocopy timestamp_tab_t
, p_silent_worker_tab out nocopy silent_worker_tab_t
)
is
  l_result pls_integer;
  l_current_timestamp api_time_pkg.timestamp_t := null;
  l_send_timestamp_str timestamp_str_t := null;
  l_recv_timestamp_str timestamp_str_t := null;
  l_send_pipe constant pipename_t := p_supervisor_channel;
  l_send_timeout constant naturaln := 0; -- step 3
  l_recv_pipe constant pipename_t := get_pipename(p_supervisor_channel, null);
  l_recv_timeout naturaln := p_first_recv_timeout;
  l_worker_nr positive;
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT || '.RECV');
  dbug.print
  ( dbug."input"
  , 'p_supervisor_channel: %s; p_silence_threshold: %s; p_first_recv_timeout: %s'
  , p_supervisor_channel
  , p_silence_threshold
  , p_first_recv_timeout
  );
$end

  loop
    -- step 1
    dbms_pipe.reset_buffer;
    l_result := dbms_pipe.receive_message(pipename => l_recv_pipe, timeout => l_recv_timeout);
$if oracle_tools.cfg_pkg.c_debugging $then
    dbug.print(dbug."info", 'dbms_pipe.receive_message(pipename => %s, timeout => %s): %s', l_recv_pipe, l_recv_timeout, l_result);
$end
    -- step 2
    exit when nvl(l_result, -1) <> 0;

    -- step 3
    l_recv_timeout := 0;

    dbms_pipe.unpack_message(l_worker_nr);
    dbms_pipe.unpack_message(l_recv_timestamp_str);

$if oracle_tools.cfg_pkg.c_debugging $then
    dbug.print(dbug."info", 'timestamp received from sender: %s', l_recv_timestamp_str);
$end

    -- step 4
    l_current_timestamp := api_time_pkg.get_timestamp;
    l_send_timestamp_str := api_time_pkg.timestamp2str(l_current_timestamp);

    dbms_pipe.reset_buffer;
    dbms_pipe.pack_message(l_send_timestamp_str);
    l_result := dbms_pipe.send_message(pipename => l_send_pipe, timeout => l_send_timeout);
$if oracle_tools.cfg_pkg.c_debugging $then
    dbug.print(dbug."info", 'dbms_pipe.send_message(pipename => %s, timeout => %s): %s', l_send_pipe, l_send_timeout, l_result);
$end

    -- step 5
    exit when nvl(l_result, -1) <> 0;

    -- step 6
    p_timestamp_tab(l_worker_nr) := api_time_pkg.str2timestamp(l_recv_timestamp_str);

    -- step 7
  end loop;

  -- step 8
  determine_silent_workers(p_silence_threshold, p_timestamp_tab, p_silent_worker_tab);

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.print
  ( dbug."output"
  , 'p_timestamp_tab.count: %s; p_silent_worker_tab).count: %s'
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

end API_HEARTBEAT_PKG;
/

