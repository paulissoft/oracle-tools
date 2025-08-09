whenever sqlerror exit failure
whenever oserror exit failure

set serveroutput on size unlimited

declare
  l_type_tab sys.odcivarchar2list :=
    sys.odcivarchar2list
    ( -- collections
      'MSG_TAB_TYP'
    , 'HTTP_COOKIE_TAB_TYP'
    , 'HTTP_HEADER_TAB_TYP'
      -- object types
    , 'REST_WEB_SERVICE_REQUEST_TYP'
    , 'WEB_SERVICE_RESPONSE_TYP'
    , 'WEB_SERVICE_REQUEST_TYP'
    , 'HTTP_REQUEST_RESPONSE_TYP'
    , 'MSG_TYP'
    , 'HTTP_COOKIE_TYP'
    , 'HTTP_HEADER_TYP'
    );
  l_sequence_tab sys.odcivarchar2list :=
    sys.odcivarchar2list
    ( 'WEB_SERVICE_REQUEST_SEQ'
    );
  l_count pls_integer;
  l_nr_objects_dropped pls_integer;

  -- ORA-00942: table or view does not exist
  e_table_or_view_does_not_exist exception;
  pragma exception_init(e_table_or_view_does_not_exist, -942);

  procedure execute_immediate
  ( p_cmd in varchar2
  )
  is
  begin
    dbms_output.put_line(p_cmd);
    execute immediate p_cmd;
  exception
    when others
    then
      dbms_output.put_line(sqlerrm);
      raise;
  end execute_immediate;
  
  procedure drop_object
  ( p_cmd in varchar2
  )
  is
  begin
    execute_immediate(p_cmd);
    l_nr_objects_dropped := l_nr_objects_dropped + 1;
  exception
    when others
    then null;
  end drop_object;
begin
  begin
    execute_immediate('delete from "schema_version_tools_msg"');
    commit;
  exception
    when e_table_or_view_does_not_exist
    then null;
  end;

  <<while_objects_dropped_loop>>
  loop
    l_nr_objects_dropped := 0;
    
    for i_idx in l_sequence_tab.first .. l_sequence_tab.last
    loop
      drop_object('drop sequence ' || l_sequence_tab(i_idx));
    end loop;

    for i_idx in l_type_tab.first .. l_type_tab.last
    loop
      for r in
      ( select  'drop type ' || type_name || ' force' as cmd
        from    user_types
        connect by
                supertype_name = prior type_name
        start with
                type_name = l_type_tab(i_idx)
        order by
                level desc
      )
      loop
        drop_object(r.cmd);
      end loop;
    end loop;
    
    exit when l_nr_objects_dropped = 0;
  end loop while_objects_dropped_loop;
end;
/
