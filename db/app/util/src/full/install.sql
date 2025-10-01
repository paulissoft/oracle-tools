REMARK Try to call Flyway script beforeEachMigrate.sql (add its directory to SQLPATH) so that PLSQL_CCFlags can be set.
REMARK But no harm done if it is not there.

whenever oserror continue
whenever sqlerror continue
@@beforeEachMigrate.sql

whenever oserror exit failure
whenever sqlerror exit failure
set define off sqlblanklines on
ALTER SESSION SET PLSQL_WARNINGS = 'ENABLE:ALL';

prompt @@R__09.PACKAGE_SPEC.UTIL_DICT_PKG.sql
@@R__09.PACKAGE_SPEC.UTIL_DICT_PKG.sql
show errors PACKAGE "UTIL_DICT_PKG"
prompt @@R__14.PACKAGE_BODY.UTIL_DICT_PKG.sql
@@R__14.PACKAGE_BODY.UTIL_DICT_PKG.sql
show errors PACKAGE BODY "UTIL_DICT_PKG"
prompt @@R__18.OBJECT_GRANT.UTIL_DICT_PKG.sql
@@R__18.OBJECT_GRANT.UTIL_DICT_PKG.sql
