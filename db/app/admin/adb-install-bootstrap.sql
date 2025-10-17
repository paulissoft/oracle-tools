/*
-- Script: adb-install-bootstrap.sql
-- Goal  : A SQL*Plus script to install the ADMIN part of (P)aulissoft (A)pplication (T)ools for (O)racle
-- Note  : This script should NOT be run by DBMS_CLOUD_REPO.INSTALL_FILE
           but it may invoke scripts that use DBMS_CLOUD_REPO.INSTALL_FILE or DBMS_CLOUD_REPO.INSTALL_SQL.
*/

whenever oserror exit failure
whenever sqlerror exit failure

alter session set current_schema = ADMIN;

prompt @@src/full/R__00.PUBLIC_SYNONYM.ADMIN_RECOMPILE_PKG.sql
@@src/full/R__00.PUBLIC_SYNONYM.ADMIN_RECOMPILE_PKG.sql
prompt @@src/full/R__00.PUBLIC_SYNONYM.ADMIN_SCHEDULER_PKG.sql
@@src/full/R__00.PUBLIC_SYNONYM.ADMIN_SCHEDULER_PKG.sql
prompt @@src/full/R__00.PUBLIC_SYNONYM.ADMIN_SYSTEM_PKG.sql
@@src/full/R__00.PUBLIC_SYNONYM.ADMIN_SYSTEM_PKG.sql
prompt @@src/full/R__09.PACKAGE_SPEC.ADMIN_RECOMPILE_PKG.sql
@@src/full/R__09.PACKAGE_SPEC.ADMIN_RECOMPILE_PKG.sql
prompt @@src/full/R__09.PACKAGE_SPEC.ADMIN_SCHEDULER_PKG.sql
@@src/full/R__09.PACKAGE_SPEC.ADMIN_SCHEDULER_PKG.sql
prompt @@src/full/R__09.PACKAGE_SPEC.ADMIN_SYSTEM_PKG.sql
@@src/full/R__09.PACKAGE_SPEC.ADMIN_SYSTEM_PKG.sql
prompt @@src/full/R__14.PACKAGE_BODY.ADMIN_RECOMPILE_PKG.sql
@@src/full/R__14.PACKAGE_BODY.ADMIN_RECOMPILE_PKG.sql
prompt @@src/full/R__14.PACKAGE_BODY.ADMIN_SCHEDULER_PKG.sql
@@src/full/R__14.PACKAGE_BODY.ADMIN_SCHEDULER_PKG.sql
prompt @@src/full/R__14.PACKAGE_BODY.ADMIN_SYSTEM_PKG.sql
@@src/full/R__14.PACKAGE_BODY.ADMIN_SYSTEM_PKG.sql
prompt @@src/full/R__18.OBJECT_GRANT.ADMIN_RECOMPILE_PKG.sql
@@src/full/R__18.OBJECT_GRANT.ADMIN_RECOMPILE_PKG.sql
prompt @@src/full/R__18.OBJECT_GRANT.ADMIN_SCHEDULER_PKG.sql
@@src/full/R__18.OBJECT_GRANT.ADMIN_SCHEDULER_PKG.sql
prompt @@src/full/R__18.OBJECT_GRANT.ADMIN_SYSTEM_PKG.sql
@@src/full/R__18.OBJECT_GRANT.ADMIN_SYSTEM_PKG.sql
