set define on verify off

define oracle_tools_username = ORACLE_TOOLS

accept oracle_tools_username prompt "Oracle tools schema [&&oracle_tools_username] ? " default "&&oracle_tools_username"

grant create job -
,create materialized view -
,create procedure -
,create sequence -
,create session -
,create synonym -
,create table -
,create trigger -
,create type -
,create view -
to &&oracle_tools_username;
