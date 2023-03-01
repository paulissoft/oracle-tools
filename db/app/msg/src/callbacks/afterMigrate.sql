begin
  ${oracle_tools_schema}.cfg_install_pkg."afterMigrate"(p_compile_all => ${compile_all}, p_reuse_settings => ${reuse_settings});
  -- start the supervisor job
  execute immediate q'[begin msg_scheduler_pkg.do(p_command => 'start', p_processing_package => 'MSG_AQ_PKG'); end;]';
end;
/
