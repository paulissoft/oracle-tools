set define on verify off

whenever sqlerror exit failure

define oracle_tools_username = ORACLE_TOOLS

accept oracle_tools_username prompt "PATO username [&&oracle_tools_username] ? " default "&&oracle_tools_username"

define oracle_tools_password = &&oracle_tools_username

accept oracle_tools_password prompt "PATO password [&&oracle_tools_password] ? " default "&&oracle_tools_password" hide

define tablespace_users = DATA

accept tablespace_users prompt "Default tablespace [&&tablespace_users] ? " default "&&tablespace_users"

define tablespace_temp = TEMP

accept tablespace_temp prompt "Temporary tablespace [&&tablespace_temp] ? " default "&&tablespace_temp"

-- create user &&oracle_tools_username
declare
  -- ORA-01920: user name 'ORACLE_TOOLS' conflicts with another user or role name
  e_user_already_exists exception;
  pragma exception_init(e_user_already_exists, -1920);
begin
  execute immediate 'create user &&oracle_tools_username
identified by "&&oracle_tools_password"
default tablespace &&tablespace_users
temporary tablespace &&tablespace_temp';

  execute immediate 'alter user &&oracle_tools_username
quota unlimited on &&tablespace_users';
exception
  when e_user_already_exists
  then null;
end;
/

-- create user EMPTY
declare
  l_found pls_integer;
begin
  -- does ut.version (utPLSQL V3) or utconfig.showfailuresonly (utPLSQL v1 and v2) exist?
  begin
    select  1
    into    l_found
    from    all_procedures
    where   ( ( object_name = 'UT' and procedure_name = 'VERSION' ) or
              ( object_name = 'UTCONFIG' and procedure_name = 'SHOWFAILURESONLY' )
            )
    and     not
            ( exists
              ( select  1
                from    all_users u
                where   u.username = 'EMPTY'
              )
            );

  exception
    when no_data_found
    then
      l_found := 0;
    when too_many_rows
    then
      l_found := 1;
  end;

  -- when utPLSQL exists create a user EMPTY for unit testing
  if l_found = 1
  then
    execute immediate 'create user EMPTY identified by "EMPTY" default tablespace &&tablespace_users temporary tablespace &&tablespace_temp';
    execute immediate 'alter user EMPTY quota unlimited on &&tablespace_users';
    execute immediate 'grant create procedure, create type, create view, create session to EMPTY';
  end if;
end;
/
