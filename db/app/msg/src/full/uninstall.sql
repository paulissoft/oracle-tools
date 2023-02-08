/* perl generate_ddl.pl (version 2023-01-05) --nodynamic-sql --force-view --group-constraints --skip-install-sql --source-schema=ORACLE_TOOLS --strip-source-schema */

/*
-- JDBC url - username : jdbc:oracle:thin:@pato - ORACLE_TOOLS
-- source schema       : 
-- source database link: 
-- target schema       : ORACLE_TOOLS
-- target database link: 
-- object type         : 
-- object names include: 1
-- object names        : MSG_TYP,MSG_AQ_PKG,MSG_NOTIFICATION_PRC,REST_WEB_SERVICE_TYP
-- skip repeatables    : 0
-- interface           : pkg_ddl_util v4
-- transform params    : 
-- exclude objects     : 
-- include objects     : 
-- owner               : ORACLE_TOOLS
*/
-- pkg_ddl_util v4
call dbms_application_info.set_module('uninstall.sql', null);
/* SQL statement 1 (DROP;ORACLE_TOOLS;PACKAGE_BODY;MSG_AQ_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 1');
DROP PACKAGE BODY MSG_AQ_PKG;

/* SQL statement 2 (DROP;ORACLE_TOOLS;PROCEDURE;MSG_NOTIFICATION_PRC;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 2');
DROP PROCEDURE MSG_NOTIFICATION_PRC;

/* SQL statement 3 (DROP;ORACLE_TOOLS;TYPE_BODY;MSG_TYP;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 3');
DROP TYPE BODY MSG_TYP;

/* SQL statement 4 (DROP;ORACLE_TOOLS;PACKAGE_SPEC;MSG_AQ_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 4');
DROP PACKAGE MSG_AQ_PKG;

/* SQL statement 5 (DROP;ORACLE_TOOLS;TYPE_BODY;REST_WEB_SERVICE_TYP;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 5');
DROP TYPE BODY REST_WEB_SERVICE_TYP;

/* SQL statement 6 (DROP;ORACLE_TOOLS;TYPE_SPEC;REST_WEB_SERVICE_TYP;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 6');
DROP TYPE REST_WEB_SERVICE_TYP FORCE;

/* SQL statement 7 (DROP;ORACLE_TOOLS;TYPE_SPEC;MSG_TYP;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 7');
DROP TYPE MSG_TYP FORCE;

