/* perl generate_ddl.pl (version 2023-01-05) --nodynamic-sql --force-view --group-constraints --skip-install-sql --source-schema=ORACLE_TOOLS --nostrip-source-schema */

/*
-- JDBC url - username : jdbc:oracle:thin:@//127.0.0.1:1521/freepdb1 - BC_PROXY[ORACLE_TOOLS]
-- source schema       : 
-- source database link: 
-- target schema       : ORACLE_TOOLS
-- target database link: 
-- object type         : 
-- object names include: 1
-- object names        : F_GENERATE_DDL
,PKG_DDL_ERROR
,PKG_DDL_UTIL
,PKG_SCHEMA_OBJECT_FILTER
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
,V_ALL_SCHEMA_DDLS
,V_ALL_SCHEMA_OBJECTS
,V_DISPLAY_DDL_SCHEMA
,V_MY_GENERATE_DDL_SESSION_SCHEMA_DDL_BATCHES
,V_MY_INCLUDE_OBJECTS
,V_MY_SCHEMA_DDL_INFO
,V_MY_SCHEMA_OBJECT_INFO
,V_MY_SCHEMA_DDLS
,V_MY_SCHEMA_OBJECTS
,V_MY_SCHEMA_OBJECTS_NO_DDL_YET
,V_MY_NAMED_SCHEMA_OBJECTS
,SCHEMA_OBJECT_FILTERS
,ALL_SCHEMA_DDLS
,ALL_SCHEMA_OBJECTS
,SCHEMA_OBJECTS_API
,SCHEMA_OBJECT_FILTERS$SEQ
-- skip repeatables    : 0
-- interface           : pkg_ddl_util v4
-- transform params    : 
-- exclude objects     : 
-- include objects     : 
-- owner               : ORACLE_TOOLS
*/
-- pkg_ddl_util v4
call dbms_application_info.set_module('uninstall.sql', null);
/* SQL statement 1 (DROP;ORACLE_TOOLS;TYPE_BODY;T_VIEW_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 1');
DROP TYPE BODY ORACLE_TOOLS.T_VIEW_OBJECT;

/* SQL statement 2 (DROP;ORACLE_TOOLS;TYPE_BODY;T_TYPE_SPEC_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 2');
DROP TYPE BODY ORACLE_TOOLS.T_TYPE_SPEC_OBJECT;

/* SQL statement 3 (DROP;ORACLE_TOOLS;TYPE_BODY;T_TYPE_SPEC_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 3');
DROP TYPE BODY ORACLE_TOOLS.T_TYPE_SPEC_DDL;

/* SQL statement 4 (DROP;ORACLE_TOOLS;TYPE_BODY;T_TYPE_METHOD_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 4');
DROP TYPE BODY ORACLE_TOOLS.T_TYPE_METHOD_OBJECT;

/* SQL statement 5 (DROP;ORACLE_TOOLS;TYPE_BODY;T_TYPE_METHOD_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 5');
DROP TYPE BODY ORACLE_TOOLS.T_TYPE_METHOD_DDL;

/* SQL statement 6 (DROP;ORACLE_TOOLS;TYPE_BODY;T_TYPE_BODY_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 6');
DROP TYPE BODY ORACLE_TOOLS.T_TYPE_BODY_OBJECT;

/* SQL statement 7 (DROP;ORACLE_TOOLS;TYPE_BODY;T_TYPE_ATTRIBUTE_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 7');
DROP TYPE BODY ORACLE_TOOLS.T_TYPE_ATTRIBUTE_OBJECT;

/* SQL statement 8 (DROP;ORACLE_TOOLS;TYPE_BODY;T_TYPE_ATTRIBUTE_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 8');
DROP TYPE BODY ORACLE_TOOLS.T_TYPE_ATTRIBUTE_DDL;

/* SQL statement 9 (DROP;ORACLE_TOOLS;TYPE_BODY;T_TRIGGER_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 9');
DROP TYPE BODY ORACLE_TOOLS.T_TRIGGER_OBJECT;

/* SQL statement 10 (DROP;ORACLE_TOOLS;TYPE_BODY;T_TRIGGER_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 10');
DROP TYPE BODY ORACLE_TOOLS.T_TRIGGER_DDL;

/* SQL statement 11 (DROP;ORACLE_TOOLS;TYPE_BODY;T_TABLE_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 11');
DROP TYPE BODY ORACLE_TOOLS.T_TABLE_OBJECT;

/* SQL statement 12 (DROP;ORACLE_TOOLS;TYPE_BODY;T_TABLE_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 12');
DROP TYPE BODY ORACLE_TOOLS.T_TABLE_DDL;

/* SQL statement 13 (DROP;ORACLE_TOOLS;TYPE_BODY;T_TABLE_COLUMN_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 13');
DROP TYPE BODY ORACLE_TOOLS.T_TABLE_COLUMN_OBJECT;

/* SQL statement 14 (DROP;ORACLE_TOOLS;TYPE_BODY;T_TABLE_COLUMN_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 14');
DROP TYPE BODY ORACLE_TOOLS.T_TABLE_COLUMN_DDL;

/* SQL statement 15 (DROP;ORACLE_TOOLS;TYPE_BODY;T_SYNONYM_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 15');
DROP TYPE BODY ORACLE_TOOLS.T_SYNONYM_OBJECT;

/* SQL statement 16 (DROP;ORACLE_TOOLS;TYPE_BODY;T_SYNONYM_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 16');
DROP TYPE BODY ORACLE_TOOLS.T_SYNONYM_DDL;

/* SQL statement 17 (DROP;ORACLE_TOOLS;TYPE_BODY;T_SEQUENCE_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 17');
DROP TYPE BODY ORACLE_TOOLS.T_SEQUENCE_OBJECT;

/* SQL statement 18 (DROP;ORACLE_TOOLS;TYPE_BODY;T_SEQUENCE_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 18');
DROP TYPE BODY ORACLE_TOOLS.T_SEQUENCE_DDL;

/* SQL statement 19 (DROP;ORACLE_TOOLS;TYPE_BODY;T_SCHEMA_OBJECT_FILTER;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 19');
DROP TYPE BODY ORACLE_TOOLS.T_SCHEMA_OBJECT_FILTER;

/* SQL statement 20 (DROP;ORACLE_TOOLS;TYPE_BODY;T_SCHEMA_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 20');
DROP TYPE BODY ORACLE_TOOLS.T_SCHEMA_OBJECT;

/* SQL statement 21 (DROP;ORACLE_TOOLS;TYPE_BODY;T_SCHEMA_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 21');
DROP TYPE BODY ORACLE_TOOLS.T_SCHEMA_DDL;

/* SQL statement 22 (DROP;ORACLE_TOOLS;TYPE_BODY;T_REF_CONSTRAINT_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 22');
DROP TYPE BODY ORACLE_TOOLS.T_REF_CONSTRAINT_OBJECT;

/* SQL statement 23 (DROP;ORACLE_TOOLS;TYPE_BODY;T_REFRESH_GROUP_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 23');
DROP TYPE BODY ORACLE_TOOLS.T_REFRESH_GROUP_OBJECT;

/* SQL statement 24 (DROP;ORACLE_TOOLS;TYPE_BODY;T_REFRESH_GROUP_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 24');
DROP TYPE BODY ORACLE_TOOLS.T_REFRESH_GROUP_DDL;

/* SQL statement 25 (DROP;ORACLE_TOOLS;TYPE_BODY;T_PROCOBJ_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 25');
DROP TYPE BODY ORACLE_TOOLS.T_PROCOBJ_OBJECT;

/* SQL statement 26 (DROP;ORACLE_TOOLS;TYPE_BODY;T_PROCOBJ_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 26');
DROP TYPE BODY ORACLE_TOOLS.T_PROCOBJ_DDL;

/* SQL statement 27 (DROP;ORACLE_TOOLS;TYPE_BODY;T_PROCEDURE_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 27');
DROP TYPE BODY ORACLE_TOOLS.T_PROCEDURE_OBJECT;

/* SQL statement 28 (DROP;ORACLE_TOOLS;TYPE_BODY;T_PACKAGE_SPEC_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 28');
DROP TYPE BODY ORACLE_TOOLS.T_PACKAGE_SPEC_OBJECT;

/* SQL statement 29 (DROP;ORACLE_TOOLS;TYPE_BODY;T_PACKAGE_BODY_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 29');
DROP TYPE BODY ORACLE_TOOLS.T_PACKAGE_BODY_OBJECT;

/* SQL statement 30 (DROP;ORACLE_TOOLS;TYPE_BODY;T_OBJECT_GRANT_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 30');
DROP TYPE BODY ORACLE_TOOLS.T_OBJECT_GRANT_OBJECT;

/* SQL statement 31 (DROP;ORACLE_TOOLS;TYPE_BODY;T_OBJECT_GRANT_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 31');
DROP TYPE BODY ORACLE_TOOLS.T_OBJECT_GRANT_DDL;

/* SQL statement 32 (DROP;ORACLE_TOOLS;TYPE_BODY;T_NAMED_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 32');
DROP TYPE BODY ORACLE_TOOLS.T_NAMED_OBJECT;

/* SQL statement 33 (DROP;ORACLE_TOOLS;TYPE_BODY;T_MEMBER_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 33');
DROP TYPE BODY ORACLE_TOOLS.T_MEMBER_OBJECT;

/* SQL statement 34 (DROP;ORACLE_TOOLS;TYPE_BODY;T_MATERIALIZED_VIEW_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 34');
DROP TYPE BODY ORACLE_TOOLS.T_MATERIALIZED_VIEW_OBJECT;

/* SQL statement 35 (DROP;ORACLE_TOOLS;TYPE_BODY;T_MATERIALIZED_VIEW_LOG_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 35');
DROP TYPE BODY ORACLE_TOOLS.T_MATERIALIZED_VIEW_LOG_OBJECT;

/* SQL statement 36 (DROP;ORACLE_TOOLS;TYPE_BODY;T_MATERIALIZED_VIEW_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 36');
DROP TYPE BODY ORACLE_TOOLS.T_MATERIALIZED_VIEW_DDL;

/* SQL statement 37 (DROP;ORACLE_TOOLS;TYPE_BODY;T_JAVA_SOURCE_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 37');
DROP TYPE BODY ORACLE_TOOLS.T_JAVA_SOURCE_OBJECT;

/* SQL statement 38 (DROP;ORACLE_TOOLS;TYPE_BODY;T_INDEX_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 38');
DROP TYPE BODY ORACLE_TOOLS.T_INDEX_OBJECT;

/* SQL statement 39 (DROP;ORACLE_TOOLS;TYPE_BODY;T_INDEX_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 39');
DROP TYPE BODY ORACLE_TOOLS.T_INDEX_DDL;

/* SQL statement 40 (DROP;ORACLE_TOOLS;TYPE_BODY;T_FUNCTION_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 40');
DROP TYPE BODY ORACLE_TOOLS.T_FUNCTION_OBJECT;

/* SQL statement 41 (DROP;ORACLE_TOOLS;TYPE_BODY;T_DEPENDENT_OR_GRANTED_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 41');
DROP TYPE BODY ORACLE_TOOLS.T_DEPENDENT_OR_GRANTED_OBJECT;

/* SQL statement 42 (DROP;ORACLE_TOOLS;TYPE_BODY;T_DDL_SEQUENCE;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 42');
DROP TYPE BODY ORACLE_TOOLS.T_DDL_SEQUENCE;

/* SQL statement 43 (DROP;ORACLE_TOOLS;TYPE_BODY;T_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 43');
DROP TYPE BODY ORACLE_TOOLS.T_DDL;

/* SQL statement 44 (DROP;ORACLE_TOOLS;TYPE_BODY;T_CONSTRAINT_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 44');
DROP TYPE BODY ORACLE_TOOLS.T_CONSTRAINT_OBJECT;

/* SQL statement 45 (DROP;ORACLE_TOOLS;TYPE_BODY;T_CONSTRAINT_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 45');
DROP TYPE BODY ORACLE_TOOLS.T_CONSTRAINT_DDL;

/* SQL statement 46 (DROP;ORACLE_TOOLS;TYPE_BODY;T_COMMENT_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 46');
DROP TYPE BODY ORACLE_TOOLS.T_COMMENT_OBJECT;

/* SQL statement 47 (DROP;ORACLE_TOOLS;TYPE_BODY;T_COMMENT_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 47');
DROP TYPE BODY ORACLE_TOOLS.T_COMMENT_DDL;

/* SQL statement 48 (DROP;ORACLE_TOOLS;TYPE_BODY;T_CLUSTER_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 48');
DROP TYPE BODY ORACLE_TOOLS.T_CLUSTER_OBJECT;

/* SQL statement 49 (DROP;ORACLE_TOOLS;TYPE_BODY;T_ARGUMENT_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 49');
DROP TYPE BODY ORACLE_TOOLS.T_ARGUMENT_OBJECT;

/* SQL statement 50 (DROP;ORACLE_TOOLS;PACKAGE_BODY;SCHEMA_OBJECTS_API;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 50');
DROP PACKAGE BODY ORACLE_TOOLS.SCHEMA_OBJECTS_API;

/* SQL statement 51 (DROP;ORACLE_TOOLS;PACKAGE_BODY;PKG_STR_UTIL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 51');
DROP PACKAGE BODY ORACLE_TOOLS.PKG_STR_UTIL;

/* SQL statement 52 (DROP;ORACLE_TOOLS;PACKAGE_BODY;PKG_SCHEMA_OBJECT_FILTER;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 52');
DROP PACKAGE BODY ORACLE_TOOLS.PKG_SCHEMA_OBJECT_FILTER;

/* SQL statement 53 (DROP;ORACLE_TOOLS;PACKAGE_BODY;PKG_DDL_UTIL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 53');
DROP PACKAGE BODY ORACLE_TOOLS.PKG_DDL_UTIL;

/* SQL statement 54 (DROP;ORACLE_TOOLS;PACKAGE_BODY;PKG_DDL_ERROR;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 54');
DROP PACKAGE BODY ORACLE_TOOLS.PKG_DDL_ERROR;

/* SQL statement 55 (DROP;ORACLE_TOOLS;PROCEDURE;P_GENERATE_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 55');
DROP PROCEDURE ORACLE_TOOLS.P_GENERATE_DDL;

/* SQL statement 56 (DROP;ORACLE_TOOLS;VIEW;V_MY_SCHEMA_OBJECT_INFO;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 56');
DROP VIEW ORACLE_TOOLS.V_MY_SCHEMA_OBJECT_INFO;

/* SQL statement 57 (DROP;ORACLE_TOOLS;VIEW;V_MY_SCHEMA_OBJECTS_NO_DDL_YET;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 57');
DROP VIEW ORACLE_TOOLS.V_MY_SCHEMA_OBJECTS_NO_DDL_YET;

/* SQL statement 58 (DROP;ORACLE_TOOLS;VIEW;V_MY_SCHEMA_OBJECTS;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 58');
DROP VIEW ORACLE_TOOLS.V_MY_SCHEMA_OBJECTS;

/* SQL statement 59 (DROP;ORACLE_TOOLS;VIEW;V_MY_SCHEMA_DDL_INFO;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 59');
DROP VIEW ORACLE_TOOLS.V_MY_SCHEMA_DDL_INFO;

/* SQL statement 60 (DROP;ORACLE_TOOLS;VIEW;V_MY_SCHEMA_DDLS;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 60');
DROP VIEW ORACLE_TOOLS.V_MY_SCHEMA_DDLS;

/* SQL statement 61 (DROP;ORACLE_TOOLS;VIEW;V_MY_NAMED_SCHEMA_OBJECTS;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 61');
DROP VIEW ORACLE_TOOLS.V_MY_NAMED_SCHEMA_OBJECTS;

/* SQL statement 62 (DROP;ORACLE_TOOLS;VIEW;V_MY_INCLUDE_OBJECTS;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 62');
DROP VIEW ORACLE_TOOLS.V_MY_INCLUDE_OBJECTS;

/* SQL statement 63 (DROP;ORACLE_TOOLS;VIEW;V_MY_GENERATE_DDL_SESSION_SCHEMA_DDL_BATCHES;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 63');
DROP VIEW ORACLE_TOOLS.V_MY_GENERATE_DDL_SESSION_SCHEMA_DDL_BATCHES;

/* SQL statement 64 (DROP;ORACLE_TOOLS;VIEW;V_DISPLAY_DDL_SCHEMA;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 64');
DROP VIEW ORACLE_TOOLS.V_DISPLAY_DDL_SCHEMA;

/* SQL statement 65 (DROP;ORACLE_TOOLS;VIEW;V_ALL_SCHEMA_OBJECTS;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 65');
DROP VIEW ORACLE_TOOLS.V_ALL_SCHEMA_OBJECTS;

/* SQL statement 66 (DROP;ORACLE_TOOLS;PACKAGE_SPEC;SCHEMA_OBJECTS_API;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 66');
DROP PACKAGE ORACLE_TOOLS.SCHEMA_OBJECTS_API;

/* SQL statement 67 (DROP;ORACLE_TOOLS;PACKAGE_SPEC;PKG_STR_UTIL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 67');
DROP PACKAGE ORACLE_TOOLS.PKG_STR_UTIL;

/* SQL statement 68 (DROP;ORACLE_TOOLS;PACKAGE_SPEC;PKG_SCHEMA_OBJECT_FILTER;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 68');
DROP PACKAGE ORACLE_TOOLS.PKG_SCHEMA_OBJECT_FILTER;

/* SQL statement 69 (DROP;ORACLE_TOOLS;PACKAGE_SPEC;PKG_DDL_UTIL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 69');
DROP PACKAGE ORACLE_TOOLS.PKG_DDL_UTIL;

/* SQL statement 70 (DROP;ORACLE_TOOLS;PACKAGE_SPEC;PKG_DDL_ERROR;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 70');
DROP PACKAGE ORACLE_TOOLS.PKG_DDL_ERROR;

/* SQL statement 71 (DROP;ORACLE_TOOLS;FUNCTION;F_GENERATE_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 71');
DROP FUNCTION ORACLE_TOOLS.F_GENERATE_DDL;

/* SQL statement 72 (DROP;ORACLE_TOOLS;TABLE;SCHEMA_OBJECT_FILTERS;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 72');
DROP TABLE ORACLE_TOOLS.SCHEMA_OBJECT_FILTERS PURGE;

/* SQL statement 73 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_VIEW_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 73');
DROP TYPE ORACLE_TOOLS.T_VIEW_OBJECT FORCE;

/* SQL statement 74 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_TYPE_SPEC_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 74');
DROP TYPE ORACLE_TOOLS.T_TYPE_SPEC_OBJECT FORCE;

/* SQL statement 75 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_TYPE_SPEC_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 75');
DROP TYPE ORACLE_TOOLS.T_TYPE_SPEC_DDL FORCE;

/* SQL statement 76 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_TYPE_METHOD_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 76');
DROP TYPE ORACLE_TOOLS.T_TYPE_METHOD_OBJECT FORCE;

/* SQL statement 77 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_TYPE_METHOD_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 77');
DROP TYPE ORACLE_TOOLS.T_TYPE_METHOD_DDL FORCE;

/* SQL statement 78 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_TYPE_BODY_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 78');
DROP TYPE ORACLE_TOOLS.T_TYPE_BODY_OBJECT FORCE;

/* SQL statement 79 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_TYPE_ATTRIBUTE_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 79');
DROP TYPE ORACLE_TOOLS.T_TYPE_ATTRIBUTE_OBJECT FORCE;

/* SQL statement 80 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_TYPE_ATTRIBUTE_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 80');
DROP TYPE ORACLE_TOOLS.T_TYPE_ATTRIBUTE_DDL FORCE;

/* SQL statement 81 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_TRIGGER_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 81');
DROP TYPE ORACLE_TOOLS.T_TRIGGER_OBJECT FORCE;

/* SQL statement 82 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_TRIGGER_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 82');
DROP TYPE ORACLE_TOOLS.T_TRIGGER_DDL FORCE;

/* SQL statement 83 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_TEXT_TAB;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 83');
DROP TYPE ORACLE_TOOLS.T_TEXT_TAB FORCE;

/* SQL statement 84 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_TABLE_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 84');
DROP TYPE ORACLE_TOOLS.T_TABLE_OBJECT FORCE;

/* SQL statement 85 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_TABLE_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 85');
DROP TYPE ORACLE_TOOLS.T_TABLE_DDL FORCE;

/* SQL statement 86 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_TABLE_COLUMN_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 86');
DROP TYPE ORACLE_TOOLS.T_TABLE_COLUMN_OBJECT FORCE;

/* SQL statement 87 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_TABLE_COLUMN_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 87');
DROP TYPE ORACLE_TOOLS.T_TABLE_COLUMN_DDL FORCE;

/* SQL statement 88 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_SYNONYM_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 88');
DROP TYPE ORACLE_TOOLS.T_SYNONYM_OBJECT FORCE;

/* SQL statement 89 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_SYNONYM_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 89');
DROP TYPE ORACLE_TOOLS.T_SYNONYM_DDL FORCE;

/* SQL statement 90 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_SEQUENCE_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 90');
DROP TYPE ORACLE_TOOLS.T_SEQUENCE_OBJECT FORCE;

/* SQL statement 91 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_SEQUENCE_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 91');
DROP TYPE ORACLE_TOOLS.T_SEQUENCE_DDL FORCE;

/* SQL statement 92 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_SCHEMA_OBJECT_TAB;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 92');
DROP TYPE ORACLE_TOOLS.T_SCHEMA_OBJECT_TAB FORCE;

/* SQL statement 93 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_SCHEMA_OBJECT_FILTER;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 93');
DROP TYPE ORACLE_TOOLS.T_SCHEMA_OBJECT_FILTER FORCE;

/* SQL statement 94 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_SCHEMA_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 94');
DROP TYPE ORACLE_TOOLS.T_SCHEMA_OBJECT FORCE;

/* SQL statement 95 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_SCHEMA_DDL_TAB;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 95');
DROP TYPE ORACLE_TOOLS.T_SCHEMA_DDL_TAB FORCE;

/* SQL statement 96 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_SCHEMA_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 96');
DROP TYPE ORACLE_TOOLS.T_SCHEMA_DDL FORCE;

/* SQL statement 97 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_REF_CONSTRAINT_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 97');
DROP TYPE ORACLE_TOOLS.T_REF_CONSTRAINT_OBJECT FORCE;

/* SQL statement 98 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_REFRESH_GROUP_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 98');
DROP TYPE ORACLE_TOOLS.T_REFRESH_GROUP_OBJECT FORCE;

/* SQL statement 99 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_REFRESH_GROUP_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 99');
DROP TYPE ORACLE_TOOLS.T_REFRESH_GROUP_DDL FORCE;

/* SQL statement 100 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_PROCOBJ_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 100');
DROP TYPE ORACLE_TOOLS.T_PROCOBJ_OBJECT FORCE;

/* SQL statement 101 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_PROCOBJ_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 101');
DROP TYPE ORACLE_TOOLS.T_PROCOBJ_DDL FORCE;

/* SQL statement 102 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_PROCEDURE_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 102');
DROP TYPE ORACLE_TOOLS.T_PROCEDURE_OBJECT FORCE;

/* SQL statement 103 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_PACKAGE_SPEC_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 103');
DROP TYPE ORACLE_TOOLS.T_PACKAGE_SPEC_OBJECT FORCE;

/* SQL statement 104 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_PACKAGE_BODY_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 104');
DROP TYPE ORACLE_TOOLS.T_PACKAGE_BODY_OBJECT FORCE;

/* SQL statement 105 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_OBJECT_INFO_TAB;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 105');
DROP TYPE ORACLE_TOOLS.T_OBJECT_INFO_TAB FORCE;

/* SQL statement 106 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_OBJECT_INFO_REC;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 106');
DROP TYPE ORACLE_TOOLS.T_OBJECT_INFO_REC FORCE;

/* SQL statement 107 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_OBJECT_GRANT_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 107');
DROP TYPE ORACLE_TOOLS.T_OBJECT_GRANT_OBJECT FORCE;

/* SQL statement 108 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_OBJECT_GRANT_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 108');
DROP TYPE ORACLE_TOOLS.T_OBJECT_GRANT_DDL FORCE;

/* SQL statement 109 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_NAMED_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 109');
DROP TYPE ORACLE_TOOLS.T_NAMED_OBJECT FORCE;

/* SQL statement 110 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_MEMBER_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 110');
DROP TYPE ORACLE_TOOLS.T_MEMBER_OBJECT FORCE;

/* SQL statement 111 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_MATERIALIZED_VIEW_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 111');
DROP TYPE ORACLE_TOOLS.T_MATERIALIZED_VIEW_OBJECT FORCE;

/* SQL statement 112 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_MATERIALIZED_VIEW_LOG_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 112');
DROP TYPE ORACLE_TOOLS.T_MATERIALIZED_VIEW_LOG_OBJECT FORCE;

/* SQL statement 113 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_MATERIALIZED_VIEW_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 113');
DROP TYPE ORACLE_TOOLS.T_MATERIALIZED_VIEW_DDL FORCE;

/* SQL statement 114 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_JAVA_SOURCE_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 114');
DROP TYPE ORACLE_TOOLS.T_JAVA_SOURCE_OBJECT FORCE;

/* SQL statement 115 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_INDEX_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 115');
DROP TYPE ORACLE_TOOLS.T_INDEX_OBJECT FORCE;

/* SQL statement 116 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_INDEX_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 116');
DROP TYPE ORACLE_TOOLS.T_INDEX_DDL FORCE;

/* SQL statement 117 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_FUNCTION_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 117');
DROP TYPE ORACLE_TOOLS.T_FUNCTION_OBJECT FORCE;

/* SQL statement 118 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_DEPENDENT_OR_GRANTED_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 118');
DROP TYPE ORACLE_TOOLS.T_DEPENDENT_OR_GRANTED_OBJECT FORCE;

/* SQL statement 119 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_DDL_TAB;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 119');
DROP TYPE ORACLE_TOOLS.T_DDL_TAB FORCE;

/* SQL statement 120 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_DDL_SEQUENCE;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 120');
DROP TYPE ORACLE_TOOLS.T_DDL_SEQUENCE FORCE;

/* SQL statement 121 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 121');
DROP TYPE ORACLE_TOOLS.T_DDL FORCE;

/* SQL statement 122 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_CONSTRAINT_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 122');
DROP TYPE ORACLE_TOOLS.T_CONSTRAINT_OBJECT FORCE;

/* SQL statement 123 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_CONSTRAINT_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 123');
DROP TYPE ORACLE_TOOLS.T_CONSTRAINT_DDL FORCE;

/* SQL statement 124 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_COMMENT_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 124');
DROP TYPE ORACLE_TOOLS.T_COMMENT_OBJECT FORCE;

/* SQL statement 125 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_COMMENT_DDL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 125');
DROP TYPE ORACLE_TOOLS.T_COMMENT_DDL FORCE;

/* SQL statement 126 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_CLUSTER_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 126');
DROP TYPE ORACLE_TOOLS.T_CLUSTER_OBJECT FORCE;

/* SQL statement 127 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_ARGUMENT_OBJECT_TAB;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 127');
DROP TYPE ORACLE_TOOLS.T_ARGUMENT_OBJECT_TAB FORCE;

/* SQL statement 128 (DROP;ORACLE_TOOLS;TYPE_SPEC;T_ARGUMENT_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 128');
DROP TYPE ORACLE_TOOLS.T_ARGUMENT_OBJECT FORCE;

/* SQL statement 129 (DROP;ORACLE_TOOLS;SEQUENCE;SCHEMA_OBJECT_FILTERS$SEQ;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 129');
DROP SEQUENCE ORACLE_TOOLS.SCHEMA_OBJECT_FILTERS$SEQ;

