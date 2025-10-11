create or replace FUNCTION "DATA_SESSION_USERNAME" 
return varchar2 
is
  l_session_username varchar2(128 char) := null;
begin
/*DBUG    
  dbug.enter('DATA_SESSION_USERNAME');
/*DBUG*/    

  l_session_username :=
    case
      when sys_context('APEX$SESSION', 'APP_USER') is not null
      then 'APEX-' || sys_context('APEX$SESSION', 'APP_USER')
      when sys_context('USERENV', 'CLIENT_IDENTIFIER') is not null
      then 'CLNT-' || regexp_substr(sys_context('USERENV', 'CLIENT_IDENTIFIER'), '^[^:]*')
      else 'ORCL-' || sys_context('USERENV', 'SESSION_USER')
    end;
    
/*DBUG    
  dbug.leave;
/*DBUG*/    
  
  return l_session_username;
exception
  when others
  then
/*DBUG    
    dbug.leave_on_error;
/*DBUG*/    
    return null;
end;
/

