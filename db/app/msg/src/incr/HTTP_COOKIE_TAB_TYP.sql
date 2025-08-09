begin
  execute immediate q'[create or replace type http_cookie_tab_typ as table of http_cookie_typ]';
end;
/
