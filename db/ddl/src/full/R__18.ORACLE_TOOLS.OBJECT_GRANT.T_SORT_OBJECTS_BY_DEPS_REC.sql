call dbms_application_info.set_module('R__18.ORACLE_TOOLS.OBJECT_GRANT.T_SORT_OBJECTS_BY_DEPS_REC.sql', null);
call dbms_application_info.set_action('SQL statement 1');
call oracle_tools.pkg_ddl_util.execute_ddl(p_id => ':OBJECT_GRANT::ORACLE_TOOLS::T_SORT_OBJECTS_BY_DEPS_REC::WR_ORACLE_TOOLS:EXECUTE:NO', p_text => 'GRANT EXECUTE ON "ORACLE_TOOLS"."T_SORT_OBJECTS_BY_DEPS_REC" TO "WR_ORACLE_TOOLS"');

