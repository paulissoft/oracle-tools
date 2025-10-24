/*
-- Script: adb-bootstrap.sql
-- Goal  : A SQL*Plus script to bootstrap the ADMIN part of (P)aulissoft (A)pplication (T)ools for (O)racle
-- Note  : This script should NOT be run by DBMS_CLOUD_REPO.INSTALL_FILE
*/

whenever oserror exit failure
whenever sqlerror exit failure

alter session set current_schema = ADMIN;

prompt @@src/incr/V20251021102600__create_GITHUB_INSTALLED_PROJECTS.sql
@@src/incr/V20251021102600__create_GITHUB_INSTALLED_PROJECTS.sql
prompt @@src/incr/V20251021103000__create_GITHUB_INSTALLED_VERSIONS.sql
@@src/incr/V20251021103000__create_GITHUB_INSTALLED_VERSIONS.sql
prompt @@src/incr/V20251021103400__create_GITHUB_INSTALLED_VERSIONS_OBJECTS.sql
@@src/incr/V20251021103400__create_GITHUB_INSTALLED_VERSIONS_OBJECTS.sql
prompt @@src/incr/V20251024163100__alter_GITHUB_INSTALLED_PROJECTS.sql
@@src/incr/V20251024163100__alter_GITHUB_INSTALLED_PROJECTS.sql

prompt @@src/full/R__09.PACKAGE_SPEC.ADMIN_INSTALL_PKG.sql
@@src/full/R__09.PACKAGE_SPEC.ADMIN_INSTALL_PKG.sql
prompt @@src/full/R__10.VIEW.GITHUB_INSTALLED_VERSIONS_V.sql
@@src/full/R__10.VIEW.GITHUB_INSTALLED_VERSIONS_V.sql
prompt @@src/full/R__14.PACKAGE_BODY.ADMIN_INSTALL_PKG.sql
@@src/full/R__14.PACKAGE_BODY.ADMIN_INSTALL_PKG.sql
