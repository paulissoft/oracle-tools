begin
  ${oracle_tools_schema}.cfg_install_pkg."beforeMigrate"(p_oracle_tools_schema_msg => '${oracle_tools_schema_msg}');
exception
  when others
  then null;
end;
/
