call dbms_application_info.set_module('R__18.ORACLE_TOOLS.OBJECT_GRANT.P_GENERATE_DDL.sql', null);
call dbms_application_info.set_action('SQL statement 1');
call oracle_tools.pkg_ddl_util.execute_ddl(p_id => ':OBJECT_GRANT::ORACLE_TOOLS::P_GENERATE_DDL::PUBLIC:EXECUTE:NO', p_text => 'GRANT EXECUTE ON "ORACLE_TOOLS"."P_GENERATE_DDL" TO PUBLIC');

