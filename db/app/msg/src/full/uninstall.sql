/* perl generate_ddl.pl (version 2023-01-05) --nodynamic-sql --force-view --group-constraints --skip-install-sql --source-schema=ORACLE_TOOLS --strip-source-schema */

/*
-- JDBC url - username : jdbc:oracle:thin:@pato - ORACLE_TOOLS
-- source schema       : 
-- source database link: 
-- target schema       : ORACLE_TOOLS
-- target database link: 
-- object type         : 
-- object names include: 1
-- object names        : MSG_TYP,
      MSG_PKG,
      MSG_AQ_PKG,
      MSG_NOTIFICATION_PRC,
      WEB_SERVICE_REQUEST_SEQ,
      WEB_SERVICE_REQUEST_TYP,
      WEB_SERVICE_RESPONSE_TYP,
      REST_WEB_SERVICE_REQUEST_TYP,
      WEB_SERVICE_PKG,
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

/* SQL statement 2 (DROP;ORACLE_TOOLS;PACKAGE_BODY;MSG_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 2');
DROP PACKAGE BODY MSG_PKG;

/* SQL statement 3 (DROP;ORACLE_TOOLS;PACKAGE_BODY;WEB_SERVICE_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 3');
DROP PACKAGE BODY WEB_SERVICE_PKG;

/* SQL statement 4 (DROP;ORACLE_TOOLS;PROCEDURE;MSG_NOTIFICATION_PRC;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 4');
DROP PROCEDURE MSG_NOTIFICATION_PRC;

/* SQL statement 5 (DROP;ORACLE_TOOLS;TYPE_BODY;MSG_TYP;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 5');
DROP TYPE BODY MSG_TYP;

/* SQL statement 6 (DROP;ORACLE_TOOLS;PACKAGE_SPEC;MSG_AQ_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 6');
DROP PACKAGE MSG_AQ_PKG;

/* SQL statement 7 (DROP;ORACLE_TOOLS;PACKAGE_SPEC;MSG_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 7');
DROP PACKAGE MSG_PKG;

/* SQL statement 8 (DROP;ORACLE_TOOLS;PACKAGE_SPEC;WEB_SERVICE_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 8');
DROP PACKAGE WEB_SERVICE_PKG;

/* SQL statement 9 (DROP;ORACLE_TOOLS;SEQUENCE;WEB_SERVICE_REQUEST_SEQ;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 9');
DROP SEQUENCE WEB_SERVICE_REQUEST_SEQ;

/* SQL statement 10 (DROP;ORACLE_TOOLS;TYPE_BODY;REST_WEB_SERVICE_REQUEST_TYP;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 10');
DROP TYPE BODY REST_WEB_SERVICE_REQUEST_TYP;

/* SQL statement 11 (DROP;ORACLE_TOOLS;TYPE_BODY;WEB_SERVICE_REQUEST_TYP;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 11');
DROP TYPE BODY WEB_SERVICE_REQUEST_TYP;

/* SQL statement 12 (DROP;ORACLE_TOOLS;TYPE_BODY;WEB_SERVICE_RESPONSE_TYP;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 12');
DROP TYPE BODY WEB_SERVICE_RESPONSE_TYP;

/* SQL statement 13 (DROP;ORACLE_TOOLS;TYPE_SPEC;REST_WEB_SERVICE_REQUEST_TYP;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 13');
DROP TYPE REST_WEB_SERVICE_REQUEST_TYP FORCE;

/* SQL statement 14 (DROP;ORACLE_TOOLS;TYPE_SPEC;WEB_SERVICE_RESPONSE_TYP;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 14');
DROP TYPE WEB_SERVICE_RESPONSE_TYP FORCE;

/* SQL statement 15 (DROP;ORACLE_TOOLS;TYPE_SPEC;WEB_SERVICE_REQUEST_TYP;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 15');
DROP TYPE WEB_SERVICE_REQUEST_TYP FORCE;

/* SQL statement 16 (DROP;ORACLE_TOOLS;TYPE_SPEC;MSG_TYP;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 16');
DROP TYPE MSG_TYP FORCE;

