/* perl generate_ddl.pl (version 2021-08-24) --nodynamic-sql --force-view --noremove-output-directory --skip-install-sql --nostrip-source-schema */

/*
-- JDBC url            : jdbc:oracle:thin:ORACLE_TOOLS@//localhost:1521/orcl
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
-- transform params    : SEGMENT_ATTRIBUTES,TABLESPACE
-- owner               : ORACLE_TOOLS
*/
-- pkg_ddl_util v4
call dbms_application_info.set_module('uninstall.sql', null);
/* SQL statement 1 (DROP;ORACLE_TOOLS;PACKAGE_BODY;EXT_LOAD_FILE_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 1');
DROP PACKAGE BODY ORACLE_TOOLS.EXT_LOAD_FILE_PKG;

/* SQL statement 2 (DROP;ORACLE_TOOLS;VIEW;EXT_LOAD_FILE_COLUMN_V;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 2');
DROP VIEW ORACLE_TOOLS.EXT_LOAD_FILE_COLUMN_V;

/* SQL statement 3 (DROP;ORACLE_TOOLS;VIEW;EXT_LOAD_FILE_OBJECT_V;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 3');
DROP VIEW ORACLE_TOOLS.EXT_LOAD_FILE_OBJECT_V;

/* SQL statement 4 (DROP;ORACLE_TOOLS;PACKAGE_SPEC;EXT_LOAD_FILE_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 4');
DROP PACKAGE ORACLE_TOOLS.EXT_LOAD_FILE_PKG;

