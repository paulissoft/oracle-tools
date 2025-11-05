create or replace package cloud_repo authid definer is

/**
A package based on DBMS_CLOUD_REPO in order to make it easier to use the DBMS_CLOUD_REPO
routines with the repo, branch, tag and commit id parameters.

The idea is to:
1) initialize a repo using one of the INIT subroutines
2) use its git repo index to get info about the parameters needed later on

That information is stored in an internal PL/SQL table.

You can also add files with name, checksum, size, url and content.
That information is also stored in an internal PL/SQL table.
**/

-- TYPES

-- repository types

subtype git_repo_index_t is positive; -- index from internal PL/SQL table (the key)
/** The key for a Git repository info including branch, tag or commit id. **/

subtype provider_t is varchar2(100);
subtype credential_name_t is user_credentials.credential_name%type;
subtype region_t is varchar2(128 char);
subtype organization_t is varchar2(128 char);
subtype project_t is varchar2(128 char);
subtype repo_owner_t is varchar2(128 char);
subtype repo_name_t is varchar2(128 char);
subtype current_schema_t is all_users.username%type;
subtype branch_name_t is varchar2(128 char);
subtype tag_name_t is varchar2(128 char);
subtype commit_id_t is varchar2(40 char);
subtype repo_t is clob;
subtype repo_id_t is varchar2(128 char);

-- file types for columns returned by DBMS_CLOUD_REPO.LIST_FILES

subtype file_index_t is positive; -- index from internal PL/SQL table (the key)
subtype file_index_tab_t is sys.odcinumberlist;

subtype file_id_t is varchar2(128); -- is also a checksum (SHA1, 40 bytes)
subtype file_name_t is varchar2(4000);
subtype file_url_t is varchar2(4000);
subtype file_bytes_t is number;         
subtype file_content_t is clob; -- only text files

-- CONSTANTS
c_provider_pato constant provider_t := dbms_cloud_repo.github_repo;
c_repo_owner_pato constant repo_owner_t := 'paulissoft';
c_repo_name_pato constant repo_name_t := 'oracle-tools';
c_git_repo_index_pato constant git_repo_index_t := 1; -- The first initialized repo will be PATO (main branch)

-- ROUTINES

function init_aws_repo
( p_credential_name in credential_name_t -- The credential name (use DBMS_CLOUD)
, p_repo_name in repo_name_t -- The repository name
, p_region in region_t -- The region
, p_branch_name in branch_name_t default null -- The branch to use for DBMS_CLOUD_REPO operations
, p_tag_name in tag_name_t default null -- The tag to use for DBMS_CLOUD_REPO operations
, p_commit_id in commit_id_t default null -- The commit id to use for DBMS_CLOUD_REPO operations
, p_overwrite in boolean default true -- Overwrite an existing internal entry? If not raise dup_val_on_index
)
return git_repo_index_t;
/**
Will use DBMS_CLOUD_REPO.INIT_AWS_REPO to create an opaque REPO handle.  That
handle plus the other parameters will be stored in an internal table and the
index will be returned.
**/

function init_azure_repo
( p_credential_name in credential_name_t -- The credential name (use DBMS_CLOUD)
, p_repo_name in repo_name_t -- The repository name
, p_organization in organization_t -- The organization
, p_project in project_t -- The project
, p_branch_name in branch_name_t default null -- The branch to use for DBMS_CLOUD_REPO operations
, p_tag_name in tag_name_t default null -- The tag to use for DBMS_CLOUD_REPO operations
, p_commit_id in commit_id_t default null -- The commit id to use for DBMS_CLOUD_REPO operations
, p_overwrite in boolean default true -- Overwrite an existing internal entry? If not raise dup_val_on_index
)
return git_repo_index_t;
/**
Will use DBMS_CLOUD_REPO.INIT_AZURE_REPO to create an opaque REPO handle.  That
handle plus the other parameters will be stored in an internal table and the
index will be returned.
**/

function init_github_repo
( p_credential_name in credential_name_t default null -- The credential name (use DBMS_CLOUD)
, p_repo_name in repo_name_t -- The repository name
, p_repo_owner in repo_owner_t -- The repository owner
, p_branch_name in branch_name_t default null -- The branch to use for DBMS_CLOUD_REPO operations
, p_tag_name in tag_name_t default null -- The tag to use for DBMS_CLOUD_REPO operations
, p_commit_id in commit_id_t default null -- The commit id to use for DBMS_CLOUD_REPO operations
, p_overwrite in boolean default true -- Overwrite an existing internal entry? If not raise dup_val_on_index
)
return git_repo_index_t;
/**
Will use DBMS_CLOUD_REPO.INIT_GITHUB_REPO to create an opaque REPO handle.  That
handle plus the other parameters will be stored in an internal table and the
index will be returned.
**/

function init_repo
( p_params in clob
, p_branch_name in branch_name_t default null -- The branch to use for DBMS_CLOUD_REPO operations
, p_tag_name in tag_name_t default null -- The tag to use for DBMS_CLOUD_REPO operations
, p_commit_id in commit_id_t default null -- The commit id to use for DBMS_CLOUD_REPO operations
, p_overwrite in boolean default true -- Overwrite an existing internal entry? If not raise dup_val_on_index
)
return git_repo_index_t;
/**
| JSON key        | Desciption                                                     |
| :-------        | :------------------------------------------------------------- |
| provider        | Cloud code repository provider from the following:             |
|                 | * DBMS_CLOUD_REPO.GITHUB_REPO ('GITHUB')                       |
|                 | * DBMS_CLOUD_REPO.AWS_REPO ('AWS')                             |
|                 | * DBMS_CLOUD_REPO.AZURE_REPO ('AZURE')                         |
|                 |                                                                |
| credential_name | From DBA_CREDENTIALS and set with DBMS_CLOUD.                  |
|                 |                                                                |
| repo_name       | Specifies the repository name. DBMS_CLOUD_REPO.PARAM_REPO_NAME |
|                 |                                                                |
| owner           | GitHub Repository Owner. DBMS_CLOUD_REPO.PARAM_OWNER           |
|                 | This parameter is only applicable for GitHub cloud provider.   |
|                 |                                                                |
| region          | AWS Repository Region DBMS_CLOUD_REPO.PARAM_REGION             |
|                 | This parameter is only applicable for AWS cloud provider.      |
|                 |                                                                |
| organization    | Azure Organization DBMS_CLOUD_REPO.PARAM_ORGANIZATION          |
|                 | This parameter is only applicable for Azure cloud provider.    |
|                 |                                                                |
| project         | Azure Team Project DBMS_CLOUD_REPO.PARAM_PROJECT               |
|                 | This parameter is only applicable for Azure cloud provider     |
**/

function find_repo
( p_provider in varchar2 -- The provider: DBMS_CLOUD_REPO.AWS_REPO, DBMS_CLOUD_REPO.AZURE_REPO or DBMS_CLOUD_REPO.GITHUB_REPO
, p_repo_name in repo_name_t -- The repository name, mandatory
, p_region in region_t default null -- Only relevant for AWS
, p_organization in organization_t default null -- Only relevant for Azure
, p_project in project_t default null -- Only relevant for Azure
, p_repo_owner in repo_owner_t default null -- Only relevant for GitHub
)
return git_repo_index_t;

procedure get_repo
( p_git_repo_index in git_repo_index_t default null -- The repository index as returned by one of the INIT subroutines
, p_repo out nocopy repo_t -- The DBMS_CLOUD_REPO REPO argument as determined by one of the INIT subroutines
, p_branch_name out nocopy branch_name_t -- The DBMS_CLOUD_REPO BRANCH_NAME argument as supplied to one of the INIT subroutines
, p_tag_name out nocopy tag_name_t -- The DBMS_CLOUD_REPO TAG_NAME argument as supplied to one of the INIT subroutines
, p_commit_id out nocopy commit_id_t -- The DBMS_CLOUD_REPO COMMIT_ID argument as supplied to one of the INIT subroutines
);
/**
Get the parameters for subprograms from DBMS_CLOUD_REPO where one of these OUT parameters are needed.
**/

procedure get_repo
( p_git_repo_index in git_repo_index_t default null -- The repository index as returned by one of the INIT subroutines
, p_provider out nocopy provider_t -- The provider
, p_repo_name out nocopy repo_name_t -- The repo name
, p_credential_name out nocopy credential_name_t -- The credential name
, p_region out nocopy region_t -- AWS region
, p_organization out nocopy organization_t -- Azure organization
, p_project out nocopy project_t -- Azure project
, p_repo_owner out nocopy repo_owner_t -- GitHub repo owner  
, p_current_schema out nocopy current_schema_t -- current schema to return to after work
, p_branch_name out nocopy branch_name_t -- The DBMS_CLOUD_REPO BRANCH_NAME argument as supplied to one of the INIT subroutines
, p_tag_name out nocopy tag_name_t -- The DBMS_CLOUD_REPO TAG_NAME argument as supplied to one of the INIT subroutines
, p_commit_id out nocopy commit_id_t -- The DBMS_CLOUD_REPO COMMIT_ID argument as supplied to one of the INIT subroutines
, p_repo out nocopy repo_t -- The DBMS_CLOUD_REPO REPO argument as determined by one of the INIT subroutines
, p_repo_id out nocopy repo_id_t -- The repo id is returned by DBMS_CLOUD_REPO.LIST_REPOSITORIES.
);
/**
Get all the parameters used in one of the INIT subroutines.
**/

procedure done_repo
( p_git_repo_index in git_repo_index_t default null -- Destroy this index (or all when null)
);
/**
Destroy the repo identified by the index as well as all files added for the repo.
**/

/*
-- File/folder operations
*/

procedure add_file
( p_git_repo_index in git_repo_index_t default null -- When null the last repository added
, p_file_name in file_name_t -- The file name (unique within a repo)
, p_id in file_id_t default null -- The file id, that is also a checksum (SHA1, 40 bytes)
, p_url in file_url_t default null -- The file URL
, p_bytes in file_bytes_t default null -- The size in bytes
, p_content in file_content_t default null -- The (text) file content
, p_overwrite in boolean default true -- Overwrite an existing internal entry? If not raise dup_val_on_index
, p_file_index out nocopy file_index_t -- The file index that must be used in combination with the git repo index
);
/**
Add a file to internal (package) storage.

The parameters are returned by a combination of DBMS_CLOUD_REPO.LIST_FILES() and DBMS_CLOUD_REPO.GET_FILE().

The file index is an index in the git repo internal table (as supplied by one of the INIT subroutines).

The unique key for a file is the combination of the git_repo_index and name.
**/

procedure add_folder
( p_git_repo_index in git_repo_index_t -- When null the last repository added
, p_path in file_name_t -- The folder
, p_base_name_wildcard in file_name_t default '%' -- Base names must comply to this wildcard
, p_with_content in boolean default false -- Do we add content using DBMS_CLOUD_REPO.GET_FILE?
, p_overwrite in boolean default true -- Parameter in add_file(..., p_overwrite => p_overwrite)
, p_file_index_tab out nocopy file_index_tab_t -- The list of file indexes
);
/**
Use DBMS_CLOUD_REPO.LIST_FILES to add files from the folder p_path like this:

```
select  t.name as file_name
,       t.id
,       t.url
,       t.bytes
,       case
          when b_with_content = 1
          then dbms_cloud_repo.get_file
               ( repo => b_repo
               , file_path => t.name
               , branch_name => b_branch_name
               , tag_name => b_tag_name
               , commit_name => b_commit_name
               )
        end as content
from    table
        ( dbms_cloud_repo.list_files
          ( repo => b_repo
          , path => b_path
          , branch_name => b_branch_name
          , tag_name => b_tag_name
          , commit_id => b_commit_id
          )
        ) t
where   t.name like b_path || '/' || b_base_name_wildcard escape '\'
order by
        t.name;
```
**/

procedure upd_file
( p_git_repo_index in git_repo_index_t default null -- When null the last repository added
, p_file_index in file_index_t default null -- When null the last file added (within the repository)
, p_content in file_content_t -- The (text) file content
);
/**
Update the file content for a file added with ADD_FILE().
**/

procedure upd_file_content
( p_git_repo_index in git_repo_index_t default null -- When null the last repository added
, p_file_index in file_index_t default null -- When null the last file added (within the repository)
);
/**
Update the file content for a file added with ADD_FILE() by using DBMS_CLOUD_REPO.GET_FILE() to get the content.
**/

function find_file
( p_git_repo_index in git_repo_index_t default null -- When null the last repository added
, p_file_name in file_name_t -- The file name (unique within a repo)
)
return file_index_t; -- The file index that must be used in combination with the git repo index
/**
Find a file in internal (package) storage.

The unique key for a file is the combination of the git_repo_index and name.

The file index is an index in the git repo internal table (as supplied by one of the INIT subroutines).
**/

procedure get_file
( p_git_repo_index in git_repo_index_t default null -- When null the last repository added
, p_file_index in file_index_t default null -- The file index that must be used in combination with the git repo index
, p_file_name out nocopy file_name_t -- The file name (unique within a repo)
, p_id out nocopy file_id_t -- The file id, that is also a checksum (SHA1, 40 bytes)
, p_url out nocopy file_url_t -- The file URL
, p_bytes out nocopy file_bytes_t -- The size in bytes
, p_content out nocopy file_content_t -- The (text) file content
);
/**
Get file info from internal storage, as added by add_file/add_folder.
**/

procedure del_file
( p_git_repo_index in git_repo_index_t default null -- When null the last repository added
, p_file_index in file_index_t default null -- When null the last file added (within the repository)
);
/**
Deletes a single file.
**/

-- Do not use ORACLE_TOOLS.CFG_PKG.C_TESTING here since this package will be created before ORACLE_TOOLS.CFG_PKG.

--%suitepath(API)
--%suite

--%beforeall
procedure ut_setup;

--%afterall
procedure ut_teardown;

--%test
procedure ut_init_github_repo;

--%test
procedure ut_init_repo;

--%test
procedure ut_find_repo;

--%test
procedure ut_get_repo;

--%test
procedure ut_done_repo;

--%test
procedure ut_add_file;

--%test
procedure ut_add_folder;

--%test
procedure ut_upd_file;

--%test
procedure ut_upd_file_content;

--%test
procedure ut_find_file;

--%test
procedure ut_get_file;

--%test
procedure ut_del_file;

end;
/
