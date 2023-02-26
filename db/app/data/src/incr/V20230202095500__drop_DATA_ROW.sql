begin
  for r in
  ( select  'drop ' || object_type || ' ' || object_name || case when object_type = 'TYPE' then ' force' end as cmd
    from    user_objects
    where   object_name in ( 'DATA_ROW_T', 'DATA_ROW_ID_T', 'DATA_DML_EVENT_MGR_PKG', 'DATA_ROW_NOTIFICATION_PRC' )
    and     object_type in ( 'TYPE', 'PACKAGE', 'PROCEDURE' )
    order by
            length(object_name) desc -- drop DATA_ROW_ID_T before DATA_ROW_T
  )
  loop
    execute immediate r.cmd;
  end loop;
end;
/
