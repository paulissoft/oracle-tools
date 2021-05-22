create or replace function data_session_username
return varchar2 as
begin
  return coalesce
         ( sys_context('APEX$SESSION', 'app_user')
         , regexp_substr(sys_context('userenv', 'client_identifier'), '^[^:]*')
         , sys_context('userenv', 'session_user')
         );
end;
/
