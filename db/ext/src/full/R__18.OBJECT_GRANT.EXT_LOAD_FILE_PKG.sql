begin
  for r in
  ( select  'grant execute on EXT_LOAD_FILE_PKG to ' || username as cmd
    from    all_users
    where   username = replace(user, '_EXT', '_UI')
    and     username != user
  )
  loop
    dbms_output.put_line(r.cmd);
    execute immediate r.cmd;
  end loop;
end;
/
