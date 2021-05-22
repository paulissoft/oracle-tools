begin
  for r in
  ( select  'grant execute on DATA_BR_PKG to ' || username as cmd
    from    all_users
    where   username = replace(user, '_DATA', '_API')
    and     username != user
  )
  loop
    dbms_output.put_line(r.cmd);
    execute immediate r.cmd;
  end loop;
end;
/
