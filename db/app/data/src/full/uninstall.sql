/* perl generate_ddl.pl (version 2023-01-05) --nodynamic-sql --force-view --group-constraints --skip-install-sql --source-schema=ORACLE_TOOLS --strip-source-schema */

/*
-- JDBC url            : jdbc:oracle:thin:BC_PROXY[ORACLE_TOOLS]@bc_dev
-- source schema       : 
-- source database link: 
-- target schema       : ORACLE_TOOLS
-- target database link: 
-- object type         : 
-- object names include: 1
-- object names        : DATA_SESSION_USERNAME,DATA_TIMESTAMP,DATA_API_PKG,DATA_BR_PKG,DATA_PARTITIONING_PKG,DATA_TABLE_MGMT_PKG,DATA_ROW_T,DATA_ROW_ID_T,DATA_DML_EVENT_MGR_PKG,DATA_ROW_NOTIFICATION_PRC
-- skip repeatables    : 0
-- interface           : pkg_ddl_util v4
-- transform params    : 
-- exclude objects     : 
-- include objects     : 
-- owner               : ORACLE_TOOLS
*/
-- pkg_ddl_util v4
call dbms_application_info.set_module('uninstall.sql', null);
/* SQL statement 1 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;PACKAGE_SPEC;DATA_API_PKG;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 1');
REVOKE EXECUTE ON "DATA_API_PKG" FROM "PUBLIC";

/* SQL statement 2 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;PACKAGE_SPEC;DATA_BR_PKG;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 2');
REVOKE EXECUTE ON "DATA_BR_PKG" FROM "PUBLIC";

/* SQL statement 3 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;PACKAGE_SPEC;DATA_DML_EVENT_MGR_PKG;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 3');
REVOKE EXECUTE ON "DATA_DML_EVENT_MGR_PKG" FROM "PUBLIC";

/* SQL statement 4 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;PACKAGE_SPEC;DATA_PARTITIONING_PKG;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 4');
REVOKE EXECUTE ON "DATA_PARTITIONING_PKG" FROM "PUBLIC";

/* SQL statement 5 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;TYPE_SPEC;DATA_ROW_ID_T;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 5');
REVOKE EXECUTE ON "DATA_ROW_ID_T" FROM "PUBLIC";

/* SQL statement 6 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;TYPE_SPEC;DATA_ROW_ID_T;;PUBLIC;UNDER;NO;2) */
call dbms_application_info.set_action('SQL statement 6');
REVOKE UNDER ON "DATA_ROW_ID_T" FROM "PUBLIC";

/* SQL statement 7 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;PROCEDURE;DATA_ROW_NOTIFICATION_PRC;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 7');
REVOKE EXECUTE ON "DATA_ROW_NOTIFICATION_PRC" FROM "PUBLIC";

/* SQL statement 8 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;TYPE_SPEC;DATA_ROW_T;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 8');
REVOKE EXECUTE ON "DATA_ROW_T" FROM "PUBLIC";

/* SQL statement 9 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;TYPE_SPEC;DATA_ROW_T;;PUBLIC;UNDER;NO;2) */
call dbms_application_info.set_action('SQL statement 9');
REVOKE UNDER ON "DATA_ROW_T" FROM "PUBLIC";

/* SQL statement 10 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;FUNCTION;DATA_SESSION_USERNAME;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 10');
REVOKE EXECUTE ON "DATA_SESSION_USERNAME" FROM "PUBLIC";

/* SQL statement 11 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;PACKAGE_SPEC;DATA_TABLE_MGMT_PKG;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 11');
REVOKE EXECUTE ON "DATA_TABLE_MGMT_PKG" FROM "PUBLIC";

/* SQL statement 12 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;FUNCTION;DATA_TIMESTAMP;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 12');
REVOKE EXECUTE ON "DATA_TIMESTAMP" FROM "PUBLIC";

/* SQL statement 13 (DROP;ORACLE_TOOLS;FUNCTION;DATA_SESSION_USERNAME;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 13');
DROP FUNCTION DATA_SESSION_USERNAME;

/* SQL statement 14 (DROP;ORACLE_TOOLS;FUNCTION;DATA_TIMESTAMP;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 14');
DROP FUNCTION DATA_TIMESTAMP;

/* SQL statement 15 (DROP;ORACLE_TOOLS;PACKAGE_BODY;DATA_API_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 15');
DROP PACKAGE BODY DATA_API_PKG;

/* SQL statement 16 (DROP;ORACLE_TOOLS;PACKAGE_BODY;DATA_BR_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 16');
DROP PACKAGE BODY DATA_BR_PKG;

/* SQL statement 17 (DROP;ORACLE_TOOLS;PACKAGE_BODY;DATA_DML_EVENT_MGR_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 17');
DROP PACKAGE BODY DATA_DML_EVENT_MGR_PKG;

/* SQL statement 18 (DROP;ORACLE_TOOLS;PACKAGE_BODY;DATA_PARTITIONING_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 18');
DROP PACKAGE BODY DATA_PARTITIONING_PKG;

/* SQL statement 19 (DROP;ORACLE_TOOLS;PACKAGE_BODY;DATA_TABLE_MGMT_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 19');
DROP PACKAGE BODY DATA_TABLE_MGMT_PKG;

/* SQL statement 20 (DROP;ORACLE_TOOLS;PACKAGE_SPEC;DATA_API_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 20');
DROP PACKAGE DATA_API_PKG;

/* SQL statement 21 (DROP;ORACLE_TOOLS;PACKAGE_SPEC;DATA_BR_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 21');
DROP PACKAGE DATA_BR_PKG;

/* SQL statement 22 (DROP;ORACLE_TOOLS;PACKAGE_SPEC;DATA_DML_EVENT_MGR_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 22');
DROP PACKAGE DATA_DML_EVENT_MGR_PKG;

/* SQL statement 23 (DROP;ORACLE_TOOLS;PACKAGE_SPEC;DATA_PARTITIONING_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 23');
DROP PACKAGE DATA_PARTITIONING_PKG;

/* SQL statement 24 (DROP;ORACLE_TOOLS;PACKAGE_SPEC;DATA_TABLE_MGMT_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 24');
DROP PACKAGE DATA_TABLE_MGMT_PKG;

/* SQL statement 25 (DROP;ORACLE_TOOLS;PROCEDURE;DATA_ROW_NOTIFICATION_PRC;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 25');
DROP PROCEDURE DATA_ROW_NOTIFICATION_PRC;

/* SQL statement 26 (DROP;ORACLE_TOOLS;TYPE_BODY;DATA_ROW_ID_T;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 26');
DROP TYPE BODY DATA_ROW_ID_T;

/* SQL statement 27 (DROP;ORACLE_TOOLS;TYPE_BODY;DATA_ROW_T;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 27');
DROP TYPE BODY DATA_ROW_T;

/* SQL statement 28 (DROP;ORACLE_TOOLS;TYPE_SPEC;DATA_ROW_ID_T;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 28');
DROP TYPE DATA_ROW_ID_T FORCE;

/* SQL statement 29 (DROP;ORACLE_TOOLS;TYPE_SPEC;DATA_ROW_T;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 29');
DROP TYPE DATA_ROW_T FORCE;

