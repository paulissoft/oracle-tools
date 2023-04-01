begin
  -- stop the supervisor job
  execute immediate q'[begin msg_scheduler_pkg.do(p_command => 'drop'); end;]';
exception
  when others
  then null;
end;
/
