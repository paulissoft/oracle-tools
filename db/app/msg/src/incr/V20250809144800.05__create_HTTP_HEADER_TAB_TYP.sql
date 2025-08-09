begin
  execute immediate q'[create or replace type http_header_tab_typ as table of http_header_typ]';
end;
/
