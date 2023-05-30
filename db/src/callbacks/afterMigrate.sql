declare
  l_found pls_integer;
begin
  ${oracle_tools_schema}.cfg_install_pkg."afterMigrate"(p_compile_all => ${compile_all}, p_reuse_settings => ${reuse_settings});
  begin
    select  1
    into    l_found
    from    all_objects o
    where   o.owner = upper('${oracle_tools_schema_msg}')
    and     o.object_name = 'MSG_SCHEDULER_PKG'
    and     o.object_type = 'PACKAGE BODY'
    and     o.status = 'VALID';
  
    -- start the supervisor job
    execute immediate q'[begin ${oracle_tools_schema_msg}.msg_scheduler_pkg.do(p_command => 'start'); end;]';
  exception
    when others
    then null;
  end;
end;
/
