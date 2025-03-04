-- &1 userid
-- &2 workspace name
-- &3 application id
-- &4 export file

set serveroutput on size unlimited format trunc

prompt (import.sql)

whenever oserror exit failure
whenever sqlerror exit failure

define workspace_name = '&2'
define application_id = '&3'
define export_file = '&4'

@@ connect.sql '&1'

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

undefine 1 2 3 4 workspace_name application_id export_file

exit sql.sqlcode
