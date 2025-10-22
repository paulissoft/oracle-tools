/*
-- Script: adb-install-bootstrap.sql
-- Goal  : A SQL*Plus script to install the bootstrap parts of (P)aulissoft (A)pplication (T)ools for (O)racle
-- Note  : This script should NOT be run by DBMS_CLOUD_REPO.INSTALL_FILE
*/

whenever oserror exit failure
whenever sqlerror exit failure

-- Create user ORACLE_TOOLS (if necessary)
prompt @@db/src/admin/create.sql
@@db/src/admin/create.sql
prompt @@db/src/admin/grant.sql
@@db/src/admin/grant.sql

prompt @@db/app/admin/adb-install-bootstrap.sql
@@db/app/admin/adb-install-bootstrap.sql
