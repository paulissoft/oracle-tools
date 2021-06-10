create or replace package body ui_user_management_pkg
is

function show_users
( p_user_name in apex_workspace_apex_users.user_name%type default null
)
return t_users_tab
pipelined
is
begin
  for r in
  ( select  usr.user_name
    ,       usr.last_name
    ,       usr.first_name
    ,       usr.email
    ,       usr.date_created
    ,       usr.account_expiry
    ,       substr(usr.account_locked, 1, 1) as account_locked
    ,       substr(usr.is_admin, 1, 1) as is_admin
    ,       substr(usr.is_application_developer, 1, 1) as is_application_developer
    ,       ui_user_management_pkg.get_role(usr.user_name) as group_name
    ,       usr.first_schema_provisioned 
    from    apex_workspace_apex_users usr
    where   ( p_user_name is null or upper(usr.user_name) = upper(p_user_name) ) 
  )
  loop
    pipe row (r);
  end loop;
  
  return;
end show_users;

function has_role
( p_role_tab in sys.odcivarchar2list
, p_app_user in varchar2
, p_app_id in number
)
return integer
is
  l_result integer;
  l_group varchar2(32767 char) := null;
  l_build_option_value varchar2(32767 char) := null;
  l_cursor sys_refcursor;
begin
$if cfg_pkg.c_debugging $then
  dbug.enter('ui_user_management_pkg.has_role');
  if p_role_tab is not null and p_role_tab.count > 0
  then
    for i_idx in p_role_tab.first .. p_role_tab.last
    loop
      dbug.print(dbug."input", 'p_role_tab(%s): %s', i_idx, p_role_tab(i_idx));    
    end loop;
  end if;
  dbug.print(dbug."input", 'p_app_user: %s; p_app_id: %s', p_app_user, p_app_id);
$end

  l_build_option_value :=
    apex_util.get_build_option_status
    ( p_application_id => p_app_id
    , p_build_option_name => "USE_APEX_GROUPS"
    );

$if cfg_pkg.c_debugging $then
  dbug.print(dbug."info", 'l_build_option_value: %s', l_build_option_value);
$end

  begin
    if upper(substr(l_build_option_value, 1, 1)) = 'I' -- Include: True
    then
      l_group := apex_util.get_groups_user_belongs_to(p_username => p_app_user);

      -- l_group can be 'Backoffice employees, PM Administrators, Portal Administrators'
      -- so split by regular expression, see below

$if cfg_pkg.c_debugging $then
      dbug.print(dbug."info", 'l_group: %s', l_group);
$end    

      select  sign(count(*)) -- 0: 0, > 0: 1
      into    l_result
      from    ( select  i.column_value as role
                from    table(p_role_tab) i
                intersect
                select  g.column_value as role
                from    table(apex_string.split(l_group, '\s*,\s*')) g
              );              
    else
      open l_cursor for q'[
      select  1
      from    table(:1) t
              inner join users_tbl usr
              on usr.profil like t.column_value escape '\'
      where   upper(usr.login) = :2
      and     rownum = 1]' using p_role_tab, p_app_user;  
      fetch l_cursor into l_result;
      if not(l_cursor%found)
      then
        close l_cursor;
        raise no_data_found;
      else
        fetch l_cursor into l_result;
        if l_cursor%found
        then
          close l_cursor;
          raise too_many_rows;
        else
          close l_cursor;
        end if;
      end if;
    end if;
  exception
    when no_data_found or too_many_rows
    then
      l_result := 0;
  end;

$if cfg_pkg.c_debugging $then
  dbug.print(dbug."output", 'return: %s', l_result);
  dbug.leave;
$end

  return l_result;
$if cfg_pkg.c_debugging $then
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end has_role;

$if dbms_db_version.ver_le_12 $then

/* ACL does not exist on Apex 5.1 */

$else

function has_acl_role
( p_role_tab in sys.odcivarchar2list
, p_app_user in varchar2 default apex_application.g_user
, p_app_id in number default apex_application.g_flow_id
)
return integer
is
  l_result integer := 0;  
begin
$if cfg_pkg.c_debugging $then
  dbug.enter('ui_user_management_pkg.has_acl_role');
  if p_role_tab is not null and p_role_tab.count > 0
  then
    for i_idx in p_role_tab.first .. p_role_tab.last
    loop
      dbug.print(dbug."input", 'p_role_tab(%s): %s', i_idx, p_role_tab(i_idx));    
    end loop;
  end if;
  dbug.print(dbug."input", 'p_app_user: %s; p_app_id: %s', p_app_user, p_app_id);
$end

  if p_role_tab is not null and p_role_tab.count > 0
  then
    for i_idx in p_role_tab.first .. p_role_tab.last
    loop
      if apex_acl.has_user_role
         ( p_application_id => p_app_id
         , p_user_name => p_app_user
         , p_role_static_id => p_role_tab(i_idx)
         )
      then
        l_result := 1;
        exit;
      end if;
    end loop;
  end if;

$if cfg_pkg.c_debugging $then
  dbug.print(dbug."output", 'return: %s', l_result);
  dbug.leave;
$end

  return l_result;
  
$if cfg_pkg.c_debugging $then
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end has_acl_role;

$end

function get_role
( p_app_user in varchar2
, p_app_id in number
)
return varchar2
is
  l_role varchar2(4000 char);
  l_build_option_value varchar2(32767 char) := null;
  l_cursor sys_refcursor;
begin
$if cfg_pkg.c_debugging $then
  dbug.enter('ui_user_management_pkg.get_role');
  dbug.print(dbug."input", 'p_app_user: %s; p_app_id: %s', p_app_user, p_app_id);
$end

  l_build_option_value :=
    apex_util.get_build_option_status
    ( p_application_id => p_app_id
    , p_build_option_name => "USE_APEX_GROUPS"
    );

$if cfg_pkg.c_debugging $then
  dbug.print(dbug."info", 'l_build_option_value: %s', l_build_option_value);
$end

  begin
    if upper(substr(l_build_option_value, 1, 1)) = 'I' -- Include: True
    then
      l_role := apex_util.get_groups_user_belongs_to(p_username => p_app_user);
    else
      open l_cursor for q'[
      select  usr.profil
      from    users_tbl usr
      where   upper(usr.login) = :1]' using p_app_user;
      fetch l_cursor into l_role;
      if not(l_cursor%found)
      then
        close l_cursor;
        raise no_data_found;
      else
        fetch l_cursor into l_role;
        if l_cursor%found
        then
          close l_cursor;
          raise too_many_rows;
        else
          close l_cursor;
        end if;
      end if;
    end if;
  exception
    when no_data_found or too_many_rows
    then
      l_role := null;
  end;

$if cfg_pkg.c_debugging $then
  dbug.print(dbug."output", 'return: %s', l_role);
  dbug.leave;
$end

  return l_role;
$if cfg_pkg.c_debugging $then
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end get_role;

procedure reset_passwords
( p_user_tab in apex_application_global.vc_arr2
)
is
  l_workspace_id constant apex_applications.workspace_id%type := sys_context('APEX$SESSION', 'WORKSPACE_ID');
begin
$if cfg_pkg.c_debugging $then
  dbug.enter('ui_user_management_pkg.reset_passwords');
  dbug.print(dbug."input", 'p_user_tab.count: %s', p_user_tab.count);
$end

  -- Borrowed from Salary Planning.
  
  -- Create an Apex admin session
  wwv_flow_api.set_security_group_id(l_workspace_id);

  for i_idx in 1..p_user_tab.count
  loop
    reset_password
    ( p_username => upper(p_user_tab(i_idx))
    , p_message => apex_lang.message(p_name => 'PSQL9')
    , p_workspace_id => l_workspace_id
    , p_use_current_session => 1 -- BR-13 When an application user is created no email is received by the user created.
    );
  end loop;

  -- return the number of emails sent
  htp.prn(p_user_tab.count);
  
$if cfg_pkg.c_debugging $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end reset_passwords;

procedure reset_password
( p_username in varchar2
, p_message in varchar2
, p_workspace_id in number
, p_use_current_session in integer
)
is
  l_procedure_name constant varchar2(30 char) := upper('reset_password');
  l_job_name constant varchar2(30 char) := 'UI_RESET_PWD_JOB'; -- do not use the same name for the job and procedure
  l_found pls_integer;
  l_users_rec t_users_rec;
begin
$if cfg_pkg.c_debugging $then
  dbug.enter('UI_USER_MANAGEMENT_PKG.' || l_procedure_name);
  dbug.print
  ( dbug."input"
  , 'p_username: %s; p_message: %s; p_workspace_id: %s; p_use_current_session: %s'
  , p_username
  , p_message
  , p_workspace_id
  , p_use_current_session
  );
$end

  if p_use_current_session != 0
  then
    apex_util.set_security_group_id(p_workspace_id);
    
    apex_util.reset_pw
    ( p_user => p_username
    , p_msg => p_message
    );
    -- The change_password_on_first_use property is now Y

    select  t.*
    into    l_users_rec
    from    table
            ( ui_user_management_pkg.show_users(p_username)
            ) t
    ;
            
    -- Set change_password_on_first_use to N by this procedure
    dml_apex_user
    ( p_action => 'U'
    , p_user_name => l_users_rec.user_name
    , p_last_name => l_users_rec.last_name
    , p_first_name => l_users_rec.first_name
    , p_email => l_users_rec.email
    , p_account_expiry => l_users_rec.account_expiry
    , p_account_locked => l_users_rec.account_locked
    , p_is_admin => l_users_rec.is_admin
    , p_is_application_developer => l_users_rec.is_application_developer
    , p_group_name => l_users_rec.group_name
    , p_first_schema_provisioned => l_users_rec.first_schema_provisioned
    );

    apex_mail.push_queue; -- send all emails: does an implicit commit  
  else
    -- p_use_current_session = 0
    
    -- Should we create the job?
    begin
      select  1
      into    l_found
      from    user_scheduler_jobs
      where   job_name = l_job_name;
    exception
      when no_data_found
      then
        -- this call does an implicit commit
        dbms_scheduler.create_job
        ( job_name => l_job_name
        , job_type => 'STORED_PROCEDURE'
        , job_action => 'UI_USER_MANAGEMENT_PKG.' || l_procedure_name
        , number_of_arguments => 4
        , enabled => false
        );
        -- so now the job exists
    end;
    
    -- the job exists either before the call to reset_password or it has been created just right now
    dbms_scheduler.set_job_argument_value
    ( job_name => l_job_name
    , argument_position => 1
    , argument_value => p_username
    );
    dbms_scheduler.set_job_argument_value
    ( job_name => l_job_name
    , argument_position => 2
    , argument_value => p_message
    );
    dbms_scheduler.set_job_argument_value
    ( job_name => l_job_name
    , argument_position => 3
    , argument_value => p_workspace_id
    );
    dbms_scheduler.set_job_argument_value
    ( job_name => l_job_name
    , argument_position => 4
    , argument_value => 1
    );
    -- this call does an implicit commit
    dbms_scheduler.run_job
    ( job_name => l_job_name
    , use_current_session => false
    );
  end if;
  
$if cfg_pkg.c_debugging $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end reset_password;

procedure dml_apex_user
( p_action in varchar2
, p_user_name in apex_workspace_apex_users.user_name%type
, p_last_name in apex_workspace_apex_users.last_name%type
, p_first_name in apex_workspace_apex_users.first_name%type
, p_email in apex_workspace_apex_users.email%type
, p_account_expiry in apex_workspace_apex_users.account_expiry%type
, p_account_locked in apex_workspace_apex_users.account_locked%type
, p_is_admin in apex_workspace_apex_users.is_admin%type
, p_is_application_developer in apex_workspace_apex_users.is_application_developer%type
, p_group_name in apex_workspace_group_users.group_name%type
, p_first_schema_provisioned in apex_workspace_apex_users.first_schema_provisioned%type
)
is
  l_user_id number := null;
  l_group_id number := null;
  
  l_developer_privs constant varchar2(100 char) :=
    case
      when 'Y' in (substr(p_is_admin, 1, 1))
      then 'ADMIN:'
    end ||
    case
      when 'Y' in (substr(p_is_admin, 1, 1), substr(p_is_application_developer, 1, 1))
      then 'CREATE:DATA_LOADER:EDIT:HELP:MONITOR:SQL'
    end;
  l_procedure_name constant varchar2(30 char) := upper('dml_apex_user');
begin
$if cfg_pkg.c_debugging $then
  dbug.enter('UI_USER_MANAGEMENT_PKG.' || l_procedure_name);
  dbug.print
  ( dbug."input"
  , 'p_action: %s; p_user_name: %s; p_last_name: %s; p_first_name: %s; p_email: %s'
  , p_action
  , p_user_name
  , p_last_name
  , p_first_name
  , p_email
  );
  dbug.print
  ( dbug."input"
  , 'p_account_expiry: %s; p_account_locked: %s'
  , p_account_expiry
  , p_account_locked
  );
$end

  if p_group_name is not null and p_action != 'D'
  then
    l_group_id := apex_util.get_group_id(p_group_name);
    if l_group_id is null
    then
      apex_util.create_user_group(p_group_name => p_group_name);
      l_group_id := apex_util.get_group_id(p_group_name);
    end if;
  end if;

  case p_action
    when 'I'
    then
      -- Create Apex user if necessary
      apex_util.create_user
      ( p_user_name => upper(p_user_name)
      , p_first_name => p_first_name
      , p_last_name => p_last_name
      , p_email_address => p_email
      , p_web_password => 'TOOLS'
      , p_developer_privs => l_developer_privs
      , p_account_expiry => p_account_expiry
      , p_account_locked => substr(p_account_locked, 1, 1)
      , p_change_password_on_first_use => 'Y'
      , p_default_schema => p_first_schema_provisioned
      , p_group_ids => to_char(l_group_id)
      );
    
    when 'U'
    then
      l_user_id := apex_util.get_user_id(upper(p_user_name));

      apex_util.edit_user
      ( p_user_id => l_user_id
      , p_user_name => upper(p_user_name)
      , p_first_name => p_first_name
      , p_last_name => p_last_name
      , p_email_address => p_email
      , p_developer_roles => l_developer_privs
      , p_account_expiry => p_account_expiry
      , p_account_locked => substr(p_account_locked, 1, 1)
      , p_change_password_on_first_use => 'N'
      , p_default_schema => p_first_schema_provisioned
      , p_group_ids => to_char(l_group_id)
      );
      
    when 'D'
    then
      apex_util.remove_user
      ( p_user_name => upper(p_user_name)
      );
      
  end case;

$if cfg_pkg.c_debugging $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end dml_apex_user;

end ui_user_management_pkg;
/
