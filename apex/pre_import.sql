prompt (pre_import.sql)

set define on

whenever sqlerror exit failure
whenever oserror exit failure

define application_status = 'DEVELOPERS_ONLY'

prompt Set application status for id &&1 to &&application_status

REMARK set by import.sql
-- set verify off

declare
  l_app_id apex_applications.application_id%type := to_number('&&1');
  -- ORA-20987: APEX - ERR-1014 Application not found. - Contact your application
  e_apex_error exception;
  pragma exception_init(e_apex_error, -20987);
begin
  apex_session.create_session
  ( p_app_id => l_app_id
  , p_page_id => 1
  , p_username => 'ADMIN'
  );

  apex_util.set_application_status
  ( p_application_id => l_app_id
  , p_application_status => '&&application_status'
  , p_unavailable_value => 'Updating application'
  );
  
  commit;
exception
  when e_apex_error
  then
    null;
end;
/

undefine 1 application_status
