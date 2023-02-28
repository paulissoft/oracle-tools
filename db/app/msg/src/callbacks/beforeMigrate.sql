begin
  -- stop the supervisor job
  execute immediate q'[begin msg_scheduler_pkg.do(p_command => 'stop', p_processing_package => 'MSG_AQ_PCK'); end;]';
exception
  when others
  then null;
end;
/
