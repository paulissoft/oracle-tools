/*
-- Script: adb-process.sql
-- Goal  : A SQL*Plus script to start the Autonomous DataBase process to install or export
-- Input : 1) The repo owner (case sensitive)
--         2) The repo name (case sensitive)
--         3) The operation (list-projects/list-files/install) (defaults to install)
--         4) Stop on error? (1=true, 0=false) (defaults to 1)
--         5) Do we perform a dry run? (1=true, 0=false) (defaults to 1)
--         8) Verbose? (1=true, 0=false) (defaults to 0)
-- Remark: Verify by https://github.com/&1/&2
*/

set serveroutput on size unlimited format trunc
set feedback off verify off

-- set defines 3, 4, 5 and 6 even though undefined
column d3 new_value 3
column d4 new_value 4
column d5 new_value 5
column d6 new_value 6

set termout off

select   1 d3
,        1 d4
,        1 d5
,        0 d6
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

select   '0' d6
from     dual
where    'X&6' = 'X';

set termout on

column d3 clear
column d4 clear
column d5 clear
column d6 clear

alter session set current_schema = ADMIN;

variable github_access_handle varchar2(256);

begin
  admin_install_pkg.delete_github_access; -- delete all
  admin_install_pkg.set_github_access
  ( p_repo_owner => '&1'
  , p_repo_name => '&2'
  , p_branch_name => 'development'
  , p_github_access_handle => :github_access_handle
  );
end;
/

set pagesize 1000 arraysize 10

column dbms_output format a255 wrap heading "DBMS output"

select  t.column_value as dbms_output
from    table
        ( admin.admin_install_pkg.process_pom
          ( p_github_access_handle => :github_access_handle
          , p_operation => '&3'
          , p_stop_on_error => nvl(to_number('&4'), 1)
          , p_dry_run => nvl(to_number('&5'), 0)
          , p_verbose => nvl(to_number('&6'), 0)
          )
        ) t;

alter session set current_schema = ADMIN;

undefine 1 2 3 4 5 6
