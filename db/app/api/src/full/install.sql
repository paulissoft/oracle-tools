whenever oserror exit failure
whenever sqlerror exit failure
set define off sqlblanklines on
ALTER SESSION SET PLSQL_WARNINGS = 'ENABLE:ALL';

prompt @@R__09.PACKAGE_SPEC.API_PKG.sql
@@R__09.PACKAGE_SPEC.API_PKG.sql
show errors PACKAGE "API_PKG"
prompt @@R__14.PACKAGE_BODY.API_PKG.sql
@@R__14.PACKAGE_BODY.API_PKG.sql
show errors PACKAGE BODY "API_PKG"
prompt @@R__18.OBJECT_GRANT.API_PKG.sql
@@R__18.OBJECT_GRANT.API_PKG.sql
