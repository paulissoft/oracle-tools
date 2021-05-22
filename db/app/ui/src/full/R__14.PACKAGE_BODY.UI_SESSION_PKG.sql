create or replace package body ui_session_pkg
as

function get_date_format
return varchar2
is
begin
  return c_date_fmt;
end get_date_format;

function get_nls_numeric_characters
( p_language in varchar2
)
return varchar2
is
begin
  return
    case lower(substr(p_language, 1, 2))
      when 'fr'
      then ', ' /* 1 000,00 for 1000 euros */
      else c_nls_numeric_characters
    end;
end get_nls_numeric_characters;

function get_date
( p_name in varchar2
, p_add_page_prefix in integer
)
return date is
begin
  return to_date(get_string(p_name, p_add_page_prefix), c_date_fmt);
end get_date;
 
function get_number
( p_name in varchar2
, p_add_page_prefix in integer
)
return number is
begin
  return to_number(get_string(p_name, p_add_page_prefix));
end get_number;
 
function get_string
( p_name in varchar2
, p_add_page_prefix in integer
)
return varchar2
is
  l_name varchar2(32767) := null;
  l_string varchar2(32767) := null;
  l_app_page_id constant integer := case when p_add_page_prefix = 1 then to_number(v('APP_PAGE_ID')) end;
begin
  l_name := case when p_add_page_prefix = 1 then 'P' || l_app_page_id || '_' end || p_name;
  l_string := v(l_name);
  
$if cfg_pkg.c_debugging $then
  dbug.enter('ui_session_pkg.get_string');
  dbug.print
  ( dbug."info"
  , 'p_name: %s; p_add_page_prefix: %s; l_name: %s; return: %s'
  , p_name
  , p_add_page_prefix
  , l_name
  , l_string
  );
  dbug.leave;
$end
  
  return l_string;
end get_string;
 
procedure set_date
( p_name in varchar2
, p_value in date := null
)
is
begin
  set_string(p_name, to_char(p_value, c_date_fmt));
end set_date;
  
procedure set_number
( p_name in varchar2
, p_value in number := null
)
is
begin
  set_string(p_name, to_char(p_value));
end set_number;
 
procedure set_string
( p_name in varchar2
, p_value in varchar2 := null
)
is
begin
$if cfg_pkg.c_debugging $then
  dbug.enter('ui_session_pkg.set_string');
  dbug.print
  ( dbug."input"
  , 'p_name: %s; p_value: %s'
  , p_name
  , p_value
  );
$end

  apex_util.set_session_state(p_name, p_value);
  
$if cfg_pkg.c_debugging $then
  dbug.leave;
$end
end set_string;

function cast_to_number
( p_value in varchar2
, p_language in varchar2
)
return number
is
  l_value number;
begin
  begin
    -- start simple
    l_value := to_number(p_value);
  exception
    when value_error
    then
      l_value := to_number(p_value, c_number_fmt, 'nls_numeric_characters=''' || get_nls_numeric_characters(p_language) || '''');
  end;
  
  return l_value;
exception
  when value_error
  then
    raise_application_error
    ( -20000
    , 'Could not convert "' ||
      p_value ||
      '" to number with format "' ||
      c_number_fmt ||
      '" and nls_numeric_characters "' ||
      get_nls_numeric_characters(p_language) ||
      '"'
    , true
    );
end cast_to_number;

function cast_to_date
( p_value in varchar2
)
return date
is
  l_date date;
begin
  l_date := to_date(p_value, c_date_fmt);
  return l_date;
exception
  when value_error
  then
    raise_application_error
    ( -20000
    , 'Could not convert "' ||
      p_value ||
      '" to date with format "' ||
      c_date_fmt ||
      '"'
    , true
    );
end cast_to_date;

function cast_to_varchar2
( p_value in number
, p_language in varchar2
)
return varchar2
is
begin
  return to_char(p_value, c_number_fmt, 'nls_numeric_characters=''' || get_nls_numeric_characters(p_language) || '''');
exception
  when value_error
  then
    raise_application_error
    ( -20000
    , 'Could not convert number "' ||
      p_value ||
      '" to string with format "' ||
      c_number_fmt ||
      '" and nls_numeric_characters "' ||
      get_nls_numeric_characters(p_language) ||
      '"'
    , true
    );
end cast_to_varchar2;

function cast_to_varchar2
( p_value in date
)
return varchar2
is
begin
  return cast_to_varchar2(p_value, c_date_fmt, null);
end cast_to_varchar2;

function cast_to_varchar2
( p_value in date
, p_date_fmt in varchar2 
, p_language in varchar2
)
return varchar2
is
  l_nls_date_language constant varchar2(30) :=
     case lower(substr(p_language, 1, 2))
       when 'en' then 'english'
       when 'fr' then 'french'
       when 'nl' then 'dutch'
       else
         case
           when p_language is not null
           then to_char(1/0)
           else null
         end
     end;
begin
  return case
           when l_nls_date_language is not null
           then to_char(p_value, p_date_fmt, 'nls_date_language = ' || l_nls_date_language)
           else to_char(p_value, p_date_fmt)
         end;
exception
  when value_error
  then
    raise_application_error
    ( -20000
    , 'Could not convert date "' ||
      p_value ||
      '" to string with format "' ||
      p_date_fmt ||
      '" and language "' ||
      p_language ||
      '"'
    , true
    );
end cast_to_varchar2;

procedure create_apex_session
( p_app_id in apex_applications.application_id%type
, p_app_user in apex_workspace_activity_log.apex_user%type
, p_app_page_id in apex_application_pages.page_id%type default 1
)
as
  l_workspace_id apex_applications.workspace_id%type;
  l_cgivar_name  owa.vc_arr;
  l_cgivar_val   owa.vc_arr;
begin
  htp.init;

  l_cgivar_name(1) := 'REQUEST_PROTOCOL';
  l_cgivar_val(1) := 'HTTP';

  owa.init_cgi_env
  ( num_params => 1
  , param_name => l_cgivar_name
  , param_val => l_cgivar_val
  );

  select  workspace_id
  into    l_workspace_id
  from    apex_applications
  where   application_id = p_app_id;

  wwv_flow_api.set_security_group_id(l_workspace_id);

  apex_application.g_instance := 1;
  apex_application.g_flow_id := p_app_id;
  apex_application.g_flow_step_id := p_app_page_id;

  apex_custom_auth.post_login
  ( p_uname => p_app_user
  , p_session_id => null -- could use APEX_CUSTOM_AUTH.GET_NEXT_SESSION_ID
  , p_app_page => apex_application.g_flow_id||chr(58)||p_app_page_id
  );
end create_apex_session;

procedure copy_page_items
( p_page_item_names in varchar2
, p_app_page_id_from in naturaln
, p_app_page_id_to in naturaln
, p_sep in varchar2
)
is
  l_page_item_name_tab apex_t_varchar2;
  l_prefix_from constant varchar2(100) := 'P' || p_app_page_id_from || '_';
  l_prefix_to   constant varchar2(100) := 'P' || p_app_page_id_to   || '_';
begin
$if cfg_pkg.c_debugging $then
  dbug.enter('ui_session_pkg.copy_page_items');
  dbug.print
  ( dbug."input"
  , 'p_page_item_names: %s; p_app_page_id_from: %s; p_app_page_id_to: %s; p_sep: %s'
  , p_page_item_names
  , p_app_page_id_from
  , p_app_page_id_to
  , p_sep
  );
$end

  if p_app_page_id_from = p_app_page_id_to
  then
    raise_application_error
    ( -20000
    , 'Page id from (' || p_app_page_id_from || ') should not be equal to (' || p_app_page_id_to || ')'
    );
  end if;

  l_page_item_name_tab := apex_string.split(p_str => p_page_item_names, p_sep => p_sep);
  
  for i_idx in 1..l_page_item_name_tab.count
  loop
    if substr(l_page_item_name_tab(i_idx), 1, length(l_prefix_from)) = l_prefix_from
    then
      null;
    else
      raise_application_error
      ( -20000
      , 'Page item (' || l_page_item_name_tab(i_idx) || ') should start with "' || l_prefix_from || '"'
      );
    end if;
    
    ui_session_pkg.set_string
    ( -- replacing just the prefix
      l_prefix_to || substr(l_page_item_name_tab(i_idx), 1 + length(l_prefix_from))
    , ui_session_pkg.get_string
      ( p_name => l_page_item_name_tab(i_idx)
      , p_add_page_prefix => 0
      )
    );
  end loop;

$if cfg_pkg.c_debugging $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end copy_page_items;

function prepare_dialog_url
( p_url in varchar2
)
return varchar2
deterministic
is
begin
  return regexp_substr(apex_util.prepare_url( p_url ), 'f\?p=[^'']*');
end prepare_dialog_url;

end ui_session_pkg;
/
