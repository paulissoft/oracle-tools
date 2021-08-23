call dbms_application_info.set_module('R__18.ORACLE_TOOLS.OBJECT_GRANT.T_SCHEMA_OBJECT.sql', null);
call dbms_application_info.set_action('SQL statement 1');
begin
  execute immediate 'GRANT EXECUTE ON "ORACLE_TOOLS"."T_SCHEMA_OBJECT" TO PUBLIC'; 
exception
  when others
  then null;
end;
/

