/* perl generate_ddl.pl (version 2023-01-05) --nodynamic-sql --force-view --group-constraints --skip-install-sql --source-schema=ORACLE_TOOLS --strip-source-schema */

/*
-- JDBC url            : jdbc:oracle:thin:ORACLE_TOOLS@//localhost:1521/orcl
-- source schema       : 
-- source database link: 
-- target schema       : ORACLE_TOOLS
-- target database link: 
-- object type         : 
-- object names include: 1
-- object names        : DATA_SESSION_USERNAME,DATA_TIMESTAMP,DATA_API_PKG,DATA_BR_PKG,DATA_PARTITIONING_PKG,DATA_TABLE_MGMT_PKG
-- skip repeatables    : 0
-- interface           : pkg_ddl_util v4
-- transform params    : SEGMENT_ATTRIBUTES,TABLESPACE
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

/* SQL statement 3 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;PACKAGE_SPEC;DATA_PARTITIONING_PKG;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 3');
REVOKE EXECUTE ON "DATA_PARTITIONING_PKG" FROM "PUBLIC";

/* SQL statement 4 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;FUNCTION;DATA_SESSION_USERNAME;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 4');
REVOKE EXECUTE ON "DATA_SESSION_USERNAME" FROM "PUBLIC";

/* SQL statement 5 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;PACKAGE_SPEC;DATA_TABLE_MGMT_PKG;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 5');
REVOKE EXECUTE ON "DATA_TABLE_MGMT_PKG" FROM "PUBLIC";

/* SQL statement 6 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;FUNCTION;DATA_TIMESTAMP;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 6');
REVOKE EXECUTE ON "DATA_TIMESTAMP" FROM "PUBLIC";

/* SQL statement 7 (DROP;ORACLE_TOOLS;FUNCTION;DATA_SESSION_USERNAME;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 7');
DROP FUNCTION DATA_SESSION_USERNAME;

/* SQL statement 8 (DROP;ORACLE_TOOLS;FUNCTION;DATA_TIMESTAMP;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 8');
DROP FUNCTION DATA_TIMESTAMP;

/* SQL statement 9 (DROP;ORACLE_TOOLS;PACKAGE_BODY;DATA_API_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 9');
DROP PACKAGE BODY DATA_API_PKG;

/* SQL statement 10 (DROP;ORACLE_TOOLS;PACKAGE_BODY;DATA_BR_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 10');
DROP PACKAGE BODY DATA_BR_PKG;

/* SQL statement 11 (DROP;ORACLE_TOOLS;PACKAGE_BODY;DATA_PARTITIONING_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 11');
DROP PACKAGE BODY DATA_PARTITIONING_PKG;

/* SQL statement 12 (DROP;ORACLE_TOOLS;PACKAGE_BODY;DATA_TABLE_MGMT_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 12');
DROP PACKAGE BODY DATA_TABLE_MGMT_PKG;

/* SQL statement 13 (DROP;ORACLE_TOOLS;PACKAGE_SPEC;DATA_API_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 13');
DROP PACKAGE DATA_API_PKG;

/* SQL statement 14 (DROP;ORACLE_TOOLS;PACKAGE_SPEC;DATA_BR_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 14');
DROP PACKAGE DATA_BR_PKG;

/* SQL statement 15 (DROP;ORACLE_TOOLS;PACKAGE_SPEC;DATA_PARTITIONING_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 15');
DROP PACKAGE DATA_PARTITIONING_PKG;

/* SQL statement 16 (DROP;ORACLE_TOOLS;PACKAGE_SPEC;DATA_TABLE_MGMT_PKG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 16');
DROP PACKAGE DATA_TABLE_MGMT_PKG;

