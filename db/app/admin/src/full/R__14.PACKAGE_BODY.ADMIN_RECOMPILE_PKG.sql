CREATE OR REPLACE PACKAGE BODY "ADMIN_RECOMPILE_PKG" AS 

function get_schemas
( p_schema in varchar2
, p_exclude_oracle_maintained in pls_integer default 0
)
return sys.odcivarchar2list
is
  l_current_user constant all_users.username%type := sys_context('USERENV', 'SESSION_USER');
  l_dba constant pls_integer := case when sys_context('USERENV', 'ISDBA') = 'TRUE' or l_current_user = $$PLSQL_UNIT_OWNER then 1 else 0 end;
  l_schema_tab sys.odcivarchar2list;
begin
  select  u.username
  bulk collect
  into    l_schema_tab
  from    all_users u
  where   ( p_exclude_oracle_maintained = 0 or u.oracle_maintained <> 'Y' )
  and     ( ( l_dba = 1
              and
              u.username in ( nvl(p_schema, u.username), upper(p_schema) )
            )
            or
            ( l_dba = 0
              and
              u.username = l_current_user
              and
              ( p_schema is null or u.username in ( p_schema, upper(p_schema) ) ) -- a normal user can not compile another schema
            )
          )
  order by
          username;

/*
  dbms_output.put_line('p_schema: ' || p_schema);
  dbms_output.put_line('p_exclude_oracle_maintained: ' || p_exclude_oracle_maintained);
  dbms_output.put_line('l_current_user: ' || l_current_user);
  dbms_output.put_line('l_dba: ' || l_dba);  
  dbms_output.put_line('l_schema_tab.count: ' || l_schema_tab.count);
  if l_schema_tab.count > 0
  then
    for i_idx in l_schema_tab.first .. l_schema_tab.last
    loop
      dbms_output.put_line('schema ' || i_idx || ': ' || l_schema_tab(i_idx));
    end loop;
  end if;
*/  
  
  return l_schema_tab;
end get_schemas;

procedure show
( p_schema_tab in sys.odcivarchar2list
)
is
begin
  dbms_output.put_line('*** invalid objects ***');
  for r in ( select t.* from table(admin_recompile_pkg.show(p_schema_tab)) t )
  loop
    dbms_output.put_line
    ( utl_lms.format_message
      ( 'owner: %s; object_name: %s; object_type: %s; status: %s'
      , r.owner
      , r.object_name
      , r.object_type
      , r.status
      )
    );
  end loop;
  dbms_output.put_line(chr(10));
end show;

-- PUBLIC

function show
( p_schema_tab in sys.odcivarchar2list
)
return invalid_object_tab_t
pipelined
is
begin
  for r in
  ( select  o.owner
    ,       o.object_name
    ,       o.object_type
    ,       o.status
    from    all_objects o
            inner join
            ( select  t.column_value as schema
              from    table(p_schema_tab) t
            ) s
            on s.schema = o.owner
    where   o.status <> 'VALID'
    order by
            owner
    ,       object_name
    ,       object_type
  )
  loop
    pipe row (r);
  end loop;
  return;
end show;

procedure recomp_parallel
( p_threads in pls_integer
, p_schema in varchar2
)
is
  l_schema_tab sys.odcivarchar2list := get_schemas(p_schema);
begin
  if l_schema_tab.count = 0
  then
    raise no_data_found;
  end if;
  dbms_output.put_line(utl_lms.format_message(q'[execute sys.utl_recomp.recomp_parallel(threads => %s, schema => '%s')]', nvl(to_char(p_threads), 'null'), p_schema));
  sys.utl_recomp.recomp_parallel(threads => p_threads, schema => p_schema);
  show(l_schema_tab);
end recomp_parallel;

procedure recomp_serial
( p_schema in varchar2
, p_exclude_oracle_maintained in boolean
)
is
  l_schema_tab sys.odcivarchar2list := get_schemas(p_schema, case when p_exclude_oracle_maintained then 1 else 0 end);
begin
  if l_schema_tab.count = 0
  then
    raise no_data_found;
  end if;
  for i_idx in l_schema_tab.first .. l_schema_tab.last
  loop
    dbms_output.put_line(utl_lms.format_message(q'[execute sys.utl_recomp.recomp_serial(schema => '%s')]', l_schema_tab(i_idx)));
    sys.utl_recomp.recomp_serial(schema => l_schema_tab(i_idx));
  end loop;
  show(l_schema_tab);
end recomp_serial;

end ADMIN_RECOMPILE_PKG;
/
