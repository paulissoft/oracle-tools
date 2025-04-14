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

-- ORA-08177: can't serialize access for this transaction
-- https://support.oracle.com/epmos/faces/DocumentDisplay?_afrLoop=103654445502564&parent=EXTERNAL_SEARCH&sourceId=PROBLEM&id=2893264.1&_afrWindowMode=0&_adf.ctrl-state=eb5o4ic74_4
alter session set nls_numeric_characters = '.,';

prompt apex export -applicationid &&application_id -expPubReports -expSavedReports -expTranslations -expOriginalIds -split -nochecksum
apex export -applicationid &&application_id -expPubReports -expSavedReports -expTranslations -expOriginalIds -split -nochecksum

undefine 1 2 workspace_name application_id

exit sql.sqlcode
