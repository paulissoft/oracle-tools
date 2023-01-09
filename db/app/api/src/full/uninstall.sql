/* perl generate_ddl.pl (version 2023-01-05) --nodynamic-sql --force-view --group-constraints --skip-install-sql --source-schema=ORACLE_TOOLS --strip-source-schema */

/*
-- JDBC url            : jdbc:oracle:thin:ORACLE_TOOLS@//localhost:1521/orcl
-- source schema       : 
-- source database link: 
-- target schema       : ORACLE_TOOLS
-- target database link: 
-- object type         : 
-- object names include: 1
-- object names        : API_PKG,API_LONGOPS_PKG
-- skip repeatables    : 0
-- interface           : pkg_ddl_util v4
-- transform params    : 
-- exclude objects     : 
-- include objects     : 
-- owner               : ORACLE_TOOLS
*/
-- pkg_ddl_util v4
call dbms_application_info.set_module('uninstall.sql', null);
/* SQL statement 1 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;PACKAGE_SPEC;API_LONGOPS_PKG;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 1');
REVOKE EXECUTE ON "API_LONGOPS_PKG" FROM "PUBLIC";

/* SQL statement 2 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;PACKAGE_SPEC;API_PKG;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 2');
REVOKE EXECUTE ON "API_PKG" FROM "PUBLIC";

/* SQL statement 3 (DROP;ORACLE_TOOLS;PACKAGE_BODY;API_LONGOPS_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 3');
DROP PACKAGE BODY API_LONGOPS_PKG;

/* SQL statement 4 (DROP;ORACLE_TOOLS;PACKAGE_BODY;API_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 4');
DROP PACKAGE BODY API_PKG;

/* SQL statement 5 (DROP;ORACLE_TOOLS;PACKAGE_SPEC;API_LONGOPS_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 5');
DROP PACKAGE API_LONGOPS_PKG;

/* SQL statement 6 (DROP;ORACLE_TOOLS;PACKAGE_SPEC;API_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 6');
DROP PACKAGE API_PKG;

