/* perl generate_ddl.pl (version 2022-12-02) --nodynamic-sql --force-view --group-constraints --skip-install-sql --source-schema=ORACLE_TOOLS --nostrip-source-schema */

/*
-- JDBC url            : jdbc:oracle:thin:ORACLE_TOOLS@//localhost:1521/orcl
-- source schema       : 
-- source database link: 
-- target schema       : ORACLE_TOOLS
-- target database link: 
-- object type         : 
-- object names include: 1
-- object names        : F_GENERATE_DDL
,PKG_DDL_ERROR
,PKG_DDL_UTIL
,PKG_STR_UTIL
,P_GENERATE_DDL
,T_ARGUMENT_OBJECT
,T_ARGUMENT_OBJECT_TAB
,T_CLUSTER_OBJECT
,T_COMMENT_DDL
,T_COMMENT_OBJECT
,T_CONSTRAINT_DDL
,T_CONSTRAINT_OBJECT
,T_DDL
,T_DDL_SEQUENCE
,T_DDL_TAB
,T_DEPENDENT_OR_GRANTED_OBJECT
,T_FUNCTION_OBJECT
,T_INDEX_DDL
,T_INDEX_OBJECT
,T_JAVA_SOURCE_OBJECT
,T_MATERIALIZED_VIEW_DDL
,T_MATERIALIZED_VIEW_LOG_OBJECT
,T_MATERIALIZED_VIEW_OBJECT
,T_MEMBER_OBJECT
,T_NAMED_OBJECT
,T_OBJECT_GRANT_DDL
,T_OBJECT_GRANT_OBJECT
,T_OBJECT_INFO_REC
,T_OBJECT_INFO_TAB
,T_PACKAGE_BODY_OBJECT
,T_PACKAGE_SPEC_OBJECT
,T_PROCEDURE_OBJECT
,T_PROCOBJ_DDL
,T_PROCOBJ_OBJECT
,T_REFRESH_GROUP_DDL
,T_REFRESH_GROUP_OBJECT
,T_REF_CONSTRAINT_OBJECT
,T_SCHEMA_DDL
,T_SCHEMA_DDL_TAB
,T_SCHEMA_OBJECT
,T_SCHEMA_OBJECT_FILTER
,T_SCHEMA_OBJECT_TAB
,T_SEQUENCE_DDL
,T_SEQUENCE_OBJECT
,T_SYNONYM_DDL
,T_SYNONYM_OBJECT
,T_TABLE_COLUMN_DDL
,T_TABLE_COLUMN_OBJECT
,T_TABLE_DDL
,T_TABLE_OBJECT
,T_TEXT_TAB
,T_TRIGGER_DDL
,T_TRIGGER_OBJECT
,T_TYPE_ATTRIBUTE_DDL
,T_TYPE_ATTRIBUTE_OBJECT
,T_TYPE_BODY_OBJECT
,T_TYPE_METHOD_DDL
,T_TYPE_METHOD_OBJECT
,T_TYPE_SPEC_DDL
,T_TYPE_SPEC_OBJECT
,T_VIEW_OBJECT
,V_DISPLAY_DDL_SCHEMA
,V_MY_FETCH_DDL
,V_MY_SCHEMA_DDL_INFO
,V_MY_SCHEMA_OBJECT_INFO
-- skip repeatables    : 0
-- interface           : pkg_ddl_util v4
-- transform params    : SEGMENT_ATTRIBUTES,TABLESPACE
-- owner               : ORACLE_TOOLS
*/
-- pkg_ddl_util v4
call dbms_application_info.set_module('uninstall.sql', null);
/* SQL statement 1 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;FUNCTION;F_GENERATE_DDL;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 1');
REVOKE EXECUTE ON "ORACLE_TOOLS"."F_GENERATE_DDL" FROM "PUBLIC";

/* SQL statement 2 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;PACKAGE_SPEC;PKG_DDL_ERROR;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 2');
REVOKE EXECUTE ON "ORACLE_TOOLS"."PKG_DDL_ERROR" FROM "PUBLIC";

/* SQL statement 3 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;PACKAGE_SPEC;PKG_DDL_UTIL;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 3');
REVOKE EXECUTE ON "ORACLE_TOOLS"."PKG_DDL_UTIL" FROM "PUBLIC";

/* SQL statement 4 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;PACKAGE_SPEC;PKG_STR_UTIL;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 4');
REVOKE EXECUTE ON "ORACLE_TOOLS"."PKG_STR_UTIL" FROM "PUBLIC";

/* SQL statement 5 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;PROCEDURE;P_GENERATE_DDL;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 5');
REVOKE EXECUTE ON "ORACLE_TOOLS"."P_GENERATE_DDL" FROM "PUBLIC";

/* SQL statement 6 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;TYPE_SPEC;T_ARGUMENT_OBJECT;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 6');
REVOKE EXECUTE ON "ORACLE_TOOLS"."T_ARGUMENT_OBJECT" FROM "PUBLIC";

/* SQL statement 7 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;TYPE_SPEC;T_ARGUMENT_OBJECT_TAB;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 7');
REVOKE EXECUTE ON "ORACLE_TOOLS"."T_ARGUMENT_OBJECT_TAB" FROM "PUBLIC";

/* SQL statement 8 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;TYPE_SPEC;T_CLUSTER_OBJECT;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 8');
REVOKE EXECUTE ON "ORACLE_TOOLS"."T_CLUSTER_OBJECT" FROM "PUBLIC";

/* SQL statement 9 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;TYPE_SPEC;T_COMMENT_DDL;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 9');
REVOKE EXECUTE ON "ORACLE_TOOLS"."T_COMMENT_DDL" FROM "PUBLIC";

/* SQL statement 10 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;TYPE_SPEC;T_COMMENT_OBJECT;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 10');
REVOKE EXECUTE ON "ORACLE_TOOLS"."T_COMMENT_OBJECT" FROM "PUBLIC";

/* SQL statement 11 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;TYPE_SPEC;T_CONSTRAINT_DDL;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 11');
REVOKE EXECUTE ON "ORACLE_TOOLS"."T_CONSTRAINT_DDL" FROM "PUBLIC";

/* SQL statement 12 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;TYPE_SPEC;T_CONSTRAINT_OBJECT;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 12');
REVOKE EXECUTE ON "ORACLE_TOOLS"."T_CONSTRAINT_OBJECT" FROM "PUBLIC";

/* SQL statement 13 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;TYPE_SPEC;T_DDL;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 13');
REVOKE EXECUTE ON "ORACLE_TOOLS"."T_DDL" FROM "PUBLIC";

/* SQL statement 14 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;TYPE_SPEC;T_DDL_SEQUENCE;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 14');
REVOKE EXECUTE ON "ORACLE_TOOLS"."T_DDL_SEQUENCE" FROM "PUBLIC";

/* SQL statement 15 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;TYPE_SPEC;T_DDL_TAB;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 15');
REVOKE EXECUTE ON "ORACLE_TOOLS"."T_DDL_TAB" FROM "PUBLIC";

/* SQL statement 16 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;TYPE_SPEC;T_DEPENDENT_OR_GRANTED_OBJECT;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 16');
REVOKE EXECUTE ON "ORACLE_TOOLS"."T_DEPENDENT_OR_GRANTED_OBJECT" FROM "PUBLIC";

/* SQL statement 17 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;TYPE_SPEC;T_FUNCTION_OBJECT;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 17');
REVOKE EXECUTE ON "ORACLE_TOOLS"."T_FUNCTION_OBJECT" FROM "PUBLIC";

/* SQL statement 18 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;TYPE_SPEC;T_INDEX_DDL;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 18');
REVOKE EXECUTE ON "ORACLE_TOOLS"."T_INDEX_DDL" FROM "PUBLIC";

/* SQL statement 19 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;TYPE_SPEC;T_INDEX_OBJECT;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 19');
REVOKE EXECUTE ON "ORACLE_TOOLS"."T_INDEX_OBJECT" FROM "PUBLIC";

/* SQL statement 20 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;TYPE_SPEC;T_JAVA_SOURCE_OBJECT;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 20');
REVOKE EXECUTE ON "ORACLE_TOOLS"."T_JAVA_SOURCE_OBJECT" FROM "PUBLIC";

/* SQL statement 21 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;TYPE_SPEC;T_MATERIALIZED_VIEW_DDL;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 21');
REVOKE EXECUTE ON "ORACLE_TOOLS"."T_MATERIALIZED_VIEW_DDL" FROM "PUBLIC";

/* SQL statement 22 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;TYPE_SPEC;T_MATERIALIZED_VIEW_LOG_OBJECT;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 22');
REVOKE EXECUTE ON "ORACLE_TOOLS"."T_MATERIALIZED_VIEW_LOG_OBJECT" FROM "PUBLIC";

/* SQL statement 23 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;TYPE_SPEC;T_MATERIALIZED_VIEW_OBJECT;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 23');
REVOKE EXECUTE ON "ORACLE_TOOLS"."T_MATERIALIZED_VIEW_OBJECT" FROM "PUBLIC";

/* SQL statement 24 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;TYPE_SPEC;T_MEMBER_OBJECT;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 24');
REVOKE EXECUTE ON "ORACLE_TOOLS"."T_MEMBER_OBJECT" FROM "PUBLIC";

/* SQL statement 25 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;TYPE_SPEC;T_NAMED_OBJECT;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 25');
REVOKE EXECUTE ON "ORACLE_TOOLS"."T_NAMED_OBJECT" FROM "PUBLIC";

/* SQL statement 26 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;TYPE_SPEC;T_OBJECT_GRANT_DDL;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 26');
REVOKE EXECUTE ON "ORACLE_TOOLS"."T_OBJECT_GRANT_DDL" FROM "PUBLIC";

/* SQL statement 27 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;TYPE_SPEC;T_OBJECT_GRANT_OBJECT;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 27');
REVOKE EXECUTE ON "ORACLE_TOOLS"."T_OBJECT_GRANT_OBJECT" FROM "PUBLIC";

/* SQL statement 28 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;TYPE_SPEC;T_OBJECT_INFO_REC;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 28');
REVOKE EXECUTE ON "ORACLE_TOOLS"."T_OBJECT_INFO_REC" FROM "PUBLIC";

/* SQL statement 29 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;TYPE_SPEC;T_OBJECT_INFO_TAB;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 29');
REVOKE EXECUTE ON "ORACLE_TOOLS"."T_OBJECT_INFO_TAB" FROM "PUBLIC";

/* SQL statement 30 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;TYPE_SPEC;T_PACKAGE_BODY_OBJECT;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 30');
REVOKE EXECUTE ON "ORACLE_TOOLS"."T_PACKAGE_BODY_OBJECT" FROM "PUBLIC";

/* SQL statement 31 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;TYPE_SPEC;T_PACKAGE_SPEC_OBJECT;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 31');
REVOKE EXECUTE ON "ORACLE_TOOLS"."T_PACKAGE_SPEC_OBJECT" FROM "PUBLIC";

/* SQL statement 32 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;TYPE_SPEC;T_PROCEDURE_OBJECT;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 32');
REVOKE EXECUTE ON "ORACLE_TOOLS"."T_PROCEDURE_OBJECT" FROM "PUBLIC";

/* SQL statement 33 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;TYPE_SPEC;T_PROCOBJ_DDL;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 33');
REVOKE EXECUTE ON "ORACLE_TOOLS"."T_PROCOBJ_DDL" FROM "PUBLIC";

/* SQL statement 34 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;TYPE_SPEC;T_PROCOBJ_OBJECT;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 34');
REVOKE EXECUTE ON "ORACLE_TOOLS"."T_PROCOBJ_OBJECT" FROM "PUBLIC";

/* SQL statement 35 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;TYPE_SPEC;T_REFRESH_GROUP_DDL;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 35');
REVOKE EXECUTE ON "ORACLE_TOOLS"."T_REFRESH_GROUP_DDL" FROM "PUBLIC";

/* SQL statement 36 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;TYPE_SPEC;T_REFRESH_GROUP_OBJECT;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 36');
REVOKE EXECUTE ON "ORACLE_TOOLS"."T_REFRESH_GROUP_OBJECT" FROM "PUBLIC";

/* SQL statement 37 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;TYPE_SPEC;T_REF_CONSTRAINT_OBJECT;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 37');
REVOKE EXECUTE ON "ORACLE_TOOLS"."T_REF_CONSTRAINT_OBJECT" FROM "PUBLIC";

/* SQL statement 38 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;TYPE_SPEC;T_SCHEMA_DDL;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 38');
REVOKE EXECUTE ON "ORACLE_TOOLS"."T_SCHEMA_DDL" FROM "PUBLIC";

/* SQL statement 39 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;TYPE_SPEC;T_SCHEMA_DDL_TAB;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 39');
REVOKE EXECUTE ON "ORACLE_TOOLS"."T_SCHEMA_DDL_TAB" FROM "PUBLIC";

/* SQL statement 40 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;TYPE_SPEC;T_SCHEMA_OBJECT;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 40');
REVOKE EXECUTE ON "ORACLE_TOOLS"."T_SCHEMA_OBJECT" FROM "PUBLIC";

/* SQL statement 41 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;TYPE_SPEC;T_SCHEMA_OBJECT_FILTER;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 41');
REVOKE EXECUTE ON "ORACLE_TOOLS"."T_SCHEMA_OBJECT_FILTER" FROM "PUBLIC";

/* SQL statement 42 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;TYPE_SPEC;T_SCHEMA_OBJECT_TAB;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 42');
REVOKE EXECUTE ON "ORACLE_TOOLS"."T_SCHEMA_OBJECT_TAB" FROM "PUBLIC";

/* SQL statement 43 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;TYPE_SPEC;T_SEQUENCE_DDL;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 43');
REVOKE EXECUTE ON "ORACLE_TOOLS"."T_SEQUENCE_DDL" FROM "PUBLIC";

/* SQL statement 44 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;TYPE_SPEC;T_SEQUENCE_OBJECT;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 44');
REVOKE EXECUTE ON "ORACLE_TOOLS"."T_SEQUENCE_OBJECT" FROM "PUBLIC";

/* SQL statement 45 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;TYPE_SPEC;T_SYNONYM_DDL;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 45');
REVOKE EXECUTE ON "ORACLE_TOOLS"."T_SYNONYM_DDL" FROM "PUBLIC";

/* SQL statement 46 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;TYPE_SPEC;T_SYNONYM_OBJECT;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 46');
REVOKE EXECUTE ON "ORACLE_TOOLS"."T_SYNONYM_OBJECT" FROM "PUBLIC";

/* SQL statement 47 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;TYPE_SPEC;T_TABLE_COLUMN_DDL;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 47');
REVOKE EXECUTE ON "ORACLE_TOOLS"."T_TABLE_COLUMN_DDL" FROM "PUBLIC";

/* SQL statement 48 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;TYPE_SPEC;T_TABLE_COLUMN_OBJECT;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 48');
REVOKE EXECUTE ON "ORACLE_TOOLS"."T_TABLE_COLUMN_OBJECT" FROM "PUBLIC";

/* SQL statement 49 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;TYPE_SPEC;T_TABLE_DDL;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 49');
REVOKE EXECUTE ON "ORACLE_TOOLS"."T_TABLE_DDL" FROM "PUBLIC";

/* SQL statement 50 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;TYPE_SPEC;T_TABLE_OBJECT;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 50');
REVOKE EXECUTE ON "ORACLE_TOOLS"."T_TABLE_OBJECT" FROM "PUBLIC";

/* SQL statement 51 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;TYPE_SPEC;T_TEXT_TAB;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 51');
REVOKE EXECUTE ON "ORACLE_TOOLS"."T_TEXT_TAB" FROM "PUBLIC";

/* SQL statement 52 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;TYPE_SPEC;T_TRIGGER_DDL;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 52');
REVOKE EXECUTE ON "ORACLE_TOOLS"."T_TRIGGER_DDL" FROM "PUBLIC";

/* SQL statement 53 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;TYPE_SPEC;T_TRIGGER_OBJECT;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 53');
REVOKE EXECUTE ON "ORACLE_TOOLS"."T_TRIGGER_OBJECT" FROM "PUBLIC";

/* SQL statement 54 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;TYPE_SPEC;T_TYPE_ATTRIBUTE_DDL;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 54');
REVOKE EXECUTE ON "ORACLE_TOOLS"."T_TYPE_ATTRIBUTE_DDL" FROM "PUBLIC";

/* SQL statement 55 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;TYPE_SPEC;T_TYPE_ATTRIBUTE_OBJECT;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 55');
REVOKE EXECUTE ON "ORACLE_TOOLS"."T_TYPE_ATTRIBUTE_OBJECT" FROM "PUBLIC";

/* SQL statement 56 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;TYPE_SPEC;T_TYPE_BODY_OBJECT;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 56');
REVOKE EXECUTE ON "ORACLE_TOOLS"."T_TYPE_BODY_OBJECT" FROM "PUBLIC";

/* SQL statement 57 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;TYPE_SPEC;T_TYPE_METHOD_DDL;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 57');
REVOKE EXECUTE ON "ORACLE_TOOLS"."T_TYPE_METHOD_DDL" FROM "PUBLIC";

/* SQL statement 58 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;TYPE_SPEC;T_TYPE_METHOD_OBJECT;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 58');
REVOKE EXECUTE ON "ORACLE_TOOLS"."T_TYPE_METHOD_OBJECT" FROM "PUBLIC";

/* SQL statement 59 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;TYPE_SPEC;T_TYPE_SPEC_DDL;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 59');
REVOKE EXECUTE ON "ORACLE_TOOLS"."T_TYPE_SPEC_DDL" FROM "PUBLIC";

/* SQL statement 60 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;TYPE_SPEC;T_TYPE_SPEC_OBJECT;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 60');
REVOKE EXECUTE ON "ORACLE_TOOLS"."T_TYPE_SPEC_OBJECT" FROM "PUBLIC";

/* SQL statement 61 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;TYPE_SPEC;T_VIEW_OBJECT;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 61');
REVOKE EXECUTE ON "ORACLE_TOOLS"."T_VIEW_OBJECT" FROM "PUBLIC";

/* SQL statement 62 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;VIEW;V_DISPLAY_DDL_SCHEMA;;PUBLIC;SELECT;NO;2) */
call dbms_application_info.set_action('SQL statement 62');
REVOKE SELECT ON "ORACLE_TOOLS"."V_DISPLAY_DDL_SCHEMA" FROM "PUBLIC";

/* SQL statement 63 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;VIEW;V_MY_FETCH_DDL;;PUBLIC;SELECT;NO;2) */
call dbms_application_info.set_action('SQL statement 63');
REVOKE SELECT ON "ORACLE_TOOLS"."V_MY_FETCH_DDL" FROM "PUBLIC";

/* SQL statement 64 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;VIEW;V_MY_SCHEMA_DDL_INFO;;PUBLIC;SELECT;NO;2) */
call dbms_application_info.set_action('SQL statement 64');
REVOKE SELECT ON "ORACLE_TOOLS"."V_MY_SCHEMA_DDL_INFO" FROM "PUBLIC";

/* SQL statement 65 (REVOKE;;OBJECT_GRANT;;ORACLE_TOOLS;VIEW;V_MY_SCHEMA_OBJECT_INFO;;PUBLIC;SELECT;NO;2) */
call dbms_application_info.set_action('SQL statement 65');
REVOKE SELECT ON "ORACLE_TOOLS"."V_MY_SCHEMA_OBJECT_INFO" FROM "PUBLIC";

/* SQL statement 66 (DROP;ORACLE_TOOLS;FUNCTION;F_GENERATE_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 66');
DROP FUNCTION ORACLE_TOOLS.F_GENERATE_DDL;

/* SQL statement 67 (DROP;ORACLE_TOOLS;PACKAGE_BODY;PKG_DDL_UTIL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 67');
DROP PACKAGE BODY ORACLE_TOOLS.PKG_DDL_UTIL;

/* SQL statement 68 (DROP;ORACLE_TOOLS;PACKAGE_BODY;PKG_STR_UTIL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 68');
DROP PACKAGE BODY ORACLE_TOOLS.PKG_STR_UTIL;

/* SQL statement 69 (DROP;ORACLE_TOOLS;PROCEDURE;P_GENERATE_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 69');
DROP PROCEDURE ORACLE_TOOLS.P_GENERATE_DDL;

/* SQL statement 70 (DROP;ORACLE_TOOLS;TYPE_BODY;T_COMMENT_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 70');
DROP TYPE BODY ORACLE_TOOLS.T_COMMENT_OBJECT;

/* SQL statement 71 (DROP;ORACLE_TOOLS;TYPE_BODY;T_INDEX_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 71');
DROP TYPE BODY ORACLE_TOOLS.T_INDEX_OBJECT;

/* SQL statement 72 (DROP;ORACLE_TOOLS;TYPE_BODY;T_NAMED_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 72');
DROP TYPE BODY ORACLE_TOOLS.T_NAMED_OBJECT;

/* SQL statement 73 (DROP;ORACLE_TOOLS;TYPE_BODY;T_OBJECT_GRANT_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 73');
DROP TYPE BODY ORACLE_TOOLS.T_OBJECT_GRANT_OBJECT;

/* SQL statement 74 (DROP;ORACLE_TOOLS;TYPE_BODY;T_PROCOBJ_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 74');
DROP TYPE BODY ORACLE_TOOLS.T_PROCOBJ_DDL;

/* SQL statement 75 (DROP;ORACLE_TOOLS;TYPE_BODY;T_PROCOBJ_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 75');
DROP TYPE BODY ORACLE_TOOLS.T_PROCOBJ_OBJECT;

/* SQL statement 76 (DROP;ORACLE_TOOLS;TYPE_BODY;T_REF_CONSTRAINT_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 76');
DROP TYPE BODY ORACLE_TOOLS.T_REF_CONSTRAINT_OBJECT;

/* SQL statement 77 (DROP;ORACLE_TOOLS;TYPE_BODY;T_SCHEMA_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 77');
DROP TYPE BODY ORACLE_TOOLS.T_SCHEMA_DDL;

/* SQL statement 78 (DROP;ORACLE_TOOLS;TYPE_BODY;T_SCHEMA_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 78');
DROP TYPE BODY ORACLE_TOOLS.T_SCHEMA_OBJECT;

/* SQL statement 79 (DROP;ORACLE_TOOLS;TYPE_BODY;T_SYNONYM_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 79');
DROP TYPE BODY ORACLE_TOOLS.T_SYNONYM_OBJECT;

/* SQL statement 80 (DROP;ORACLE_TOOLS;TYPE_BODY;T_TRIGGER_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 80');
DROP TYPE BODY ORACLE_TOOLS.T_TRIGGER_OBJECT;

/* SQL statement 81 (DROP;ORACLE_TOOLS;TYPE_BODY;T_TYPE_METHOD_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 81');
DROP TYPE BODY ORACLE_TOOLS.T_TYPE_METHOD_OBJECT;

/* SQL statement 82 (DROP;ORACLE_TOOLS;PACKAGE_SPEC;PKG_DDL_ERROR;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 82');
DROP PACKAGE ORACLE_TOOLS.PKG_DDL_ERROR;

/* SQL statement 83 (DROP;ORACLE_TOOLS;TYPE_BODY;T_CLUSTER_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 83');
DROP TYPE BODY ORACLE_TOOLS.T_CLUSTER_OBJECT;

/* SQL statement 84 (DROP;ORACLE_TOOLS;TYPE_BODY;T_COMMENT_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 84');
DROP TYPE BODY ORACLE_TOOLS.T_COMMENT_DDL;

/* SQL statement 85 (DROP;ORACLE_TOOLS;TYPE_BODY;T_CONSTRAINT_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 85');
DROP TYPE BODY ORACLE_TOOLS.T_CONSTRAINT_DDL;

/* SQL statement 86 (DROP;ORACLE_TOOLS;TYPE_BODY;T_CONSTRAINT_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 86');
DROP TYPE BODY ORACLE_TOOLS.T_CONSTRAINT_OBJECT;

/* SQL statement 87 (DROP;ORACLE_TOOLS;TYPE_BODY;T_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 87');
DROP TYPE BODY ORACLE_TOOLS.T_DDL;

/* SQL statement 88 (DROP;ORACLE_TOOLS;TYPE_BODY;T_DEPENDENT_OR_GRANTED_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 88');
DROP TYPE BODY ORACLE_TOOLS.T_DEPENDENT_OR_GRANTED_OBJECT;

/* SQL statement 89 (DROP;ORACLE_TOOLS;TYPE_BODY;T_FUNCTION_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 89');
DROP TYPE BODY ORACLE_TOOLS.T_FUNCTION_OBJECT;

/* SQL statement 90 (DROP;ORACLE_TOOLS;TYPE_BODY;T_INDEX_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 90');
DROP TYPE BODY ORACLE_TOOLS.T_INDEX_DDL;

/* SQL statement 91 (DROP;ORACLE_TOOLS;TYPE_BODY;T_JAVA_SOURCE_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 91');
DROP TYPE BODY ORACLE_TOOLS.T_JAVA_SOURCE_OBJECT;

/* SQL statement 92 (DROP;ORACLE_TOOLS;TYPE_BODY;T_MATERIALIZED_VIEW_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 92');
DROP TYPE BODY ORACLE_TOOLS.T_MATERIALIZED_VIEW_DDL;

/* SQL statement 93 (DROP;ORACLE_TOOLS;TYPE_BODY;T_MATERIALIZED_VIEW_LOG_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 93');
DROP TYPE BODY ORACLE_TOOLS.T_MATERIALIZED_VIEW_LOG_OBJECT;

/* SQL statement 94 (DROP;ORACLE_TOOLS;TYPE_BODY;T_MATERIALIZED_VIEW_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 94');
DROP TYPE BODY ORACLE_TOOLS.T_MATERIALIZED_VIEW_OBJECT;

/* SQL statement 95 (DROP;ORACLE_TOOLS;TYPE_BODY;T_MEMBER_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 95');
DROP TYPE BODY ORACLE_TOOLS.T_MEMBER_OBJECT;

/* SQL statement 96 (DROP;ORACLE_TOOLS;TYPE_BODY;T_OBJECT_GRANT_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 96');
DROP TYPE BODY ORACLE_TOOLS.T_OBJECT_GRANT_DDL;

/* SQL statement 97 (DROP;ORACLE_TOOLS;TYPE_BODY;T_PACKAGE_BODY_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 97');
DROP TYPE BODY ORACLE_TOOLS.T_PACKAGE_BODY_OBJECT;

/* SQL statement 98 (DROP;ORACLE_TOOLS;TYPE_BODY;T_PACKAGE_SPEC_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 98');
DROP TYPE BODY ORACLE_TOOLS.T_PACKAGE_SPEC_OBJECT;

/* SQL statement 99 (DROP;ORACLE_TOOLS;TYPE_BODY;T_PROCEDURE_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 99');
DROP TYPE BODY ORACLE_TOOLS.T_PROCEDURE_OBJECT;

/* SQL statement 100 (DROP;ORACLE_TOOLS;TYPE_BODY;T_REFRESH_GROUP_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 100');
DROP TYPE BODY ORACLE_TOOLS.T_REFRESH_GROUP_DDL;

/* SQL statement 101 (DROP;ORACLE_TOOLS;TYPE_BODY;T_REFRESH_GROUP_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 101');
DROP TYPE BODY ORACLE_TOOLS.T_REFRESH_GROUP_OBJECT;

/* SQL statement 102 (DROP;ORACLE_TOOLS;TYPE_BODY;T_SCHEMA_OBJECT_FILTER;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 102');
DROP TYPE BODY ORACLE_TOOLS.T_SCHEMA_OBJECT_FILTER;

/* SQL statement 103 (DROP;ORACLE_TOOLS;TYPE_BODY;T_SEQUENCE_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 103');
DROP TYPE BODY ORACLE_TOOLS.T_SEQUENCE_DDL;

/* SQL statement 104 (DROP;ORACLE_TOOLS;TYPE_BODY;T_SEQUENCE_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 104');
DROP TYPE BODY ORACLE_TOOLS.T_SEQUENCE_OBJECT;

/* SQL statement 105 (DROP;ORACLE_TOOLS;TYPE_BODY;T_SYNONYM_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 105');
DROP TYPE BODY ORACLE_TOOLS.T_SYNONYM_DDL;

/* SQL statement 106 (DROP;ORACLE_TOOLS;TYPE_BODY;T_TABLE_COLUMN_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 106');
DROP TYPE BODY ORACLE_TOOLS.T_TABLE_COLUMN_DDL;

/* SQL statement 107 (DROP;ORACLE_TOOLS;TYPE_BODY;T_TABLE_COLUMN_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 107');
DROP TYPE BODY ORACLE_TOOLS.T_TABLE_COLUMN_OBJECT;

/* SQL statement 108 (DROP;ORACLE_TOOLS;TYPE_BODY;T_TABLE_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 108');
DROP TYPE BODY ORACLE_TOOLS.T_TABLE_DDL;

/* SQL statement 109 (DROP;ORACLE_TOOLS;TYPE_BODY;T_TABLE_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 109');
DROP TYPE BODY ORACLE_TOOLS.T_TABLE_OBJECT;

/* SQL statement 110 (DROP;ORACLE_TOOLS;TYPE_BODY;T_TRIGGER_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 110');
DROP TYPE BODY ORACLE_TOOLS.T_TRIGGER_DDL;

/* SQL statement 111 (DROP;ORACLE_TOOLS;TYPE_BODY;T_TYPE_ATTRIBUTE_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 111');
DROP TYPE BODY ORACLE_TOOLS.T_TYPE_ATTRIBUTE_DDL;

/* SQL statement 112 (DROP;ORACLE_TOOLS;TYPE_BODY;T_TYPE_ATTRIBUTE_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 112');
DROP TYPE BODY ORACLE_TOOLS.T_TYPE_ATTRIBUTE_OBJECT;

/* SQL statement 113 (DROP;ORACLE_TOOLS;TYPE_BODY;T_TYPE_BODY_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 113');
DROP TYPE BODY ORACLE_TOOLS.T_TYPE_BODY_OBJECT;

/* SQL statement 114 (DROP;ORACLE_TOOLS;TYPE_BODY;T_TYPE_METHOD_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 114');
DROP TYPE BODY ORACLE_TOOLS.T_TYPE_METHOD_DDL;

/* SQL statement 115 (DROP;ORACLE_TOOLS;TYPE_BODY;T_TYPE_SPEC_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 115');
DROP TYPE BODY ORACLE_TOOLS.T_TYPE_SPEC_DDL;

/* SQL statement 116 (DROP;ORACLE_TOOLS;TYPE_BODY;T_TYPE_SPEC_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 116');
DROP TYPE BODY ORACLE_TOOLS.T_TYPE_SPEC_OBJECT;

/* SQL statement 117 (DROP;ORACLE_TOOLS;TYPE_BODY;T_VIEW_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 117');
DROP TYPE BODY ORACLE_TOOLS.T_VIEW_OBJECT;

/* SQL statement 118 (DROP;ORACLE_TOOLS;VIEW;V_DISPLAY_DDL_SCHEMA;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 118');
DROP VIEW ORACLE_TOOLS.V_DISPLAY_DDL_SCHEMA;

/* SQL statement 119 (DROP;ORACLE_TOOLS;VIEW;V_MY_FETCH_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 119');
DROP VIEW ORACLE_TOOLS.V_MY_FETCH_DDL;

/* SQL statement 120 (DROP;ORACLE_TOOLS;VIEW;V_MY_SCHEMA_DDL_INFO;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 120');
DROP VIEW ORACLE_TOOLS.V_MY_SCHEMA_DDL_INFO;

/* SQL statement 121 (DROP;ORACLE_TOOLS;VIEW;V_MY_SCHEMA_OBJECT_INFO;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 121');
DROP VIEW ORACLE_TOOLS.V_MY_SCHEMA_OBJECT_INFO;

/* SQL statement 122 (DROP;ORACLE_TOOLS;PACKAGE_SPEC;PKG_DDL_UTIL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 122');
DROP PACKAGE ORACLE_TOOLS.PKG_DDL_UTIL;

/* SQL statement 123 (DROP;ORACLE_TOOLS;PACKAGE_SPEC;PKG_STR_UTIL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 123');
DROP PACKAGE ORACLE_TOOLS.PKG_STR_UTIL;

/* SQL statement 124 (DROP;ORACLE_TOOLS;TYPE_BODY;T_ARGUMENT_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 124');
DROP TYPE BODY ORACLE_TOOLS.T_ARGUMENT_OBJECT;

/* SQL statement 125 (DROP;ORACLE_TOOLS;TYPE_BODY;T_DDL_SEQUENCE;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 125');
DROP TYPE BODY ORACLE_TOOLS.T_DDL_SEQUENCE;

/* SQL statement 126 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_TYPE_METHOD_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 126');
DROP TYPE ORACLE_TOOLS.T_TYPE_METHOD_OBJECT;

/* SQL statement 127 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_ARGUMENT_OBJECT_TAB;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 127');
DROP TYPE ORACLE_TOOLS.T_ARGUMENT_OBJECT_TAB;

/* SQL statement 128 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_ARGUMENT_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 128');
DROP TYPE ORACLE_TOOLS.T_ARGUMENT_OBJECT;

/* SQL statement 129 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_CLUSTER_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 129');
DROP TYPE ORACLE_TOOLS.T_CLUSTER_OBJECT;

/* SQL statement 130 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_COMMENT_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 130');
DROP TYPE ORACLE_TOOLS.T_COMMENT_DDL;

/* SQL statement 131 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_COMMENT_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 131');
DROP TYPE ORACLE_TOOLS.T_COMMENT_OBJECT;

/* SQL statement 132 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_CONSTRAINT_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 132');
DROP TYPE ORACLE_TOOLS.T_CONSTRAINT_DDL;

/* SQL statement 133 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_REF_CONSTRAINT_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 133');
DROP TYPE ORACLE_TOOLS.T_REF_CONSTRAINT_OBJECT;

/* SQL statement 134 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_CONSTRAINT_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 134');
DROP TYPE ORACLE_TOOLS.T_CONSTRAINT_OBJECT;

/* SQL statement 135 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_DDL_SEQUENCE;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 135');
DROP TYPE ORACLE_TOOLS.T_DDL_SEQUENCE;

/* SQL statement 136 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_INDEX_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 136');
DROP TYPE ORACLE_TOOLS.T_INDEX_DDL;

/* SQL statement 137 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_MATERIALIZED_VIEW_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 137');
DROP TYPE ORACLE_TOOLS.T_MATERIALIZED_VIEW_DDL;

/* SQL statement 138 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_OBJECT_GRANT_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 138');
DROP TYPE ORACLE_TOOLS.T_OBJECT_GRANT_DDL;

/* SQL statement 139 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_PROCOBJ_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 139');
DROP TYPE ORACLE_TOOLS.T_PROCOBJ_DDL;

/* SQL statement 140 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_REFRESH_GROUP_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 140');
DROP TYPE ORACLE_TOOLS.T_REFRESH_GROUP_DDL;

/* SQL statement 141 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_SCHEMA_DDL_TAB;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 141');
DROP TYPE ORACLE_TOOLS.T_SCHEMA_DDL_TAB;

/* SQL statement 142 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_SEQUENCE_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 142');
DROP TYPE ORACLE_TOOLS.T_SEQUENCE_DDL;

/* SQL statement 143 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_SYNONYM_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 143');
DROP TYPE ORACLE_TOOLS.T_SYNONYM_DDL;

/* SQL statement 144 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_TABLE_COLUMN_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 144');
DROP TYPE ORACLE_TOOLS.T_TABLE_COLUMN_DDL;

/* SQL statement 145 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_TABLE_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 145');
DROP TYPE ORACLE_TOOLS.T_TABLE_DDL;

/* SQL statement 146 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_TRIGGER_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 146');
DROP TYPE ORACLE_TOOLS.T_TRIGGER_DDL;

/* SQL statement 147 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_TYPE_ATTRIBUTE_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 147');
DROP TYPE ORACLE_TOOLS.T_TYPE_ATTRIBUTE_DDL;

/* SQL statement 148 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_TYPE_METHOD_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 148');
DROP TYPE ORACLE_TOOLS.T_TYPE_METHOD_DDL;

/* SQL statement 149 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_TYPE_SPEC_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 149');
DROP TYPE ORACLE_TOOLS.T_TYPE_SPEC_DDL;

/* SQL statement 150 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_SCHEMA_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 150');
DROP TYPE ORACLE_TOOLS.T_SCHEMA_DDL;

/* SQL statement 151 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_DDL_TAB;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 151');
DROP TYPE ORACLE_TOOLS.T_DDL_TAB;

/* SQL statement 152 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 152');
DROP TYPE ORACLE_TOOLS.T_DDL;

/* SQL statement 153 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_INDEX_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 153');
DROP TYPE ORACLE_TOOLS.T_INDEX_OBJECT;

/* SQL statement 154 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_TABLE_COLUMN_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 154');
DROP TYPE ORACLE_TOOLS.T_TABLE_COLUMN_OBJECT;

/* SQL statement 155 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_TYPE_ATTRIBUTE_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 155');
DROP TYPE ORACLE_TOOLS.T_TYPE_ATTRIBUTE_OBJECT;

/* SQL statement 156 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_MEMBER_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 156');
DROP TYPE ORACLE_TOOLS.T_MEMBER_OBJECT;

/* SQL statement 157 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_OBJECT_GRANT_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 157');
DROP TYPE ORACLE_TOOLS.T_OBJECT_GRANT_OBJECT;

/* SQL statement 158 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_SYNONYM_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 158');
DROP TYPE ORACLE_TOOLS.T_SYNONYM_OBJECT;

/* SQL statement 159 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_TRIGGER_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 159');
DROP TYPE ORACLE_TOOLS.T_TRIGGER_OBJECT;

/* SQL statement 160 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_DEPENDENT_OR_GRANTED_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 160');
DROP TYPE ORACLE_TOOLS.T_DEPENDENT_OR_GRANTED_OBJECT;

/* SQL statement 161 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_FUNCTION_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 161');
DROP TYPE ORACLE_TOOLS.T_FUNCTION_OBJECT;

/* SQL statement 162 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_JAVA_SOURCE_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 162');
DROP TYPE ORACLE_TOOLS.T_JAVA_SOURCE_OBJECT;

/* SQL statement 163 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_MATERIALIZED_VIEW_LOG_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 163');
DROP TYPE ORACLE_TOOLS.T_MATERIALIZED_VIEW_LOG_OBJECT;

/* SQL statement 164 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_MATERIALIZED_VIEW_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 164');
DROP TYPE ORACLE_TOOLS.T_MATERIALIZED_VIEW_OBJECT;

/* SQL statement 165 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_PACKAGE_BODY_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 165');
DROP TYPE ORACLE_TOOLS.T_PACKAGE_BODY_OBJECT;

/* SQL statement 166 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_PACKAGE_SPEC_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 166');
DROP TYPE ORACLE_TOOLS.T_PACKAGE_SPEC_OBJECT;

/* SQL statement 167 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_PROCEDURE_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 167');
DROP TYPE ORACLE_TOOLS.T_PROCEDURE_OBJECT;

/* SQL statement 168 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_PROCOBJ_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 168');
DROP TYPE ORACLE_TOOLS.T_PROCOBJ_OBJECT;

/* SQL statement 169 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_REFRESH_GROUP_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 169');
DROP TYPE ORACLE_TOOLS.T_REFRESH_GROUP_OBJECT;

/* SQL statement 170 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_SEQUENCE_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 170');
DROP TYPE ORACLE_TOOLS.T_SEQUENCE_OBJECT;

/* SQL statement 171 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_TABLE_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 171');
DROP TYPE ORACLE_TOOLS.T_TABLE_OBJECT;

/* SQL statement 172 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_TYPE_BODY_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 172');
DROP TYPE ORACLE_TOOLS.T_TYPE_BODY_OBJECT;

/* SQL statement 173 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_TYPE_SPEC_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 173');
DROP TYPE ORACLE_TOOLS.T_TYPE_SPEC_OBJECT;

/* SQL statement 174 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_VIEW_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 174');
DROP TYPE ORACLE_TOOLS.T_VIEW_OBJECT;

/* SQL statement 175 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_NAMED_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 175');
DROP TYPE ORACLE_TOOLS.T_NAMED_OBJECT;

/* SQL statement 176 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_OBJECT_INFO_TAB;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 176');
DROP TYPE ORACLE_TOOLS.T_OBJECT_INFO_TAB;

/* SQL statement 177 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_OBJECT_INFO_REC;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 177');
DROP TYPE ORACLE_TOOLS.T_OBJECT_INFO_REC;

/* SQL statement 178 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_SCHEMA_OBJECT_FILTER;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 178');
DROP TYPE ORACLE_TOOLS.T_SCHEMA_OBJECT_FILTER;

/* SQL statement 179 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_SCHEMA_OBJECT_TAB;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 179');
DROP TYPE ORACLE_TOOLS.T_SCHEMA_OBJECT_TAB;

/* SQL statement 180 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_SCHEMA_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 180');
DROP TYPE ORACLE_TOOLS.T_SCHEMA_OBJECT;

/* SQL statement 181 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_TEXT_TAB;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 181');
DROP TYPE ORACLE_TOOLS.T_TEXT_TAB;

