begin
  ${oracle_tools_schema}.cfg_install_pkg.afterMigrate(p_compile_all => ${compile_all}, p_reuse_settings => ${reuse_settings});
end;
/
