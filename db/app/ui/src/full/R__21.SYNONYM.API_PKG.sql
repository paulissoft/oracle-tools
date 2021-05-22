begin
  for r_obj in
  ( select  'create or replace synonym ' || object_name || ' for ' || owner || '.' || object_name as cmd
    from    all_objects
    where   object_name = 'API_PKG'
    and     object_type = 'PACKAGE'
    and     owner != user
    and     ( object_name, object_type ) not in ( select object_name, object_type from user_objects )
  )
  loop
    execute immediate r_obj.cmd;
  end loop;
end;
/
