begin
  for r in
  ( select  'grant execute on DATA_API_PKG to ' || username as cmd
    from    all_users
    where   username in ( replace(user, '_DATA', '_API'), replace(user, '_DATA', '_UI') )
    and     username != user
  )
  loop
    dbms_output.put_line(r.cmd);
    execute immediate r.cmd;
  end loop;
end;
/
