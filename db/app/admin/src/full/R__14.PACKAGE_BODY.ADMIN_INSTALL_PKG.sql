create or replace package body admin_install_pkg is

-- LOCAL

-- TYPES

type project_rec_t is record
( project_type varchar2(4 byte) -- db/apex
, schema varchar(128 char) -- The database schema
, parent_github_access_handle github_access_handle_t default null -- The parent GitHub access handle
, parent_path varchar2(1000 char) default null -- The parent repository file path
, modules sys.odcivarchar2list default null -- The sub module paths to process when the POM is a container
, src_callbacks varchar2(1000 char)
, src_incr varchar2(1000 char)
, src_full varchar2(1000 char)
, src_dml varchar2(1000 char)
, src_ords varchar2(1000 char)
, application_id integer
);

subtype project_handle_t is varchar2(512 char); -- <repo owner>/<repo name>:<path>

type project_tab_t is table of project_rec_t index by project_handle_t;

type github_access_tab_t is table of github_access_rec_t index by github_access_handle_t;

-- copy from pkg_str_util

subtype t_max_varchar2 is varchar2(32767);

-- CONSTANTS

c_max_varchar2_size constant pls_integer := 32767;

-- VARIABLES

g_github_access_tab github_access_tab_t;

g_project_tab project_tab_t; -- when github_access is removed, remove also its projects

-- ROUTINES

function get_project_handle
( p_github_access_handle in github_access_handle_t -- The GitHub access handle
, p_path in varchar2 -- The repository file path
)
return project_handle_t
deterministic
is
begin
  return p_github_access_handle || ':' || p_path;
end get_project_handle;
  
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

function sql_statement_terminator
( p_file_path in varchar2
)
return varchar2
deterministic
is
  l_object_types constant sys.odcivarchar2list :=
    sys.odcivarchar2list
    ( -- PATO generated files end with ';'
      'SEQUENCE'
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
      -- PATO generated files end with /
    , 'TYPE_SPEC'
    , 'FUNCTION'
    , 'PACKAGE_SPEC'
    , 'PROCEDURE'
    , 'PACKAGE_BODY'
    , 'TYPE_BODY'
    , 'TRIGGER'
    , 'JAVA_SOURCE'
    , 'REFRESH_GROUP'
    , 'PROCOBJ'
    );
  l_base_name constant varchar2(1000 byte) := base_name(p_file_path);
begin
  -- Is it a R__*.sql file?
  if substr(l_base_name, 1, 3) = 'R__' and substr(l_base_name, -4) = '.sql'
  then 
    for i_object_type_idx in l_object_types.first .. l_object_types.last
    loop
      if instr(l_base_name, '.' || l_object_types(i_object_type_idx) || '.') > 0
      then
        return case
                 when l_object_types(i_object_type_idx) in
                      ( 'TYPE_SPEC'
                      , 'FUNCTION'
                      , 'PACKAGE_SPEC'
                      , 'PROCEDURE'
                      , 'PACKAGE_BODY'
                      , 'TYPE_BODY'
                      , 'TRIGGER'
                      , 'JAVA_SOURCE'
                      , 'REFRESH_GROUP'
                      , 'PROCOBJ'
                      )
                 then '/'
                 else ';'
               end;
      end if;  
    end loop;
  end if;
  return null;
end sql_statement_terminator;

function normalize_file_name
( p_file_path in varchar2
)
return varchar2
deterministic
is
begin
  -- a//b => a/b, a/ => a, /a => a
  return trim('/' from replace(p_file_path, '//', '/'));
end normalize_file_name;

procedure add_project
( p_github_access_handle in github_access_handle_t -- The GitHub access handle
, p_path in varchar2 -- The repository file path
, p_project_rec in project_rec_t
)
is
  l_project_handle constant project_handle_t := get_project_handle(p_github_access_handle, p_path);
begin
  --/*DBUG
  dbms_output.put_line(utl_lms.format_message('add_project("%s", "%s")', p_github_access_handle, p_path));
  --/*DBUG*/

  if g_project_tab.exists(l_project_handle) then raise dup_val_on_index; end if;

  g_project_tab(l_project_handle) := p_project_rec;

  -- process the modules recursively
  if p_project_rec.modules is not null and p_project_rec.modules.count > 0
  then
    for i_idx in p_project_rec.modules.first .. p_project_rec.modules.last
    loop
      process_file
      ( p_github_access_handle => p_github_access_handle
      , p_schema => p_project_rec.schema
      , p_file_path => normalize_file_name(p_path || '/' || p_project_rec.modules(i_idx) || '/' || 'pom.sql')
      , p_stop_on_error => true
      );
    end loop;
  end if;
exception
  when others
  then raise_application_error(-20000, utl_lms.format_message('add_project("%s", "%s")', p_github_access_handle, p_path), true);
end add_project;

-- PUBLIC

procedure set_github_access
( p_repo_owner in varchar2
, p_repo_name in varchar2
, p_branch_name in varchar2
, p_tag_name in varchar2
, p_commit_id in varchar2
, p_github_access_handle out nocopy github_access_handle_t
)
is
  l_github_access_rec github_access_rec_t;
begin
  p_github_access_handle := p_repo_owner || '/' || p_repo_name;
  
  if g_github_access_tab.exists(p_github_access_handle)
  then
    raise dup_val_on_index;
  end if;
  
  l_github_access_rec.repo_owner := p_repo_owner;
  l_github_access_rec.repo_name := p_repo_name;
  l_github_access_rec.branch_name := p_branch_name;
  l_github_access_rec.tag_name := p_tag_name;
  l_github_access_rec.commit_id := p_commit_id;
  
  select  c.credential_name
  into    l_github_access_rec.credential_name
  from    dba_credentials c
  where   c.owner = 'ADMIN'
  and     c.credential_name like '%GITHUB%';

  l_github_access_rec.repo :=
    dbms_cloud_repo.init_github_repo
    ( credential_name => l_github_access_rec.credential_name
    , repo_name => l_github_access_rec.repo_name
    , owner => l_github_access_rec.repo_owner
    );

  -- check it does exist
  select  t.id
  into    l_github_access_rec.repo_id
  from    table(dbms_cloud_repo.list_repositories(repo => l_github_access_rec.repo)) t
  where   t.owner = l_github_access_rec.repo_owner
  and     t.name = l_github_access_rec.repo_name;

  l_github_access_rec.current_schema := sys_context('USERENV', 'CURRENT_SCHEMA');

  g_github_access_tab(p_github_access_handle) := l_github_access_rec;
exception
  when others
  then raise_application_error
       ( -20000
       , utl_lms.format_message
         ( 'set_github_access("%s", "%s", "%s", "%s", "%s")'
         , p_repo_owner
         , p_repo_name
         , p_branch_name
         , p_tag_name
         , p_commit_id
         )
       , true
       );
end set_github_access;

procedure get_github_access
( p_github_access_handle in github_access_handle_t -- The GitHub repository handle as returned from set_github_access()
, p_github_access_rec out nocopy github_access_rec_t
)
is
begin
  p_github_access_rec := g_github_access_tab(p_github_access_handle);
end get_github_access;

procedure delete_github_access
( p_github_access_handle in github_access_handle_t -- The GitHub repository handle as returned from set_github_access()
)
is
  l_github_access_rec github_access_rec_t;
  l_project_handle project_handle_t;
  l_project_handle_next project_handle_t;
begin
  l_github_access_rec := g_github_access_tab(p_github_access_handle);
  g_github_access_tab.delete(p_github_access_handle);

  l_project_handle := g_project_tab.first;
  while l_project_handle is not null
  loop
    l_project_handle_next := g_project_tab.next(l_project_handle);
    if l_project_handle like p_github_access_handle || ':%'
    then
      g_project_tab.delete(l_project_handle);
    end if;
    l_project_handle := l_project_handle_next;
  end loop;
  if l_github_access_rec.current_schema is not null
  then
    execute immediate 'alter session set current_schema = ' || l_github_access_rec.current_schema;
  end if;
end delete_github_access;

procedure define_project_db
( p_github_access_handle in github_access_handle_t -- The GitHub access handle
, p_path in varchar2 -- The repository file path
, p_schema in varchar -- The database schema
, p_parent_github_access_handle in github_access_handle_t
, p_parent_path in varchar2
, p_modules in sys.odcivarchar2list
, p_src_callbacks in varchar2
, p_src_incr in varchar2
, p_src_full in varchar2
, p_src_dml in varchar2
, p_src_ords in varchar2
)
is
  l_project_rec project_rec_t;
begin
  l_project_rec.project_type := 'db';
  l_project_rec.schema := p_schema;
  l_project_rec.parent_github_access_handle := p_parent_github_access_handle;
  l_project_rec.parent_path := p_parent_path;
  l_project_rec.modules := p_modules;
  l_project_rec.src_callbacks := p_src_callbacks;
  l_project_rec.src_incr := p_src_incr;
  l_project_rec.src_full := p_src_full;
  l_project_rec.src_dml := p_src_dml;
  l_project_rec.src_ords := p_src_ords;

  add_project
  ( p_github_access_handle => p_github_access_handle
  , p_path => p_path
  , p_project_rec => l_project_rec
  );
end define_project_db;

procedure define_project_apex
( p_github_access_handle in github_access_handle_t -- The GitHub access handle
, p_path in varchar2 -- The repository file path
, p_schema in varchar -- The database schema
, p_parent_github_access_handle in github_access_handle_t
, p_parent_path in varchar2
, p_modules in sys.odcivarchar2list
, p_application_id in integer
)
is
  l_project_rec project_rec_t;
begin
  l_project_rec.project_type := 'apex';
  l_project_rec.schema := p_schema;
  l_project_rec.parent_github_access_handle := p_parent_github_access_handle;
  l_project_rec.parent_path := p_parent_path;
  l_project_rec.modules := p_modules;
  l_project_rec.application_id := p_application_id;

  add_project
  ( p_github_access_handle => p_github_access_handle
  , p_path => p_path
  , p_project_rec => l_project_rec
  );
end define_project_apex;

procedure process_project
( p_github_access_handle in github_access_handle_t
, p_path in varchar2 -- The repository file path
, p_operation in varchar2
, p_stop_on_error in boolean
)
is
  l_file_contents clob := null;
  l_github_access_rec github_access_rec_t;
  l_project_handle constant project_handle_t := get_project_handle(p_github_access_handle, p_path);
  l_project_rec project_rec_t;
begin
  l_github_access_rec := g_github_access_tab(p_github_access_handle);
  l_project_rec := g_project_tab(l_project_handle);

  -- APEX not implemented yet
  if l_project_rec.project_type = 'db' then null; else raise program_error; end if;

  -- export not implemented yet
  if p_operation = 'install' then null; else raise program_error; end if;

  for r in
  ( select  id
    ,       name
    ,       bytes
    ,       case
              when instr(name, l_project_rec.src_callbacks) > 0 then 0
              when instr(name, l_project_rec.src_incr) > 0 then 1
              when instr(name, l_project_rec.src_full) > 0 then 2
              when instr(name, l_project_rec.src_dml) > 0 then 3
              when instr(name, l_project_rec.src_ords) > 0 then 4
            end as file_type
    from    table
            ( dbms_cloud_repo.list_files
              ( repo => l_github_access_rec.repo
              , path => p_path
              , branch_name => l_github_access_rec.branch_name
              , tag_name => l_github_access_rec.tag_name
              , commit_id => l_github_access_rec.commit_id
              )
            )
    where   ( name like 'R\_\_%.sql' escape '\' -- Flyway repeatable scripts
              or
              name like '%/R\_\_%.sql' escape '\' -- Flyway repeatable scripts
              or
              name like 'V_%\_\_%.sql' escape '\' -- Flyway incremental scripts
              or
              name like '%/V_%\_\_%.sql' escape '\' -- Flyway incremental scripts
            )
    and     name not like '%.PACKAGE%.' || $$PLSQL_UNIT || '.sql' -- never process this package (body) by itself
    order by
            file_type
    ,       name        
  )
  loop
    /*DBUG
    dbms_output.put_line('id: ' || r.id);
    dbms_output.put_line('name: ' || r.name);
    dbms_output.put_line('bytes: ' || r.bytes);
    dbms_output.put_line('file_type: ' || r.file_type);
    /*DBUG*/
    l_file_contents := l_file_contents || '@' || r.name || chr(10);
  end loop;

  if l_file_contents is not null
  then
    process_file
    ( p_github_access_handle => p_github_access_handle
    , p_schema => l_project_rec.schema
    , p_file_path => p_path || '/process.sql'
    , p_content => l_file_contents
    , p_stop_on_error => p_stop_on_error
    );
  end if;
end process_project;

procedure process_file
( p_github_access_handle in github_access_handle_t
, p_schema in varchar -- The database schema 
, p_file_path in varchar2 -- The repository file path
, p_stop_on_error in boolean
)
is
  l_github_access_rec github_access_rec_t;
begin
  l_github_access_rec := g_github_access_tab(p_github_access_handle);

  process_file
  ( p_github_access_handle => p_github_access_handle
  , p_schema => p_schema
  , p_file_path => p_file_path
  , p_content => dbms_cloud_repo.get_file
                 ( repo => l_github_access_rec.repo
                 , file_path => p_file_path
                 , branch_name => l_github_access_rec.branch_name
                 , tag_name => l_github_access_rec.tag_name
                 , commit_id => l_github_access_rec.commit_id
                 )
  , p_stop_on_error => p_stop_on_error
  );
end process_file;

procedure process_file
( p_github_access_handle in github_access_handle_t
, p_schema in varchar -- The database schema
, p_file_path in varchar2 -- The repository file path
, p_content in clob -- The content from the repository file
, p_stop_on_error in boolean
)
is
  l_base_name constant varchar2(48 char) := substr(base_name(p_file_path), 1, 48);
  l_first_char varchar2(1 byte);
  l_root_file_path varchar2(32767 byte);
  l_line_tab dbms_sql.varchar2a;
  l_github_access_rec github_access_rec_t;
begin
  l_github_access_rec := g_github_access_tab(p_github_access_handle);

  dbms_application_info.set_module(module_name => l_base_name, action_name => 'processing');
   
  if p_schema is not null
  then
    execute immediate 'alter session set current_schema = ' || p_schema;
  end if;

  -- first character @ ?
  <<sql_include_file_loop>>
  loop
    l_first_char := dbms_lob.substr(p_content, amount => 1, offset => 1);

    /*DBUG
    dbms_output.put_line('l_first_char: "' || l_first_char || '"');
    /*DBUG*/
    
    if l_first_char = '@'
    then
      -- do all lines start with @ (or @@) (ir comment or PROMPT)?
      PRAGMA INLINE (split, 'YES');
      split
      ( p_content
      , chr(10)
      , l_line_tab
      );
      
      /*DBUG
      dbms_output.put_line('l_line_tab.count: ' || l_line_tab.count);
      /*DBUG*/
      
      if l_line_tab.count > 0
      then
        for i_idx in l_line_tab.first .. l_line_tab.last
        loop
          /*DBUG
          dbms_output.put_line('line ' || i_idx || ': "' || l_line_tab(i_idx) || '"');
          /*DBUG*/
          
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
          -- You can process SQL statements containing nested SQL from a Cloud Code repository file using the following:
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
            /*DBUG
            dbms_output.put_line('SQL include file: ' || l_root_file_path);
            /*DBUG*/

            -- recursively process everything
            process_file
            ( p_github_access_handle => p_github_access_handle
            , p_schema => p_schema
            , p_file_path => l_root_file_path
            , p_content => dbms_cloud_repo.get_file
                           ( repo => l_github_access_rec.repo
                           , file_path => l_root_file_path
                           , branch_name => l_github_access_rec.branch_name
                           , tag_name => l_github_access_rec.tag_name
                           , commit_id => l_github_access_rec.commit_id
                           )
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

  /*DBUG
  dbms_output.put_line('Not a simple SQL include file');
  /*DBUG*/

  -- assume this is a SQL file (without includes)
  process_sql
  ( p_github_access_handle => p_github_access_handle
  , p_file_path => p_file_path
  , p_content => p_content
  , p_stop_on_error => p_stop_on_error
  );

  dbms_application_info.set_module(module_name => l_base_name, action_name => 'processed');
exception
  when others
  then
    dbms_application_info.set_module(module_name => l_base_name, action_name => 'error while processing');
    raise_application_error(-20000, 'Error processing ' || p_file_path, true);
end process_file;

procedure process_sql
( p_github_access_handle in github_access_handle_t
, p_file_path in varchar2 -- The repository file path, for reference only
, p_content in clob -- The content from the repository file
, p_stop_on_error in boolean
)
is
  l_base_name constant varchar2(48 char) := substr(base_name(p_file_path), 1, 48);
  
  l_statement_tab dbms_sql.varchar2a;

  procedure process_sql
  ( p_content in clob -- The content from the repository file
  , p_stop_on_error in boolean
  , p_statement_nr in positive default null
  )
  is
  begin
    --/*DBUG
    dbms_output.put_line('Processing file ' || p_file_path  || case when p_statement_nr is not null then '; statement ' || p_statement_nr end );
    --/*DBUG*/

    dbms_application_info.set_module
    ( module_name => l_base_name
    , action_name => 'processing SQL' || case when p_statement_nr is not null then ' statement ' || p_statement_nr end
    );
    dbms_cloud_repo.install_sql
    ( content => p_content
    , stop_on_error => p_stop_on_error
    );
    dbms_application_info.set_module
    ( module_name => l_base_name
    , action_name => 'processed SQL' || case when p_statement_nr is not null then ' statement ' || p_statement_nr end
    );
  end process_sql;
begin
  if p_file_path like '%.PACKAGE%.' || $$PLSQL_UNIT || '.sql' -- never process this package (body) by itself
  then
    return;
  end if;

  PRAGMA INLINE(sql_statement_terminator, 'YES');
  if sql_statement_terminator(p_file_path) = ';'
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
          process_sql
          ( p_content => to_clob(l_statement_tab(i_statement_idx))
          , p_stop_on_error => p_stop_on_error
          , p_statement_nr => i_statement_idx
          );
        end if;
      end loop;
      
      return; -- finished
    end if;
  end if;
  
  -- normal handling
  process_sql
  ( p_content => p_content
  , p_stop_on_error => p_stop_on_error
  );
end process_sql;

end;
/

