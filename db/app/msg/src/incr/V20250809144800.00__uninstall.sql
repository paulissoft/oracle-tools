declare
  l_type_tab sys.odcivarchar2list :=
    -- in reversed creation order
    sys.odcivarchar2list
    ( 'MSG_TAB_TYP'
    , 'REST_WEB_SERVICE_PUT_REQUEST_TYP'
    , 'REST_WEB_SERVICE_DELETE_REQUEST_TYP'
    , 'REST_WEB_SERVICE_PATCH_REQUEST_TYP'
    , 'REST_WEB_SERVICE_POST_REQUEST_TYP'
    , 'REST_WEB_SERVICE_GET_REQUEST_TYP'
    , 'REST_WEB_SERVICE_REQUEST_TYP'
    , 'WEB_SERVICE_RESPONSE_TYP'
    , 'WEB_SERVICE_REQUEST_TYP'
    , 'HTTP_REQUEST_RESPONSE_TYP'
    , 'HTTP_HEADER_TAB_TYP'
    , 'HTTP_HEADER_TYP'
    , 'HTTP_COOKIE_TAB_TYP'
    , 'HTTP_COOKIE_TYP'
    , 'MSG_TYP'
    );
  l_nr_objects_dropped pls_integer;
  
  procedure drop_object
  ( p_cmd in varchar2
  )
  is
  begin
    execute immediate p_cmd;
    l_nr_objects_dropped := l_nr_objects_dropped + 1;
  exception
    when others
    then null;
  end drop_object;
begin
  <<while_objects_dropped_loop>>
  loop
    l_nr_objects_dropped := 0;
    
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
