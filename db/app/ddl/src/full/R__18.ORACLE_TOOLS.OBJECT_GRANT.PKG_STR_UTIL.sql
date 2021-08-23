call dbms_application_info.set_module('R__18.ORACLE_TOOLS.OBJECT_GRANT.PKG_STR_UTIL.sql', null);
call dbms_application_info.set_action('SQL statement 1');
begin
  execute immediate 'GRANT EXECUTE ON "ORACLE_TOOLS"."PKG_STR_UTIL" TO PUBLIC'; 
exception
  when others
  then null;
end;
/

