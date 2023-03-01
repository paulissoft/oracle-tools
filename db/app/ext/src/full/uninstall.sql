/* perl generate_ddl.pl (version 2023-01-05) --nodynamic-sql --force-view --group-constraints --skip-install-sql --source-schema=ORACLE_TOOLS --strip-source-schema */

/*
-- JDBC url - username : jdbc:oracle:thin:@pato - ORACLE_TOOLS
-- source schema       : 
-- source database link: 
-- target schema       : ORACLE_TOOLS
-- target database link: 
-- object type         : 
-- object names include: 1
-- object names        : EXT_LOAD_FILE_PKG
,EXT_LOAD_FILE_COLUMN_V
,EXT_LOAD_FILE_OBJECT_V
-- skip repeatables    : 0
-- interface           : pkg_ddl_util v4
-- transform params    : 
-- exclude objects     : 
-- include objects     : 
-- owner               : ORACLE_TOOLS
*/
-- pkg_ddl_util v4
call dbms_application_info.set_module('uninstall.sql', null);
/* SQL statement 1 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;PACKAGE_SPEC;EXT_LOAD_FILE_PKG;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 1');
REVOKE EXECUTE ON "EXT_LOAD_FILE_PKG" FROM "PUBLIC";

/* SQL statement 2 (DROP;ORACLE_TOOLS;PACKAGE_BODY;EXT_LOAD_FILE_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 2');
DROP PACKAGE BODY EXT_LOAD_FILE_PKG;

/* SQL statement 3 (DROP;ORACLE_TOOLS;VIEW;EXT_LOAD_FILE_COLUMN_V;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 3');
DROP VIEW EXT_LOAD_FILE_COLUMN_V;

/* SQL statement 4 (DROP;ORACLE_TOOLS;VIEW;EXT_LOAD_FILE_OBJECT_V;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 4');
DROP VIEW EXT_LOAD_FILE_OBJECT_V;

/* SQL statement 5 (DROP;ORACLE_TOOLS;PACKAGE_SPEC;EXT_LOAD_FILE_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 5');
DROP PACKAGE EXT_LOAD_FILE_PKG;

