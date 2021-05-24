set define on verify off

define oracle_tools_username = ORACLE_TOOLS

accept oracle_tools_username prompt "Oracle tools schema [&&oracle_tools_username] ? " default "&&oracle_tools_username"

grant CREATE SESSION -
,CREATE TABLE -
,CREATE CLUSTER -
,CREATE SYNONYM -
,CREATE VIEW -
,CREATE SEQUENCE -
,CREATE PROCEDURE -
,CREATE TRIGGER -
,CREATE MATERIALIZED VIEW -
,CREATE TYPE -
,CREATE OPERATOR -
,CREATE INDEXTYPE -
,CREATE DIMENSION -
,CREATE JOB -
to &&oracle_tools_username;
