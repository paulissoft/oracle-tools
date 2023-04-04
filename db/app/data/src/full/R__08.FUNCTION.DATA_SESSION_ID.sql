CREATE OR REPLACE FUNCTION "DATA_SESSION_ID" 
return varchar2 as
begin
  return case
           when sys_context('APEX$SESSION', 'APP_SESSION') is not null
           then 'APEX-' || sys_context('APEX$SESSION', 'APP_SESSION')
           else 'ORCL-' || sys_context('USERENV', 'SESSIONID')
         end;
end;
/

