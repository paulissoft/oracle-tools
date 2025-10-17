/*
-- Script: adb-install-bootstrap.sql
-- Goal  : A SQL*Plus script to install the most relevant parts of (P)aulissoft (A)pplication (T)ools for (O)racle
-- Note  : 1) When this script has run once, the installation will continue with adb-install.sql.
--         2) This script should NOT be run by DBMS_CLOUD_REPO.INSTALL_FILE
              but it may invoke scripts that use DBMS_CLOUD_REPO.INSTALL_FILE or DBMS_CLOUD_REPO.INSTALL_SQL.
*/

whenever oserror exit failure
whenever sqlerror exit failure

-- define DBMS_CLOUD_REPO handle for this repository
prompt @@adb-install-configure.sql paulissoft oracle-tools
@@adb-install-configure.sql paulissoft oracle-tools

prompt @@db/src/admin/create.sql
@@db/src/admin/create.sql
prompt @@db/src/admin/grant.sql
@@db/src/admin/grant.sql

prompt @@db/app/admin/adb-install-bootstrap.sql
@@db/app/admin/adb-install-bootstrap.sql

alter session set current_schema = ORACLE_TOOLS;

-- @@apex/app/src/export/install.sql
