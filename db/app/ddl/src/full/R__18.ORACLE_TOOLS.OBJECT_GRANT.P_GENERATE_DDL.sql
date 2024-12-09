call dbms_application_info.set_module('R__18.ORACLE_TOOLS.OBJECT_GRANT.P_GENERATE_DDL.sql', null);
call dbms_application_info.set_action('SQL statement 1');
GRANT EXECUTE ON "ORACLE_TOOLS"."P_GENERATE_DDL" TO "ADMIN" WITH GRANT OPTION;

call dbms_application_info.set_action('SQL statement 2');
GRANT EXECUTE ON "ORACLE_TOOLS"."P_GENERATE_DDL" TO PUBLIC;

