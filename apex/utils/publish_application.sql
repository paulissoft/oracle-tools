prompt (publish_application.sql)

-- precondition: prepare_import.sql must have been called

-- to solve ORA-01722 in apex_lang.update_language_mapping()
alter session set nls_numeric_characters = '.,';

set feedback off

declare
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
begin
  dbms_output.put_line('workspace id    : ' || wwv_flow_application_install.get_workspace_id);
  dbms_output.put_line('application id  : ' || wwv_flow_application_install.get_application_id);

  apex_util.set_security_group_id(wwv_flow_application_install.get_workspace_id);

  dbms_output.put_line('*** update_language_mapping ***');
  
  for r in c_translations(wwv_flow_application_install.get_application_id)
  loop    
    dbms_output.put_line('primary_application_id  : ' || r.primary_application_id);
    dbms_output.put_line('translated_app_language : ' || r.translated_app_language);
    dbms_output.put_line('new_trans_application_id: ' || r.new_trans_application_id);
    
    if r.translated_application_id != r.new_trans_application_id
    then
      apex_lang.update_language_mapping
      ( p_application_id => r.primary_application_id
      , p_language => r.translated_app_language
      , p_new_trans_application_id => r.new_trans_application_id
      );
    end if;
  end loop;

  commit;
       
  dbms_output.put_line('*** publish application ***');
  
  for r in c_translations(wwv_flow_application_install.get_application_id)
  loop
    dbms_output.put_line('primary_application_id  : ' || r.primary_application_id);
    dbms_output.put_line('translated_app_language : ' || r.translated_app_language);
    dbms_output.put_line('new_trans_application_id: ' || r.new_trans_application_id);

    apex_lang.publish_application
    ( p_application_id => r.primary_application_id
    , p_language => r.translated_app_language
    );
  end loop;
  
  dbms_output.put_line(chr(10));

  commit;
exception
  when others
  then
    dbms_output.put_line(substr(sqlerrm, 1, 255));
    raise;
end;
/
