begin
  execute immediate q'[create or replace type msg_tab_typ as table of msg_typ]';
end;
/

begin
  oracle_tools.cfg_install_pkg.check_object_valid('TYPE', 'MSG_TAB_TYP');
end;
/
