/*
-- Script: adb-process.sql
-- Goal  : A SQL*Plus script to start the Autonomous DataBase process to install or export
-- Input : 1) The repo owner (case sensitive)
--         2) The repo name (case sensitive)
--         3) The operation (install/export)
--         4) Stop on error? (true/false)
--         5) Do we perform a dry run? (true/false)
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

select   'true' d4
from     dual
where    'X&4' = 'X';

select   'true' d5
from     dual
where    'X&5' = 'X';

column d3 clear
column d4 clear
column d5 clear

declare
  l_github_access_handle admin_install_pkg.github_access_handle_t := null;

  procedure cleanup
  is
  begin
    if l_github_access_handle is not null
    then
      admin_install_pkg.delete_github_access
      ( p_github_access_handle => l_github_access_handle
      );
      l_github_access_handle := null;
    end if;
    execute immediate 'alter session set current_schema = ADMIN';
  end;
begin
  admin_install_pkg.set_github_access
  ( p_repo_owner => '&1'
  , p_repo_name => '&2'
  , p_branch_name => 'development'
  , p_github_access_handle => l_github_access_handle
  );
  admin_install_pkg.process_root_project
  ( p_github_access_handle => l_github_access_handle
  , p_operation => '&3'
  , p_stop_on_error => &4
  , p_dry_run => &5
  );
  cleanup;
exception
  when others
  then
    cleanup;
    raise;
end;
/

undefine 1 2 3 4 5
