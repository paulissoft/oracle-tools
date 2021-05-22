begin
  for r in
  ( select  'drop package ' || o.object_name as stmt
    from    user_objects o
    where   o.object_name = 'CFG_PCK'
    and     o.object_type = 'PACKAGE'
  )
  loop
    execute immediate r.stmt;
  end loop;
end;
/
