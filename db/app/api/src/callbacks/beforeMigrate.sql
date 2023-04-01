begin
  -- stop the supervisor job (if any)
  execute immediate q'[begin ${oracle_tools_schema_msg}.msg_scheduler_pkg.do(p_command => 'stop'); end;]';
exception
  when others
  then null;
end;
/
