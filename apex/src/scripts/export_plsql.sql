-- &1 workspace name
-- &2 application id

set serveroutput on size unlimited format trunc

prompt (export_plsql.sql)

whenever oserror exit failure
whenever sqlerror exit failure

set define on verify off feedback off

define workspace_name = '&1'
define application_id = '&2'

set heading off pagesize 0 trimspool on linesize 1000 termout on arraysize 1000

select  line
from    table
        ( oracle_tools.ui_apex_export_pkg.get_application
          ( p_workspace_name => '&workspace_name'
          , p_application_id => &application_id
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

undefine 1 2 workspace_name application_id

exit sql.sqlcode
