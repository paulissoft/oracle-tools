create or replace package admin_install_pkg authid definer is

/**
A package based on DBMS_CLOUD_REPO in order to:
- install files (database/APEX) from a repository like the PATO does with Maven POM files using Flyway.
- export (database/APEX) scripts to a repository like the PATO does with Maven POM files.

In order to mimic this Maven POM behaviour:
- there will be `pom.sql` files in folders with a `pom.xml` defining the most important properties using:
  * `process_root_project` (node)
  * `process_project` (node)
  * `process_project_db` (leaf)
  * `process_project_apex` (leaf)
- the node routines (`process_root_project` and `process_project`) must have a pom.sql in that folder
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

procedure process_project_db
( p_github_access_handle in github_access_handle_t -- The GitHub access handle
, p_path in varchar2 -- The repository file path
, p_schema in varchar default null -- The database schema
, p_parent_github_access_handle in github_access_handle_t default null -- The parent GitHub access handle
, p_parent_path in varchar2 default null -- The parent repository file path
, p_src_callbacks in varchar2 default '/src/callbacks/'
, p_src_incr in varchar2 default '/src/incr/'
, p_src_full in varchar2 default '/src/full/'
, p_src_dml in varchar2 default '/src/dml/'
, p_src_ords in varchar2 default '/src/ords/'
);
/**
A loose representation of a database POM in folder p_path (i.e. <p_path>/pom.xml).
Will be used to define the project in internal memory so it can be used by install_project.
This procedure can be used in pom.sql.
**/

procedure process_project_apex
( p_github_access_handle in github_access_handle_t -- The GitHub access handle
, p_path in varchar2 -- The repository file path
, p_schema in varchar default null -- The database schema
, p_parent_github_access_handle in github_access_handle_t default null -- The parent GitHub access handle
, p_parent_path in varchar2 default null -- The parent repository file path
, p_application_id in integer default null -- The APEX application id
);
/**
A loose representation of an APEX POM in folder p_path (i.e. <p_path>/pom.xml).
Will be used to define the project in internal memory so it can be used by process_project.
Can be used in pom.sql.
**/

procedure process_project
( p_github_access_handle in github_access_handle_t -- The GitHub access handle
, p_path in varchar2 -- The repository file path
, p_parent_github_access_handle in github_access_handle_t default null -- The parent GitHub access handle
, p_parent_path in varchar2 default null -- The parent repository file path
);
/**
A loose representation of an aggregator POM in folder p_path (i.e. <p_path>/pom.xml).
Will be used to define the project in internal memory so it can be used by process_project.
Can be used in pom.sql.
**/

procedure process_root_project
( p_github_access_handle in github_access_handle_t -- The GitHub access handle
, p_parent_github_access_handle in github_access_handle_t default null -- The parent GitHub access handle
, p_parent_path in varchar2 default null -- The parent repository file path
, p_operation in varchar2 default null -- top level must be 'install' or 'export'
, p_stop_on_error in boolean default true -- Must we stop on error?
, p_dry_run in boolean default false -- A dry run?
);
/**
A loose representation of an aggregator POM in folder p_path (i.e. <p_path>/pom.xml).
Will be used to define the project in internal memory so it can be used by process_project.
Can be used in pom.sql.
**/

end;
/

