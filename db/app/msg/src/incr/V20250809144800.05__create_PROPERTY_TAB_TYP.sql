begin
  execute immediate q'[create or replace type property_tab_typ as table of property_typ]';
end;
/
