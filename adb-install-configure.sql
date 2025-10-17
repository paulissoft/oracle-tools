/*
-- Script: adb-install-configure.sql
-- Goal  : A SQL*Plus script to return the repo handle from DBMS_CLOUD_REPO.INIT_GITHUB_REPO
-- Input : 1) The repo owner (case sensitive)
--         2) The repo name (case sensitive)
-- Remark: Verify by https://github.com/&1/&2
*/

-- input parameters 1 and 2
var repo_owner varchar2(128)
var repo_name varchar2(128)

-- output parameters
var repo_id varchar2(128)
var credential_name varchar2(128)
var repo clob

set feedback off verify off pagesize 100 long 10000

declare
begin
  :repo_owner := '&1';
  :repo_name := '&2';
  
  select  credential_name
  into    :credential_name
  from    dba_credentials
  where   owner = 'ADMIN'
  and     credential_name like '%GITHUB%';

  :repo :=
    DBMS_CLOUD_REPO.INIT_GITHUB_REPO
    ( credential_name => :credential_name
    , repo_name => :repo_name
    , owner => :repo_owner
    );

  -- check it does exist
  select  t.id
  into    :repo_id
  from    table(DBMS_CLOUD_REPO.LIST_REPOSITORIES(:repo)) t
  where   t.owner = :repo_owner
  and     t.name = :repo_name;
end;
/

column id format a30 wrap
column name format a40 wrap
column owner format a30 wrap
column description format a100 wrap
column private heading "PRIVATE"
column url format a100
column bytes format 999G999G999G999
column created format a35
column last_modified format a35

select  t.*
from    table(DBMS_CLOUD_REPO.LIST_REPOSITORIES(:repo)) t
where   t.id = :repo_id
/

undefine 1 2
