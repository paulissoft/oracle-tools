set define on verify off

define oracle_tools_username = ORACLE_TOOLS

accept oracle_tools_username prompt "PATO schema [&&oracle_tools_username] ? " default "&&oracle_tools_username"

define privileges = "create job, create materialized view, create procedure, create sequence, create session, create synonym, create table, create trigger, create type, create view"

grant &&privileges to &&oracle_tools_username;

grant execute on sys.dbms_aqadm to &&oracle_tools_username;
grant execute on sys.dbms_aq to &&oracle_tools_username;
grant execute on sys.dbms_pipe to &&oracle_tools_username;

declare
  l_found pls_integer;
begin
  -- does ut.version (utPLSQL V3) or utconfig.showfailuresonly (utPLSQL v1 and v2) exist?
  begin
    select  1
    into    l_found
    from    all_procedures
    where   ( object_name = 'UT' and procedure_name = 'VERSION' )
    or      ( object_name = 'UTCONFIG' and procedure_name = 'SHOWFAILURESONLY' );

  exception
    when no_data_found
    then
      l_found := 0;
    when too_many_rows
    then
      l_found := 1;
  end;

  -- when utPLSQL exists issue extra grants
  if l_found = 1
  then
    -- same priviliges for EMPTY as for ORACLE_TOOLS
    execute immediate 'grant &&privileges to EMPTY';
    -- something extra for ORACLE_TOOLS
    execute immediate 'grant create database link to &&oracle_tools_username';
    execute immediate 'grant select_catalog_role to &&oracle_tools_username';
  end if;
end;
/
