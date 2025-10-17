/*
-- Script: adb-install-configure.sql
-- Goal  : A SQL*Plus script to return the repo handle from DBMS_CLOUD_REPO.INIT_GITHUB_REPO
-- Input : 1) The repo owner (case sensitive)
--         2) The repo name (case sensitive)
-- Remark: Verify by https://github.com/&1/&2
*/

begin
  admin_install_pkg.init(p_repo_owner => '&1', p_repo_name => '&2');
end;
/

undefine 1 2
