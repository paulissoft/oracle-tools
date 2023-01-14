declare
  -- ${apex.application} is a Flyway placeholder but when you run this in SQL Developer it will not be replaced
  l_application_id constant number :=
    case
      when substr('${apex.application}', 1, 1) = '$'
      then 138
      else to_number('${apex.application}')
    end;
  l_max_name_length constant pls_integer := 50;  
begin
  ui_apex_messages_pkg.init(l_application_id);

  -- messages to merge
  for r in
  ( with src as
    ( -- dummy row to get the header straight
      select  '' as name                             , '' as language, '' as message_text from dual union all
      --
      select 'DBMS_ASSERT.ENQUOTE_NAME'              , 'en', 'Can not enclose this "<p1>" name with quotes: <p2>' from dual union all
      select 'DBMS_ASSERT.ENQUOTE_NAME'              , 'nl', 'Kan geen quotes om deze "<p1>" naam zetten: <p2>' from dual union all
      select 'DBMS_ASSERT.QUALIFIED_SQL_NAME'        , 'en', 'This is no qualified SQL "<p1>" name: <p2>' from dual union all
      select 'DBMS_ASSERT.QUALIFIED_SQL_NAME'        , 'nl', 'Dit is geen gekwalificeerde SQL "<p1>" naam: <p2>' from dual union all
      select 'DBMS_ASSERT.SCHEMA_NAME'               , 'en', 'This is no "<p1>" schema name: <p2>' from dual union all
      select 'DBMS_ASSERT.SCHEMA_NAME'               , 'nl', 'Dit is geen "<p1>" schemanaam: <p2>' from dual union all
      select 'DBMS_ASSERT.SIMPLE_SQL_NAME'           , 'en', 'This is no simple SQL "<p1>" name: <p2>' from dual union all
      select 'DBMS_ASSERT.SIMPLE_SQL_NAME'           , 'nl', 'Dit is geen simpele SQL "<p1>" naam: <p2>' from dual union all
      select 'DBMS_ASSERT.SQL_OBJECT_NAME'           , 'en', 'This is no SQL "<p1>" object name: <p2>' from dual union all
      select 'DBMS_ASSERT.SQL_OBJECT_NAME'           , 'nl', 'Dit is geen SQL "<p1>" objectnaam: <p2>' from dual union all
      --
      select  ''   as name                           , '' as language, '' as message_text                                                                                               from dual -- finish
    ), dst as
    ( select  t.name
      ,       t.language
      ,       t.message_text
      from    table(ui_apex_messages_pkg.get_messages( p_application_id => l_application_id
                                                     , p_language => null -- all
                                                     )
                   ) t
    )
    select  upper(src.name) as name -- Must be in upper case for APEX
    ,       src.language
    ,       src.message_text
    from    src
    where   src.name is not null -- skip first and last dummy row
    minus
    select  dst.name
    ,       dst.language
    ,       dst.message_text
    from    dst
  )
  loop
    if length(r.name) > l_max_name_length
    then
      raise_application_error(-20000, 'The message name (' || r.name || ') has more than ' || l_max_name_length || ' characters.');
    end if;
    ui_apex_messages_pkg.merge_message
    ( p_application_id => l_application_id
    , p_name => r.name
    , p_language => r.language
    , p_message_text => r.message_text
    );
  end loop;
end;
/
