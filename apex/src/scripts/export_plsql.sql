-- &1 workspace name
-- &2 application id
-- &3 output file

set serveroutput on size unlimited format trunc

prompt (export_plsql.sql)

whenever oserror exit failure
whenever sqlerror exit failure

set define on verify off feedback off

define workspace_name = '&1'
define application_id = '&2'
define output_file = '&3'

/*
prompt @@ pre_export.sql &&workspace_name &&application_id
@@ pre_export.sql &&workspace_name &&application_id
*/

set heading off pagesize 0 trimspool on linesize 1000 termout off

spool &output_file

select  line
from    table
        ( oracle_tools.ui_apex_export_pkg.get_application
          ( p_application_id => &application_id
          , p_split => 1
          , p_with_date => 0
          , p_with_ir_public_reports => 1
          , p_with_ir_private_reports => 1
          , p_with_ir_notifications => 0
          , p_with_translations => 1
          , p_with_original_ids => 1
          , p_with_no_subscriptions => 0
          , p_with_comments => 0
          )
        );

spool off

undefine 1 2 3 workspace_name application_id output_file

exit sql.sqlcode
