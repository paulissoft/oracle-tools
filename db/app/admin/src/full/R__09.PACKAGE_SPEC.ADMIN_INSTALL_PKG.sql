create or replace package admin_install_pkg authid definer is

procedure init
( p_repo_owner in varchar2
, p_repo_name in varchar2
);
/** Must be the first **/

procedure done;
/** Finished installing. Will reset the current schema to the one when `init()` was called. **/

procedure install_project
( p_schema in varchar -- The database schema to install into
, p_path in varchar2 -- The repository file path
, p_branch_name in varchar2 default null -- The branch
, p_tag_name in varchar2 default null -- The tag
, p_commit_id in varchar2 default null -- The commit
, p_stop_on_error in boolean default true -- Must we stop on error?
);

procedure install_file
( p_schema in varchar -- The database schema to install into
, p_file_path in varchar2 -- The repository file path
, p_branch_name in varchar2 default null -- The branch
, p_tag_name in varchar2 default null -- The tag
, p_commit_id in varchar2 default null -- The commit
, p_stop_on_error in boolean default true -- Must we stop on error?
);
/**
An enhanced version of DBMS_CLOUD_REPO.INSTALL_FILE.

Will retrieve the file contents via DBMS_CLOUD_REPO.GET_FILE and then invoke the second variant of INSTALL_FILE, see below.
**/

procedure install_file
( p_schema in varchar -- The database schema to install into
, p_file_path in varchar2 -- The repository file path, for reference only
, p_content in clob -- The content from the repository file
, p_branch_name in varchar2 default null -- The branch
, p_tag_name in varchar2 default null -- The tag
, p_commit_id in varchar2 default null -- The commit
, p_stop_on_error in boolean default true -- Must we stop on error?
);
/**
An enhanced version of DBMS_CLOUD_REPO.INSTALL_FILE:
1) you must specify the schema to install into (alter sesison set current_schema = <p_schema>)
2) when the first line starts with a @ (or @@), the file is assumed to be a simple SQL include file from the same repository (and same branch/tag/commit)
   a) now every line starting with @ (or @@) will be installed by ADMIN_INSTALL_PKG.INSTALL_FILE
   b) after getting its contents from DBMS_CLOUD_REPO.GET_FILE and setting the new file path
3) else, just use ADMIN_INSTALL_PKG.INSTALL_SQL

**/

procedure install_sql
( p_file_path in varchar2 -- The repository file path, for reference only
, p_content in clob -- The content from the repository file
, p_stop_on_error in boolean default true -- Must we stop on error?
);
/**
An enhanced version of DBMS_CLOUD_REPO.INSTALL_SQL.

There is some special handling (see also db/src/scripts/generate_ddl.pl) for file path names containing these DBMS_METADATA object types:
- SEQUENCE
- CLUSTER
- TABLE
- VIEW
- MATERIALIZED_VIEW
- MATERIALIZED_VIEW_LOG
- INDEX
- OBJECT_GRANT
- CONSTRAINT
- REF_CONSTRAINT
- PUBLIC_SYNONYM
- SYNONYM
- COMMENT

The PATO will add a semi-colon (;) as SQL terminator but DBMS_CLOUD_REPO expects a slash (/) on a new line.
So we will:
1) split by lines ending with a semi-colon
2) strip the semi-colon
3) feed it to DBMS_CLOUD_REPO.INSTALL_SQL without any terminator since that works fine

**/

end;
/

