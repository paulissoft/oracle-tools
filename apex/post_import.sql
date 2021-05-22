prompt (post_import.sql)

set define on

whenever sqlerror exit failure
whenever oserror exit failure

define application_status = 'AVAILABLE_W_EDIT_LINK'

prompt Set application status for id &&1 to &&application_status

REMARK set by import.sql but maybe overwritten by the application script
set verify off

declare
  l_app_id apex_applications.application_id%type := to_number('&1');
begin
  apex_session.create_session
  ( p_app_id => l_app_id
  , p_page_id => 1
  , p_username => 'ADMIN'
  );

  apex_util.set_application_status
  ( p_application_id => l_app_id
  , p_application_status => '&&application_status'
  );
  
  commit;
end;
/

undefine 1 application_status
