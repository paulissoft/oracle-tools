create or replace package admin_install_pkg authid definer is

/**
A package based on DBMS_CLOUD_REPO in order to:
- install files (database/APEX) from a repository like the PATO does with Maven POM files using Flyway.
- export (database/APEX) scripts to a repository like the PATO does with Maven POM files.

In order to mimic this Maven POM behaviour:
- there will be `pom.sql` files in folders with a `pom.xml` defining the most important properties using:
  * `define_project_db`
  * `define_project_apex`
- these project definition routines will recursively define sub folder modules (each expecting a pom.sql along the pom.xml)
- the root folder will thus contain at most two invocations: one to the root database folder and one to the root apex folder
**/

type github_access_rec_t is record
( repo_owner varchar2(128 char)
, repo_name varchar2(128 char)
, branch_name varchar2(128 char)
, tag_name varchar2(128 char)
, commit_id varchar2(40 char) -- SHA1
, credential_name user_credentials.credential_name%type
, repo clob -- defined by DBMS_CLOUD_REPO.INIT_GITHUB_REPO() using the repo owner and name
, repo_id varchar2(128 char)
, current_schema all_users.username%type -- when this record was constructed in set_github_access()
);

subtype github_access_handle_t is varchar2(256);

procedure set_github_access
( p_repo_owner in varchar2
, p_repo_name in varchar2
, p_branch_name in varchar2 default null -- The branch
, p_tag_name in varchar2 default null -- The tag
, p_commit_id in varchar2 default null -- The commit
, p_github_access_handle out nocopy github_access_handle_t -- This will be p_repo_owner, a slash (/) and the p_repo_name
);
/**
Will store the info for future use in internal memory.

Will define the repo handle based on an ADMIN credential name like '%GITHUB%' and the repo owner and name.

Will also store the branch/tag/commit id for future use.

The github access handle will be the repo owner and name
like in https://github.com/<github access handle>.git, for instance paulissoft/oracle-tools.
**/

procedure get_github_access
( p_github_access_handle in github_access_handle_t -- The GitHub repository handle as returned from set_github_access()
, p_github_access_rec out nocopy github_access_rec_t
);
/** Get the info from internal memory. **/

procedure delete_github_access
( p_github_access_handle in github_access_handle_t -- The GitHub repository handle as returned from set_github_access()
);
/** Will remove this handle from internal memory and restore the current schema to the schema before invoking set_github_access(). **/

procedure define_project_db
( p_github_access_handle in github_access_handle_t -- The GitHub access handle
, p_path in varchar2 -- The repository file path
, p_schema in varchar default null -- The database schema
, p_parent_github_access_handle in github_access_handle_t default null -- The parent GitHub access handle
, p_parent_path in varchar2 default null -- The parent repository file path
, p_modules in sys.odcivarchar2list default null -- The sub module paths to process when the POM is a container
, p_src_callbacks in varchar2 default '/src/callbacks/'
, p_src_incr in varchar2 default '/src/incr/'
, p_src_full in varchar2 default '/src/full/'
, p_src_dml in varchar2 default '/src/dml/'
, p_src_ords in varchar2 default '/src/ords/'
);
/**
A loose representation of a database POM in folder p_path (i.e. <p_path>/po.xml).
Will be used to define the project in internal memory so it can be used by install_project.
This procedure can be used in pom.sql.
**/

procedure define_project_apex
( p_github_access_handle in github_access_handle_t -- The GitHub access handle
, p_path in varchar2 -- The repository file path
, p_schema in varchar default null -- The database schema
, p_parent_github_access_handle in github_access_handle_t default null -- The parent GitHub access handle
, p_parent_path in varchar2 default null -- The parent repository file path
, p_modules in sys.odcivarchar2list default null -- The sub module paths to process when the POM is a container
, p_application_id in integer default null -- The APEX application id
);
/**
A loose representation of an APEX POM in folder p_path (i.e. <p_path>/po.xml).
Will be used to define the project in internal memory so it can be used by process_project.
Can be used in pom.sql.
**/

procedure process_project
( p_github_access_handle in github_access_handle_t -- The GitHub access handle
, p_path in varchar2 -- The repository file path
, p_operation in varchar2 default 'install' -- install/export
, p_stop_on_error in boolean default true -- Must we stop on error?
);
/** The project must have been defined by define_project_db or define_project_apex. **/

procedure process_file
( p_github_access_handle in github_access_handle_t
, p_schema in varchar -- The database schema 
, p_file_path in varchar2 -- The repository file path
, p_stop_on_error in boolean default true -- Must we stop on error?
);
/**
An enhanced version of DBMS_CLOUD_REPO.INSTALL_FILE.

Will retrieve the file contents via DBMS_CLOUD_REPO.GET_FILE and then invoke the second variant of PROCESS_FILE, see below.
**/

procedure process_file
( p_github_access_handle in github_access_handle_t
, p_schema in varchar -- The database schema 
, p_file_path in varchar2 -- The repository file path, for reference only
, p_content in clob -- The content from the repository file
, p_stop_on_error in boolean default true -- Must we stop on error?
);
/**
An enhanced version of DBMS_CLOUD_REPO.INSTALL_FILE:
1) you must specify the schema (alter sesison set current_schema = <p_schema>)
2) when the first line starts with a @ (or @@), the file is assumed to be a simple SQL include file from the same repository (and same branch/tag/commit)
   a) now every line starting with @ (or @@) will be processed by ADMIN_INSTALL_PKG.PROCESS_FILE
   b) after getting its contents from DBMS_CLOUD_REPO.GET_FILE and setting the new file path
3) else, just use ADMIN_INSTALL_PKG.PROCESS_SQL

**/

procedure process_sql
( p_github_access_handle in github_access_handle_t
, p_file_path in varchar2 -- The repository file path, for reference only
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

