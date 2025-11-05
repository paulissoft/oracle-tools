create or replace package body cloud_repo is

-- LOCAL

-- TYPES

type git_repo_rec_t is record
( provider provider_t
, repo_name repo_name_t
, credential_name credential_name_t
, region region_t -- AWS
, organization organization_t -- Azure
, project project_t -- Azure
, repo_owner repo_owner_t -- GitHub
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

type git_repo_by_index_tab_t is table of git_repo_rec_t index by git_repo_index_t;

-- | PROVIDER | UNIQUE KEY |
-- | :------- | :--------- |
-- | aws      | provider:repo_name:region |
-- | azure    | provider:repo_name:organization:project |
-- | github   | provider:repo_name:repo_owner |

subtype git_uk_t is varchar2(512); 

type git_repo_by_uk_tab_t is table of git_repo_index_t index by git_uk_t;

type file_rec_t is record
( file_name file_name_t
, id file_id_t
, url file_url_t
, bytes file_bytes_t
, content file_content_t
);

type file_by_index_tab_t is table of file_rec_t index by file_index_t;

type git_repo_index_file_by_index_tab_t is table of file_by_index_tab_t index by git_repo_index_t;

type file_by_name_tab_t is table of file_index_t index by file_name_t;

type git_repo_index_file_by_name_tab_t is table of file_by_name_tab_t index by git_repo_index_t;

-- VARIABLES

g_git_repo_by_index_tab git_repo_by_index_tab_t;

g_git_repo_by_uk_tab git_repo_by_uk_tab_t;

g_git_repo_index_file_by_index_tab git_repo_index_file_by_index_tab_t;

g_git_repo_index_file_by_name_tab git_repo_index_file_by_name_tab_t;

-- PROCEDURES

function git_repo_uk
( p_git_repo_rec in git_repo_rec_t
)
return git_uk_t
deterministic
is
begin
  return p_git_repo_rec.provider ||
         ':' ||
         p_git_repo_rec.repo_name ||
         ':' || 
         case p_git_repo_rec.provider
           when dbms_cloud_repo.github_repo
           then p_git_repo_rec.repo_owner
           when dbms_cloud_repo.aws_repo
           then p_git_repo_rec.region
           when dbms_cloud_repo.azure_repo
           then p_git_repo_rec.organization || ':' || p_git_repo_rec.project
         end;
end git_repo_uk;

function init
( p_provider in varchar2
, p_repo_name in repo_name_t
, p_credential_name in credential_name_t
, p_region in region_t default null
, p_organization in organization_t default null
, p_project in project_t default null
, p_repo_owner in repo_owner_t default null
, p_branch_name in branch_name_t
, p_tag_name in tag_name_t
, p_commit_id in commit_id_t
, p_overwrite in boolean
)
return git_repo_index_t
is
  l_git_repo_rec git_repo_rec_t;
  l_git_repo_index git_repo_index_t;

  -- ORA-20401: Authorization failed for URI - https://api.github.com/user/repos?page=1
  "Authorization failed for URI" exception;
  pragma exception_init("Authorization failed for URI", -20401);
begin
  dbms_output.put_line
  ( utl_lms.format_message
    ( q'[init(p_provider => '%s', p_credential_name => '%s', p_repo_owner => '%s', p_repo_name => '%s')]'
    , p_provider
    , p_credential_name
    , p_repo_owner
    , p_repo_name
    )
  );

  if p_provider = c_provider_pato and
     p_repo_owner = c_repo_owner_pato and
     p_repo_name = c_repo_name_pato
  then
    l_git_repo_index := c_git_repo_index_pato; -- this entry call is for PATO
  else
    -- The first call must assure that PATO gets first,
    -- so if the first call is not for the PATO do that now.
    if g_git_repo_by_index_tab.count = 0
    then
      -- default PATO, no credentials necessaryfor GitHub
      l_git_repo_index :=
        init
        ( p_provider => c_provider_pato
        , p_repo_name => c_repo_name_pato
        , p_credential_name => null
        , p_repo_owner => c_repo_owner_pato
        , p_branch_name => null
        , p_tag_name => null
        , p_commit_id => null
        , p_overwrite => false
        );
    end if;
    -- we still need to pick the next even though PATO has just been installed (ignore that one)
    l_git_repo_index := g_git_repo_by_index_tab.count + 1;    
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

  l_git_repo_rec.provider := p_provider;
  l_git_repo_rec.repo_name := p_repo_name;
  l_git_repo_rec.region := p_region;
  l_git_repo_rec.organization := p_organization;
  l_git_repo_rec.project := p_project;
  l_git_repo_rec.repo_owner := p_repo_owner;

  if not g_git_repo_by_uk_tab.exists(git_repo_uk(l_git_repo_rec))
  then
    g_git_repo_by_uk_tab(git_repo_uk(l_git_repo_rec)) := l_git_repo_index;
  elsif p_overwrite
  then
    l_git_repo_index := g_git_repo_by_uk_tab(git_repo_uk(l_git_repo_rec));
  else
    raise dup_val_on_index;
  end if;

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
  begin
    select  t.id
    into    l_git_repo_rec.repo_id
    from    table(dbms_cloud_repo.list_repositories(repo => l_git_repo_rec.repo)) t
    where   t.owner = l_git_repo_rec.repo_owner
    and     t.name = l_git_repo_rec.repo_name;
  exception
    when "Authorization failed for URI"
    then l_git_repo_rec.repo_id := null;
  end;

  g_git_repo_by_index_tab(l_git_repo_index) := l_git_repo_rec;

  dbms_output.put_line(utl_lms.format_message('return: %d', l_git_repo_index));

  return l_git_repo_index;
end init;

-- PUBLIC

function find_repo
( p_provider in varchar2
, p_repo_name in repo_name_t
, p_region in region_t
, p_organization in organization_t
, p_project in project_t
, p_repo_owner in repo_owner_t
)
return git_repo_index_t
is
  l_git_repo_rec git_repo_rec_t;
begin  
  l_git_repo_rec.provider := p_provider;
  l_git_repo_rec.repo_name := p_repo_name;
  -- AWS
  l_git_repo_rec.region := p_region;
  -- AZURE
  l_git_repo_rec.organization := p_organization;
  l_git_repo_rec.project := p_project;
  -- GITHUB
  l_git_repo_rec.repo_owner := p_repo_owner;

  return g_git_repo_by_uk_tab(git_repo_uk(l_git_repo_rec));
exception
  when no_data_found
  then return null;
end find_repo;

function init_aws_repo
( p_credential_name in credential_name_t
, p_repo_name in repo_name_t
, p_region in region_t
, p_branch_name in branch_name_t
, p_tag_name in tag_name_t
, p_commit_id in commit_id_t
, p_overwrite in boolean
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
         , p_overwrite => p_overwrite
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
, p_overwrite in boolean
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
         , p_overwrite => p_overwrite
         );
end init_azure_repo;

function init_github_repo
( p_credential_name in credential_name_t
, p_repo_name in repo_name_t
, p_repo_owner in repo_owner_t
, p_branch_name in branch_name_t
, p_tag_name in tag_name_t
, p_commit_id in commit_id_t
, p_overwrite in boolean
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
         , p_overwrite => p_overwrite
         );
end init_github_repo;
 
function init_repo
( p_params in clob
, p_branch_name in branch_name_t
, p_tag_name in tag_name_t
, p_commit_id in commit_id_t
, p_overwrite in boolean
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
         , p_overwrite => p_overwrite
         );
end init_repo;

procedure done_repo
( p_git_repo_index in git_repo_index_t
)
is
begin
  if p_git_repo_index is null
  then
    g_git_repo_by_index_tab.delete;
    g_git_repo_by_uk_tab.delete;
    g_git_repo_index_file_by_index_tab.delete;
    g_git_repo_index_file_by_name_tab.delete;
  else
    g_git_repo_by_uk_tab.delete(git_repo_uk(g_git_repo_by_index_tab(p_git_repo_index)));
    g_git_repo_by_index_tab.delete(p_git_repo_index);
    g_git_repo_index_file_by_index_tab.delete(p_git_repo_index);
    g_git_repo_index_file_by_name_tab.delete(p_git_repo_index);
  end if;
end done_repo;

procedure get_repo
( p_git_repo_index in git_repo_index_t
, p_repo out nocopy repo_t
, p_branch_name out nocopy branch_name_t
, p_tag_name out nocopy tag_name_t
, p_commit_id out nocopy commit_id_t
)
is
  l_git_repo_rec git_repo_rec_t := g_git_repo_by_index_tab(nvl(p_git_repo_index, g_git_repo_by_index_tab.last));
begin
  p_repo := l_git_repo_rec.repo;
  p_branch_name := l_git_repo_rec.branch_name;
  p_tag_name := l_git_repo_rec.tag_name;
  p_commit_id := l_git_repo_rec.commit_id;
end get_repo;

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
)
is
  l_git_repo_rec git_repo_rec_t := g_git_repo_by_index_tab(nvl(p_git_repo_index, g_git_repo_by_index_tab.last));
begin
  p_provider := l_git_repo_rec.provider;
  p_repo_name := l_git_repo_rec.repo_name;
  p_credential_name := l_git_repo_rec.credential_name;
  p_region := l_git_repo_rec.region;
  p_organization := l_git_repo_rec.organization;
  p_project := l_git_repo_rec.project;
  p_repo_owner := l_git_repo_rec.repo_owner;
  p_current_schema := l_git_repo_rec.current_schema;
  p_branch_name := l_git_repo_rec.branch_name;
  p_tag_name := l_git_repo_rec.tag_name;
  p_commit_id := l_git_repo_rec.commit_id;
  p_repo := l_git_repo_rec.repo;
  p_repo_id := l_git_repo_rec.repo_id;
end get_repo;

function find_file
( p_git_repo_index in git_repo_index_t
, p_file_name in file_name_t
)
return file_index_t
is
  l_git_repo_index constant git_repo_index_t := nvl(p_git_repo_index, g_git_repo_by_index_tab.last);
  l_file_rec file_rec_t;
begin
  return
    case
      when g_git_repo_index_file_by_name_tab(l_git_repo_index).exists(p_file_name)
      then g_git_repo_index_file_by_name_tab(l_git_repo_index)(p_file_name)
      else null
    end;
end find_file;

procedure add_file
( p_git_repo_index in git_repo_index_t
, p_file_name in file_name_t
, p_id in file_id_t
, p_url in file_url_t
, p_bytes in file_bytes_t
, p_content in file_content_t
, p_overwrite in boolean
, p_file_index out nocopy file_index_t
)
is
  l_git_repo_index constant git_repo_index_t := nvl(p_git_repo_index, g_git_repo_by_index_tab.last);
  l_file_rec file_rec_t;
begin
  p_file_index := find_file(p_git_repo_index => l_git_repo_index, p_file_name => p_file_name);
  if p_file_index is null -- not found
  then
    p_file_index := g_git_repo_index_file_by_index_tab(l_git_repo_index).count + 1;
    g_git_repo_index_file_by_name_tab(l_git_repo_index)(p_file_name) := p_file_index;
  elsif p_overwrite
  then
    null;
  else
    raise dup_val_on_index;
  end if;
  
  l_file_rec.file_name := p_file_name;
  l_file_rec.id := p_id;
  l_file_rec.url := p_url;
  l_file_rec.bytes := p_bytes;
  l_file_rec.content := p_content;  

  g_git_repo_index_file_by_index_tab(l_git_repo_index)(p_file_index) := l_file_rec;
end add_file;

procedure upd_file
( p_git_repo_index in git_repo_index_t
, p_file_index in file_index_t
, p_content in file_content_t
)
is
  l_git_repo_index constant git_repo_index_t := nvl(p_git_repo_index, g_git_repo_by_index_tab.last);
  l_file_index constant file_index_t := nvl(p_file_index, g_git_repo_index_file_by_index_tab(l_git_repo_index).last);
begin
  g_git_repo_index_file_by_index_tab(l_git_repo_index)(l_file_index).content := p_content;
end upd_file;

procedure upd_file_content
( p_git_repo_index in git_repo_index_t
, p_file_index in file_index_t
)
is
  l_git_repo_index constant git_repo_index_t := nvl(p_git_repo_index, g_git_repo_by_index_tab.last);
  l_file_index constant file_index_t := nvl(p_file_index, g_git_repo_index_file_by_index_tab(l_git_repo_index).last);
  l_repo repo_t;
  l_branch_name branch_name_t;
  l_tag_name tag_name_t;
  l_commit_id commit_id_t;
begin
  get_repo
  ( p_git_repo_index => l_git_repo_index
  , p_repo => l_repo
  , p_branch_name => l_branch_name
  , p_tag_name => l_tag_name
  , p_commit_id => l_commit_id
  );

  upd_file
  ( p_git_repo_index => l_git_repo_index
  , p_file_index => l_file_index
  , p_content =>
      dbms_cloud_repo.get_file
      ( repo => l_repo
      , file_path => g_git_repo_index_file_by_index_tab(l_git_repo_index)(l_file_index).file_name
      , branch_name => l_branch_name
      , tag_name => l_tag_name
      , commit_id => l_commit_id
      )
  );
end upd_file_content;

procedure get_file
( p_git_repo_index in git_repo_index_t default null -- When null the last repository added
, p_file_index in file_index_t default null -- The file index that must be used in combination with the git repo index
, p_file_name out nocopy file_name_t -- The file name (unique within a repo)
, p_id out nocopy file_id_t -- The file id, that is also a checksum (SHA1, 40 bytes)
, p_url out nocopy file_url_t -- The file URL
, p_bytes out nocopy file_bytes_t -- The size in bytes
, p_content out nocopy file_content_t -- The (text) file content
)
is
  l_git_repo_index constant git_repo_index_t := nvl(p_git_repo_index, g_git_repo_by_index_tab.last);
  l_file_index constant file_index_t := nvl(p_file_index, g_git_repo_index_file_by_index_tab(l_git_repo_index).last);
  l_file_rec file_rec_t;
begin
  l_file_rec := g_git_repo_index_file_by_index_tab(l_git_repo_index)(l_file_index);
  p_file_name := l_file_rec.file_name;
  p_id := l_file_rec.id;
  p_url := l_file_rec.url;
  p_bytes := l_file_rec.bytes;
  p_content := l_file_rec.content;  
end get_file;

procedure del_file
( p_git_repo_index in git_repo_index_t
, p_file_index in file_index_t
)
is
  l_git_repo_index constant git_repo_index_t := nvl(p_git_repo_index, g_git_repo_by_index_tab.last);
  l_file_index constant file_index_t := nvl(p_file_index, g_git_repo_index_file_by_index_tab(l_git_repo_index).last);
begin
  g_git_repo_index_file_by_name_tab(l_git_repo_index).delete(g_git_repo_index_file_by_index_tab(l_git_repo_index)(l_file_index).file_name);
  g_git_repo_index_file_by_index_tab(l_git_repo_index).delete(l_file_index);
end del_file;

procedure add_folder
( p_git_repo_index in git_repo_index_t
, p_path in file_name_t
, p_base_name_wildcard in file_name_t
, p_with_content in boolean
, p_overwrite in boolean
, p_file_index_tab out nocopy file_index_tab_t
)
is
  l_git_repo_index constant git_repo_index_t := nvl(p_git_repo_index, g_git_repo_by_index_tab.last);
  l_repo repo_t;
  l_branch_name branch_name_t;
  l_tag_name tag_name_t;
  l_commit_id commit_id_t;
  
  cursor c_list_files
  ( b_repo in repo_t
  , b_branch_name in branch_name_t
  , b_tag_name in tag_name_t
  , b_commit_id in commit_id_t
  , b_path in file_name_t
  , b_base_name_wildcard in file_name_t
  , b_with_content in naturaln
  )
  is
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
                   , commit_id => b_commit_id
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
begin
  p_file_index_tab := sys.odcinumberlist();
  get_repo
  ( p_git_repo_index => l_git_repo_index
  , p_repo => l_repo
  , p_branch_name => l_branch_name
  , p_tag_name => l_tag_name
  , p_commit_id => l_commit_id
  );
  for r in c_list_files( b_repo => l_repo
                       , b_branch_name => l_branch_name
                       , b_tag_name => l_tag_name
                       , b_commit_id => l_commit_id
                       , b_path => p_path
                       , b_base_name_wildcard => p_base_name_wildcard
                       , b_with_content => case when p_with_content then 1 else 0 end
                       )
  loop
    p_file_index_tab.extend(1);
    add_file
    ( p_git_repo_index => l_git_repo_index
    , p_file_name => r.file_name
    , p_id => r.id
    , p_url => r.url
    , p_bytes => r.bytes
    , p_content => r.content
    , p_overwrite => p_overwrite
    , p_file_index => p_file_index_tab(p_file_index_tab.last)
    );
  end loop;
end add_folder;

-- TEST

procedure ut_setup
is
begin
  null;
end ut_setup;

--%aftereach
procedure ut_teardown
is
begin
  done_repo;
end;

--%test
procedure ut_init_github_repo
is
  l_git_repo_index git_repo_index_t;
begin
  l_git_repo_index :=
    init_github_repo
    ( p_credential_name => null
    , p_repo_name => 'pato-gui'
    , p_repo_owner => c_repo_owner_pato
    );
  execute immediate q'[call ut.expect(:b1).to_equal(:b2)]' using l_git_repo_index, c_git_repo_index_pato + 1;
end;

--%test
procedure ut_init_repo
is
begin
  null;
end;

--%test
procedure ut_get
is
begin
  null;
end;

--%test
procedure ut_credential_name
is
begin
  null;
end;

--%test
procedure ut_region
is
begin
  null;
end;

--%test
procedure ut_organization
is
begin
  null;
end;

--%test
procedure ut_project
is
begin
  null;
end;

--%test
procedure ut_repo_owner
is
begin
  null;
end;

--%test
procedure ut_repo_name
is
begin
  null;
end;

--%test
procedure ut_current_schema
is
begin
  null;
end;

--%test
procedure ut_branch_name
is
begin
  null;
end;

--%test
procedure ut_tag_name
is
begin
  null;
end;

--%test
procedure ut_commit_id
is
begin
  null;
end;

--%test
procedure ut_repo
is
begin
  null;
end;

--%test
procedure ut_repo_id
is
begin
  null;
end;

end;
/
