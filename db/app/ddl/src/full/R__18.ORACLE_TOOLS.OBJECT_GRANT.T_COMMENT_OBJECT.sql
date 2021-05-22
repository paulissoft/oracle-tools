call dbms_application_info.set_module('R__18.ORACLE_TOOLS.OBJECT_GRANT.T_COMMENT_OBJECT.sql', null);
call dbms_application_info.set_action('SQL statement 1');
call oracle_tools.pkg_ddl_util.execute_ddl(p_id => ':OBJECT_GRANT::ORACLE_TOOLS::T_COMMENT_OBJECT::WR_ORACLE_TOOLS:EXECUTE:NO', p_text => 'GRANT EXECUTE ON "ORACLE_TOOLS"."T_COMMENT_OBJECT" TO "WR_ORACLE_TOOLS"');

