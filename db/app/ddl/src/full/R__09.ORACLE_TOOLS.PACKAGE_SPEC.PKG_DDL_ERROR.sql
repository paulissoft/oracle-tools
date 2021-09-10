CREATE OR REPLACE PACKAGE "ORACLE_TOOLS"."PKG_DDL_ERROR" IS

-- The error_code is an integer in the range -20000..-20999 and the message is a character string of at most 2048 bytes.

/* EXCEPTIONS */
c_schema_does_not_exist        constant integer := -20100;
e_schema_does_not_exist        exception;
pragma exception_init(e_schema_does_not_exist, -20100);

c_numeric_boolean_wrong   constant integer := -20101;
e_numeric_boolean_wrong   exception;
pragma exception_init(e_numeric_boolean_wrong, -20101);

c_database_link_does_not_exist constant integer := -20102;
e_database_link_does_not_exist exception;
pragma exception_init(e_database_link_does_not_exist, -20102);

c_schema_wrong                 constant integer := -20103;
e_schema_wrong                 exception;
pragma exception_init(e_schema_wrong, -20103);

c_source_and_target_equal      constant integer := -20104;
e_source_and_target_equal      exception;
pragma exception_init(e_source_and_target_equal, -20104);

c_object_names_wrong  constant integer := -20105;
e_object_names_wrong  exception;
pragma exception_init(e_object_names_wrong, -20105);

c_object_type_wrong  constant integer := -20106;
e_object_type_wrong  exception;
pragma exception_init(e_object_type_wrong, -20106);

c_could_not_process_interface  constant pls_integer := -20107;
e_could_not_process_interface  exception;
pragma exception_init(e_could_not_process_interface, -20107);

c_reraise_with_backtrace       constant pls_integer := -20108;
e_reraise_with_backtrace       exception;
pragma exception_init(e_reraise_with_backtrace, -20108);

c_could_not_parse              constant pls_integer := -20109;
e_could_not_parse              exception;
pragma exception_init(e_could_not_parse, -20109);

c_invalid_parameters           constant pls_integer := -20110;
e_invalid_parameters           exception;
pragma exception_init(e_invalid_parameters, -20110);

c_missing_session_role         constant pls_integer := -20111;
e_missing_session_role         exception;
pragma exception_init(e_missing_session_role, -20111);

c_missing_session_privilege    constant pls_integer := -20112;
e_missing_session_privilege    exception;
pragma exception_init(e_missing_session_privilege, -20112);

c_object_not_correct           constant pls_integer := -20113;
e_object_not_correct           exception;
pragma exception_init(e_object_not_correct, -20113);

c_object_not_found             constant pls_integer := -20114;
e_object_not_found             exception;
pragma exception_init(e_object_not_found, -20114);

c_execute_via_db_link          constant pls_integer := -20115;
e_execute_via_db_link          exception;
pragma exception_init(e_execute_via_db_link, -20115);

c_duplicate_item               constant pls_integer := -20116;
e_duplicate_item               exception;
pragma exception_init(e_duplicate_item, -20116);

c_object_not_valid             constant pls_integer := -20117;
e_object_not_valid             exception;
pragma exception_init(e_object_not_valid, -20117);

c_no_ddl_retrieved             constant pls_integer := -20118;
e_no_ddl_retrieved             exception;
pragma exception_init(e_no_ddl_retrieved, -20118);

c_missing_schema               constant pls_integer := -20119;
e_missing_schema               exception;
pragma exception_init(e_missing_schema, -20119);

c_missing_db_link              constant pls_integer := -20120;
e_missing_db_link              exception;
pragma exception_init(e_missing_db_link, -20120);

c_schema_not_empty             constant pls_integer := -20121;
e_schema_not_empty             exception;
pragma exception_init(e_schema_not_empty, -20121);

c_wrong_db_link                constant pls_integer := -20121;
e_wrong_db_link                exception;
pragma exception_init(e_wrong_db_link, -20121);

c_not_implemented              constant pls_integer := -20122;
e_not_implemented              exception;
pragma exception_init(e_not_implemented, -20122);

end pkg_ddl_error;
/

