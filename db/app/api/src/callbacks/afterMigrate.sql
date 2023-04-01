begin
  ${oracle_tools_schema}.cfg_install_pkg."afterMigrate"(p_compile_all => ${compile_all}, p_reuse_settings => ${reuse_settings});
  -- start the supervisor job (if any)
  begin
    execute immediate q'[begin ${oracle_tools_schema_msg}.msg_scheduler_pkg.do(p_command => 'start'); end;]';
  exception
    when others
    then null;
  end;
end;
/

