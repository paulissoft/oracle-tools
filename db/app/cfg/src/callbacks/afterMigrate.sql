begin
  /* keep in sync with ../../../../src/callbacks/afterMigrate.sql */
  ${oracle_tools_schema}.cfg_install_pkg."afterMigrate"(p_compile_all => ${compile_all}, p_reuse_settings => ${reuse_settings}, p_oracle_tools_schema_msg => '${oracle_tools_schema_msg}');
exception
  when others
  then null;
end;
/
