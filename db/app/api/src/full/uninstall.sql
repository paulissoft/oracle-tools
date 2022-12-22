/* perl generate_ddl.pl (version 2022-12-02) --nodynamic-sql --force-view --group-constraints --skip-install-sql --source-schema=ORACLE_TOOLS --strip-source-schema */

/*
-- JDBC url            : jdbc:oracle:thin:ORACLE_TOOLS@//localhost:1521/orcl
-- owner               : ORACLE_TOOLS
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
-- objects include     : 
-- objects             : 
*/
-- pkg_ddl_util v4
call dbms_application_info.set_module('uninstall.sql', null);
/* SQL statement 1 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;PACKAGE_SPEC;API_PKG;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 1');
REVOKE EXECUTE ON "API_PKG" FROM "PUBLIC";

/* SQL statement 2 (DROP;ORACLE_TOOLS;PACKAGE_BODY;API_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 2');
DROP PACKAGE BODY API_PKG;

/* SQL statement 3 (DROP;ORACLE_TOOLS;PACKAGE_SPEC;API_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 3');
DROP PACKAGE API_PKG;

