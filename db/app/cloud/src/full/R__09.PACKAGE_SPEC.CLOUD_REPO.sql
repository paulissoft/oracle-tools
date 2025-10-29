create or replace package cloud_repo authid definer is

/**
A package based on DBMS_CLOUD_REPO in order to make it easier to use the DBMS_CLOUD_REPO
routines with the repo, branch, tag and commit id parameters.

The idea is to initialize a repo and use its index to get info about the parameters needed later on.
**/

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

subtype git_repo_index_t is binary_integer; -- index from internal PL/SQL table

function init_aws_repo
( p_credential_name in credential_name_t
, p_repo_name in repo_name_t
, p_region in region_t
, p_branch_name in branch_name_t default null
, p_tag_name in tag_name_t default null
, p_commit_id in commit_id_t default null
)
return git_repo_index_t;

function init_azure_repo
( p_credential_name in credential_name_t
, p_repo_name in repo_name_t
, p_organization in organization_t
, p_project in project_t
, p_branch_name in branch_name_t default null
, p_tag_name in tag_name_t default null
, p_commit_id in commit_id_t default null
)
return git_repo_index_t;

function init_github_repo
( p_credential_name in credential_name_t default null
, p_repo_name in repo_name_t
, p_repo_owner in repo_owner_t
, p_branch_name in branch_name_t default null
, p_tag_name in tag_name_t default null
, p_commit_id in commit_id_t default null
) 
return git_repo_index_t;

function init_repo
( p_params in clob
, p_branch_name in branch_name_t default null
, p_tag_name in tag_name_t default null
, p_commit_id in commit_id_t default null
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

function credential_name
( p_git_repo_index in git_repo_index_t default null
)
return credential_name_t
deterministic;

function region
( p_git_repo_index in git_repo_index_t default null
)
return region_t
deterministic;

function organization
( p_git_repo_index in git_repo_index_t default null
)
return organization_t
deterministic;

function project
( p_git_repo_index in git_repo_index_t default null
)
return project_t
deterministic;

function repo_owner
( p_git_repo_index in git_repo_index_t default null
)
return repo_owner_t
deterministic;

function repo_name
( p_git_repo_index in git_repo_index_t default null
)
return repo_name_t
deterministic;

function current_schema
( p_git_repo_index in git_repo_index_t default null
)
return current_schema_t
deterministic;

function branch_name
( p_git_repo_index in git_repo_index_t default null
)
return branch_name_t
deterministic;

function tag_name
( p_git_repo_index in git_repo_index_t default null
)
return tag_name_t
deterministic;

function commit_id
( p_git_repo_index in git_repo_index_t default null
)
return commit_id_t
deterministic;

function repo
( p_git_repo_index in git_repo_index_t default null
)
return repo_t
deterministic;

function repo_id
( p_git_repo_index in git_repo_index_t default null
)
return repo_id_t
deterministic;

procedure done
( p_git_repo_index in git_repo_index_t default null -- Destroy this index (or all when null)
);
/** Destroy the repo identified by the index. **/

end;
/
