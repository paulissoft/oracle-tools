CREATE OR REPLACE PACKAGE BODY "MSG_PKG" AS

c_max_size_vc constant simple_integer := 4000;
c_max_size_raw constant simple_integer := 2000;

c_session_id constant user_scheduler_running_jobs.session_id%type := to_number(sys_context('USERENV', 'SID'));

g_longops_rec oracle_tools.api_longops_pkg.t_longops_rec :=
  oracle_tools.api_longops_pkg.longops_init
  ( p_target_desc => $$PLSQL_UNIT
  , p_totalwork => 0
  , p_op_name => 'process'
  , p_units => 'messages'
  );

-- PUBLIC

procedure init
is
begin
  null;
end init;

procedure done
is
begin
  oracle_tools.api_longops_pkg.longops_done(g_longops_rec);
end done;  
  
function get_object_name
( p_object_name in varchar2
, p_what in varchar2
, p_schema_name in varchar2
, p_fq in integer
, p_qq in integer
, p_uc in integer
)
return varchar2
is
begin
  return oracle_tools.data_api_pkg.get_object_name
         ( p_object_name => p_object_name
         , p_what => p_what
         , p_schema_name => p_schema_name
         , p_fq => p_fq
         , p_qq => p_qq
         , p_uc => p_uc
         );
end get_object_name;

function get_msg_tab
return msg_tab_t
is
  l_msg_tab msg_tab_t := msg_tab_t();
  l_statement varchar2(32767 byte);
begin
  for r in
  ( select  ut.type_name
    ,       ut.supertype_name
    from    user_types ut
    connect by prior
            ut.type_name = ut.supertype_name and ut.supertype_owner = user
    start with
            ut.type_name = 'MSG_TYP'
  )
  loop
    if r.supertype_name is not null
    then
      l_msg_tab.extend(1);

      l_statement := utl_lms.format_message('begin :1 := new %s(); end;', r.type_name);

      begin
        execute immediate l_statement using out l_msg_tab(l_msg_tab.last);
$if oracle_tools.cfg_pkg.c_debugging $then
      exception
        when others
        then
          dbug.print(dbug."error", 'statement: %s', l_statement);
          dbug.on_error;
          raise;
$end
      end;
    end if;
  end loop;
  
  return l_msg_tab;
end get_msg_tab;

procedure process_msg
( p_msg in msg_typ
, p_commit in boolean
)
is
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT || '.PROCESS_MSG for group ' || p_msg.group$);
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

function timestamp_tz2timestamp_tz_str
( p_val in timestamp_tz_t
)
return timestamp_tz_str_t
is
begin
  return to_char(p_val, c_timestamp_tz_format);
end timestamp_tz2timestamp_tz_str;

function timestamp_tz_str2timestamp_tz
( p_val in timestamp_tz_str_t
)
return timestamp_tz_t
is
begin
  return to_timestamp_tz(p_val, c_timestamp_tz_format);
end timestamp_tz_str2timestamp_tz;

procedure send_heartbeat
( p_controlling_package in varchar2
, p_recv_timeout in naturaln -- receive timeout in seconds
, p_worker_nr in positiven -- the worker number
, p_recv_timestamp out nocopy timestamp_tz_t
)
is
  l_result pls_integer;
  l_timestamp_tz_str timestamp_tz_str_t := timestamp_tz2timestamp_tz_str(current_timestamp);
  l_send_pipe constant varchar2(128 char) := p_controlling_package;
  l_send_timeout constant naturaln := 0;
  l_recv_pipe constant varchar2(128 char) := p_controlling_package || '#' || p_worker_nr;
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT || '.SEND_HEARTBEAT');
  dbug.print
  ( dbug."input"
  , 'p_controlling_package: %s; p_recv_timeout: %s; p_worker_nr: %s'
  , p_controlling_package
  , p_recv_timeout
  , p_worker_nr
  );
$end

  p_recv_timestamp := null;

  dbms_pipe.reset_buffer;
  dbms_pipe.pack_message(p_worker_nr);
  dbms_pipe.pack_message(l_timestamp_tz_str);
  l_result := dbms_pipe.send_message(pipename => l_send_pipe, timeout => l_send_timeout);
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.print(dbug."info", 'timestamp sent to receiver: %s', l_timestamp_tz_str);
  dbug.print(dbug."info", 'dbms_pipe.send_message(pipename => %s, timeout => %s): %s', l_send_pipe, l_send_timeout, l_result);
$end
  if l_result = 0
  then
    dbms_pipe.reset_buffer;
    l_result := dbms_pipe.receive_message(pipename => l_recv_pipe, timeout => p_recv_timeout);
$if oracle_tools.cfg_pkg.c_debugging $then
    dbug.print(dbug."info", 'dbms_pipe.receive_message(pipename => %s, timeout => %s): %s', l_recv_pipe, p_recv_timeout, l_result);
$end
    if l_result = 0
    then
      dbms_pipe.unpack_message(l_timestamp_tz_str);
      p_recv_timestamp := timestamp_tz_str2timestamp_tz(l_timestamp_tz_str);
    else
      raise_application_error
      ( c_heartbeat_failure
      , utl_lms.format_message(q'[dbms_pipe.receive_message('%s', %d) returned %d]', l_recv_pipe, p_recv_timeout, l_result)
      );
    end if;
  else
    raise_application_error
    ( c_heartbeat_failure
    , utl_lms.format_message(q'[dbms_pipe.send_message('%s', %d) returned %d]', l_send_pipe, l_send_timeout, l_result)
    );
  end if;

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.print
  ( dbug."output"
  , 'timestamp received from receiver: %s'
  , l_timestamp_tz_str
  );
  dbug.leave;
$end
end send_heartbeat;    
  
procedure recv_heartbeat
( p_controlling_package in varchar2
, p_recv_timeout in naturaln -- receive timeout in seconds
, p_worker_nr out nocopy positive
, p_send_timestamp out nocopy timestamp_tz_t
)
is
  l_result pls_integer;
  l_timestamp_tz_str timestamp_tz_str_t := null;  
  l_send_pipe constant varchar2(128 char) := p_controlling_package || '#' || p_worker_nr;
  l_send_timeout constant naturaln := 0;
  l_recv_pipe constant varchar2(128 char) := p_controlling_package;
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT || '.RECV_HEARTBEAT');
  dbug.print
  ( dbug."input"
  , 'p_controlling_package: %s; p_recv_timeout: %s'
  , p_controlling_package
  , p_recv_timeout
  );
$end

  p_send_timestamp := null;
  
  dbms_pipe.reset_buffer;
  l_result := dbms_pipe.receive_message(pipename => l_recv_pipe, timeout => p_recv_timeout);
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.print(dbug."info", 'dbms_pipe.receive_message(pipename => %s, timeout => %s): %s', l_recv_pipe, p_recv_timeout, l_result);
$end
  if l_result = 0
  then
    dbms_pipe.unpack_message(p_worker_nr);
    dbms_pipe.unpack_message(l_timestamp_tz_str);
    
    dbms_pipe.reset_buffer;
    dbms_pipe.pack_message(timestamp_tz2timestamp_tz_str(current_timestamp));
    l_result := dbms_pipe.send_message(pipename => l_send_pipe, timeout => l_send_timeout);
$if oracle_tools.cfg_pkg.c_debugging $then
    dbug.print(dbug."info", 'timestamp received from sender: %s', l_timestamp_tz_str);
    dbug.print(dbug."info", 'dbms_pipe.send_message(pipename => %s, timeout => %s): %s', l_send_pipe, l_send_timeout, l_result);
$end
    if l_result = 0
    then
      p_send_timestamp := timestamp_tz_str2timestamp_tz(l_timestamp_tz_str);
    else
      raise_application_error
      ( c_heartbeat_failure
      , utl_lms.format_message(q'[dbms_pipe.send_message('%s', %d) returned %d]', l_send_pipe, l_send_timeout, l_result)
      );
    end if;
  else
    raise_application_error
    ( c_heartbeat_failure
    , utl_lms.format_message(q'[dbms_pipe.receive_message('%s', %d) returned %d]', l_recv_pipe, p_recv_timeout, l_result)
    );
  end if;

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.print
  ( dbug."output"
  , 'p_worker_nr: %s; timestamp sent to sender: %s'
  , p_worker_nr
  , l_timestamp_tz_str
  );
  dbug.leave;
$end
end recv_heartbeat;    

end msg_pkg;
/

