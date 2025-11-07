-- &1 workspace name
-- &2 application id
-- &3 export file
-- &4 application alias

set serveroutput on size unlimited format trunc

prompt (import.sql)

whenever oserror exit failure
whenever sqlerror exit failure

set define on verify off feedback off

column workspace_name new_value workspace_name format a100
-- the next two columns may be just a SPACE (instead of empty): trim them
column export_file new_value export_file format a1000
column application_alias new_value application_alias format a100

select  upper('&1') as workspace_name
,       trim('&3') as export_file
,       trim('&4') as application_alias
from    dual;

column workspace_name clear

define application_id = '&2'

-- disable access to application
prompt @@ pre_import.sql &&application_id
@@ pre_import.sql &&application_id

prompt @@ prepare_import.sql &&workspace_name &&application_id &&application_alias
@@ prepare_import.sql &&workspace_name &&application_id &&application_alias

prompt @ &&export_file
@ &&export_file

prompt @@ publish_application.sql
@@ publish_application.sql

-- enable access to application
prompt @@ post_import.sql &&application_id
@@ post_import.sql &&application_id

undefine 1 2 3 4 workspace_name application_id export_file application_alias

exit sql.sqlcode
