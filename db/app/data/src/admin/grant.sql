set define on
whenever sqlerror exit failure

grant create session to &&oracle_tools_schema;
grant create table to &&oracle_tools_schema;
grant create view to &&oracle_tools_schema;
grant create procedure to &&oracle_tools_schema;
grant create sequence to &&oracle_tools_schema;
grant create trigger to &&oracle_tools_schema;
grant create materialized view to &&oracle_tools_schema;
grant create synonym to &&oracle_tools_schema;
grant create type to &&oracle_tools_schema;
grant create job to &&oracle_tools_schema;

