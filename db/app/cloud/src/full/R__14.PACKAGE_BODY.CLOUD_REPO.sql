create or replace package body cloud_repo is

-- LOCAL

-- TYPES

type git_repo_rec_t is record
( credential_name credential_name_t
, region region_t
, organization organization_t
, project project_t
, repo_owner repo_owner_t
, repo_name repo_name_t
  -- current schema to return to after work
, current_schema current_schema_t
  -- standard parameters for DBMS_CLOUD_REPO.GET_FILE and so on
, branch_name branch_name_t
, tag_name tag_name_t
, commit_id commit_id_t
  -- output
, repo repo_t
, repo_id repo_id_t
);

type git_repo_tab_t is table of git_repo_rec_t index by git_repo_index_t;

type file_rec_t is record
( name file_name_t
, id file_id_t
, url file_url_t
, bytes file_bytes_t
, content file_content_t
);

type file_tab_t is table of file_rec_t index by file_index_t;

-- VARIABLES

g_git_repo_tab git_repo_tab_t;

g_file_tab file_tab_t;

-- PROCEDURES

function init
( p_provider in varchar2 default null
, p_credential_name in credential_name_t default null
, p_region in region_t default null
, p_organization in organization_t default null
, p_project in project_t default null
, p_repo_owner in repo_owner_t default null
, p_repo_name in repo_name_t default null
, p_branch_name in branch_name_t default null
, p_tag_name in tag_name_t default null
, p_commit_id in commit_id_t default null
)
return git_repo_index_t
is
  l_git_repo_rec git_repo_rec_t;
  l_git_repo_index git_repo_index_t;
begin
  if p_provider = c_provider_pato and
     p_repo_owner = c_repo_owner_pato and
     p_repo_name = c_repo_name_pato
  then
    l_git_repo_index := c_git_repo_index_pato; -- this entry call is for PATO
  else
    -- The first call must assure that PATO gets first,
    -- so if the first call is not for the PATO do that now.
    if g_git_repo_tab.count = 0
    then
      -- default PATO, no credentials necessaryfor GitHub
      l_git_repo_index :=
        init
        ( p_provider => c_provider_pato
        , p_repo_owner => c_repo_owner_pato
        , p_repo_name => c_repo_name_pato
        );
    end if;
    -- we still need to pick the next even though PATO has just been installed (ignore that one)
    l_git_repo_index := g_git_repo_tab.count + 1;    
  end if;

  -- GitHub does not really need credentials but the others do: no checking here
  select  max(c.credential_name)
  into    l_git_repo_rec.credential_name
  from    dba_credentials c
  where   c.owner = 'ADMIN'
  and     c.credential_name like nvl(p_credential_name, '%' || upper(p_provider) || '%') escape '\';

  if p_provider in (dbms_cloud_repo.aws_repo, dbms_cloud_repo.azure_repo) and
     l_git_repo_rec.credential_name is null
  then
    raise value_error;
  end if;

  l_git_repo_rec.region := p_region;
  l_git_repo_rec.organization := p_organization;
  l_git_repo_rec.project := p_project;
  l_git_repo_rec.repo_owner := p_repo_owner;
  l_git_repo_rec.repo_name := p_repo_name;
  l_git_repo_rec.branch_name := p_branch_name;
  l_git_repo_rec.tag_name := p_tag_name;
  l_git_repo_rec.commit_id := p_commit_id;

  l_git_repo_rec.current_schema := sys_context('USERENV', 'CURRENT_SCHEMA');

  l_git_repo_rec.repo :=
    case p_provider
      when dbms_cloud_repo.github_repo
      then dbms_cloud_repo.init_github_repo
           ( credential_name => l_git_repo_rec.credential_name
           , repo_name => p_repo_name
           , owner => p_repo_owner
           )
      when dbms_cloud_repo.aws_repo
      then dbms_cloud_repo.init_aws_repo
           ( credential_name => l_git_repo_rec.credential_name
           , repo_name => p_repo_name
           , region => p_region 
           )
      when dbms_cloud_repo.azure_repo
      then dbms_cloud_repo.init_azure_repo
           ( credential_name => l_git_repo_rec.credential_name
           , repo_name => p_repo_name
           , organization => p_organization
           , project => p_project
           )
    end;

  if l_git_repo_rec.repo is null
  then
    raise_application_error
    ( -20000
    , utl_lms.format_message
      ( 'Provider (%s) must be one of %s, %s, or %s'
      , p_provider
      , dbms_cloud_repo.github_repo
      , dbms_cloud_repo.aws_repo
      , dbms_cloud_repo.azure_repo
      )
    );
  end if;

  -- check it does exist
  select  t.id
  into    l_git_repo_rec.repo_id
  from    table(dbms_cloud_repo.list_repositories(repo => l_git_repo_rec.repo)) t
  where   t.owner = l_git_repo_rec.repo_owner
  and     t.name = l_git_repo_rec.repo_name;

  g_git_repo_tab(l_git_repo_index) := l_git_repo_rec;

  return l_git_repo_index;
end init;

-- PUBLIC

function init_aws_repo
( p_credential_name in credential_name_t
, p_repo_name in repo_name_t
, p_region in region_t
, p_branch_name in branch_name_t
, p_tag_name in tag_name_t
, p_commit_id in commit_id_t
)
return git_repo_index_t
is
begin
  return init
         ( p_provider => dbms_cloud_repo.aws_repo
         , p_credential_name => p_credential_name
         , p_repo_name => p_repo_name
         , p_region => p_region
         , p_branch_name => p_branch_name
         , p_tag_name => p_tag_name
         , p_commit_id => p_commit_id
         );
end init_aws_repo;

function init_azure_repo
( p_credential_name in credential_name_t
, p_repo_name in repo_name_t
, p_organization in organization_t
, p_project in project_t
, p_branch_name in branch_name_t
, p_tag_name in tag_name_t
, p_commit_id in commit_id_t
)
return git_repo_index_t
is
begin
  return init
         ( p_provider => dbms_cloud_repo.azure_repo
         , p_credential_name => p_credential_name
         , p_repo_name => p_repo_name
         , p_organization => p_organization
         , p_project => p_project
         , p_branch_name => p_branch_name
         , p_tag_name => p_tag_name
         , p_commit_id => p_commit_id
         );
end init_azure_repo;

function init_github_repo
( p_credential_name in credential_name_t
, p_repo_name in repo_name_t
, p_repo_owner in repo_owner_t
, p_branch_name in branch_name_t
, p_tag_name in tag_name_t
, p_commit_id in commit_id_t
) 
return git_repo_index_t
is
begin
  return init
         ( p_provider => dbms_cloud_repo.github_repo
         , p_credential_name => p_credential_name
         , p_repo_name => p_repo_name
         , p_repo_owner => p_repo_owner
         , p_branch_name => p_branch_name
         , p_tag_name => p_tag_name
         , p_commit_id => p_commit_id
         );
end init_github_repo;
 
function init_repo
( p_params in clob
, p_branch_name in branch_name_t
, p_tag_name in tag_name_t
, p_commit_id in commit_id_t
)
return git_repo_index_t
is
  l_json_params json_object_t := json_object_t(p_params);
begin
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
  return init
         ( p_provider => l_json_params.get_string('provider')
         , p_credential_name => l_json_params.get_string('credential_name')
         , p_region => l_json_params.get_string('region')
         , p_organization => l_json_params.get_string('organization')
         , p_project => l_json_params.get_string('project')
         , p_repo_name => l_json_params.get_string('repo_name')
         , p_repo_owner => l_json_params.get_string('repo_owner')
         , p_branch_name => p_branch_name
         , p_tag_name => p_tag_name
         , p_commit_id => p_commit_id
         );
end init_repo;

procedure get
( p_git_repo_index in git_repo_index_t
, p_repo out nocopy repo_t
, p_branch_name out nocopy branch_name_t
, p_tag_name out nocopy tag_name_t
, p_commit_id out nocopy commit_id_t
)
is
  l_git_repo_rec git_repo_rec_t := g_git_repo_tab(nvl(p_git_repo_index, g_git_repo_tab.last));
begin
  p_repo := l_git_repo_rec.repo;
  p_branch_name := l_git_repo_rec.branch_name;
  p_tag_name := l_git_repo_rec.tag_name;
  p_commit_id := l_git_repo_rec.commit_id;
end get;

function credential_name
( p_git_repo_index in git_repo_index_t
)
return credential_name_t
deterministic
is
begin
  return g_git_repo_tab(nvl(p_git_repo_index, g_git_repo_tab.last)).credential_name;
end credential_name;  

function region
( p_git_repo_index in git_repo_index_t
)
return region_t
deterministic
is
begin
  return g_git_repo_tab(nvl(p_git_repo_index, g_git_repo_tab.last)).region;
end region;  

function organization
( p_git_repo_index in git_repo_index_t
)
return organization_t
deterministic
is
begin
  return g_git_repo_tab(nvl(p_git_repo_index, g_git_repo_tab.last)).organization;
end organization;  

function project
( p_git_repo_index in git_repo_index_t
)
return project_t
deterministic
is
begin
  return g_git_repo_tab(nvl(p_git_repo_index, g_git_repo_tab.last)).project;
end project;  

function repo_owner
( p_git_repo_index in git_repo_index_t
)
return repo_owner_t
deterministic
is
begin
  return g_git_repo_tab(nvl(p_git_repo_index, g_git_repo_tab.last)).repo_owner;
end repo_owner;  

function repo_name
( p_git_repo_index in git_repo_index_t
)
return repo_name_t
deterministic
is
begin
  return g_git_repo_tab(nvl(p_git_repo_index, g_git_repo_tab.last)).repo_name;
end repo_name;  

function current_schema
( p_git_repo_index in git_repo_index_t
)
return current_schema_t
deterministic
is
begin
  return g_git_repo_tab(nvl(p_git_repo_index, g_git_repo_tab.last)).current_schema;
end current_schema;  

function branch_name
( p_git_repo_index in git_repo_index_t
)
return branch_name_t
deterministic
is
begin
  return g_git_repo_tab(nvl(p_git_repo_index, g_git_repo_tab.last)).branch_name;
end branch_name;  

function tag_name
( p_git_repo_index in git_repo_index_t
)
return tag_name_t
deterministic
is
begin
  return g_git_repo_tab(nvl(p_git_repo_index, g_git_repo_tab.last)).tag_name;
end tag_name;  

function commit_id
( p_git_repo_index in git_repo_index_t
)
return commit_id_t
deterministic
is
begin
  return g_git_repo_tab(nvl(p_git_repo_index, g_git_repo_tab.last)).commit_id;
end commit_id;  

function repo
( p_git_repo_index in git_repo_index_t
)
return repo_t
deterministic
is
begin
  return g_git_repo_tab(nvl(p_git_repo_index, g_git_repo_tab.last)).repo;
end repo;  

function repo_id
( p_git_repo_index in git_repo_index_t
)
return repo_id_t
deterministic
is
begin
  return g_git_repo_tab(nvl(p_git_repo_index, g_git_repo_tab.last)).repo_id;
end repo_id;  

procedure add_file
( p_git_repo_index in git_repo_index_t default null -- When null the last repository added
, p_name in file_name_t
, p_id in file_id_t default null
, p_url in file_url_t default null
, p_bytes in file_bytes_t default null
, p_content in file_content_t default null
, p_file_index out nocopy file_index_t
)
is
  l_file_rec file_rec_t;
begin
g_file_tab file_tab_t;
/**
Add a file to internal (package) storage.

The parameters are returned by a combination of DBMS_CLOUD_REPO.LIST_FILES() and DBMS_CLOUD_REPO.GET_FILE().
**/

procedure upd_file
( p_git_repo_index in git_repo_index_t default null -- When null the last repository added
, p_file_index in file_index_t default null -- When null the last file added (within the repository)
, p_content in file_content_t default null
);
/**
Update the file content for a file added with ADD_FILE().
**/

procedure upd_content
( p_git_repo_index in git_repo_index_t default null -- When null the last repository added
, p_file_index in file_index_t default null -- When null the last file added (within the repository)
);
/**
Update the file content for a file added with ADD_FILE() by using DBMS_CLOUD_REPO.GET_FILE() to get the content.
**/

procedure del_file
( p_git_repo_index in git_repo_index_t default null -- When null the last repository added
, p_file_index in file_index_t default null -- When null the last file added (within the repository)
);
/**
Deletes a single file.
**/

procedure done
( p_git_repo_index in git_repo_index_t
)
is
begin
  if p_git_repo_index is null
  then
    g_git_repo_tab.delete;
  else
    g_git_repo_tab.delete(p_git_repo_index);
  end if;
end done;

end;
/
