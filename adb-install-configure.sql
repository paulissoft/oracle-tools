/*
-- Script: adb-install-configure.sql
-- Goal  : A SQL*Plus script to return the repo handle from DBMS_CLOUD_REPO.INIT_GITHUB_REPO
-- Input : 1) The repo owner (case sensitive)
--         2) The repo name (case sensitive)
-- Remark: Verify by https://github.com/&1/&2
*/

set serveroutput on size unlimited format trunc
set feedback off verify off

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
  , p_operation => 'install'
  );
  cleanup;
exception
  when others
  then
    cleanup;
    raise;
end;
/

undefine 1 2
