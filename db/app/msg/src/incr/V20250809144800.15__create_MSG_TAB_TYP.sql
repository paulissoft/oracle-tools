begin
  execute immediate q'[create or replace type msg_tab_typ as table of msg_typ]';
end;
/
