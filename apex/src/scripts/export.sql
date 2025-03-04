-- &1 userid
-- &2 workspace name
-- &3 application id

set serveroutput on size unlimited format trunc

prompt (export.sql)

whenever oserror exit failure
whenever sqlerror exit failure

set define on verify off feedback off

define workspace_name = '&2'
define application_id = '&3'

@@ connect.sql '&1'

prompt @@ pre_export_no_connect.sql &&workspace_name &&application_id '' ''
@@ pre_export_no_connect.sql &&workspace_name &&application_id '' ''

REM Can only run in Java SqlCli client

prompt apex export -applicationid &&application_id -expPubReports -expSavedReports -expTranslations -expOriginalIds -split
apex export -applicationid &&application_id -expPubReports -expSavedReports -expTranslations -expOriginalIds -split

undefine 1 2 3 workspace_name application_id

exit sql.sqlcode
