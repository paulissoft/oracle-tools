/* perl generate_ddl.pl (version 2024-12-07) --nodynamic-sql --force-view --group-constraints --skip-install-sql --source-schema=ORACLE_TOOLS --strip-source-schema */

/*
-- JDBC url - username : jdbc:oracle:thin:@bc_dev - BC_PROXY[ORACLE_TOOLS]
-- source schema       : 
-- source database link: 
-- target schema       : ORACLE_TOOLS
-- target database link: 
-- object type         : 
-- object names include: 1
-- object names        : HTTP_COOKIE_TAB_TYP,
      HTTP_COOKIE_TYP,
      HTTP_REQUEST_RESPONSE_PKG,
      HTTP_REQUEST_RESPONSE_TYP,
      MSG_AQ_PKG,
      MSG_NOTIFICATION_PRC,
      MSG_PKG,
      MSG_QUEUE_INFO_V,
      MSG_SCHEDULER_PKG,
      MSG_TYP,
      PROPERTY_TAB_TYP,
      PROPERTY_TYP,
      REST_WEB_SERVICE_DELETE_REQUEST_TYP,
      REST_WEB_SERVICE_GET_REQUEST_TYP,
      REST_WEB_SERVICE_PATCH_REQUEST_TYP,
      REST_WEB_SERVICE_POST_REQUEST_TYP,
      REST_WEB_SERVICE_PUT_REQUEST_TYP,
      REST_WEB_SERVICE_REQUEST_TYP,
      WEB_SERVICE_PKG,
      WEB_SERVICE_REQUEST_SEQ,
      WEB_SERVICE_REQUEST_TYP,
      WEB_SERVICE_RESPONSE_TYP,
-- skip repeatables    : 0
-- interface           : pkg_ddl_util v4
-- transform params    : 
-- exclude objects     : 
-- include objects     : 
-- owner               : ORACLE_TOOLS
*/
-- pkg_ddl_util v4
call dbms_application_info.set_module('uninstall.sql', null);
/* SQL statement 1 (DROP;ORACLE_TOOLS;TYPE_BODY;REST_WEB_SERVICE_PUT_REQUEST_TYP;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 1');
DROP TYPE BODY REST_WEB_SERVICE_PUT_REQUEST_TYP;

/* SQL statement 2 (DROP;ORACLE_TOOLS;TYPE_BODY;REST_WEB_SERVICE_POST_REQUEST_TYP;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 2');
DROP TYPE BODY REST_WEB_SERVICE_POST_REQUEST_TYP;

/* SQL statement 3 (DROP;ORACLE_TOOLS;TYPE_BODY;REST_WEB_SERVICE_PATCH_REQUEST_TYP;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 3');
DROP TYPE BODY REST_WEB_SERVICE_PATCH_REQUEST_TYP;

/* SQL statement 4 (DROP;ORACLE_TOOLS;TYPE_BODY;REST_WEB_SERVICE_DELETE_REQUEST_TYP;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 4');
DROP TYPE BODY REST_WEB_SERVICE_DELETE_REQUEST_TYP;

/* SQL statement 5 (DROP;ORACLE_TOOLS;TYPE_BODY;REST_WEB_SERVICE_GET_REQUEST_TYP;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 5');
DROP TYPE BODY REST_WEB_SERVICE_GET_REQUEST_TYP;

/* SQL statement 6 (DROP;ORACLE_TOOLS;TYPE_BODY;MSG_TYP;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 6');
DROP TYPE BODY MSG_TYP;

/* SQL statement 7 (DROP;ORACLE_TOOLS;TYPE_BODY;WEB_SERVICE_REQUEST_TYP;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 7');
DROP TYPE BODY WEB_SERVICE_REQUEST_TYP;

/* SQL statement 8 (DROP;ORACLE_TOOLS;TYPE_BODY;HTTP_REQUEST_RESPONSE_TYP;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 8');
DROP TYPE BODY HTTP_REQUEST_RESPONSE_TYP;

/* SQL statement 9 (DROP;ORACLE_TOOLS;TYPE_BODY;WEB_SERVICE_RESPONSE_TYP;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 9');
DROP TYPE BODY WEB_SERVICE_RESPONSE_TYP;

/* SQL statement 10 (DROP;ORACLE_TOOLS;TYPE_BODY;REST_WEB_SERVICE_REQUEST_TYP;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 10');
DROP TYPE BODY REST_WEB_SERVICE_REQUEST_TYP;

/* SQL statement 11 (DROP;ORACLE_TOOLS;PACKAGE_BODY;MSG_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 11');
DROP PACKAGE BODY MSG_PKG;

/* SQL statement 12 (DROP;ORACLE_TOOLS;PACKAGE_BODY;MSG_AQ_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 12');
DROP PACKAGE BODY MSG_AQ_PKG;

/* SQL statement 13 (DROP;ORACLE_TOOLS;PACKAGE_BODY;HTTP_REQUEST_RESPONSE_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 13');
DROP PACKAGE BODY HTTP_REQUEST_RESPONSE_PKG;

/* SQL statement 14 (DROP;ORACLE_TOOLS;PACKAGE_BODY;MSG_SCHEDULER_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 14');
DROP PACKAGE BODY MSG_SCHEDULER_PKG;

/* SQL statement 15 (DROP;ORACLE_TOOLS;PACKAGE_BODY;WEB_SERVICE_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 15');
DROP PACKAGE BODY WEB_SERVICE_PKG;

/* SQL statement 16 (DROP;ORACLE_TOOLS;PROCEDURE;MSG_NOTIFICATION_PRC;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 16');
DROP PROCEDURE MSG_NOTIFICATION_PRC;

/* SQL statement 17 (DROP;ORACLE_TOOLS;VIEW;MSG_QUEUE_INFO_V;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 17');
DROP VIEW MSG_QUEUE_INFO_V;

/* SQL statement 18 (DROP;ORACLE_TOOLS;PACKAGE_SPEC;MSG_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 18');
DROP PACKAGE MSG_PKG;

/* SQL statement 19 (DROP;ORACLE_TOOLS;PACKAGE_SPEC;MSG_AQ_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 19');
DROP PACKAGE MSG_AQ_PKG;

/* SQL statement 20 (DROP;ORACLE_TOOLS;PACKAGE_SPEC;HTTP_REQUEST_RESPONSE_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 20');
DROP PACKAGE HTTP_REQUEST_RESPONSE_PKG;

/* SQL statement 21 (DROP;ORACLE_TOOLS;PACKAGE_SPEC;MSG_SCHEDULER_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 21');
DROP PACKAGE MSG_SCHEDULER_PKG;

/* SQL statement 22 (DROP;ORACLE_TOOLS;PACKAGE_SPEC;WEB_SERVICE_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 22');
DROP PACKAGE WEB_SERVICE_PKG;

/* SQL statement 23 (DROP;ORACLE_TOOLS;TYPE_SPEC;PROPERTY_TYP;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 23');
DROP TYPE PROPERTY_TYP FORCE;

/* SQL statement 24 (DROP;ORACLE_TOOLS;TYPE_SPEC;MSG_TYP;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 24');
DROP TYPE MSG_TYP FORCE;

/* SQL statement 25 (DROP;ORACLE_TOOLS;TYPE_SPEC;HTTP_COOKIE_TYP;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 25');
DROP TYPE HTTP_COOKIE_TYP FORCE;

/* SQL statement 26 (DROP;ORACLE_TOOLS;TYPE_SPEC;PROPERTY_TAB_TYP;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 26');
DROP TYPE PROPERTY_TAB_TYP FORCE;

/* SQL statement 27 (DROP;ORACLE_TOOLS;TYPE_SPEC;HTTP_COOKIE_TAB_TYP;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 27');
DROP TYPE HTTP_COOKIE_TAB_TYP FORCE;

/* SQL statement 28 (DROP;ORACLE_TOOLS;TYPE_SPEC;HTTP_REQUEST_RESPONSE_TYP;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 28');
DROP TYPE HTTP_REQUEST_RESPONSE_TYP FORCE;

/* SQL statement 29 (DROP;ORACLE_TOOLS;TYPE_SPEC;WEB_SERVICE_RESPONSE_TYP;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 29');
DROP TYPE WEB_SERVICE_RESPONSE_TYP FORCE;

/* SQL statement 30 (DROP;ORACLE_TOOLS;TYPE_SPEC;WEB_SERVICE_REQUEST_TYP;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 30');
DROP TYPE WEB_SERVICE_REQUEST_TYP FORCE;

/* SQL statement 31 (DROP;ORACLE_TOOLS;TYPE_SPEC;REST_WEB_SERVICE_REQUEST_TYP;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 31');
DROP TYPE REST_WEB_SERVICE_REQUEST_TYP FORCE;

/* SQL statement 32 (DROP;ORACLE_TOOLS;TYPE_SPEC;REST_WEB_SERVICE_PUT_REQUEST_TYP;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 32');
DROP TYPE REST_WEB_SERVICE_PUT_REQUEST_TYP FORCE;

/* SQL statement 33 (DROP;ORACLE_TOOLS;TYPE_SPEC;REST_WEB_SERVICE_POST_REQUEST_TYP;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 33');
DROP TYPE REST_WEB_SERVICE_POST_REQUEST_TYP FORCE;

/* SQL statement 34 (DROP;ORACLE_TOOLS;TYPE_SPEC;REST_WEB_SERVICE_PATCH_REQUEST_TYP;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 34');
DROP TYPE REST_WEB_SERVICE_PATCH_REQUEST_TYP FORCE;

/* SQL statement 35 (DROP;ORACLE_TOOLS;TYPE_SPEC;REST_WEB_SERVICE_GET_REQUEST_TYP;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 35');
DROP TYPE REST_WEB_SERVICE_GET_REQUEST_TYP FORCE;

/* SQL statement 36 (DROP;ORACLE_TOOLS;TYPE_SPEC;REST_WEB_SERVICE_DELETE_REQUEST_TYP;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 36');
DROP TYPE REST_WEB_SERVICE_DELETE_REQUEST_TYP FORCE;

/* SQL statement 37 (DROP;ORACLE_TOOLS;SEQUENCE;WEB_SERVICE_REQUEST_SEQ;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 37');
DROP SEQUENCE WEB_SERVICE_REQUEST_SEQ;

