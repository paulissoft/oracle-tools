call dbms_application_info.set_module('R__18.OBJECT_GRANT.DATA_ROW_ID_T.sql', null);
call dbms_application_info.set_action('SQL statement 1');
GRANT EXECUTE ON "DATA_ROW_ID_T" TO PUBLIC;

call dbms_application_info.set_action('SQL statement 2');
GRANT UNDER ON "DATA_ROW_ID_T" TO PUBLIC;

