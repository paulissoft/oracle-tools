/*
-- Script: adb-process.sql
-- Goal  : A SQL*Plus script to start the Autonomous DataBase process to install or export
-- Input : 1) The repo owner (case sensitive)
--         2) The repo name (case sensitive)
--         3) The path of the starting pom.sql (defaults to empty)
--         4) The operation (list-projects/list-files/install) (defaults to install)
--         5) Stop on error? (1=true, 0=false) (defaults to 1)
--         6) Do we perform a dry run? (1=true, 0=false) (defaults to 1)
--         7) Verbose? (1=true, 0=false) (defaults to 0)
-- Remark: Verify by https://github.com/&1/&2
*/

define repo_owner = paulissoft
define repo_name = oracle-tools
define path = null
define operation = install
define stop_on_error = 1
define dry_run = 1
define verbose = 0

set serveroutput on size unlimited format trunc
set feedback off verify off

alter session set current_schema = ADMIN;

variable github_access_handle varchar2(256);

begin
  admin_install_pkg.delete_github_access; -- delete all
  admin_install_pkg.set_github_access
  ( p_repo_owner => '&repo_owner'
  , p_repo_name => '&repo_name'
  , p_branch_name => 'development'
  , p_github_access_handle => :github_access_handle
  );
end;
/

select  t.column_value as "DBMS output"
from    table
        ( admin.admin_install_pkg.process_pom
          ( p_github_access_handle => :github_access_handle
          , p_path => &path
          , p_operation => '&operation'
          , p_stop_on_error => nvl(to_number('&stop_on_error'), 1)
          , p_dry_run => nvl(to_number('&dry_run'), 0)
          , p_verbose => nvl(to_number('&verbose'), 0)
          )
        ) t;

alter session set current_schema = ADMIN;
