begin
  execute immediate q'[create or replace type property_tab_typ as table of property_typ]';
end;
/

begin
  oracle_tools.cfg_install_pkg.check_object_valid('TYPE', 'PROPERTY_TAB_TYP');
end;
/
