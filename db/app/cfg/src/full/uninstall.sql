/* perl generate_ddl.pl (version 2022-09-28) --nodynamic-sql --force-view --group-constraints --skip-install-sql --nostrip-source-schema */

/*
-- JDBC url            : jdbc:oracle:thin:ORACLE_TOOLS@//host.docker.internal:1521/orcl
-- source schema       : 
-- source database link: 
-- target schema       : ORACLE_TOOLS
-- target database link: 
-- object type         : 
-- object names include: 1
-- object names        : CFG_INSTALL_PKG,CFG_PKG,UT_CODE_CHECK_PKG
-- skip repeatables    : 0
-- interface           : pkg_ddl_util v4
-- transform params    : SEGMENT_ATTRIBUTES,TABLESPACE
-- owner               : ORACLE_TOOLS
*/
-- pkg_ddl_util v4
call dbms_application_info.set_module('uninstall.sql', null);
/* SQL statement 1 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;PACKAGE_SPEC;CFG_INSTALL_PKG;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 1');
REVOKE EXECUTE ON "ORACLE_TOOLS"."CFG_INSTALL_PKG" FROM "PUBLIC";

/* SQL statement 2 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;PACKAGE_SPEC;CFG_PKG;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 2');
REVOKE EXECUTE ON "ORACLE_TOOLS"."CFG_PKG" FROM "PUBLIC";

/* SQL statement 3 (DROP;ORACLE_TOOLS;PACKAGE_BODY;CFG_INSTALL_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 3');
DROP PACKAGE BODY ORACLE_TOOLS.CFG_INSTALL_PKG;

/* SQL statement 4 (DROP;ORACLE_TOOLS;PACKAGE_BODY;UT_CODE_CHECK_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 4');
DROP PACKAGE BODY ORACLE_TOOLS.UT_CODE_CHECK_PKG;

/* SQL statement 5 (DROP;ORACLE_TOOLS;PACKAGE_SPEC;CFG_INSTALL_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 5');
DROP PACKAGE ORACLE_TOOLS.CFG_INSTALL_PKG;

/* SQL statement 6 (DROP;ORACLE_TOOLS;PACKAGE_SPEC;CFG_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 6');
DROP PACKAGE ORACLE_TOOLS.CFG_PKG;

/* SQL statement 7 (DROP;ORACLE_TOOLS;PACKAGE_SPEC;UT_CODE_CHECK_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 7');
DROP PACKAGE ORACLE_TOOLS.UT_CODE_CHECK_PKG;

