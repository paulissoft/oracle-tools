declare
  l_found pls_integer;
begin
  select  1
  into    l_found
  from    all_objects o
  where   o.owner = upper('${oracle_tools_schema_msg}')
  and     o.object_name = 'MSG_SCHEDULER_PKG'
  and     o.object_type = 'PACKAGE BODY'
  and     o.status = 'VALID';

  -- stop the supervisor job
  execute immediate q'[begin ${oracle_tools_schema_msg}.msg_scheduler_pkg.do(p_command => 'stop'); end;]';
exception
  when others
  then null;
end;
/
