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
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT || '.GET_MSG_TAB');
$end

  for r in
  ( select  ut.type_name
    ,       ut.supertype_name
    ,       ut.instantiable
    from    user_types ut
    connect by prior
            ut.type_name = ut.supertype_name and ut.supertype_owner = $$PLSQL_UNIT_OWNER -- GJP 2023-03-29 do not use USER
    start with
            ut.type_name = 'MSG_TYP'
  )
  loop
$if oracle_tools.cfg_pkg.c_debugging $then
    dbug.print
    ( dbug."info"
    , 'r.type_name: %s; r.supertype_name: %s; r.instantiable: %s'
    , r.type_name
    , r.supertype_name
    , r.instantiable
    );
$end
    if r.supertype_name is not null and r.instantiable = 'YES'
    then
      l_msg_tab.extend(1);

      l_statement := utl_lms.format_message('begin :1 := new %s(); end;', r.type_name);

      begin
        execute immediate l_statement using out l_msg_tab(l_msg_tab.last);
      exception
        when others
        then
$if oracle_tools.cfg_pkg.c_debugging $then
          dbug.print(dbug."error", 'statement: %s', l_statement);
          dbug.on_error;
$end
          raise_application_error(-20000, 'Could not create instance of type "' || r.type_name || '"', true);
      end;
    end if;
  end loop;

  if l_msg_tab.count = 0
  then
    raise program_error;
  end if;

  return l_msg_tab;

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
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

end msg_pkg;
/

