CREATE OR REPLACE PACKAGE BODY "UI_APEX_SYNCHRONIZE" IS

-- LOCAL

g_max_number_of_translations constant pls_integer := 1000;

cursor c_translations
( b_primary_application_id in apex_application_trans_map.primary_application_id%type
) is
select  t1.primary_application_id
,       t1.translated_app_language
,       t1.translated_application_id
from    apex_application_trans_map t1
where   t1.primary_application_id = b_primary_application_id
order by
        t1.primary_application_id
,       -- first the translated application id that are already in the range and then in ascending order so they get mapped to t1.primary_application_id * g_max_number_of_translations + 1, t1.primary_application_id * g_max_number_of_translations + 2 and so on
        -- next the translated application id that are NOT yet in the range and then in ascending order so they get a number higher than the ones already in the range
        case
          when t1.translated_application_id between t1.primary_application_id * g_max_number_of_translations + 1
                                                and t1.primary_application_id * g_max_number_of_translations + g_max_number_of_translations - 1
          then 0
          else 1
        end asc
,       t1.translated_application_id asc
,       t1.translated_app_language;

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
    dbms_output.put_line(sqlerrm);    
    if c_translations%isopen
    then
      close c_translations;
    end if;
    raise;
end get_translations;

procedure open_apex_session
( p_application_id in apex_application_trans_map.primary_application_id%type
)
is
  cursor c_apex_info(b_application_id in apex_application_trans_map.primary_application_id%type)
  is
    select  r.api_compatibility -- 2024.11.30
    ,       r.version_no -- 24.2.9
    ,       a.workspace_id
    ,       a.owner
    from    apex_release r
            cross join apex_applications a
    where   a.application_id = b_application_id;

  r_apex_info c_apex_info%rowtype;
begin
  dbms_output.put_line('*** ui_apex_synchronize.open_apex_session ***');
  dbms_output.put_line('application id: ' || p_application_id);
  
  /*
  -- Prevent an error like this:
  --
  -- Error report -
  -- ORA-20987: APEX - An API call has been prohibited.
  -- Contact your administrator.
  -- Details about this incident are available via debug id "1293648". - Contact your application administrator.
  --
  -- Solution: reuse part of application/delete_application.sql, i.e. wwv_flow_imp.component_begin/wwv_flow_imp.component_end
  */
  open c_apex_info(p_application_id);
  fetch c_apex_info into r_apex_info;
  if c_apex_info%notfound
  then
    close c_apex_info;
    raise no_data_found;
  else
    close c_apex_info; -- OK
  end if;
    
  apex_application_install.generate_offset;

  dbms_output.put_line('offset        : ' || apex_application_install.get_offset);

  wwv_flow_imp.component_begin
  ( p_version_yyyy_mm_dd => r_apex_info.api_compatibility
  , p_release => r_apex_info.version_no
  , p_default_workspace_id => r_apex_info.workspace_id
  , p_default_application_id => p_application_id
  , p_default_id_offset => apex_application_install.get_offset
  , p_default_owner => r_apex_info.owner
  );
end open_apex_session;

procedure close_apex_session
( p_application_id in apex_application_trans_map.primary_application_id%type
)
is
  cursor c_apex_info(b_application_id in apex_application_trans_map.primary_application_id%type)
  is
    select  a.workspace_id
    ,       a.owner
    from    apex_release r
            cross join apex_applications a
    where   a.application_id = b_application_id;

  r_apex_info c_apex_info%rowtype;
begin
  dbms_output.put_line('*** ui_apex_synchronize.close_apex_session ***');

  open c_apex_info(p_application_id);
  fetch c_apex_info into r_apex_info;
  if c_apex_info%notfound
  then
    close c_apex_info;
    raise no_data_found;
  else
    close c_apex_info; -- OK
  end if;

  wwv_flow_imp.component_end;
end close_apex_session;

function get_workspace_id
( p_workspace_name in apex_workspaces.workspace%type
)
return apex_workspaces.workspace_id%type
is
  l_workspace_id apex_workspaces.workspace_id%type;
begin
  select  workspace_id
  into    l_workspace_id
  from    apex_workspaces
  where   workspace = upper(p_workspace_name);

  return l_workspace_id;
end get_workspace_id;

/*
 *
 * This code in wwv_flow_lang may cause an error:
 *
 * 2821     UPDATE WWV_FLOW_TRANSLATABLE_TEXT$
 * 2822        SET TRANSLATED_FLOW_ID = P_NEW_TRANS_APPLICATION_ID,
 * 2823            TRANSLATE_TO_ID = TO_NUMBER(TRANSLATE_FROM_ID || NVL(WWV_FLOW.G_NLS_DECIMAL_SEPARATOR,'.') || P_NEW_TRANS_APPLICATION_ID)
 * 2824      WHERE SECURITY_GROUP_ID = WWV_FLOW_SECURITY.G_SECURITY_GROUP_ID
 * 2825        AND TRANSLATED_FLOW_ID = L_OLD_TRANS_APPLICATION_ID
 * 2826        AND FLOW_ID = P_APPLICATION_ID;
 *
 */
procedure set_nls_numeric_characters
is
  l_nls_numeric_characters varchar2(2);
  l_command varchar2(32767);
begin
  -- to solve ORA-01722 in apex_lang.publish_application()
  
  case nvl(WWV_FLOW.G_NLS_DECIMAL_SEPARATOR,'.')
    when '.'
    then
      l_nls_numeric_characters := '.,';
      
    when ','
    then
      l_nls_numeric_characters := ',.';
  end case;
  
  l_command := utl_lms.format_message(q'[alter session set nls_numeric_characters = '%s']', l_nls_numeric_characters);

  dbms_output.put_line(l_command);
 
  execute immediate l_command;
end set_nls_numeric_characters;

procedure update_language_mapping
( p_application_id in apex_application_trans_map.primary_application_id%type
)
is
  l_translations_tab t_translations_tab;
  l_new_trans_application_id apex_application_trans_map.translated_application_id%type := p_application_id * g_max_number_of_translations;
begin
  set_nls_numeric_characters;

  dbms_output.put_line('*** ui_apex_synchronize.update_language_mapping ***');

  get_translations(p_application_id, l_translations_tab);

  if l_translations_tab.count > 0
  then
    for i_idx in l_translations_tab.first .. l_translations_tab.last
    loop
      l_new_trans_application_id := l_new_trans_application_id + 1;
        
      dbms_output.put_line('primary application id         : ' || l_translations_tab(i_idx).primary_application_id);
      dbms_output.put_line('translated application language: ' || l_translations_tab(i_idx).translated_app_language);
      dbms_output.put_line('translated application id      : ' || l_translations_tab(i_idx).translated_application_id);
      dbms_output.put_line('new translated application id  : ' || l_new_trans_application_id);
        
      apex_lang.update_language_mapping
      ( p_application_id => l_translations_tab(i_idx).primary_application_id
      , p_language => l_translations_tab(i_idx).translated_app_language
      , p_new_trans_application_id => l_new_trans_application_id
      );
    end loop;
  end if;
end update_language_mapping;

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
  dbms_output.put_line('*** ui_apex_synchronize.pre_export ***');
  dbms_output.put_line('workspace name: ' || p_workspace_name);
  dbms_output.put_line('application id: ' || p_application_id);
  
  l_workspace_id := get_workspace_id(p_workspace_name);

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
    dbms_output.put_line(sqlerrm);    
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
  dbms_output.put_line('*** ui_apex_synchronize.pre_import ***');
  dbms_output.put_line('application id: ' || p_application_id);
  
  open_apex_session(p_application_id);
  
  apex_util.set_application_status
  ( p_application_id => p_application_id
  , p_application_status => l_application_status
  , p_unavailable_value => 'Updating application'
  );

  close_apex_session(p_application_id);
exception
  when e_apex_error or no_data_found
  then
    dbms_output.put_line(sqlerrm);
    close_apex_session(p_application_id);
  when others
  then
    close_apex_session(p_application_id);
    raise;
end pre_import;

procedure prepare_import
( p_workspace_name in apex_workspaces.workspace%type
, p_application_id in apex_applications.application_id%type
, p_user in apex_applications.owner%type
, p_application_alias in apex_applications.alias%type
)
is
  l_workspace_id number;
begin
  dbms_output.put_line('*** ui_apex_synchronize.prepare_import ***');
  dbms_output.put_line('workspace name   : ' || p_workspace_name);
  dbms_output.put_line('application id   : ' || p_application_id);
  dbms_output.put_line('user             : ' || p_user);
  dbms_output.put_line('application alias: ' || p_application_alias);
  
  l_workspace_id := get_workspace_id(p_workspace_name);
  
  apex_application_install.set_workspace_id(l_workspace_id);
  apex_application_install.set_application_id(p_application_id);
  if p_application_alias is not null
  then
    apex_application_install.set_application_alias(p_application_alias);
  end if;
  apex_application_install.generate_offset;
  dbms_output.put_line('offset           : ' || apex_application_install.get_offset);
  apex_application_install.set_schema(p_user);
end prepare_import;

procedure publish_application
( p_application_id in apex_application_trans_map.primary_application_id%type
, p_workspace_id in apex_workspaces.workspace_id%type
, p_workspace_name in apex_workspaces.workspace%type
)
is
  l_nr naturaln := 0;
  l_new_trans_application_id apex_application_trans_map.translated_application_id%type := p_application_id * g_max_number_of_translations;
begin
  dbms_output.put_line('*** ui_apex_synchronize.publish_application ***');
  
  set_nls_numeric_characters;

  dbms_output.put_line('application id  : ' || p_application_id);
  dbms_output.put_line('workspace name  : ' || p_workspace_name);
  dbms_output.put_line('workspace id    : ' || p_workspace_id);

  if p_workspace_id is not null
  then
    apex_util.set_security_group_id(p_workspace_id);
  elsif p_workspace_name is not null
  then
    apex_util.set_security_group_id(get_workspace_id(p_workspace_name));
  end if;

  dbms_output.put_line('*** publish application ***');
  
  for r in c_translations(p_application_id)
  loop
    l_new_trans_application_id := l_new_trans_application_id + 1;

    dbms_output.put_line('primary application id         : ' || r.primary_application_id);
    dbms_output.put_line('translated application language: ' || r.translated_app_language);
    dbms_output.put_line('translated application id      : ' || r.translated_application_id);
    dbms_output.put_line('new translated application id  : ' || l_new_trans_application_id);

    apex_lang.publish_application
    ( p_application_id => r.primary_application_id
    , p_language => r.translated_app_language
    , p_new_trans_application_id => l_new_trans_application_id
    );
  end loop;
  
  dbms_output.put_line(chr(10));
exception
  when others
  then
    dbms_output.put_line(sqlerrm);
    raise;
end publish_application;

procedure post_import
( p_application_id in apex_application_trans_map.primary_application_id%type
)
is
  l_application_status constant varchar2(100) := 'AVAILABLE_W_EDIT_LINK';
begin
  dbms_output.put_line('*** ui_apex_synchronize.post_import ***');
  dbms_output.put_line('application id: ' || p_application_id);
  
  open_apex_session(p_application_id);

  apex_util.set_application_status
  ( p_application_id => p_application_id
  , p_application_status => l_application_status
  );
  
  close_apex_session(p_application_id);  
exception  
  when others
  then
    close_apex_session(p_application_id);
    raise;
end post_import;

end ui_apex_synchronize;
/

