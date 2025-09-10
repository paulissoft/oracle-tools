begin
  execute immediate q'[create or replace type http_cookie_tab_typ as table of http_cookie_typ]';
end;
/

begin
  oracle_tools.cfg_install_pkg.check_object_valid('TYPE', 'HTTP_COOKIE_TAB_TYP');
end;
/
