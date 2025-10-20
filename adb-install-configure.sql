/*
-- Script: adb-install-configure.sql
-- Goal  : A SQL*Plus script to return the repo handle from DBMS_CLOUD_REPO.INIT_GITHUB_REPO
-- Input : 1) The repo owner (case sensitive)
--         2) The repo name (case sensitive)
-- Remark: Verify by https://github.com/&1/&2
*/

declare
  l_github_access_handle admin_install_pkg.github_access_handle_t;
begin
  admin_install_pkg.set_github_access
  ( p_repo_owner => '&1'
  , p_repo_name => '&2'
  , p_branch_name => 'development'
  , p_github_access_handle => l_github_access_handle
  );
  admin_install_pkg.process_file
  ( p_github_access_handle => l_github_access_handle
  , p_schema => null
  , p_file_path => 'pom.sql'
  );
end;
/

undefine 1 2
