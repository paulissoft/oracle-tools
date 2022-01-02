create or replace package body ui_apex_synchronize is

-- LOCAL

cursor c_translations
( b_primary_application_id in apex_application_trans_map.primary_application_id%type
) is
  select  t.primary_application_id
  ,       t.translated_app_language
  ,       t.translated_application_id
  ,       t.primary_application_id * 100
          + (row_number() over (partition by t.primary_application_id order by t.translated_app_language)) as new_trans_application_id
  from    apex_application_trans_map t
  where   t.primary_application_id = b_primary_application_id
  order by
          t.primary_application_id
  ,       t.translated_app_language;

type t_translations_tab is table of c_translations%rowtype;

procedure get_translations
( p_application_id in apex_application_trans_map.primary_application_id%type
, p_translations_tab in out nocopy t_translations_tab
)
is
begin
  open c_translations(p_application_id);
  fetch c_translations bulk collect into p_translations_tab;
  close c_translations;
exception
  when others
  then
    if c_translations%isopen
    then
      close c_translations;
    end if;
    raise;
end get_translations;

procedure update_language_mapping
( p_application_id in apex_application_trans_map.primary_application_id%type
)
is
  l_translations_tab t_translations_tab;
begin
  -- to solve ORA-01722 in apex_lang.update_language_mapping()
  execute immediate q'[alter session set nls_numeric_characters = '.,']';

  dbms_output.put_line('*** update language mapping ***');

  get_translations(p_application_id, l_translations_tab);

  if l_translations_tab.count > 0
  then
    for i_idx in l_translations_tab.first .. l_translations_tab.last
    loop
      savepoint spt;
      
      begin
        if l_translations_tab(i_idx).translated_application_id != l_translations_tab(i_idx).new_trans_application_id
        then      
          dbms_output.put_line('translated application id      : ' || l_translations_tab(i_idx).translated_application_id);
          dbms_output.put_line('translated application language: ' || l_translations_tab(i_idx).translated_app_language);
          dbms_output.put_line('new translated application id  : ' || l_translations_tab(i_idx).new_trans_application_id);
          
          apex_lang.update_language_mapping
          ( p_application_id => l_translations_tab(i_idx).primary_application_id
          , p_language => l_translations_tab(i_idx).translated_app_language
          , p_new_trans_application_id => l_translations_tab(i_idx).new_trans_application_id
          );
        end if;
      exception
        when others
        then
          rollback to spt;
          dbms_output.put_line(substr('error ignored: ' || sqlerrm, 1, 255));
          -- ignore the error
      end;
    end loop;
  end if;
end update_language_mapping;

procedure create_apex_session
( p_application_id in apex_application_trans_map.primary_application_id%type
)
is
  l_username constant varchar2(30) := 'ADMIN';
begin
$if dbms_db_version.ver_le_12 $then

  /* apex_session.create_session does not exist for Apex 5.1 */

  ui_session_pkg.create_apex_session
  ( p_app_id => p_application_id
  , p_app_user => l_username
  , p_app_page_id => 1
  );

$else

  apex_session.create_session
  ( p_app_id => p_application_id
  , p_page_id => 1
  , p_username => l_username
  );

$end

end create_apex_session;

-- GLOBAL

procedure pre_export
( p_workspace_name in apex_workspaces.workspace%type
, p_application_id in apex_application_trans_map.primary_application_id%type
, p_update_language_mapping in boolean
, p_seed_and_publish in boolean
)
is
  l_workspace_id apex_workspaces.workspace_id%type;

  l_translations_tab t_translations_tab;
begin
  dbms_output.put_line('*** pre_export ***');
  dbms_output.put_line('workspace name: ' || p_workspace_name);
  dbms_output.put_line('application id: ' || p_application_id);
  
  select  workspace_id
  into    l_workspace_id
  from    apex_workspaces
  where   workspace = p_workspace_name;

  apex_util.set_security_group_id(l_workspace_id);

  if p_update_language_mapping
  then
    update_language_mapping(p_application_id);
  end if;

  if p_seed_and_publish
  then
    dbms_output.put_line('*** seed and publish ***');

    get_translations(p_application_id, l_translations_tab);

    if l_translations_tab.count > 0
    then
      for i_idx in l_translations_tab.first .. l_translations_tab.last
      loop
        dbms_output.put_line('primary application id: ' || l_translations_tab(i_idx).primary_application_id);
        dbms_output.put_line('language              : ' || l_translations_tab(i_idx).translated_app_language);

        apex_lang.seed_translations
        ( p_application_id => l_translations_tab(i_idx).primary_application_id
        , p_language => l_translations_tab(i_idx).translated_app_language
        );

        apex_lang.publish_application
        ( p_application_id => l_translations_tab(i_idx).primary_application_id
        , p_language => l_translations_tab(i_idx).translated_app_language
        );
      end loop;
    end if;
  end if;

  if p_update_language_mapping or p_seed_and_publish
  then
    dbms_output.put_line(chr(10));
  end if;
exception
  when others
  then
    dbms_output.put_line(substr(sqlerrm, 1, 255));
    raise;
end pre_export;

procedure pre_import
( p_application_id in apex_application_trans_map.primary_application_id%type
)
is
  l_application_status constant varchar2(100) := 'DEVELOPERS_ONLY';
  
  -- ORA-20987: APEX - ERR-1014 Application not found. - Contact your application
  e_apex_error exception;
  pragma exception_init(e_apex_error, -20987);
begin
  create_apex_session(p_application_id);
  
  apex_util.set_application_status
  ( p_application_id => p_application_id
  , p_application_status => l_application_status
  , p_unavailable_value => 'Updating application'
  );
exception
  when e_apex_error or no_data_found
  then
    null;   
end pre_import;

procedure prepare_import
( p_workspace_name in apex_workspaces.workspace%type
, p_application_id in apex_application_trans_map.primary_application_id%type
, p_user in varchar2
)
is
  l_workspace_id number;
begin
  select  workspace_id
  into    l_workspace_id
  from    apex_workspaces
  where   workspace = p_workspace_name;
  
  apex_application_install.set_workspace_id(l_workspace_id);
  apex_application_install.set_application_id(p_application_id);
  apex_application_install.generate_offset;
  apex_application_install.set_schema(p_user);
end prepare_import;

procedure publish_application
is
begin
  -- to solve ORA-01722 in apex_lang.update_language_mapping()
  execute immediate q'[alter session set nls_numeric_characters = '.,']';

  dbms_output.put_line('workspace id    : ' || wwv_flow_application_install.get_workspace_id);
  dbms_output.put_line('application id  : ' || wwv_flow_application_install.get_application_id);

  apex_util.set_security_group_id(wwv_flow_application_install.get_workspace_id);

  update_language_mapping(wwv_flow_application_install.get_application_id);

  dbms_output.put_line('*** publish application ***');
  
  for r in c_translations(wwv_flow_application_install.get_application_id)
  loop
    dbms_output.put_line('primary application id         : ' || r.primary_application_id);
    dbms_output.put_line('translated application language: ' || r.translated_app_language);
    dbms_output.put_line('new translated application id  : ' || r.new_trans_application_id);

    apex_lang.publish_application
    ( p_application_id => r.primary_application_id
    , p_language => r.translated_app_language
    );
  end loop;
  
  dbms_output.put_line(chr(10));
exception
  when others
  then
    dbms_output.put_line(substr(sqlerrm, 1, 255));
    raise;
end publish_application;

procedure post_import
( p_application_id in apex_application_trans_map.primary_application_id%type
)
is
  l_application_status constant varchar2(100) := 'AVAILABLE_W_EDIT_LINK';
begin
  create_apex_session(p_application_id);

  apex_util.set_application_status
  ( p_application_id => p_application_id
  , p_application_status => l_application_status
  );
end post_import;

end ui_apex_synchronize; 
/
