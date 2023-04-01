REMARK Try to call Flyway script beforeEachMigrate.sql (add its directory to SQLPATH) so that PLSQL_CCFlags can be set.
REMARK But no harm done if it is not there.

whenever oserror continue
whenever sqlerror continue
@@beforeEachMigrate.sql

whenever oserror exit failure
whenever sqlerror exit failure
set define off sqlblanklines on
ALTER SESSION SET PLSQL_WARNINGS = 'ENABLE:ALL';

prompt @@R__09.PACKAGE_SPEC.EXT_LOAD_FILE_PKG.sql
@@R__09.PACKAGE_SPEC.EXT_LOAD_FILE_PKG.sql
show errors PACKAGE "EXT_LOAD_FILE_PKG"
prompt @@R__10.VIEW.EXT_LOAD_FILE_COLUMN_V.sql
@@R__10.VIEW.EXT_LOAD_FILE_COLUMN_V.sql
show errors VIEW "EXT_LOAD_FILE_COLUMN_V"
prompt @@R__10.VIEW.EXT_LOAD_FILE_OBJECT_V.sql
@@R__10.VIEW.EXT_LOAD_FILE_OBJECT_V.sql
show errors VIEW "EXT_LOAD_FILE_OBJECT_V"
prompt @@R__14.PACKAGE_BODY.EXT_LOAD_FILE_PKG.sql
@@R__14.PACKAGE_BODY.EXT_LOAD_FILE_PKG.sql
show errors PACKAGE BODY "EXT_LOAD_FILE_PKG"
prompt @@R__18.OBJECT_GRANT.EXT_LOAD_FILE_PKG.sql
@@R__18.OBJECT_GRANT.EXT_LOAD_FILE_PKG.sql
