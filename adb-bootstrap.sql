/*
-- Script: adb-bootstrap.sql
-- Goal  : A SQL*Plus script to bootstrap parts of (P)aulissoft (A)pplication (T)ools for (O)racle
-- Note  : This script should NOT be run by DBMS_CLOUD_REPO.INSTALL_FILE
*/
set serveroutput on size unlimited format trunc

whenever oserror exit failure
whenever sqlerror exit failure

-- Create user ORACLE_TOOLS (if necessary)
prompt @@db/src/admin/create.sql
@@db/src/admin/create.sql
prompt @@db/src/admin/grant.sql
@@db/src/admin/grant.sql

prompt @@db/app/admin/adb-bootstrap.sql
@@db/app/admin/adb-bootstrap.sql

-- install Transferware/dbug
declare
  l_github_access_handle admin_install_pkg.github_access_handle_t;

  procedure reset_session
  is
  begin
    execute immediate 'alter session set current_schema = ADMIN';
    admin_install_pkg.delete_github_access;
  end reset_session;
begin
  reset_session;
  
  -- first call must be to paulissoft/oracle-tools
  admin_install_pkg.set_github_access
  ( p_repo_owner => 'paulissoft'
  , p_repo_name => 'oracle-tools'
  , p_branch_name => 'development'
  , p_github_access_handle => l_github_access_handle
  );
  admin_install_pkg.set_github_access
  ( p_repo_owner => 'TransferWare'
  , p_repo_name => 'dbug'
  , p_github_access_handle => l_github_access_handle
  );
  begin
    admin_install_pkg.install_file
    ( p_github_access_handle => l_github_access_handle
    , p_schema => 'ORACLE_TOOLS'
    , p_file_path => 'src/sql/install-versioned-migrations.sql'
    );
  exception
    when others
    then null;
  end;
  admin_install_pkg.install_file
  ( p_github_access_handle => l_github_access_handle
  , p_schema => 'ORACLE_TOOLS'
  , p_file_path => 'src/sql/install-repeatable-migrations.sql'
  );
  reset_session;
exception
  when others
  then
    reset_session;
    raise;
end;
/
