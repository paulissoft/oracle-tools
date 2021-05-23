-- &1 workspace name
-- &2 application id
-- &3 export file

set serveroutput on size unlimited format trunc

prompt (import.sql)

whenever oserror exit failure
whenever sqlerror exit failure

set define on verify off feedback off

column workspace_name new_value workspace_name format a20

select  upper('&1') as workspace_name
from    dual;

column workspace_name clear

define application_id = '&2'

define export_file  = '&3'

-- disable access to application
prompt @@ pre_import.sql &&application_id
@@ pre_import.sql &&application_id

prompt @@ prepare_import.sql &&workspace_name &&application_id
@@ prepare_import.sql &&workspace_name &&application_id

prompt @ &&export_file
@ &&export_file

prompt @@ publish_application.sql
@@ publish_application.sql

-- enable access to application
prompt @@ post_import.sql &&application_id
@@ post_import.sql &&application_id

undefine 1 2 3 workspace_name application_id export_file

exit sql.sqlcode
