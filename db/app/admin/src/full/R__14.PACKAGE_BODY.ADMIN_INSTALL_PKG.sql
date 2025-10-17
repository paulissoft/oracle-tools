create or replace package body admin_install_pkg is

-- LOCAL

g_repo clob := null;
g_repo_id varchar2(128 char);
g_current_schema all_users.username%type := null;

-- copy from pkg_str_util

subtype t_max_varchar2 is varchar2(32767);
c_max_varchar2_size constant pls_integer := 32767;

function dbms_lob_substr
( p_clob in clob
, p_amount in naturaln
, p_offset in positiven
, p_check in varchar2
)
return varchar2
is
  l_offset positiven := p_offset;
  l_amount naturaln := p_amount; -- can become 0
  l_buffer t_max_varchar2 := null;
  l_chunk t_max_varchar2;
  l_chunk_length naturaln := 0; -- never null
  l_clob_length constant naturaln := nvl(dbms_lob.getlength(p_clob), 0);
begin
  if p_check is null or p_check in ('O', 'L', 'OL')
  then
    null; -- OK
  else
    raise program_error;
  end if;

  -- read till this entry is full (during testing I got 32764 instead of c_max_varchar2_size)
  <<buffer_loop>>
  while l_amount > 0
  loop
    l_chunk :=
      dbms_lob.substr
      ( lob_loc => p_clob
      , offset => l_offset
      , amount => l_amount
      );

    l_chunk_length := nvl(length(l_chunk), 0);

    begin
      l_buffer := l_buffer || l_chunk;
    exception
      when value_error
      then
        if p_check in ('O', 'OL')
        then raise; -- overflow
        else exit buffer_loop;
        end if;
    end;

    -- nothing read: stop;
    -- buffer length at least p_amount: stop
    exit buffer_loop when l_chunk_length = 0 or length(l_buffer) >= p_amount;

    l_offset := l_offset + l_chunk_length;
    l_amount := l_amount - l_chunk_length;
  end loop buffer_loop;

  if p_check in ('L', 'OL')
  then
    if nvl(length(l_buffer), 0) = p_amount
    then null; -- buffer length is amount requested, i.e. OK
    else raise value_error;
    end if;
  end if;

  return l_buffer;
end dbms_lob_substr;

procedure split
( p_str in clob
, p_delimiter in varchar2
  -- type varchar2a is table of varchar2(32767) index by binary_integer;
, p_str_tab out nocopy dbms_sql.varchar2a
)
deterministic
is
  l_pos pls_integer;
  l_start positiven := 1; -- never null
  l_amount simple_integer := 0; -- never null
  l_str_length constant naturaln := nvl(dbms_lob.getlength(p_str), 0);
begin
  if l_str_length = 0
  then
    p_str_tab(p_str_tab.count+1) := null;
  else
    while l_start <= l_str_length
    loop
      l_pos := case when p_delimiter is not null then dbms_lob.instr(lob_loc => p_str, pattern => p_delimiter, offset => l_start) else 0 end;

      l_amount := case when l_pos > 0 then l_pos - l_start else c_max_varchar2_size end;
      p_str_tab(p_str_tab.count+1) :=
        dbms_lob_substr
        ( p_clob => p_str
        , p_offset => l_start
        , p_amount => l_amount
        , p_check => case when l_pos > 0 then 'OL' end
        );
      l_start := l_start + nvl(length(p_str_tab(p_str_tab.count+0)), 0) + nvl(length(p_delimiter), 0);
    end loop;
    -- everything has been read BUT ...
    if l_pos > 0
    then
      -- the delimiter string is just at the end of p_str, hence add another empty line so a join() can reconstruct exactly the same clob
      p_str_tab(p_str_tab.count+1) := null;
    end if;
  end if;
end split;

function directory_name
( p_file_path in varchar2
)
return varchar2
deterministic
is
  l_pos_last_slash constant pls_integer := instr(p_file_path, '/', -1);
begin
  -- t.sql => null, /t.sql => /, a/b/c/t.sql => a/b/c/
  return case when l_pos_last_slash > 0 then substr(p_file_path, 1, l_pos_last_slash) end;
end directory_name;

function base_name
( p_file_path in varchar2
)
return varchar2
deterministic
is
begin
  PRAGMA INLINE(directory_name, 'YES');
  return substr(p_file_path, 1 + nvl(length(directory_name(p_file_path)), 0));
end base_name;

-- PUBLIC

procedure init
( p_repo_owner in varchar2
, p_repo_name in varchar2
)
is
  l_credential_name dba_credentials.credential_name%type := null;
begin
  select  c.credential_name
  into    l_credential_name
  from    dba_credentials c
  where   c.owner = 'ADMIN'
  and     c.credential_name like '%GITHUB%';

  g_repo :=
    dbms_cloud_repo.init_github_repo
    ( credential_name => l_credential_name
    , repo_name => p_repo_name
    , owner => p_repo_owner
    );

  -- check it does exist
  select  t.id
  into    g_repo_id
  from    table(dbms_cloud_repo.list_repositories(repo => g_repo)) t
  where   t.owner = p_repo_owner
  and     t.name = p_repo_name;

  g_current_schema := sys_context('userenv', 'current_schema');
end init;

procedure done
is
begin
  g_repo := null;
  g_repo_id := null;
  if g_current_schema is not null
  then
    execute immediate 'alter session set current_schema = ' || g_current_schema;
    g_current_schema := null;
  end if;
end done;

procedure install_project
( p_schema in varchar -- The database schema to install into
, p_path in varchar2 -- The repository file path
, p_branch_name in varchar2 default null -- The branch
, p_tag_name in varchar2 default null -- The tag
, p_commit_id in varchar2 default null -- The commit
, p_stop_on_error in boolean default true -- Must we stop on error?
)
is
begin
  for r in
  ( select  id
    ,       name
    ,       bytes
    from    table
            ( dbms_cloud_repo.list_files
              ( repo => g_repo
              , path => p_path
              , branch_name => p_branch_name
              , tag_name => p_tag_name
              , commit_id => p_commit_id
              )
            )
    where   ( name like '%R\_\_%.sql' escape '\' -- Flyway replaceable scripts
              or
              name like '%V%\_\_%.sql' escape '\' -- Flyway incremental scripts
            )
    and     name not like '%.PACKAGE%.' || $$PLSQL_UNIT || '.sql' -- never install this package (body) by itself
  )
  loop
    dbms_output.put_line('id: ' || r.id);
    dbms_output.put_line('name: ' || r.name);
    dbms_output.put_line('bytes: ' || r.bytes);
  end loop;
end install_project;

procedure install_file
( p_schema in varchar -- The database schema to install into
, p_file_path in varchar2 -- The repository file path
, p_branch_name in varchar2 default null -- The branch
, p_tag_name in varchar2 default null -- The tag
, p_commit_id in varchar2 default null -- The commit
, p_stop_on_error in boolean default true -- Must we stop on error?
)
is
begin
  install_file
  ( p_schema => p_schema
  , p_file_path => p_file_path
  , p_content => dbms_cloud_repo.get_file
                 ( repo => g_repo
                 , file_path => p_file_path
                 , branch_name => p_branch_name
                 , tag_name => p_tag_name
                 , commit_id => p_commit_id
                 )
  , p_branch_name => p_branch_name
  , p_tag_name => p_tag_name
  , p_commit_id => p_commit_id
  , p_stop_on_error => p_stop_on_error
  );
end install_file;

procedure install_file
( p_schema in varchar -- The database schema to install into
, p_file_path in varchar2 -- The repository file path
, p_content in clob -- The content from the repository file
, p_branch_name in varchar2 default null -- The branch
, p_tag_name in varchar2 default null -- The tag
, p_commit_id in varchar2 default null -- The commit
, p_stop_on_error in boolean default true -- Must we stop on error?
)
is
  l_base_name constant varchar2(48 char) := substr(base_name(p_file_path), 1, 48);
  l_first_char varchar2(1 byte);
  l_root_file_path varchar2(32767 byte);
  l_line_tab dbms_sql.varchar2a;
begin
  dbms_application_info.set_module(module_name => l_base_name, action_name => 'installing');
   
  if p_schema is not null
  then
    execute immediate 'alter session set current_schema = ' || p_schema;
  end if;

  -- first character @ ?
  <<sql_include_file_loop>>
  loop
    l_first_char := dbms_lob.substr(p_content, amount => 1, offset => 1);

    --/*DBUG
    dbms_output.put_line('l_first_char: "' || l_first_char || '"');
    --/*DBUG*/
    
    if l_first_char = '@'
    then
      -- do all lines start with @ (or @@) (ir comment or PROMPT)?
      PRAGMA INLINE (split, 'YES');
      split
      ( p_content
      , chr(10)
      , l_line_tab
      );
      
      --/*DBUG
      dbms_output.put_line('l_line_tab.count: ' || l_line_tab.count);
      --/*DBUG*/
      
      if l_line_tab.count > 0
      then
        for i_idx in l_line_tab.first .. l_line_tab.last
        loop
          --/*DBUG
          dbms_output.put_line('line ' || i_idx || ': "' || l_line_tab(i_idx) || '"');
          --/*DBUG*/
          
          if l_line_tab(i_idx) is null or
             substr(l_line_tab(i_idx), 1, 1) = '@' or
             substr(l_line_tab(i_idx), 1, 2) = '--' or -- comment line
             upper(substr(l_line_tab(i_idx), 1, 6)) = 'PROMPT' 
          then
            null;
          else
            exit sql_include_file_loop;
          end if;
        end loop;

        for i_idx in l_line_tab.first .. l_line_tab.last
        loop
          /*
          -- You can install SQL statements containing nested SQL from a Cloud Code repository file using the following:
          -- @: includes a SQL file with a relative path to the ROOT of the repository.
          -- @@: includes a SQL file with a path relative to the current file.
          */
          if l_line_tab(i_idx) is null or
             substr(l_line_tab(i_idx), 1, 2) = '--' or -- comment line
             upper(substr(l_line_tab(i_idx), 1, 6)) = 'PROMPT' 
          then
            l_root_file_path := null;
          elsif substr(l_line_tab(i_idx), 1, 2) = '@@'
          then
            -- relative to the current file directory
            PRAGMA INLINE (directory_name, 'YES');
            l_root_file_path := directory_name(p_file_path) || trim(substr(l_line_tab(i_idx), 3));
          else -- it starts with @
            -- relative to the ROOT of the repository, i.e. absolute
            l_root_file_path := trim(substr(l_line_tab(i_idx), 2));
          end if;

          if l_root_file_path is not null
          then
            --/*DBUG
            dbms_output.put_line('SQL include file: ' || l_root_file_path);
            --/*DBUG*/

            -- recursively install everything
            install_file
            ( p_schema => p_schema
            , p_file_path => l_root_file_path
            , p_content => dbms_cloud_repo.get_file
                           ( repo => g_repo
                           , file_path => l_root_file_path
                           , branch_name => p_branch_name
                           , tag_name => p_tag_name
                           , commit_id => p_commit_id
                           )
            , p_branch_name => p_branch_name
            , p_tag_name => p_tag_name
            , p_commit_id => p_commit_id
            , p_stop_on_error => p_stop_on_error
            );
          end if;
        end loop;

        return;
      end if;
    end if;

    -- it is not a real loop: just once
    exit sql_include_file_loop;
  end loop sql_include_file_loop;

  --/*DBUG
  dbms_output.put_line('Not a simple SQL include file');
  --/*DBUG*/

  -- assume this is a SQL file (without includes)
  install_sql
  ( p_file_path => p_file_path
  , p_content => p_content
  , p_stop_on_error => p_stop_on_error
  );

  dbms_application_info.set_module(module_name => l_base_name, action_name => 'installed');
exception
  when others
  then
    dbms_application_info.set_module(module_name => l_base_name, action_name => 'error while installing');
    raise_application_error(-20000, 'Error installing ' || p_file_path, true);
end install_file;

procedure install_sql
( p_file_path in varchar2 -- The repository file path, for reference only
, p_content in clob -- The content from the repository file
, p_stop_on_error in boolean default true -- Must we stop on error?
)
is
  l_base_name constant varchar2(48 char) := substr(base_name(p_file_path), 1, 48);
  
  l_object_types constant sys.odcivarchar2list :=
    sys.odcivarchar2list
    ( 'SEQUENCE'
    , 'CLUSTER'
    , 'TABLE'
    , 'VIEW'
    , 'MATERIALIZED_VIEW'
    , 'MATERIALIZED_VIEW_LOG'
    , 'INDEX'
    , 'OBJECT_GRANT'
    , 'CONSTRAINT'
    , 'REF_CONSTRAINT'
    , 'PUBLIC_SYNONYM'
    , 'SYNONYM'
    , 'COMMENT'
    );
  l_statement_tab dbms_sql.varchar2a;

  procedure install_sql
  ( p_content in clob -- The content from the repository file
  , p_stop_on_error in boolean default true -- Must we stop on error?
  , p_statement_nr in positive default null
  )
  is
  begin
    dbms_application_info.set_module
    ( module_name => l_base_name
    , action_name => 'installing SQL' || case when p_statement_nr is not null then ' statement ' || p_statement_nr end
    );
    dbms_cloud_repo.install_sql
    ( content => p_content
    , stop_on_error => p_stop_on_error
    );
    dbms_application_info.set_module
    ( module_name => l_base_name
    , action_name => 'installed SQL' || case when p_statement_nr is not null then ' statement ' || p_statement_nr end
    );
  end install_sql;
begin
  if p_file_path like '%.PACKAGE%.' || $$PLSQL_UNIT || '.sql' -- never install this package (body) by itself
  then
    return;
  end if;
  
  for i_object_type_idx in l_object_types.first .. l_object_types.last
  loop
    if instr(p_file_path, '.' || l_object_types(i_object_type_idx) || '.') > 0
    then
      -- special handling
      PRAGMA INLINE (split, 'YES');
      split
      ( p_content
      , ';' || chr(10) -- line ends with ;
      , l_statement_tab
      );
      if l_statement_tab.count > 0
      then
        for i_statement_idx in l_statement_tab.first .. l_statement_tab.last
        loop
          if l_statement_tab(i_statement_idx) is null or
             l_statement_tab(i_statement_idx) = chr(10)          
          then
            null;
          else
            install_sql
            ( p_content => to_clob(l_statement_tab(i_statement_idx))
            , p_stop_on_error => p_stop_on_error
            , p_statement_nr => i_statement_idx
            );
          end if;
        end loop;
        
        return; -- finished
      end if;
    else
      null;
    end if;
  end loop;

  -- normal handling
  --/*DBUG
  dbms_output.put_line('Installing file ' || p_file_path);
  --/*DBUG*/

  install_sql
  ( p_content => p_content
  , p_stop_on_error => p_stop_on_error
  );
end install_sql;

end;
/

