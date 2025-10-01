REMARK Try to call Flyway script beforeEachMigrate.sql (add its directory to SQLPATH) so that PLSQL_CCFlags can be set.
REMARK But no harm done if it is not there.

whenever oserror continue
whenever sqlerror continue
@@beforeEachMigrate.sql

whenever oserror exit failure
whenever sqlerror exit failure
set define off sqlblanklines on
ALTER SESSION SET PLSQL_WARNINGS = 'ENABLE:ALL';

prompt @@R__09.PACKAGE_SPEC.CFG_INSTALL_PKG.sql
@@R__09.PACKAGE_SPEC.CFG_INSTALL_PKG.sql
show errors PACKAGE "CFG_INSTALL_PKG"
prompt @@R__09.PACKAGE_SPEC.CFG_PKG.sql
@@R__09.PACKAGE_SPEC.CFG_PKG.sql
show errors PACKAGE "CFG_PKG"
prompt @@R__09.PACKAGE_SPEC.UT_CODE_CHECK_PKG.sql
@@R__09.PACKAGE_SPEC.UT_CODE_CHECK_PKG.sql
show errors PACKAGE "UT_CODE_CHECK_PKG"
prompt @@R__14.PACKAGE_BODY.CFG_INSTALL_PKG.sql
@@R__14.PACKAGE_BODY.CFG_INSTALL_PKG.sql
show errors PACKAGE BODY "CFG_INSTALL_PKG"
prompt @@R__14.PACKAGE_BODY.UT_CODE_CHECK_PKG.sql
@@R__14.PACKAGE_BODY.UT_CODE_CHECK_PKG.sql
show errors PACKAGE BODY "UT_CODE_CHECK_PKG"
prompt @@R__18.OBJECT_GRANT.CFG_INSTALL_PKG.sql
@@R__18.OBJECT_GRANT.CFG_INSTALL_PKG.sql
prompt @@R__18.OBJECT_GRANT.CFG_PKG.sql
@@R__18.OBJECT_GRANT.CFG_PKG.sql
