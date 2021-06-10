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
  l_username constant varchar2(30) := 'ADMIN';
  
  -- ORA-20987: APEX - ERR-1014 Application not found. - Contact your application
  e_apex_error exception;
  pragma exception_init(e_apex_error, -20987);
begin
$if dbms_db_version.ver_le_12 $then

  /* apex_session.create_session does not exist on Apex 5.1 */

  ui_session_pkg.create_apex_session
  ( p_app_id => l_app_id
  , p_app_user => l_username
  , p_app_page_id => 1
  );

$else

  apex_session.create_session
  ( p_app_id => l_app_id
  , p_page_id => 1
  , p_username => l_username
  );

$end

  apex_util.set_application_status
  ( p_application_id => l_app_id
  , p_application_status => '&&application_status'
  , p_unavailable_value => 'Updating application'
  );
  
  commit;
exception
  when e_apex_error or no_data_found
  then
    null;   
end;
.

list

/

undefine 1 application_status
