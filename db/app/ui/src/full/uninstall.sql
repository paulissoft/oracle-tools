/* perl generate_ddl.pl (version 2023-01-05) --nodynamic-sql --force-view --group-constraints --skip-install-sql --source-schema=ORACLE_TOOLS --strip-source-schema */

/*
-- JDBC url - username : jdbc:oracle:thin:@//127.0.0.1:1521/freepdb1 - BC_PROXY[ORACLE_TOOLS]
-- source schema       : 
-- source database link: 
-- target schema       : ORACLE_TOOLS
-- target database link: 
-- object type         : 
-- object names include: 1
-- object names        : UI_RESET_PWD_JOB,UI_APEX_MESSAGES_PKG,UI_APEX_SYNCHRONIZE,UI_ERROR_PKG,UI_SESSION_PKG,UI_USER_MANAGEMENT_PKG,UI_APEX_MESSAGES_V
-- skip repeatables    : 0
-- interface           : pkg_ddl_util v4
-- transform params    : 
-- exclude objects     : 
-- include objects     : 
-- owner               : ORACLE_TOOLS
*/
-- pkg_ddl_util v4
call dbms_application_info.set_module('uninstall.sql', null);
/* SQL statement 1 (DBMS_SCHEDULER.DROP_JOB;ORACLE_TOOLS;PROCOBJ;UI_RESET_PWD_JOB;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 1');
BEGIN DBMS_SCHEDULER.DROP_JOB('UI_RESET_PWD_JOB'); END;
/

/* SQL statement 2 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;PACKAGE_SPEC;UI_APEX_MESSAGES_PKG;;BC_PORTAL;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 2');
REVOKE EXECUTE ON "UI_APEX_MESSAGES_PKG" FROM "BC_PORTAL";

/* SQL statement 3 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;PACKAGE_SPEC;UI_APEX_MESSAGES_PKG;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 3');
REVOKE EXECUTE ON "UI_APEX_MESSAGES_PKG" FROM "PUBLIC";

/* SQL statement 4 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;PACKAGE_SPEC;UI_APEX_SYNCHRONIZE;;BC_BO;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 4');
REVOKE EXECUTE ON "UI_APEX_SYNCHRONIZE" FROM "BC_BO";

/* SQL statement 5 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;PACKAGE_SPEC;UI_APEX_SYNCHRONIZE;;BC_PORTAL;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 5');
REVOKE EXECUTE ON "UI_APEX_SYNCHRONIZE" FROM "BC_PORTAL";

/* SQL statement 6 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;PACKAGE_SPEC;UI_APEX_SYNCHRONIZE;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 6');
REVOKE EXECUTE ON "UI_APEX_SYNCHRONIZE" FROM "PUBLIC";

/* SQL statement 7 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;PACKAGE_SPEC;UI_ERROR_PKG;;BC_PORTAL;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 7');
REVOKE EXECUTE ON "UI_ERROR_PKG" FROM "BC_PORTAL";

/* SQL statement 8 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;PACKAGE_SPEC;UI_ERROR_PKG;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 8');
REVOKE EXECUTE ON "UI_ERROR_PKG" FROM "PUBLIC";

/* SQL statement 9 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;PACKAGE_SPEC;UI_SESSION_PKG;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 9');
REVOKE EXECUTE ON "UI_SESSION_PKG" FROM "PUBLIC";

/* SQL statement 10 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;PACKAGE_SPEC;UI_USER_MANAGEMENT_PKG;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 10');
REVOKE EXECUTE ON "UI_USER_MANAGEMENT_PKG" FROM "PUBLIC";

/* SQL statement 11 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;PACKAGE_SPEC;UI_APEX_MESSAGES_PKG;;BC_BO;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 11');
REVOKE EXECUTE ON "UI_APEX_MESSAGES_PKG" FROM "BC_BO";

/* SQL statement 12 (DROP;ORACLE_TOOLS;PACKAGE_BODY;UI_USER_MANAGEMENT_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 12');
DROP PACKAGE BODY UI_USER_MANAGEMENT_PKG;

/* SQL statement 13 (DROP;ORACLE_TOOLS;PACKAGE_BODY;UI_SESSION_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 13');
DROP PACKAGE BODY UI_SESSION_PKG;

/* SQL statement 14 (DROP;ORACLE_TOOLS;PACKAGE_BODY;UI_ERROR_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 14');
DROP PACKAGE BODY UI_ERROR_PKG;

/* SQL statement 15 (DROP;ORACLE_TOOLS;PACKAGE_BODY;UI_APEX_SYNCHRONIZE;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 15');
DROP PACKAGE BODY UI_APEX_SYNCHRONIZE;

/* SQL statement 16 (DROP;ORACLE_TOOLS;PACKAGE_BODY;UI_APEX_MESSAGES_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 16');
DROP PACKAGE BODY UI_APEX_MESSAGES_PKG;

/* SQL statement 17 (DROP;ORACLE_TOOLS;VIEW;UI_APEX_MESSAGES_V;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 17');
DROP VIEW UI_APEX_MESSAGES_V;

/* SQL statement 18 (DROP;ORACLE_TOOLS;PACKAGE_SPEC;UI_USER_MANAGEMENT_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 18');
DROP PACKAGE UI_USER_MANAGEMENT_PKG;

/* SQL statement 19 (DROP;ORACLE_TOOLS;PACKAGE_SPEC;UI_ERROR_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 19');
DROP PACKAGE UI_ERROR_PKG;

/* SQL statement 20 (DROP;ORACLE_TOOLS;PACKAGE_SPEC;UI_APEX_SYNCHRONIZE;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 20');
DROP PACKAGE UI_APEX_SYNCHRONIZE;

/* SQL statement 21 (DROP;ORACLE_TOOLS;PACKAGE_SPEC;UI_SESSION_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 21');
DROP PACKAGE UI_SESSION_PKG;

/* SQL statement 22 (DROP;ORACLE_TOOLS;PACKAGE_SPEC;UI_APEX_MESSAGES_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 22');
DROP PACKAGE UI_APEX_MESSAGES_PKG;

