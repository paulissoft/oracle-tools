CREATE OR REPLACE PACKAGE BODY "ORACLE_TOOLS"."PKG_DATAPUMP_UTIL" IS

-- EXCEPTIONS

-- ORA-31634: job already exists
e_job_already_exists exception;
pragma exception_init(e_job_already_exists, -31634);

e_job_does_not_exist exception;
pragma exception_init(e_job_does_not_exist, -31626);

-- VARIABLES
g_clob clob;

-- CONSTANTS
".DMP" constant varchar2(4 char) := '.DMP';
".SQL" constant varchar2(4 char) := '.SQL';

"set_exclude_name_expr" constant varchar2(100 char) := 'PKG_DATAPUMP_UTIL.SET_EXCLUDE_NAME_EXPR';

"create_schema_sql_file" constant varchar2(100 char) := 'PKG_DATAPUMP_UTIL.CREATE_SCHEMA_SQL_FILE';
"create_schema_export_file" constant varchar2(100 char) := 'PKG_DATAPUMP_UTIL.CREATE_SCHEMA_EXPORT_FILE';

-- LOCAL

function to_string
( p_status_tab in sys.odcivarchar2list
)
return varchar2
is
  l_string varchar2(32767 char) := null;
begin
  if p_status_tab is not null and p_status_tab.count > 0
  then
    for i_idx in p_status_tab.first .. p_status_tab.last
    loop
      l_string := l_string || p_status_tab(i_idx) || chr(10);
    end loop;
  end if;
  return l_string;
exception
  when value_error -- string too small: ignore the rest
  then
    return l_string;
end to_string;

procedure check_directory_access
( p_directory in all_directories.directory_name%type
, p_filename in all_directories.directory_path%type default userenv('sessionid') || '.txt'
, p_read in boolean default false
, p_write in boolean default false
)
is
  l_fh utl_file.file_type;
  l_found pls_integer;
  l_directory_path all_directories.directory_path%type;
  l_error_message varchar2(2048 char) := null;

  l_privilege constant all_tab_privs.privilege%type := case when p_write then 'WRITE' when p_read then 'READ' end;

  procedure cleanup
  is
  begin
    if utl_file.is_open(l_fh)
    then
      utl_file.fclose(l_fh);
      if p_write
      then
        utl_file.fremove(location => p_directory, filename => p_filename);
      end if;
    end if;
  end cleanup;
begin
  -- check directory existence
  begin
    select  d.directory_path
    into    l_directory_path
    from    all_directories d
    where   d.directory_name = p_directory;
  exception
    when no_data_found
    then
      l_error_message := 'Oracle directory "' || p_directory || '" does not exist.';
      raise;
  end;

  -- check directory privilege
  begin
    select  1
    into    l_found
    from    all_tab_privs p
    where   p.table_name = p_directory
    and     p.privilege = l_privilege
    and     ( p.grantee = user or
              p.grantee = 'PUBLIC' or
              p.grantee in (select role from session_roles) )
    and     rownum = 1;
  exception
    when no_data_found
    then
      l_error_message :=
        'Schema ' ||
        user ||
        ' needs ' ||
        l_privilege ||
        ' privilege on directory "' ||
        p_directory ||
        '", either directly to the schema, PUBLIC or indirectly via a role.';
      raise;
  end;

  -- directory and privilege okay, so can we read/write a file?
  l_fh := utl_file.fopen(location => p_directory, filename => p_filename, open_mode => lower(substr(l_privilege, 1, 1)));
  if p_write
  then
    utl_file.putf(l_fh, p_filename);
  end if;
  cleanup;
exception
  when no_data_found
  then
    cleanup;
    raise_application_error
    ( -20000
    , l_error_message
    , true
    );

  when others
  then
    cleanup;
    raise_application_error
    ( -20000
    , 'Oracle server directory path "' ||
      l_directory_path ||
      '" may not exist or have a problem.'
    , true
    );
end check_directory_access;

procedure check_privileges(p_program in varchar2, p_schema in varchar2 default null)
is
  l_found pls_integer;

  l_tablespace_name user_ts_quotas.tablespace_name%type;

  -- one of these
  l_granted_role_tab constant sys.odcivarchar2list :=
    sys.odcivarchar2list
    ( case p_program
        when "create_schema_sql_file"
        then 'DATAPUMP_IMP_FULL_DATABASE'
        when "create_schema_export_file"
        then 'DATAPUMP_EXP_FULL_DATABASE'
      end
    , case p_program
        when "create_schema_sql_file"
        then 'IMP_FULL_DATABASE'
        when "create_schema_export_file"
        then 'EXP_FULL_DATABASE'
      end
    );
begin
  -- must be able to create a table in this schema
  begin
    select  1
    into    l_found
    from    session_privs p
    where   p.privilege = 'CREATE TABLE';
  exception
    when no_data_found
    then
      raise_application_error
      ( -20000
      , 'Schema ' || user || ' has no CREATE TABLE privilege.'
      );
  end;

  begin
    select  case when t.max_bytes != 0 then 1 end as found
    ,       u.default_tablespace
    into    l_found
    ,       l_tablespace_name
    from    user_users u
            left outer join user_ts_quotas t
            on t.tablespace_name = u.default_tablespace;

    if l_found = 1
    then
      null; -- ok
    else
      raise_application_error
      ( -20000
      , 'Schema ' || user || ' must have quota on its default tablespace ' || l_tablespace_name || '.'
      );
    end if;
  end;

  -- datapump_imp_full_database / datapump_exp_full_database
  begin
    select  1
    into    l_found
    from    dual
    where   user = p_schema
    union
    select  1
    from    dual
    where   user <> p_schema
    and     exists
            ( select  1
              from    session_roles p
              where   p.role in (select column_value from table(l_granted_role_tab))
            )
    ;
  exception
    when no_data_found
    then raise_application_error
         ( -20000
         , 'User ' ||
           user ||
           ' may only execute ' ||
           p_program ||
           ' for schema ' ||
           p_schema ||
           ' when he has session role ' ||
           l_granted_role_tab(1) ||
           ' or ' ||
           l_granted_role_tab(2) ||
           '.'
         );
  end;

  -- check utl_file privilege: not granted by default on Oracle 12c
  begin
    select  1
    into    l_found
    from    all_tab_privs p
    where   p.table_name = 'UTL_FILE'
    and     p.privilege = 'EXECUTE'
    and     ( p.grantee = user or
              p.grantee = 'PUBLIC' or
              p.grantee in (select role from session_roles) )
    and     rownum = 1;
  exception
    when no_data_found
    then
      raise_application_error
      ( -20000
      , 'Schema ' ||
        user ||
        ' needs execute privilege on package "UTL_FILE", either directly to the schema, PUBLIC or indirectly via a role.'
      );
  end;
end check_privileges;

procedure show_status
( p_status ku$_status
, p_status_tab out nocopy sys.odcivarchar2list
)
is
  procedure show_JobStatus(p_JobStatus in ku$_JobStatus)
  is
  begin
    p_status_tab.extend(1);
    p_status_tab(p_status_tab.last) :=
      'job status (1): ' ||
      'job_name: ' || p_JobStatus.job_name ||
      '; operation: ' || p_JobStatus.operation ||
      '; job_mode: ' || p_JobStatus.job_mode ||
      '; bytes_processed: ' || p_JobStatus.bytes_processed ||
      '; percent_done: ' || p_JobStatus.percent_done
    ;
$if cfg_pkg.c_debugging $then
    dbug.print( dbug."info", p_status_tab(p_status_tab.last) );
$end

    p_status_tab.extend(1);
    p_status_tab(p_status_tab.last) :=
      'job status (2): ' ||
      'degree: ' || p_JobStatus.degree ||
      '; error_count: ' || p_JobStatus.error_count ||
      '; state: ' || p_JobStatus.state ||
      '; phase: ' || p_JobStatus.phase
    ;
$if cfg_pkg.c_debugging $then
    dbug.print( dbug."info", p_status_tab(p_status_tab.last) );
$end
  end show_JobStatus;

  procedure show_JobDesc(p_JobDesc in ku$_JobDesc)
  is
  begin
    p_status_tab.extend(1);
    p_status_tab(p_status_tab.last) :=
      'job descr (1): ' ||
      'job_name: ' || p_JobDesc.job_name ||
      '; operation: ' || p_JobDesc.operation ||
      '; job_mode: ' || p_JobDesc.job_mode ||
      '; remote_link: ' || p_JobDesc.remote_link ||
      '; owner: ' || p_JobDesc.owner
    ;
$if cfg_pkg.c_debugging $then
    dbug.print( dbug."info", p_status_tab(p_status_tab.last) );
$end

    p_status_tab.extend(1);
    p_status_tab(p_status_tab.last) := 'job descr (2): ' || 'start_time: ' || p_JobDesc.start_time;
$if cfg_pkg.c_debugging $then
    dbug.print( dbug."info", p_status_tab(p_status_tab.last) );
$end
  end show_JobDesc;

  procedure show_LogEntry(p_LogEntry in ku$_LogEntry)
  is
    l_idx number;               -- Loop index
  begin
    l_idx := p_LogEntry.first;
    while l_idx is not null
    loop
      p_status_tab.extend(1);
      p_status_tab(p_status_tab.last) := 'log text (' || l_idx || '): ' || substr(p_LogEntry(l_idx).LogText, 1+255*0, 255);

$if cfg_pkg.c_debugging $then
    dbug.print( dbug."info", p_status_tab(p_status_tab.last) );
$end

      l_idx := p_LogEntry.next(l_idx);
    end loop;
  end show_LogEntry;
begin
$if cfg_pkg.c_debugging $then
  dbug.enter('PKG_DATAPUMP_UTIL.SHOW_STATUS');
$end

  p_status_tab := sys.odcivarchar2list();

  if (bitand(p_status.mask, dbms_datapump.ku$_status_job_desc) != 0)
  then
    show_JobDesc(p_status.job_description);
  end if;

  if (bitand(p_status.mask, dbms_datapump.ku$_status_job_status) != 0)
  then
    show_JobStatus(p_status.job_status);
  end if;

  if (bitand(p_status.mask, dbms_datapump.ku$_status_wip) != 0)
  then
    show_LogEntry(p_status.wip);
  end if;

  if (bitand(p_status.mask, dbms_datapump.ku$_status_job_error) != 0)
  then
    show_LogEntry(p_status.error);
  end if;

$if cfg_pkg.c_debugging $then
  dbug.leave;
$end
end show_status;

procedure show_status
( p_job_handle in number
, p_status_tab out nocopy sys.odcivarchar2list
)
is
  l_status ku$_status;
  l_job_state user_datapump_jobs.state%type;
  -- ORA-31623: a job is not attached to this session via the specified handle
  e_job_not_attached exception;
  pragma exception_init(e_job_not_attached, -31623);
begin
  dbms_datapump.get_status
  ( handle => p_job_handle
  , mask => dbms_datapump.ku$_status_wip +
            dbms_datapump.ku$_status_job_desc +
            dbms_datapump.ku$_status_job_status +
            dbms_datapump.ku$_status_job_error
  , timeout => 0 -- return immediate
  , job_state => l_job_state
  , status => l_status
  );
  show_status(p_status => l_status, p_status_tab => p_status_tab);
exception
  when e_job_not_attached
  then
    null;
end show_status;

procedure handle_error
( p_status_tab out nocopy sys.odcivarchar2list
)
is
  l_idx number;               -- Loop index
  l_sts ku$_Status;           -- The status object returned by get_status
  l_job_state user_datapump_jobs.state%type;
  l_ora_31633_expr constant varchar2(100 char) := 'ORA-31633: unable to create master table "%"';
  l_table_name varchar2(4000 char);
begin
$if cfg_pkg.c_debugging $then
  dbug.enter('PKG_DATAPUMP_UTIL.HANDLE_ERROR');
$end

  dbms_datapump.get_status
  ( handle => null
  , mask => dbms_datapump.ku$_status_job_error
  , timeout => -1
  , job_state => l_job_state
  , status => l_sts
  );

  show_status(p_status => l_sts, p_status_tab => p_status_tab);

  -- If any work-in-progress (WIP) or Error messages were received for the job,
  -- display them.

  if (bitand(l_sts.mask, dbms_datapump.ku$_status_job_error) != 0)
  then
    l_idx := l_sts.error.first;
    while l_idx is not null
    loop
/*
|   | info: log text 2: ORA-31633: unable to create master table "SYS.<owner>.DDL"
ORA-06512: at "SYS.DBMS_SYS_ERROR", line 95
ORA-06512: at "SYS.KUPV$FT", line 1020
ORA-00955: name is already used by an existing object
*/
      if l_sts.error(l_idx).LogText like '%' || l_ora_31633_expr || '%ORA-00955%'
      then
        l_table_name := regexp_replace(l_sts.error(l_idx).LogText, '^' || replace(l_ora_31633_expr, '%', '([^"]+)') || '.*$', '\1', 1, 1, 'n');
        p_status_tab.extend(1);
        p_status_tab(p_status_tab.last) := 'table: ' || l_table_name;
$if cfg_pkg.c_debugging $then
        dbug.print( dbug."info", p_status_tab(p_status_tab.last) );
$end
        if instr(l_table_name, user) = 1
        then
          l_table_name := substr(l_table_name, 1 + length(user) + 1);
        end if;
        p_status_tab.extend(1);
        p_status_tab(p_status_tab.last) := 'drop table "' || l_table_name || '" purge';
$if cfg_pkg.c_debugging $then
        dbug.print( dbug."warning", p_status_tab(p_status_tab.last) );
$end
        execute immediate p_status_tab(p_status_tab.last);
      end if;

      l_idx := l_sts.error.next(l_idx);
    end loop;
  end if;

$if cfg_pkg.c_debugging $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end handle_error;

procedure wait_for_job
( p_job_name in varchar2
, p_job_handle in out number
, p_job_state out nocopy varchar2
)
is
  l_program constant varchar2(61 char) := 'PKG_DATAPUMP_UTIL.WAIT_FOR_JOB';
  -- ORA-31627: API call succeeded but more information is available
  e_more_information_available exception;
  pragma exception_init(e_more_information_available, -31627);

  l_status_tab sys.odcivarchar2list := null;
begin
$if cfg_pkg.c_debugging $then
  dbug.enter(l_program);
  dbug.print(dbug."input", 'p_job_name: %s; p_job_handle: %s', p_job_name, p_job_handle);
$end

  <<try_loop>>
  for i_try in 1..2
  loop
$if cfg_pkg.c_debugging $then
    dbug.print(dbug."info", 'i_try: %s', i_try);
$end

    begin
      dbms_datapump.start_job(handle => p_job_handle);
    exception
      when e_more_information_available
      then
$if cfg_pkg.c_debugging $then
        show_status(p_job_handle => p_job_handle, p_status_tab => l_status_tab);
$else
        null; -- probably ORA-31655: no data or metadata objects selected for job
$end
    end;
    dbms_datapump.wait_for_job(handle => p_job_handle, job_state => p_job_state);

$if cfg_pkg.c_debugging $then
    show_status(p_job_handle => p_job_handle, p_status_tab => l_status_tab);
$end

    case p_job_state
      when 'COMPLETED'
      then exit try_loop;

      when 'STOPPED'
      then if i_try = 1
           then
             dbms_datapump.detach(handle => p_job_handle);
             p_job_handle := dbms_datapump.attach(job_name => p_job_name); -- reattach
           else
             raise_application_error(-20000, 'Job has STOPPED.');
           end if;
    end case;
  end loop try_loop;

$if cfg_pkg.c_debugging $then
  dbug.print(dbug."output", 'p_job_handle: %s; p_job_state: %s', p_job_handle, p_job_state);
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise_application_error(-20000, 'datapump info: ' || chr(10) || to_string(l_status_tab), true);
$end
end wait_for_job;

procedure add_file
( p_handle in number
, p_filename in varchar2
, p_directory in varchar2
, p_filetype in number
, p_reusefile in number default null
)
is
  -- no reusefile parameter in dbms_datapump.add_file
$if dbms_db_version.ver_le_10 $then
  l_fexists boolean;
  l_file_length number;
  l_block_size number;
$end
begin

  -- no reusefile parameter in dbms_datapump.add_file
$if dbms_db_version.ver_le_10 $then

  -- utl_file is not granted by default for Oracle 12
  if p_reusefile = 1
  then
    utl_file.fgetattr
    ( location => p_directory
    , filename => p_filename
    , fexists => l_fexists
    , file_length => l_file_length
    , block_size => l_block_size
    );

    if l_fexists
    then
      utl_file.fremove
      ( location => p_directory
      , filename => p_filename
      );
    end if;
  end if;

$end

  dbms_datapump.add_file
  ( handle => p_handle
  , filename => p_filename
  , directory => p_directory
  , filetype => p_filetype
$if not(dbms_db_version.ver_le_10) $then
  , reusefile => p_reusefile
$end
  );
exception
  when others
  then
    begin
      -- try to write the file
      check_directory_access
      ( p_directory => p_directory
      , p_filename => p_filename
      , p_write => true
      );
      -- no problem: just reraise
      raise;
    exception
      when others
      then
        raise_application_error
        ( -20000
        , 'Error writing file "' || p_filename || '" to directory "' || p_directory || '" with filetype ' || p_filetype || ' and reusefile ' || p_reusefile || '.'
        , true
        );
    end;
end add_file;

procedure set_exclude_name_expr
( p_handle in number
, p_object_type in varchar2
, p_name in varchar2
)
is
  l_exclude_name_expr_tab t_text_tab;
  l_value varchar2(4000 char);

  l_program constant varchar2(100 char) := "set_exclude_name_expr";
begin
$if cfg_pkg.c_debugging $then
  dbug.enter(l_program);
  dbug.print
  ( dbug."input"
  , 'p_object_type: %s; p_name: %s'
  , p_object_type
  , p_name
  );
$end

  oracle_tools.pkg_ddl_util.get_exclude_name_expr_tab(p_object_type => p_object_type, p_exclude_name_expr_tab => l_exclude_name_expr_tab);
  if l_exclude_name_expr_tab.count > 0
  then
    for i_idx in l_exclude_name_expr_tab.first .. l_exclude_name_expr_tab.last
    loop
      l_value := q'[NOT LIKE ']' || l_exclude_name_expr_tab(i_idx) || q'[' ESCAPE '\']';

$if cfg_pkg.c_debugging $then
      dbug.print(dbug."info", 'l_value: %s', l_value);
$end
      dbms_datapump.metadata_filter
      ( handle => p_handle
      , name => p_name
      , value => l_value
      , object_path => p_object_type
      );
    end loop;
  end if;

$if cfg_pkg.c_debugging $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end set_exclude_name_expr;

-- GLOBAL
function get_schema_export_directory
return all_directories.directory_name%type
deterministic
is
begin
  return 'DATA_PUMP_DIR';
end get_schema_export_directory;

function get_schema_export_file
( p_schema in varchar2
, p_content in varchar2
, p_remote_link in varchar2
)
return varchar2
is
  l_base varchar2(30 char);
begin
  if p_content in ('ALL', 'DATA_ONLY', 'METADATA_ONLY')
  then
    null;
  else
    raise value_error;
  end if;

  l_base := case p_content when 'DATA_ONLY' then 'DML' when 'METADATA_ONLY' then 'DDL' else p_content end;

  l_base :=
    case
      when length(p_schema || '_' || l_base) <= 30
      then p_schema || '_' || l_base
      else substr(p_schema, 1, 30 - (length('$_' || l_base))) || '$_' || l_base
    end;

  return l_base || ".DMP";
end get_schema_export_file;

function get_schema_sql_file
( p_schema in varchar2
, p_content in varchar2
, p_remote_link in varchar2
)
return varchar2
is
begin
  return replace
         ( get_schema_export_file
           ( p_schema
           , p_content
           , p_remote_link
           )
         , ".DMP"
         , ".SQL"
         );
end get_schema_sql_file;

procedure create_schema_export_file
( p_schema in varchar2
, p_content in varchar2
, p_remote_link in varchar2
)
is
  l_export_file all_directories.directory_path%type;
  l_job_name user_datapump_jobs.job_name%type;
  l_job_state user_datapump_jobs.state%type;
  l_job_handle number := null;

  l_status_tab sys.odcivarchar2list := null;

  l_program constant varchar2(100 char) := "create_schema_export_file";

  procedure cleanup
  is
  begin
    if l_job_handle is not null
    then
      dbms_datapump.detach(l_job_handle);
    end if;
  end cleanup;
begin
$if cfg_pkg.c_debugging $then
  dbug.enter(l_program);
  dbug.print(dbug."input", 'p_schema: %s; p_content: %s; p_remote_link: %s', p_schema, p_content, p_remote_link);
$end

  check_privileges(l_program, p_schema);

  -- checks in the body, not declaration
  l_export_file := get_schema_export_file(p_schema => p_schema, p_content => p_content, p_remote_link => p_remote_link);

  l_job_name := replace(l_export_file, ".DMP");

  begin
    <<try_loop>>
    for i_try in 1..2
    loop
$if cfg_pkg.c_debugging $then
      dbug.print(dbug."info", 'i_try: %s', i_try);
$end
      begin
        l_job_handle :=
          dbms_datapump.open
          ( operation => 'EXPORT'
          , job_mode => 'SCHEMA'
          , remote_link => p_remote_link
          , job_name => l_job_name
          );
        exit try_loop;
      exception
        when e_job_does_not_exist
        then
          if i_try = 1
          then
            handle_error(l_status_tab);
          else
            raise;
          end if;
      end;
    end loop try_loop;

    dbms_datapump.data_filter
    ( handle => l_job_handle
    , name => 'INCLUDE_ROWS'
    , value => case when p_content = 'METADATA_ONLY' then 0 else 1 end
    );
  exception
    when e_job_already_exists
    then
$if cfg_pkg.c_debugging $then
      dbug.on_error;
$end
      l_job_handle := dbms_datapump.attach(job_name => l_job_name);

    when others
    then
$if cfg_pkg.c_debugging $then
      dbug.on_error;
      show_status(p_job_handle => l_job_handle, p_status_tab => l_status_tab);
$end
      raise;
  end;

  dbms_datapump.metadata_filter
  ( handle => l_job_handle
  , name => 'SCHEMA_EXPR'
  , value => q'[=']' || p_schema || q'[']'
  );

  add_file
  ( p_handle => l_job_handle
  , p_filename => l_export_file
  , p_directory => get_schema_export_directory
  , p_filetype  => dbms_datapump.ku$_file_type_dump_file
  , p_reusefile => 1 -- overwrite
  );

  wait_for_job(p_job_name => l_job_name, p_job_handle => l_job_handle, p_job_state => l_job_state);

  cleanup;

$if cfg_pkg.c_debugging $then
  dbug.leave;
$end
exception
  when others
  then
$if cfg_pkg.c_debugging $then
    dbug.on_error;
$end
    cleanup;
$if cfg_pkg.c_debugging $then
    dbug.leave;
$end
    raise_application_error(-20000, 'datapump info: ' || chr(10) || to_string(l_status_tab), true);
end create_schema_export_file;

procedure get_schema_export_file_info
( p_schema_export_file in varchar2
, p_creation_date out nocopy varchar2
, p_job_name out nocopy varchar2
)
is
  l_info_table ku$_dumpfile_info;
  l_filetype number;
begin
$if cfg_pkg.c_debugging $then
  dbug.enter('PKG_DATAPUMP_UTIL.GET_SCHEMA_EXPORT_FILE_INFO');
  dbug.print(dbug."input", 'p_schema_export_file: %s', p_schema_export_file);
$end

  dbms_datapump.get_dumpfile_info
  ( filename => p_schema_export_file
  , directory => get_schema_export_directory
  , info_table => l_info_table
  , filetype => l_filetype
  );
  if l_info_table is not null and l_info_table.count > 0
  then
    for i_idx in l_info_table.first .. l_info_table.last
    loop
      case l_info_table(i_idx).item_code
        when dbms_datapump.ku$_dfhdr_creation_date
        then p_creation_date := l_info_table(i_idx).value;

        when dbms_datapump.ku$_dfhdr_job_name
        then p_job_name := l_info_table(i_idx).value;

        else null;
      end case;
    end loop;
  end if;

$if cfg_pkg.c_debugging $then
  dbug.print(dbug."output", 'p_creation_date: %s; p_job_name: %s', p_creation_date, p_job_name);
  dbug.leave;
$end
end get_schema_export_file_info;

procedure create_schema_sql_file
( p_schema in varchar2
, p_content in varchar2
, p_new_schema in varchar2
, p_object_type in varchar2
, p_object_name_expr in varchar2
, p_remote_link in varchar2
, p_sql_file out nocopy bfile
)
is
  l_export_file all_directories.directory_path%type;
  l_sql_file all_directories.directory_path%type;
  l_job_name user_datapump_jobs.job_name%type := null;
  l_job_state user_datapump_jobs.state%type;
  l_job_handle number := null;

  l_status_tab sys.odcivarchar2list := null;

  l_object_type_tab constant sys.odcivarchar2list :=
    sys.odcivarchar2list( 'SEQUENCE'
                        , 'TYPE_SPEC'
                        , 'CLUSTER'
                        , 'TABLE'
                        , 'COMMENT'
                        , 'FUNCTION'
                        , 'PACKAGE_SPEC'
                        , 'VIEW'
                        , 'PROCEDURE'
                        , 'MATERIALIZED_VIEW'
                        , 'MATERIALIZED_VIEW_LOG'
                        , 'PACKAGE_BODY'
                        , 'TYPE_BODY'
                        , 'INDEX'
                        , 'TRIGGER'
                        , 'OBJECT_GRANT'
                        , 'CONSTRAINT'
                        , 'REF_CONSTRAINT'
                        , 'SYNONYM'
                        , 'DB_LINK'
                        , 'DIMENSION'
                        , 'INDEXTYPE'
                        , 'JAVA_SOURCE'
                        , 'LIBRARY'
                        , 'OPERATOR'
                        , 'REFRESH_GROUP'
                        , 'XMLSCHEMA'
                        , 'PROCOBJ'
                        );

  l_value varchar2(4000 char);

  l_program constant varchar2(100 char) := "create_schema_sql_file";

  procedure cleanup
  is
  begin
    if l_job_handle is not null
    then
      dbms_datapump.detach(l_job_handle);
    end if;
  end cleanup;
begin
$if cfg_pkg.c_debugging $then
  dbug.enter(l_program);
  dbug.print
  ( dbug."input"
  , 'p_schema: %s; p_content: %s; p_new_schema: %s; p_object_type: %s'
  , p_schema
  , p_content
  , p_new_schema
  , p_object_type
  );
  dbug.print
  ( dbug."input"
  , 'p_object_name_expr: %s; p_remote_link: %s'
  , p_object_name_expr
  , p_remote_link
  );
$end

  check_privileges(l_program, p_schema);

  -- checks in the body, not declaration
  l_export_file := get_schema_export_file(p_schema => p_schema, p_content => p_content, p_remote_link => p_remote_link);
  l_sql_file := get_schema_sql_file(p_schema => p_schema, p_content => p_content, p_remote_link => p_remote_link);

  dbms_metadata.set_transform_param(dbms_metadata.session_transform, 'PRETTY', true);

  begin
    <<try_loop>>
    for i_try in 1..2
    loop
$if cfg_pkg.c_debugging $then
      dbug.print(dbug."info", 'i_try: %s', i_try);
$end
      begin
        l_job_handle :=
          dbms_datapump.open
          ( operation => 'SQL_FILE'
          , job_mode => 'SCHEMA'
          , remote_link => p_remote_link
          , job_name => l_job_name
          );
        exit try_loop;
      exception
        when e_job_does_not_exist
        then
          if i_try = 1
          then
            handle_error(l_status_tab);
          else
            raise;
          end if;
      end;
    end loop try_loop;

  exception
    when e_job_already_exists
    then
$if cfg_pkg.c_debugging $then
      dbug.on_error;
$end
      l_job_handle := dbms_datapump.attach(job_name => l_job_name);

    when others
    then
$if cfg_pkg.c_debugging $then
      dbug.on_error;
      show_status(p_job_handle => l_job_handle, p_status_tab => l_status_tab);
$end
      raise;
  end;

  add_file
  ( p_handle => l_job_handle
  , p_filename => l_export_file
  , p_directory => get_schema_export_directory
  , p_filetype => dbms_datapump.ku$_file_type_dump_file
  );
  add_file
  ( p_handle => l_job_handle
  , p_filename => l_sql_file
  , p_directory => get_schema_export_directory
  , p_filetype => dbms_datapump.ku$_file_type_sql_file
  );

  dbms_datapump.metadata_filter
  ( handle => l_job_handle
  , name => 'SCHEMA_LIST'
  , value => '''' || p_schema || ''''
  );

  if p_new_schema is not null
  then
    dbms_datapump.metadata_remap
    ( handle => l_job_handle
    , name => 'REMAP_SCHEMA'
    , old_value => p_schema
    , value => p_new_schema
    );
  end if;

  if p_object_type is not null
  then
    dbms_datapump.metadata_filter
    ( handle => l_job_handle
    , name => 'INCLUDE_PATH_EXPR'
    , value => 'LIKE ''' || p_object_type || ''''
    );
  end if;

  -- ignore default excludes (BIN objects etcetera)
  for i_idx in l_object_type_tab.first .. l_object_type_tab.last
  loop
    if p_object_name_expr is not null
    then
      dbms_datapump.metadata_filter
      ( handle => l_job_handle
      , name => 'NAME_EXPR'
      , value => p_object_name_expr
      , object_path => l_object_type_tab(i_idx)
      );
    end if;
    set_exclude_name_expr
    ( p_handle => l_job_handle
    , p_object_type => l_object_type_tab(i_idx)
    , p_name => 'NAME_EXPR'
    );
  end loop;

  -- no statistics
  dbms_datapump.metadata_filter
  ( handle => l_job_handle
  , name => 'EXCLUDE_PATH_EXPR'
  , value => q'[LIKE 'SCHEMA_EXPORT/%/STATISTICS/%']'
  );

  for i_nr in 1..5
  loop
    begin
      l_value := case i_nr
                   -- no queue tables
                   when 1 then q'[NOT IN (SELECT q.queue_table FROM all_queue_tables q WHERE q.owner = ']' || p_schema || q'[')]'
                   -- no MATERIALIZED VIEW tables unless PREBUILT
                   when 2 then q'[NOT IN (SELECT t.mview_name FROM all_mviews t WHERE t.owner = ']' || p_schema || q'[' AND t.build_mode != 'PREBUILT')]'
                   -- Exclude nested tables, their DDL is part of their parent table.
                   when 3 then q'[NOT IN (SELECT n.table_name FROM all_nested_tables n WHERE n.owner = ']' || p_schema || q'[')]'
                   -- Exclude overflow segments, their DDL is part of their parent table.
                   when 4 then q'[NOT IN (SELECT t.table_name FROM all_tables t WHERE t.owner = ']' || p_schema || q'[' AND t.iot_type = 'IOT_OVERFLOW')]'
                   -- no 'schema_version' table
                   when 5 then q'[!= 'schema_version']'
                 end;
      dbms_datapump.metadata_filter
      ( handle => l_job_handle
      , name => 'NAME_EXPR'
      , value => l_value
      , object_path => 'TABLE'
      );
    exception
      when others
      then raise_application_error(-20000, 'Value is: "' || l_value || '"', true);
    end;
  end loop;

  -- indexes
  dbms_datapump.metadata_filter
  ( handle => l_job_handle
  , name => 'NAME_EXPR'
  , value => q'[NOT IN ('schema_version_pk','schema_version_s_idx')]'
  , object_path => 'INDEX'
  );

  -- views
  dbms_datapump.metadata_filter
  ( handle => l_job_handle
  , name => 'NAME_EXPR'
  , value => q'[NOT LIKE 'AQ$%']'
  , object_path => 'VIEW'
  );

  -- constraints
  dbms_datapump.metadata_filter
  ( handle => l_job_handle
  , name => 'NAME_EXPR'
  , value => q'[!= 'schema_version_pk']'
  , object_path => 'CONSTRAINT'
  );

  dbms_datapump.metadata_transform(l_job_handle, 'SEGMENT_ATTRIBUTES', 1);
  dbms_datapump.metadata_transform(l_job_handle, 'STORAGE', 0);

  wait_for_job(p_job_name => l_job_name, p_job_handle => l_job_handle, p_job_state => l_job_state);

  p_sql_file := bfilename(get_schema_export_directory, l_sql_file);

  cleanup;

$if cfg_pkg.c_debugging $then
  dbug.leave;
$end
exception
  when others
  then
$if cfg_pkg.c_debugging $then
    dbug.on_error;
$end
    cleanup;
$if cfg_pkg.c_debugging $then
    dbug.leave;
$end
    raise_application_error(-20000, 'datapump info: ' || chr(10) || to_string(l_status_tab), true);
end create_schema_sql_file;

function bfile2clob
( p_bfile in out nocopy bfile
)
return clob
is
  l_dest_offset number := 1;
  l_src_offset number := 1;
  l_lang_context number := 0;
  l_warning number;

  l_directory_name all_directories.directory_name%type;
  l_file_name all_directories.directory_path%type;

  l_program constant varchar2(100 char) := 'PKG_DATAPUMP_UTIL.BFILE2CLOB';

  procedure cleanup
  is
  begin
    if dbms_lob.fileisopen(p_bfile) = 1
    then
      dbms_lob.fileclose(p_bfile);
    end if;
  end cleanup;
begin
$if cfg_pkg.c_debugging $then
  dbug.enter(l_program);
$end

  dbms_lob.fileopen(p_bfile, dbms_lob.lob_readonly);
  dbms_lob.trim(g_clob, 0);

  dbms_lob.loadclobfromfile
  ( dest_lob => g_clob
  , src_bfile => p_bfile
  , amount => dbms_lob.getlength(p_bfile)
  , dest_offset => l_dest_offset
  , src_offset => l_src_offset
  , bfile_csid => 0
  , lang_context => l_lang_context
  , warning => l_warning
  );

  cleanup;
$if cfg_pkg.c_debugging $then
  dbug.leave;
$end

  return g_clob; -- this temporary clob will be cleaned up by Oracle
/*
exception
  when others
  then
$if cfg_pkg.c_debugging $then
    dbug.on_error;
$end
    cleanup;
$if cfg_pkg.c_debugging $then
    dbug.leave;
$end

    dbms_lob.filegetname(p_bfile, l_directory_name, l_file_name);

    begin
      -- try to write the file
      check_directory_access
      ( p_directory => l_directory_name
      , p_filename => l_file_name
      , p_read => true
      );
      -- no problem: just reraise
      raise;
    exception
      when others
      then
        raise_application_error
        ( -20000
        , 'Error reading file "' || l_file_name || '" from directory "' || l_directory_name || '".'
        , true
        );
    end;*/
end bfile2clob;

begin
  dbms_lob.createtemporary(lob_loc => g_clob, cache => false);
end pkg_datapump_util;
/

