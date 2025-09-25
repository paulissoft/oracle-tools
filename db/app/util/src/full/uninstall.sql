/* perl generate_ddl.pl (version 2024-12-07) --nodynamic-sql --force-view --group-constraints --skip-install-sql --source-schema=ORACLE_TOOLS --strip-source-schema */

/*
-- JDBC url - username : jdbc:oracle:thin:@knpv_dev - KNPV_PROXY[ORACLE_TOOLS]
-- source schema       : 
-- source database link: 
-- target schema       : ORACLE_TOOLS
-- target database link: 
-- object type         : 
-- object names include: 
-- object names        : 
-- skip repeatables    : 0
-- interface           : pkg_ddl_util v4
-- transform params    : 
-- exclude objects     : 
-- include objects     : :OBJECT_GRANT::ORACLE_TOOLS::UTIL_*_PKG::*:*:*
ORACLE_TOOLS:PACKAGE_BODY:UTIL_*_PKG:::::::
ORACLE_TOOLS:PACKAGE_SPEC:UTIL_*_PKG:::::::
-- owner               : ORACLE_TOOLS
*/
-- pkg_ddl_util v4
call dbms_application_info.set_module('uninstall.sql', null);
/* SQL statement 1 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;PACKAGE_SPEC;UTIL_DICT_PKG;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 1');
REVOKE EXECUTE ON "UTIL_DICT_PKG" FROM "PUBLIC";

/* SQL statement 2 (DROP;ORACLE_TOOLS;PACKAGE_BODY;UTIL_DICT_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 2');
DROP PACKAGE BODY UTIL_DICT_PKG;

/* SQL statement 3 (DROP;ORACLE_TOOLS;PACKAGE_SPEC;UTIL_DICT_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 3');
DROP PACKAGE UTIL_DICT_PKG;

