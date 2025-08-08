whenever sqlerror exit failure
whenever oserror exit failure

set serveroutput on size unlimited

delete from "schema_version_tools_msg";
commit;

declare
  l_type_tab sys.odcivarchar2list :=
    sys.odcivarchar2list
    ( -- collections
      'MSG_TAB_TYP'
      -- object types
    , 'REST_WEB_SERVICE_REQUEST_TYP'
    , 'WEB_SERVICE_RESPONSE_TYP'
    , 'WEB_SERVICE_REQUEST_TYP'
    , 'MSG_TYP'
    );
  l_sequence_tab sys.odcivarchar2list :=
    sys.odcivarchar2list
    ( 'WEB_SERVICE_REQUEST_SEQ'
    );
  l_count pls_integer;
  l_nr_objects_dropped pls_integer;

  procedure execute_immediate
  ( p_cmd in varchar2
  )
  is
  begin
    dbms_output.put_line(p_cmd);
    execute immediate p_cmd;
    l_nr_objects_dropped := l_nr_objects_dropped + 1;
  exception
    when others
    then
      dbms_output.put_line(sqlerrm);
      null;
  end execute_immediate;
begin
  select  count(*)
  into    l_count
  from    "schema_version_tools_msg";

  if l_count <> 0
  then
    raise_application_error(-20000, 'Please clean up Flyway cache by: delete from "schema_version_tools_msg"');
  end if;

  <<while_objects_dropped_loop>>
  loop
    l_nr_objects_dropped := 0;
    
    for i_idx in l_sequence_tab.first .. l_sequence_tab.last
    loop
      execute_immediate('drop sequence ' || l_sequence_tab(i_idx));
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
        execute_immediate(r.cmd);
      end loop;
    end loop;
    
    exit when l_nr_objects_dropped = 0;
  end loop while_objects_dropped_loop;
end;
/
