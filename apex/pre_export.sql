-- &1 workspace name
-- &2 application id
-- &3 update language mapping (optional, defaults to 0 - false)
-- &4 seed and publish (optional, defaults to 1 - true)

prompt (pre_export.sql)

whenever sqlerror exit failure

set define on verify off feedback off

column update_language_mapping new_value 3 noprint

-- define 3 if undefined
select  '' as update_language_mapping
from    dual
where   0 = 1;

select  '0' as update_language_mapping
from    dual
where   'X&3' = 'X';

column update_language_mapping clear

column seed_and_publish new_value 4 noprint

-- define 4 if undefined
select  '' as seed_and_publish
from    dual
where   0 = 1;

select  '1' as seed_and_publish
from    dual
where   'X&4' = 'X';

column seed_and_publish clear

declare
  l_workspace_name constant apex_workspaces.workspace%type := upper('&&1');
  l_application_id constant apex_application_trans_map.primary_application_id%type := to_number('&2');
  l_workspace_id apex_workspaces.workspace_id%type;
  l_update_language_mapping constant pls_integer := to_number('&3');
  l_seed_and_publish constant pls_integer := to_number('&4');

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
  select  workspace_id
  into    l_workspace_id
  from    apex_workspaces
  where   workspace = l_workspace_name;

  apex_util.set_security_group_id(l_workspace_id);

  if l_update_language_mapping != 0
  then
    dbms_output.put_line('*** update language mapping ***');
    
    for r in c_translations(l_application_id)
    loop
      savepoint spt;
      
      begin
        if r.translated_application_id != r.new_trans_application_id
        then      
          dbms_output.put_line('translated_application_id: ' || r.translated_application_id);
          dbms_output.put_line('language                 : ' || r.translated_app_language);
          dbms_output.put_line('new_trans_application_id : ' || r.new_trans_application_id);
          
          apex_lang.update_language_mapping
          ( p_application_id => r.primary_application_id
          , p_language => r.translated_app_language
          , p_new_trans_application_id => r.new_trans_application_id
          );
        end if;
      exception
        when others
        then
          rollback to spt;
          dbms_output.put_line(substr(sqlerrm, 1, 255));
          -- ignore the error
      end;
    end loop;

    commit;
  end if;

  if l_seed_and_publish != 0
  then
    dbms_output.put_line('*** seed and publish ***');

    for r in c_translations(l_application_id)
    loop
      dbms_output.put_line('primary_application_id: ' || r.primary_application_id);
      dbms_output.put_line('language              : ' || r.translated_app_language);

      apex_lang.seed_translations
      ( p_application_id => r.primary_application_id
      , p_language => r.translated_app_language
      );

      apex_lang.publish_application
      ( p_application_id => r.primary_application_id
      , p_language => r.translated_app_language
      );
    end loop;

    commit;
  end if;

  if l_update_language_mapping != 0 or l_seed_and_publish != 0
  then
    dbms_output.put_line(chr(10));
  end if;
exception
  when others
  then
    dbms_output.put_line(substr(sqlerrm, 1, 255));
    raise;
end;
/

undefine 1 2

