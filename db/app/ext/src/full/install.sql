whenever oserror exit failure
whenever sqlerror exit failure
set define off sqlblanklines on
ALTER SESSION SET PLSQL_WARNINGS = 'ENABLE:ALL';

prompt @@R__09.PACKAGE_SPEC.EXT_LOAD_FILE_PKG.sql
@@R__09.PACKAGE_SPEC.EXT_LOAD_FILE_PKG.sql
prompt @@R__10.VIEW.EXT_LOAD_FILE_COLUMN_V.sql
@@R__10.VIEW.EXT_LOAD_FILE_COLUMN_V.sql
prompt @@R__10.VIEW.EXT_LOAD_FILE_OBJECT_V.sql
@@R__10.VIEW.EXT_LOAD_FILE_OBJECT_V.sql
prompt @@R__14.PACKAGE_BODY.EXT_LOAD_FILE_PKG.sql
@@R__14.PACKAGE_BODY.EXT_LOAD_FILE_PKG.sql
