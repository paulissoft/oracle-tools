set define on verify off

define oracle_tools_username_msg = ORACLE_TOOLS

accept oracle_tools_username_msg prompt "PATO schema for messaging [&&oracle_tools_username_msg] ? " default "&&oracle_tools_username_msg"

define privileges = "create job, create procedure, create sequence, create session, create synonym, create table, create trigger, create type, create view"

grant &&privileges to &&oracle_tools_username_msg;

grant execute on sys.dbms_aqadm to &&oracle_tools_username_msg;
grant execute on sys.dbms_aq to &&oracle_tools_username_msg;
grant execute on sys.dbms_pipe to &&oracle_tools_username_msg;
