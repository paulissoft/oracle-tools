begin
  for r in
  ( select  'create or replace synonym '||object_name||' for '||owner||'.'||object_name as stmt
    from    all_objects    
    where   owner != user
    and     object_type = 'PACKAGE'
    and     object_name like 'DBUG%'
  )
  loop
    execute immediate r.stmt;
  end loop;
end;
/
