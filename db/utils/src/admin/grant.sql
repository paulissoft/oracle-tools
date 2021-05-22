set define on verify off

define oracle_tools_schema = oracle_tools

accept oracle_tools_schema prompt "Oracle tools schema [&&oracle_tools_schema] ? " default "&&oracle_tools_schema"

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
to &&oracle_tools_schema;
