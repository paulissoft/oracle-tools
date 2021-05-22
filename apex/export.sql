-- &1 workspace name
-- &2 application id

set serveroutput on size unlimited format trunc

prompt (export.sql)

whenever oserror exit failure
whenever sqlerror exit failure

set define on verify off feedback off

define workspace_name = '&1'
define application_id = '&2'

prompt @@ pre_export.sql &&workspace_name &&application_id
@@ pre_export.sql &&workspace_name &&application_id

REM Can only run in Java SqlCli client

prompt apex export -applicationid &&application_id -expPubReports -expSavedReports -expTranslations -expOriginalIds -split
apex export -applicationid &&application_id -expPubReports -expSavedReports -expTranslations -expOriginalIds -split

undefine 1 2 workspace_name application_id

exit sql.sqlcode
