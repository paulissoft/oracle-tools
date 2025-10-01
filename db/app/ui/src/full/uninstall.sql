/* perl generate_ddl.pl (version 2024-12-07) --nodynamic-sql --force-view --group-constraints --skip-install-sql --source-schema=ORACLE_TOOLS --strip-source-schema */

/*
-- JDBC url - username : jdbc:oracle:thin:@knpv_dev - KNPV_PROXY[ORACLE_TOOLS]
-- source schema       : 
-- source database link: 
-- target schema       : ORACLE_TOOLS
-- target database link: 
-- object type         : 
-- object names include: 1
-- object names        : UI_RESET_PWD_JOB,UI_APEX_MESSAGES_PKG,UI_APEX_SYNCHRONIZE,UI_ERROR_PKG,UI_SESSION_PKG,UI_USER_MANAGEMENT_PKG,UI_APEX_MESSAGES_V,UI_APEX_MESSAGES_TRG,UI_APEX_EXPORT_PKG
-- skip repeatables    : 0
-- interface           : pkg_ddl_util v4
-- transform params    : 
-- exclude objects     : 
-- include objects     : 
-- owner               : ORACLE_TOOLS
*/
-- pkg_ddl_util v4
call dbms_application_info.set_module('uninstall.sql', null);
/* SQL statement 1 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;PACKAGE_SPEC;UI_USER_MANAGEMENT_PKG;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 1');
REVOKE EXECUTE ON "UI_USER_MANAGEMENT_PKG" FROM "PUBLIC";

/* SQL statement 2 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;PACKAGE_SPEC;UI_SESSION_PKG;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 2');
REVOKE EXECUTE ON "UI_SESSION_PKG" FROM "PUBLIC";

/* SQL statement 3 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;PACKAGE_SPEC;UI_ERROR_PKG;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 3');
REVOKE EXECUTE ON "UI_ERROR_PKG" FROM "PUBLIC";

/* SQL statement 4 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;PACKAGE_SPEC;UI_APEX_SYNCHRONIZE;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 4');
REVOKE EXECUTE ON "UI_APEX_SYNCHRONIZE" FROM "PUBLIC";

/* SQL statement 5 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;PACKAGE_SPEC;UI_APEX_MESSAGES_PKG;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 5');
REVOKE EXECUTE ON "UI_APEX_MESSAGES_PKG" FROM "PUBLIC";

/* SQL statement 6 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;PACKAGE_SPEC;UI_APEX_EXPORT_PKG;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 6');
REVOKE EXECUTE ON "UI_APEX_EXPORT_PKG" FROM "PUBLIC";

/* SQL statement 7 (DROP;ORACLE_TOOLS;TRIGGER;UI_APEX_MESSAGES_TRG;ORACLE_TOOLS;VIEW;UI_APEX_MESSAGES_V;;;;;2) */
call dbms_application_info.set_action('SQL statement 7');
DROP TRIGGER UI_APEX_MESSAGES_TRG;

/* SQL statement 8 (DROP;ORACLE_TOOLS;PACKAGE_BODY;UI_USER_MANAGEMENT_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 8');
DROP PACKAGE BODY UI_USER_MANAGEMENT_PKG;

/* SQL statement 9 (DROP;ORACLE_TOOLS;PACKAGE_BODY;UI_SESSION_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 9');
DROP PACKAGE BODY UI_SESSION_PKG;

/* SQL statement 10 (DROP;ORACLE_TOOLS;PACKAGE_BODY;UI_ERROR_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 10');
DROP PACKAGE BODY UI_ERROR_PKG;

/* SQL statement 11 (DROP;ORACLE_TOOLS;PACKAGE_BODY;UI_APEX_SYNCHRONIZE;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 11');
DROP PACKAGE BODY UI_APEX_SYNCHRONIZE;

/* SQL statement 12 (DROP;ORACLE_TOOLS;PACKAGE_BODY;UI_APEX_EXPORT_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 12');
DROP PACKAGE BODY UI_APEX_EXPORT_PKG;

/* SQL statement 13 (DROP;ORACLE_TOOLS;PACKAGE_BODY;UI_APEX_MESSAGES_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 13');
DROP PACKAGE BODY UI_APEX_MESSAGES_PKG;

/* SQL statement 14 (DROP;ORACLE_TOOLS;VIEW;UI_APEX_MESSAGES_V;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 14');
DROP VIEW UI_APEX_MESSAGES_V;

/* SQL statement 15 (DROP;ORACLE_TOOLS;PACKAGE_SPEC;UI_USER_MANAGEMENT_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 15');
DROP PACKAGE UI_USER_MANAGEMENT_PKG;

/* SQL statement 16 (DROP;ORACLE_TOOLS;PACKAGE_SPEC;UI_SESSION_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 16');
DROP PACKAGE UI_SESSION_PKG;

/* SQL statement 17 (DROP;ORACLE_TOOLS;PACKAGE_SPEC;UI_ERROR_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 17');
DROP PACKAGE UI_ERROR_PKG;

/* SQL statement 18 (DROP;ORACLE_TOOLS;PACKAGE_SPEC;UI_APEX_SYNCHRONIZE;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 18');
DROP PACKAGE UI_APEX_SYNCHRONIZE;

/* SQL statement 19 (DROP;ORACLE_TOOLS;PACKAGE_SPEC;UI_APEX_MESSAGES_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 19');
DROP PACKAGE UI_APEX_MESSAGES_PKG;

/* SQL statement 20 (DROP;ORACLE_TOOLS;PACKAGE_SPEC;UI_APEX_EXPORT_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 20');
DROP PACKAGE UI_APEX_EXPORT_PKG;

