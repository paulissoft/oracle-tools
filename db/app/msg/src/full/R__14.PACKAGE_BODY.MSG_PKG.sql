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
, p_schema_name in varchar2
, p_fq in integer
, p_qq in integer
, p_uc in integer
)
return varchar2
is
begin
  return
    case p_fq
      when 1 -- schema.object
      then
        case p_qq
          when 1
          then dbms_assert.enquote_name(str => p_schema_name, capitalize => (p_uc = 1)) ||
               '.' ||
               dbms_assert.enquote_name(str => p_object_name, capitalize => (p_uc = 1))
          else case p_uc
                 when 1
                 then upper(p_schema_name || '.' || p_object_name)
                 else p_schema_name || '.' || p_object_name
               end
        end
        
      else -- just object
        case p_qq
          when 1
          then dbms_assert.enquote_name(str => p_object_name, capitalize => (p_uc = 1))
          else case p_uc
                 when 1
                 then upper(p_object_name)
                 else p_object_name
               end
        end
    end;
end get_object_name;

function get_msg_tab
return msg_tab_t
is
  l_msg_tab msg_tab_t := msg_tab_t();
begin
  for r in
  ( select ut.type_name, ut.supertype_name
    from   user_types ut
    connect by prior
           ut.type_name = ut.supertype_name and ut.supertype_owner = user
    start with
           ut.type_name = 'MSG_TYP'
  )
  loop
    if r.supertype_name is not null
    then
      l_msg_tab.extend(1);
      execute immediate utl_lms.format_message('begin :1 := new %s(); end;', r.type_name) using out l_msg_tab(l_msg_tab.last);
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
    then raise_application_error(c_dbms_pipe_timeout, 'Timeout while sending to pipe "' || p_job_name_supervisor || '"');
    when 3 -- Interrupt
    then raise_application_error(c_dbms_pipe_interrupted, 'Interrupt while sending to pipe "' || p_job_name_supervisor || '"');
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
    then raise_application_error(c_dbms_pipe_timeout, 'Timeout while receiving from pipe "' || p_job_name_supervisor || '"');
    when 2 -- Too large
    then raise_application_error(c_dbms_pipe_record_too_large, 'Record too large while receiving from pipe "' || p_job_name_supervisor || '"');
    when 3 -- Interrupt
    then raise_application_error(c_dbms_pipe_interrupted, 'Interrupt while receiving from pipe "' || p_job_name_supervisor || '"');
  end case;
end recv_worker_status;

end msg_pkg;
/

