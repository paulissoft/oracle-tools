/* perl generate_ddl.pl (version 2024-12-07) --nodynamic-sql --force-view --group-constraints --skip-install-sql --source-schema=BC_API --strip-source-schema */

/*
-- JDBC url - username : jdbc:oracle:thin:@bc_dev - BC_PROXY[BC_API]
-- source schema       : 
-- source database link: 
-- target schema       : BC_API
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
/* SQL statement 1 (REVOKE;;OBJECT_GRANT;;BC_API;TYPE_SPEC;MSG_TYP;;BC_SC_API;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 1');
REVOKE EXECUTE ON "MSG_TYP" FROM "BC_SC_API";

/* SQL statement 2 (REVOKE;;OBJECT_GRANT;;BC_API;PACKAGE_SPEC;MSG_SCHEDULER_PKG;;ORACLE_TOOLS;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 2');
REVOKE EXECUTE ON "MSG_SCHEDULER_PKG" FROM "ORACLE_TOOLS";

/* SQL statement 3 (REVOKE;;OBJECT_GRANT;;BC_API;PACKAGE_SPEC;MSG_SCHEDULER_PKG;;BC_BO;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 3');
REVOKE EXECUTE ON "MSG_SCHEDULER_PKG" FROM "BC_BO";

/* SQL statement 4 (DROP;BC_API;TYPE_BODY;WEB_SERVICE_RESPONSE_TYP;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 4');
DROP TYPE BODY WEB_SERVICE_RESPONSE_TYP;

/* SQL statement 5 (DROP;BC_API;TYPE_BODY;WEB_SERVICE_REQUEST_TYP;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 5');
DROP TYPE BODY WEB_SERVICE_REQUEST_TYP;

/* SQL statement 6 (DROP;BC_API;TYPE_BODY;REST_WEB_SERVICE_REQUEST_TYP;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 6');
DROP TYPE BODY REST_WEB_SERVICE_REQUEST_TYP;

/* SQL statement 7 (DROP;BC_API;TYPE_BODY;REST_WEB_SERVICE_PUT_REQUEST_TYP;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 7');
DROP TYPE BODY REST_WEB_SERVICE_PUT_REQUEST_TYP;

/* SQL statement 8 (DROP;BC_API;TYPE_BODY;REST_WEB_SERVICE_POST_REQUEST_TYP;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 8');
DROP TYPE BODY REST_WEB_SERVICE_POST_REQUEST_TYP;

/* SQL statement 9 (DROP;BC_API;TYPE_BODY;REST_WEB_SERVICE_PATCH_REQUEST_TYP;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 9');
DROP TYPE BODY REST_WEB_SERVICE_PATCH_REQUEST_TYP;

/* SQL statement 10 (DROP;BC_API;TYPE_BODY;REST_WEB_SERVICE_GET_REQUEST_TYP;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 10');
DROP TYPE BODY REST_WEB_SERVICE_GET_REQUEST_TYP;

/* SQL statement 11 (DROP;BC_API;TYPE_BODY;REST_WEB_SERVICE_DELETE_REQUEST_TYP;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 11');
DROP TYPE BODY REST_WEB_SERVICE_DELETE_REQUEST_TYP;

/* SQL statement 12 (DROP;BC_API;TYPE_BODY;PROPERTY_TYP;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 12');
DROP TYPE BODY PROPERTY_TYP;

/* SQL statement 13 (DROP;BC_API;TYPE_BODY;MSG_TYP;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 13');
DROP TYPE BODY MSG_TYP;

/* SQL statement 14 (DROP;BC_API;TYPE_BODY;HTTP_REQUEST_RESPONSE_TYP;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 14');
DROP TYPE BODY HTTP_REQUEST_RESPONSE_TYP;

/* SQL statement 15 (DROP;BC_API;PACKAGE_BODY;WEB_SERVICE_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 15');
DROP PACKAGE BODY WEB_SERVICE_PKG;

/* SQL statement 16 (DROP;BC_API;PACKAGE_BODY;MSG_SCHEDULER_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 16');
DROP PACKAGE BODY MSG_SCHEDULER_PKG;

/* SQL statement 17 (DROP;BC_API;PACKAGE_BODY;MSG_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 17');
DROP PACKAGE BODY MSG_PKG;

/* SQL statement 18 (DROP;BC_API;PACKAGE_BODY;MSG_AQ_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 18');
DROP PACKAGE BODY MSG_AQ_PKG;

/* SQL statement 19 (DROP;BC_API;PACKAGE_BODY;HTTP_REQUEST_RESPONSE_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 19');
DROP PACKAGE BODY HTTP_REQUEST_RESPONSE_PKG;

/* SQL statement 20 (DROP;BC_API;PROCEDURE;MSG_NOTIFICATION_PRC;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 20');
DROP PROCEDURE MSG_NOTIFICATION_PRC;

/* SQL statement 21 (DROP;BC_API;VIEW;MSG_QUEUE_INFO_V;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 21');
DROP VIEW MSG_QUEUE_INFO_V;

/* SQL statement 22 (DROP;BC_API;PACKAGE_SPEC;WEB_SERVICE_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 22');
DROP PACKAGE WEB_SERVICE_PKG;

/* SQL statement 23 (DROP;BC_API;PACKAGE_SPEC;MSG_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 23');
DROP PACKAGE MSG_PKG;

/* SQL statement 24 (DROP;BC_API;PACKAGE_SPEC;MSG_AQ_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 24');
DROP PACKAGE MSG_AQ_PKG;

/* SQL statement 25 (DROP;BC_API;PACKAGE_SPEC;HTTP_REQUEST_RESPONSE_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 25');
DROP PACKAGE HTTP_REQUEST_RESPONSE_PKG;

/* SQL statement 26 (DROP;BC_API;PACKAGE_SPEC;MSG_SCHEDULER_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 26');
DROP PACKAGE MSG_SCHEDULER_PKG;

/* SQL statement 27 (DROP;BC_API;TYPE_SPEC;WEB_SERVICE_RESPONSE_TYP;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 27');
DROP TYPE WEB_SERVICE_RESPONSE_TYP FORCE;

/* SQL statement 28 (DROP;BC_API;TYPE_SPEC;WEB_SERVICE_REQUEST_TYP;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 28');
DROP TYPE WEB_SERVICE_REQUEST_TYP FORCE;

/* SQL statement 29 (DROP;BC_API;TYPE_SPEC;REST_WEB_SERVICE_REQUEST_TYP;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 29');
DROP TYPE REST_WEB_SERVICE_REQUEST_TYP FORCE;

/* SQL statement 30 (DROP;BC_API;TYPE_SPEC;REST_WEB_SERVICE_PUT_REQUEST_TYP;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 30');
DROP TYPE REST_WEB_SERVICE_PUT_REQUEST_TYP FORCE;

/* SQL statement 31 (DROP;BC_API;TYPE_SPEC;REST_WEB_SERVICE_POST_REQUEST_TYP;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 31');
DROP TYPE REST_WEB_SERVICE_POST_REQUEST_TYP FORCE;

/* SQL statement 32 (DROP;BC_API;TYPE_SPEC;REST_WEB_SERVICE_PATCH_REQUEST_TYP;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 32');
DROP TYPE REST_WEB_SERVICE_PATCH_REQUEST_TYP FORCE;

/* SQL statement 33 (DROP;BC_API;TYPE_SPEC;REST_WEB_SERVICE_GET_REQUEST_TYP;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 33');
DROP TYPE REST_WEB_SERVICE_GET_REQUEST_TYP FORCE;

/* SQL statement 34 (DROP;BC_API;TYPE_SPEC;REST_WEB_SERVICE_DELETE_REQUEST_TYP;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 34');
DROP TYPE REST_WEB_SERVICE_DELETE_REQUEST_TYP FORCE;

/* SQL statement 35 (DROP;BC_API;TYPE_SPEC;PROPERTY_TYP;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 35');
DROP TYPE PROPERTY_TYP FORCE;

/* SQL statement 36 (DROP;BC_API;TYPE_SPEC;PROPERTY_TAB_TYP;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 36');
DROP TYPE PROPERTY_TAB_TYP FORCE;

/* SQL statement 37 (DROP;BC_API;TYPE_SPEC;MSG_TYP;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 37');
DROP TYPE MSG_TYP FORCE;

/* SQL statement 38 (DROP;BC_API;TYPE_SPEC;HTTP_REQUEST_RESPONSE_TYP;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 38');
DROP TYPE HTTP_REQUEST_RESPONSE_TYP FORCE;

/* SQL statement 39 (DROP;BC_API;TYPE_SPEC;HTTP_COOKIE_TYP;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 39');
DROP TYPE HTTP_COOKIE_TYP FORCE;

/* SQL statement 40 (DROP;BC_API;TYPE_SPEC;HTTP_COOKIE_TAB_TYP;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 40');
DROP TYPE HTTP_COOKIE_TAB_TYP FORCE;

/* SQL statement 41 (DROP;BC_API;SEQUENCE;WEB_SERVICE_REQUEST_SEQ;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 41');
DROP SEQUENCE WEB_SERVICE_REQUEST_SEQ;

