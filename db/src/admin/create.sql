set define on verify off

whenever sqlerror exit failure

define oracle_tools_username = ORACLE_TOOLS

accept oracle_tools_username prompt "Oracle tools username [&&oracle_tools_username] ? " default "&&oracle_tools_username"

define oracle_tools_password = &&oracle_tools_username

accept oracle_tools_password prompt "Oracle tools password [&&oracle_tools_password] ? " default "&&oracle_tools_password" hide

define tablespace_users = users

accept tablespace_users prompt "Default tablespace [&&tablespace_users] ? " default "&&tablespace_users"

define tablespace_temp = temp

accept tablespace_temp prompt "Temporary tablespace [&&tablespace_temp] ? " default "&&tablespace_temp"

create user &&oracle_tools_username -
identified by "&&oracle_tools_password" -
default tablespace &&tablespace_users -
temporary tablespace &&tablespace_users;
