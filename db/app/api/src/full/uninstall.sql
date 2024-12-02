/* perl generate_ddl.pl (version 2023-01-05) --nodynamic-sql --force-view --group-constraints --skip-install-sql --source-schema=ORACLE_TOOLS --strip-source-schema */

/*
-- JDBC url - username : jdbc:oracle:thin:@//127.0.0.1:1521/freepdb1 - BC_PROXY[ORACLE_TOOLS]
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
-- include objects     : :OBJECT_GRANT::ORACLE_TOOLS::API_CALL_STACK_PKG::*:*:*
:OBJECT_GRANT::ORACLE_TOOLS::API_HEARTBEAT_PKG::*:*:*
:OBJECT_GRANT::ORACLE_TOOLS::API_LONGOPS_PKG::*:*:*
:OBJECT_GRANT::ORACLE_TOOLS::API_PKG::*:*:*
:OBJECT_GRANT::ORACLE_TOOLS::API_TIME_PKG::*:*:*
ORACLE_TOOLS:PACKAGE_BODY:API_CALL_STACK_PKG:::::::
ORACLE_TOOLS:PACKAGE_BODY:API_HEARTBEAT_PKG:::::::
ORACLE_TOOLS:PACKAGE_BODY:API_LONGOPS_PKG:::::::
ORACLE_TOOLS:PACKAGE_BODY:API_PKG:::::::
ORACLE_TOOLS:PACKAGE_BODY:API_TIME_PKG:::::::
ORACLE_TOOLS:PACKAGE_SPEC:API_CALL_STACK_PKG:::::::
ORACLE_TOOLS:PACKAGE_SPEC:API_HEARTBEAT_PKG:::::::
ORACLE_TOOLS:PACKAGE_SPEC:API_LONGOPS_PKG:::::::
ORACLE_TOOLS:PACKAGE_SPEC:API_PKG:::::::
ORACLE_TOOLS:PACKAGE_SPEC:API_TIME_PKG:::::::
-- owner               : ORACLE_TOOLS
*/
-- pkg_ddl_util v4
call dbms_application_info.set_module('uninstall.sql', null);
/* SQL statement 1 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;PACKAGE_SPEC;API_HEARTBEAT_PKG;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 1');
REVOKE EXECUTE ON "API_HEARTBEAT_PKG" FROM "PUBLIC";

/* SQL statement 2 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;PACKAGE_SPEC;API_LONGOPS_PKG;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 2');
REVOKE EXECUTE ON "API_LONGOPS_PKG" FROM "PUBLIC";

/* SQL statement 3 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;PACKAGE_SPEC;API_CALL_STACK_PKG;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 3');
REVOKE EXECUTE ON "API_CALL_STACK_PKG" FROM "PUBLIC";

/* SQL statement 4 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;PACKAGE_SPEC;API_TIME_PKG;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 4');
REVOKE EXECUTE ON "API_TIME_PKG" FROM "PUBLIC";

/* SQL statement 5 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;PACKAGE_SPEC;API_PKG;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 5');
REVOKE EXECUTE ON "API_PKG" FROM "PUBLIC";

/* SQL statement 6 (DROP;ORACLE_TOOLS;PACKAGE_BODY;API_TIME_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 6');
DROP PACKAGE BODY API_TIME_PKG;

/* SQL statement 7 (DROP;ORACLE_TOOLS;PACKAGE_BODY;API_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 7');
DROP PACKAGE BODY API_PKG;

/* SQL statement 8 (DROP;ORACLE_TOOLS;PACKAGE_BODY;API_LONGOPS_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 8');
DROP PACKAGE BODY API_LONGOPS_PKG;

/* SQL statement 9 (DROP;ORACLE_TOOLS;PACKAGE_BODY;API_HEARTBEAT_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 9');
DROP PACKAGE BODY API_HEARTBEAT_PKG;

/* SQL statement 10 (DROP;ORACLE_TOOLS;PACKAGE_BODY;API_CALL_STACK_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 10');
DROP PACKAGE BODY API_CALL_STACK_PKG;

/* SQL statement 11 (DROP;ORACLE_TOOLS;PACKAGE_SPEC;API_HEARTBEAT_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 11');
DROP PACKAGE API_HEARTBEAT_PKG;

/* SQL statement 12 (DROP;ORACLE_TOOLS;PACKAGE_SPEC;API_CALL_STACK_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 12');
DROP PACKAGE API_CALL_STACK_PKG;

/* SQL statement 13 (DROP;ORACLE_TOOLS;PACKAGE_SPEC;API_TIME_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 13');
DROP PACKAGE API_TIME_PKG;

/* SQL statement 14 (DROP;ORACLE_TOOLS;PACKAGE_SPEC;API_LONGOPS_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 14');
DROP PACKAGE API_LONGOPS_PKG;

/* SQL statement 15 (DROP;ORACLE_TOOLS;PACKAGE_SPEC;API_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 15');
DROP PACKAGE API_PKG;

