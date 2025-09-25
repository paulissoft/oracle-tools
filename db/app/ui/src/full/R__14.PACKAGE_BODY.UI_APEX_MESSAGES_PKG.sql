CREATE OR REPLACE PACKAGE BODY "UI_APEX_MESSAGES_PKG" 
as

g_package_name constant varchar2(61 char) := $$PLSQL_UNIT;

-- are we running Apex or some other SQL client?
g_running_apex constant boolean := sys_context('APEX$SESSION', 'APP_SESSION') is not null;

-- last created Apex session (only when not running Apex)
g_application_id number := null;

procedure check_active_apex_session
is
begin
  -- Check that the Apex session is there
  if sys_context('APEX$SESSION', 'APP_SESSION') is null
  then
    raise_application_error(-20000, 'There is no active Apex session (use UI_APEX_MESSAGES_PKG.INIT()).');
  end if;
end check_active_apex_session;

function get_message
( p_application_id in number
, p_name           in varchar2
, p_language       in varchar2
)
return number
is
  l_id apex_application_translations.translation_entry_id%type := null;

  l_module_name constant varchar2(61 char) := g_package_name || '.' || 'GET_MESSAGE';
begin
$if cfg_pkg.c_debugging $then
  dbug.enter(l_module_name);
  dbug.print
  ( dbug."input"
  , 'p_application_id: %s; p_name: %s; p_language: %s'
  , p_application_id
  , p_name
  , p_language
  );
$end

  select  aat.translation_entry_id
  into    l_id
  from    apex_application_translations aat
  where   aat.application_id = p_application_id
  and     aat.translatable_message = p_name
  and     aat.language_code = lower(p_language) -- GJP 2021-01-26
  ;

$if cfg_pkg.c_debugging $then
  dbug.print(dbug."output", 'return: %s', l_id);
  dbug.leave;
$end

  return l_id;

$if cfg_pkg.c_debugging $then  
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end get_message;

-- GLOBAL

procedure init
( p_application_id in number
, p_app_user in varchar2
, p_app_page_id in number
)
is
begin
  -- We need an Apex session otherwise nothing works.
  if g_running_apex
  then
    null; -- we will never create an Apex session if we are already in Apex
  elsif p_application_id is null
  then
    raise_application_error(-20000, 'Can not initialise an Apex session without an application id.');
  elsif g_application_id = p_application_id
  then
    null;
  else
    ui_session_pkg.create_apex_session
    ( p_app_id => p_application_id
    , p_app_user => p_app_user
    , p_app_page_id => p_app_page_id
    );
    check_active_apex_session;
    g_application_id := p_application_id;
  end if;
end init;

function get_messages
( p_application_id in number
, p_name           in varchar2
, p_language       in varchar2
)
return t_tab
pipelined
is
begin
  for r in
  ( select  aat.application_id 
    ,       aat.translatable_message as name
    ,       aat.language_code as language
    ,       aat.message_text as message_text
    ,       aat.translation_entry_id as id
    from    apex_application_translations aat
    where   ( p_application_id is null or aat.application_id = p_application_id )
    and     ( p_name is null or aat.translatable_message = p_name )
    and     ( p_language is null or aat.language_code = lower(p_language) )
    order by
            application_id
    ,       name
    ,       language_code
  )
  loop
    pipe row (r);
  end loop;
  
  return; -- essential
end get_messages;

procedure insert_message
( p_application_id in number
, p_name           in varchar2
, p_language       in varchar2
, p_message_text   in varchar2
)
is
begin
  check_active_apex_session;
  
  apex_lang.create_message
  ( p_application_id => p_application_id
  , p_name => p_name
  , p_language => lower(p_language)
  , p_message_text => p_message_text
  );    
end insert_message;

procedure update_message
( p_application_id in number
, p_name           in varchar2
, p_language       in varchar2
, p_message_text   in varchar2
)
is
begin
  check_active_apex_session;

  apex_lang.update_message
  ( p_id => get_message
            ( p_application_id => p_application_id
            , p_name => p_name
            , p_language => p_language
            )
  , p_message_text => p_message_text
  );
end update_message;

procedure merge_message
( p_application_id in number
, p_name           in varchar2
, p_language       in varchar2
, p_message_text   in varchar2
)
is
begin
  begin
    update_message
    ( p_application_id => p_application_id
    , p_name => p_name
    , p_language => p_language
    , p_message_text => p_message_text
    );
  exception
    when no_data_found
    then
      insert_message
      ( p_application_id => p_application_id
      , p_name => p_name
      , p_language => p_language
      , p_message_text => p_message_text
      );    
  end;
end merge_message;

procedure delete_message
( p_application_id in number
, p_name           in varchar2
, p_language       in varchar2
)
is
begin
  check_active_apex_session;

  apex_lang.delete_message
  ( p_id => get_message
            ( p_application_id => p_application_id
            , p_name => p_name
            , p_language => p_language
            )
  );
end delete_message;

procedure dml
( p_action         in varchar2
, p_application_id in number
, p_name           in varchar2
, p_language       in varchar2
, p_message_text   in varchar2
, p_id             in out nocopy number
)
is
  l_module_name constant varchar2(61 char) := g_package_name || '.' || 'DML';
begin
$if cfg_pkg.c_debugging $then
  dbug.enter(l_module_name);
  dbug.print
  ( dbug."input"
  , 'p_action: %s; p_application_id: %s; p_name: %s; p_language: %s; p_message_text: %s'
  , p_action
  , p_application_id
  , p_name
  , p_language
  , p_message_text
  );
  dbug.print(dbug."input", 'p_id: %s', p_id);
$end

  if p_action in ('U', 'D') and p_id is null
  then
    raise value_error;
  elsif p_action = 'U' and p_message_text is null
  then
    raise value_error;
  end if;  

  case p_action
    when 'I'
    then
      -- GJP 2023-04-01
      -- This is what you get for a duplicate create_message on APEX 22.2:
      --
      -- ORA-06502: PL/SQL: numeric or value error: character to number conversion error
      -- ORA-06512: at "APEX_220200.WWV_IMP_UTIL", line 131
      -- ORA-06512: at "APEX_220200.WWV_FLOW_IMP_SHARED", line 103
      -- ORA-06512: at "APEX_220200.WWV_FLOW_IMP_SHARED", line 6407
      -- ORA-06512: at "APEX_220200.WWV_FLOW_IMP_SHARED", line 6400
      -- ORA-06512: at "APEX_220200.WWV_FLOW_LANG", line 1177
      -- ORA-06512: at "APEX_220200.HTMLDB_LANG", line 157
      -- ORA-06512: at "UI_APEX_MESSAGES_PKG", line 248
      --
      -- In order to mimic the old behaviour (dup_val_on_index):
      -- 1. first get the mssage id
      --    a. if found raise dup_val_on_index
      --    b. if not found (no_data_found) just add it
      -- 2. get the message id again
      <<try_loop>>
      for i_try in 1..2
      loop
        begin
          p_id := get_message(p_application_id => p_application_id, p_name => p_name, p_language => p_language);
          if i_try = 1 then raise dup_val_on_index; end if;
          exit try_loop;
        exception
          when no_data_found
          then
            if i_try = 2 then raise; end if;
            apex_lang.create_message
            ( p_application_id => p_application_id
            , p_name => p_name
            , p_language => lower(p_language)
            , p_message_text => p_message_text
            );
        end;
      end loop try_loop;
    when 'U'
    then
      apex_lang.update_message
      ( p_id => p_id
      , p_message_text => p_message_text
      );
      
    when 'D'
    then
      apex_lang.delete_message( p_id => p_id );
      p_id := null;
  end case;

$if cfg_pkg.c_debugging $then
  dbug.print(dbug."output", 'p_id: %s', p_id);
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end dml;

$if cfg_pkg.c_testing $then

procedure ut_setup
is
  pragma autonomous_transaction; -- due to init()
  
  l_module_name constant varchar2(61 char) := g_package_name || '.' || 'UT_SETUP';
begin
$if cfg_pkg.c_debugging $then
  dbug.enter(l_module_name);
$end

  init(to_number('200'));
  commit;

$if cfg_pkg.c_debugging $then
  dbug.leave;
$end
end ut_setup;

procedure ut_teardown
is
  l_module_name constant varchar2(61 char) := g_package_name || '.' || 'UT_TEARDOWN';
begin
$if cfg_pkg.c_debugging $then
  dbug.enter(l_module_name);
$end

  null;

$if cfg_pkg.c_debugging $then
  dbug.leave;
$end
end ut_teardown;

procedure ut_dml
is
  l_max_tries constant pls_integer := 9;

  l_action varchar2(1);
  -- 200 is a Flyway placeholder but when you run this in SQL Developer it will not be replaced
  l_application_id constant number := g_application_id;
  l_name varchar2(100 char);
  l_language varchar2(10 char);
  l_message_text varchar2(4000 char);
  l_id number;
  l_expect_message varchar2(100);
  
  l_module_name constant varchar2(61 char) := g_package_name || '.' || 'UT_DML';
begin
$if cfg_pkg.c_debugging $then
  dbug.enter(l_module_name);
$end

  for i_try in 1..l_max_tries
  loop
    begin
      l_expect_message := 'i_try: ' || to_char(i_try);
$if cfg_pkg.c_debugging $then
      dbug.print(dbug."info", 'i_try: %s', i_try);
$end

      case i_try
        -- Insert
        when 1 then l_action := 'I'; l_name := upper(l_module_name); l_language := 'en'; l_message_text := 'test'; -- OK
        when 2 then null;                                                                                          -- duplicate
        when 3 then l_language := 'fr';                                                                            -- OK
        when 4 then l_language := 'FR';                                                                            -- duplicate
        when 5 then l_name := l_name || '.TEST';                                                                   -- OK
        -- Update
        when 6 then l_action := 'U'; l_message_text := rpad('X', 4000, 'X');                                       -- OK
        when 7 then l_name := upper(l_module_name); l_message_text := rpad('Y', 4000, 'Y'); l_language := 'en';    -- OK
                    l_id := get_message(l_application_id, l_name, l_language);  
        -- Delete            
        when 8 then l_action := 'D';                                                                               -- OK 
        when 9 then l_name := l_name || '.TEST'; l_language := 'fr';                                               -- OK
                    l_id := get_message(l_application_id, l_name, l_language);
      end case;

      case l_action
        when 'I' then dml(l_action, l_application_id, l_name, l_language, l_message_text, l_id);
        when 'U' then dml(p_action => l_action, p_message_text => l_message_text, p_id => l_id);
        when 'D' then dml(p_action => l_action, p_id => l_id);
      end case;

      if l_action in ('I', 'U')
      then
        ut.expect(l_id, l_expect_message).to_equal(get_message(l_application_id, l_name, l_language));
      else
        ut.expect(l_id, l_expect_message).to_be_null;
        l_id := get_message(l_application_id, l_name, l_language); -- should raise no_data_found
        raise program_error;
      end if;      
    exception
      when others
      then
        ut.expect(sqlcode, l_expect_message).to_equal(case
                                                        when i_try in (2, 4)
                                                        then -1  -- when_dup_val_on_index
                                                        when i_try in (8, 9)
                                                        then 100 -- no_data_found                         
                                                      end);
    end;
  end loop;

$if cfg_pkg.c_debugging $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end ut_dml;

procedure ut_dml_update_null_id
is
  l_id number := null;
begin
  dml(p_action => 'U', p_id => l_id);  
end ut_dml_update_null_id;

procedure ut_dml_update_null_message_text
is
  l_id number := 0;
begin
  dml(p_action => 'U', p_id => l_id);
end ut_dml_update_null_message_text;  

procedure ut_dml_delete_null_id
is
  l_id number := null;
begin  
  dml(p_action => 'D', p_id => l_id);
end ut_dml_delete_null_id;
 
$end

end ui_apex_messages_pkg;
/

