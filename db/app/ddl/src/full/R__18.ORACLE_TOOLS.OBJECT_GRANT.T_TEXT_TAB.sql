call dbms_application_info.set_module('R__18.ORACLE_TOOLS.OBJECT_GRANT.T_TEXT_TAB.sql', null);
call dbms_application_info.set_action('SQL statement 1');
begin
  execute immediate 'GRANT EXECUTE ON "ORACLE_TOOLS"."T_TEXT_TAB" TO PUBLIC'; 
exception
  when others
  then null;
end;;

