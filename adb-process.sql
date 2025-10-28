/*
-- Script: adb-process.sql
-- Goal  : A SQL*Plus script to start the Autonomous DataBase process to install or export
-- Input : 1) The repo owner (case sensitive)
--         2) The repo name (case sensitive)
--         3) The operation (install/export)
--         4) Stop on error? (1/0)
--         5) Do we perform a dry run? (1/0)
-- Remark: Verify by https://github.com/&1/&2
*/

set serveroutput on size unlimited format trunc
set feedback off verify off

-- set defines 3, 4 and 5 even though undefined
column d3 new_value 3
column d4 new_value 4
column d5 new_value 5

select   1 d3
,        1 d4
,        1 d5
from     dual
where    1=2;

select   'install' d3
from     dual
where    'X&3' = 'X';

select   '1' d4
from     dual
where    'X&4' = 'X';

select   '1' d5
from     dual
where    'X&5' = 'X';

column d3 clear
column d4 clear
column d5 clear

alter session set current_schema = ADMIN;

declare
  l_github_access_handle admin_install_pkg.github_access_handle_t := null;
begin
  admin_install_pkg.delete_github_access; -- delete all
  admin_install_pkg.set_github_access
  ( p_repo_owner => '&1'
  , p_repo_name => '&2'
  , p_branch_name => 'development'
  , p_github_access_handle => l_github_access_handle
  );
end;
/

set pagesize 1000 arraysize 1

column dbms_output format a255 wrap heading "DBMS output"

select  t.column_value as dbms_output
from    table
        ( admin.admin_install_pkg.process_pom
          ( p_github_access_handle => 'paulissoft/oracle-tools'
          , p_operation => '&3'
          , p_stop_on_error => nvl(to_number('&4'), 1)
          , p_dry_run => nvl(to_number('&5'), 0)
          )
        ) t;

alter session set current_schema = ADMIN;

undefine 1 2 3 4 5
