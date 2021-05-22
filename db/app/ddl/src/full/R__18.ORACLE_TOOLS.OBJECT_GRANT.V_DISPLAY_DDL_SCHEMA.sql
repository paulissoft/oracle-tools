call dbms_application_info.set_module('R__18.ORACLE_TOOLS.OBJECT_GRANT.V_DISPLAY_DDL_SCHEMA.sql', null);
call dbms_application_info.set_action('SQL statement 1');
call oracle_tools.pkg_ddl_util.execute_ddl(p_id => ':OBJECT_GRANT::ORACLE_TOOLS::V_DISPLAY_DDL_SCHEMA::WR_ORACLE_TOOLS:SELECT:NO', p_text => 'GRANT SELECT ON "ORACLE_TOOLS"."V_DISPLAY_DDL_SCHEMA" TO "WR_ORACLE_TOOLS"');

