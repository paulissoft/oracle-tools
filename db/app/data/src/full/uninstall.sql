/* perl generate_ddl.pl (version 2022-09-06) --nodynamic-sql --force-view --skip-install-sql --nostrip-source-schema */

/*
-- JDBC url            : jdbc:oracle:thin:ORACLE_TOOLS@//host.docker.internal:1521/orcl
-- source schema       : 
-- source database link: 
-- target schema       : ORACLE_TOOLS
-- target database link: 
-- object type         : 
-- object names include: 1
-- object names        : DATA_SESSION_USERNAME,DATA_TIMESTAMP,DATA_API_PKG,DATA_BR_PKG
-- skip repeatables    : 0
-- interface           : pkg_ddl_util v4
-- transform params    : SEGMENT_ATTRIBUTES,TABLESPACE
-- owner               : ORACLE_TOOLS
*/
-- pkg_ddl_util v4
call dbms_application_info.set_module('uninstall.sql', null);
/* SQL statement 1 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;PACKAGE_SPEC;DATA_API_PKG;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 1');
REVOKE EXECUTE ON "ORACLE_TOOLS"."DATA_API_PKG" FROM "PUBLIC";

/* SQL statement 2 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;PACKAGE_SPEC;DATA_BR_PKG;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 2');
REVOKE EXECUTE ON "ORACLE_TOOLS"."DATA_BR_PKG" FROM "PUBLIC";

/* SQL statement 3 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;FUNCTION;DATA_SESSION_USERNAME;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 3');
REVOKE EXECUTE ON "ORACLE_TOOLS"."DATA_SESSION_USERNAME" FROM "PUBLIC";

/* SQL statement 4 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;FUNCTION;DATA_TIMESTAMP;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 4');
REVOKE EXECUTE ON "ORACLE_TOOLS"."DATA_TIMESTAMP" FROM "PUBLIC";

/* SQL statement 5 (DROP;ORACLE_TOOLS;FUNCTION;DATA_SESSION_USERNAME;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 5');
DROP FUNCTION ORACLE_TOOLS.DATA_SESSION_USERNAME;

/* SQL statement 6 (DROP;ORACLE_TOOLS;FUNCTION;DATA_TIMESTAMP;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 6');
DROP FUNCTION ORACLE_TOOLS.DATA_TIMESTAMP;

/* SQL statement 7 (DROP;ORACLE_TOOLS;PACKAGE_BODY;DATA_API_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 7');
DROP PACKAGE BODY ORACLE_TOOLS.DATA_API_PKG;

/* SQL statement 8 (DROP;ORACLE_TOOLS;PACKAGE_BODY;DATA_BR_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 8');
DROP PACKAGE BODY ORACLE_TOOLS.DATA_BR_PKG;

/* SQL statement 9 (DROP;ORACLE_TOOLS;PACKAGE_SPEC;DATA_API_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 9');
DROP PACKAGE ORACLE_TOOLS.DATA_API_PKG;

/* SQL statement 10 (DROP;ORACLE_TOOLS;PACKAGE_SPEC;DATA_BR_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 10');
DROP PACKAGE ORACLE_TOOLS.DATA_BR_PKG;

