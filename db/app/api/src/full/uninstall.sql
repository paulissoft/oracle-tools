/* perl generate_ddl.pl (version 2021-08-27) --nodynamic-sql --force-view --skip-install-sql --nostrip-source-schema */

/*
-- JDBC url            : jdbc:oracle:thin:ORACLE_TOOLS@//localhost:1521/orcl
-- source schema       : 
-- source database link: 
-- target schema       : ORACLE_TOOLS
-- target database link: 
-- object type         : 
-- object names include: 1
-- object names        : API_PKG
-- skip repeatables    : 0
-- interface           : pkg_ddl_util v4
-- transform params    : SEGMENT_ATTRIBUTES,TABLESPACE
-- owner               : ORACLE_TOOLS
*/
-- pkg_ddl_util v4
call dbms_application_info.set_module('uninstall.sql', null);
/* SQL statement 1 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;PACKAGE_SPEC;API_PKG;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 1');
REVOKE EXECUTE ON "ORACLE_TOOLS"."API_PKG" FROM "PUBLIC";

/* SQL statement 2 (DROP;ORACLE_TOOLS;PACKAGE_BODY;API_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 2');
DROP PACKAGE BODY ORACLE_TOOLS.API_PKG;

/* SQL statement 3 (DROP;ORACLE_TOOLS;PACKAGE_SPEC;API_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 3');
DROP PACKAGE ORACLE_TOOLS.API_PKG;

