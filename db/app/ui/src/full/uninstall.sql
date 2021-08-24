/* perl generate_ddl.pl (version 2021-08-24) --nodynamic-sql --force-view --noremove-output-directory --skip-install-sql --nostrip-source-schema */

/*
-- JDBC url            : jdbc:oracle:thin:ORACLE_TOOLS@//localhost:1521/orcl
-- source schema       : 
-- source database link: 
-- target schema       : ORACLE_TOOLS
-- target database link: 
-- object type         : 
-- object names include: 1
-- object names        : UI_APEX_MESSAGES_PKG
,UI_ERROR_PKG
,UI_SESSION_PKG
,UI_USER_MANAGEMENT_PKG
,UI_APEX_MESSAGES_V
,UI_RESET_PWD_JOB
-- skip repeatables    : 0
-- interface           : pkg_ddl_util v4
-- transform params    : SEGMENT_ATTRIBUTES,TABLESPACE
-- owner               : ORACLE_TOOLS
*/
-- pkg_ddl_util v4
call dbms_application_info.set_module('uninstall.sql', null);
/* SQL statement 1 (DBMS_SCHEDULER.DROP_JOB;ORACLE_TOOLS;PROCOBJ;UI_RESET_PWD_JOB;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 1');
BEGIN DBMS_SCHEDULER.DROP_JOB('UI_RESET_PWD_JOB'); END;
/

/* SQL statement 2 (DROP;ORACLE_TOOLS;PACKAGE_BODY;UI_APEX_MESSAGES_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 2');
DROP PACKAGE BODY ORACLE_TOOLS.UI_APEX_MESSAGES_PKG;

/* SQL statement 3 (DROP;ORACLE_TOOLS;PACKAGE_BODY;UI_ERROR_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 3');
DROP PACKAGE BODY ORACLE_TOOLS.UI_ERROR_PKG;

/* SQL statement 4 (DROP;ORACLE_TOOLS;PACKAGE_BODY;UI_SESSION_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 4');
DROP PACKAGE BODY ORACLE_TOOLS.UI_SESSION_PKG;

/* SQL statement 5 (DROP;ORACLE_TOOLS;PACKAGE_BODY;UI_USER_MANAGEMENT_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 5');
DROP PACKAGE BODY ORACLE_TOOLS.UI_USER_MANAGEMENT_PKG;

/* SQL statement 6 (DROP;ORACLE_TOOLS;TRIGGER;UI_APEX_MESSAGES_TRG;ORACLE_TOOLS;VIEW;UI_APEX_MESSAGES_V;;;;;2) */
call dbms_application_info.set_action('SQL statement 6');
DROP TRIGGER ORACLE_TOOLS.UI_APEX_MESSAGES_TRG;

/* SQL statement 7 (DROP;ORACLE_TOOLS;VIEW;UI_APEX_MESSAGES_V;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 7');
DROP VIEW ORACLE_TOOLS.UI_APEX_MESSAGES_V;

/* SQL statement 8 (DROP;ORACLE_TOOLS;PACKAGE_SPEC;UI_APEX_MESSAGES_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 8');
DROP PACKAGE ORACLE_TOOLS.UI_APEX_MESSAGES_PKG;

/* SQL statement 9 (DROP;ORACLE_TOOLS;PACKAGE_SPEC;UI_ERROR_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 9');
DROP PACKAGE ORACLE_TOOLS.UI_ERROR_PKG;

/* SQL statement 10 (DROP;ORACLE_TOOLS;PACKAGE_SPEC;UI_SESSION_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 10');
DROP PACKAGE ORACLE_TOOLS.UI_SESSION_PKG;

/* SQL statement 11 (DROP;ORACLE_TOOLS;PACKAGE_SPEC;UI_USER_MANAGEMENT_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 11');
DROP PACKAGE ORACLE_TOOLS.UI_USER_MANAGEMENT_PKG;

