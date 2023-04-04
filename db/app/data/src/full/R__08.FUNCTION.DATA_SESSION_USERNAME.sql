CREATE OR REPLACE FUNCTION "DATA_SESSION_USERNAME" 
return varchar2 as
begin
  return case
           when sys_context('APEX$SESSION', 'APP_USER') is not null
           then 'APEX-' || sys_context('APEX$SESSION', 'APP_USER')
           when sys_context('USERENV', 'CLIENT_IDENTIFIER') is not null
           then 'CLNT-' || regexp_substr(sys_context('USERENV', 'CLIENT_IDENTIFIER'), '^[^:]*')
           else 'ORCL-' || sys_context('USERENV', 'SESSION_USER')
         end;
end;
/

