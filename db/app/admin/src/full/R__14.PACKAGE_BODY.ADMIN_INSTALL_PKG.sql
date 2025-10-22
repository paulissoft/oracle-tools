create or replace package body admin_install_pkg is

-- LOCAL

-- TYPES

type options_rec_t is record
( operation varchar2(10)
, stop_on_error boolean
, dry_run boolean
, verbose boolean
);

-- key is base name, value is file contents
type callback_tab_t is table of clob index by varchar2(100 byte);

subtype project_handle_t is varchar2(512); -- github_access_handle || ':' || path

type project_rec_t is record
( project_type varchar2(4 byte) -- db/apex
, schema varchar(128 char) -- The database schema
, parent_github_access_handle github_access_handle_t default null -- The parent GitHub access handle
, parent_path varchar2(1000 char) default null -- The parent repository file path
, src_callbacks varchar2(1000 char) -- can be empty
, callbacks_project_handle project_handle_t -- this not and g_project_tab.exists(callbacks_project_handle)
, callback_tab callback_tab_t -- can inherit from paulissoft/oracle-tools:db/src/callbacks
, src_incr varchar2(1000 char)
, src_full varchar2(1000 char)
, src_dml varchar2(1000 char)
, src_ords varchar2(1000 char)
, application_id integer
);

type project_tab_t is table of project_rec_t index by project_handle_t;

type github_access_tab_t is table of github_access_rec_t index by github_access_handle_t;

-- copy from pkg_str_util

subtype t_max_varchar2 is varchar2(32767);

-- CONSTANTS

"paulissoft" constant varchar2(100 byte) := 'paulissoft';
"oracle-tools" constant varchar2(100 byte) := 'oracle-tools';
"paulissoft/oracle-tools" constant varchar2(100 byte) := "paulissoft" || '/' || "oracle-tools";

c_max_varchar2_size constant pls_integer := 32767;

-- DBMS_METADATA object types
c_md_object_types constant sys.odcivarchar2list :=
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

-- VARIABLES

g_project_tab project_tab_t;

g_github_access_tab github_access_tab_t;

g_options_rec options_rec_t;

g_first_error boolean := true;

g_clob clob := null;

g_pato_callbacks_project_handle project_handle_t := null;

g_empty_project_rec project_rec_t; -- do not modify this one

-- ROUTINES

procedure raise_error
( p_line in integer
, p_raise_error_statement in varchar2
)
is
begin
  execute immediate 'begin ' || p_raise_error_statement || '; end;';
  raise program_error; -- should not come here
exception
  when others
  then raise_application_error(-20100, 'Error raised on line ' || p_line, true);
end raise_error;

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
    raise_error
    ( $$PLSQL_LINE
    , utl_lms.format_message
      ( q'[raise_application_error(-20000, 'Parameter p_check (%s) should be empty or one of O, L and OL')]'
      , p_check
      )
    );
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
    else raise_error($$PLSQL_LINE, 'raise value_error');
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

function flyway_file_type
( p_file_path in varchar2
)
return varchar2
deterministic
is
begin
  return
    case
      when p_file_path like 'R\_\_%.sql' escape '\' -- Flyway repeatable scripts
           or
           p_file_path like '%/R\_\_%.sql' escape '\' -- Flyway repeatable scripts
      then 'R'
      when p_file_path like 'V_%\_\_%.sql' escape '\' -- Flyway incremental scripts
           or
           p_file_path like '%/V_%\_\_%.sql' escape '\' -- Flyway incremental scripts
      then 'V'
    end;
end flyway_file_type;

function is_flyway_file
( p_file_path in varchar2
)
return boolean
deterministic
is
begin
  PRAGMA INLINE (flyway_file_type, 'YES');
  return case when flyway_file_type(p_file_path) in ('R', 'V') then true else false end;
end is_flyway_file;

procedure parse_repeatable_file
( p_file_path in varchar2
, p_owner in out nocopy varchar2
, p_object_type out nocopy varchar2
, p_object_name out nocopy varchar2
)
is
  l_base_name constant varchar2(1000 byte) := base_name(p_file_path);
  l_parts_tab dbms_sql.varchar2a;
begin
  PRAGMA INLINE (flyway_file_type, 'YES');
  if flyway_file_type(l_base_name) = 'R'
  then
    split
    ( p_str => to_clob(l_base_name)
    , p_delimiter => '.'
    , p_str_tab => l_parts_tab
    );
    
    if l_parts_tab.count >= 4
    then
      -- R__00.PUBLIC_SYNONYM.ADMIN_RECOMPILE_PKG.sql (4) 
      -- R__18.ORACLE_TOOLS.OBJECT_GRANT.V_MY_SCHEMA_OBJECTS.sql (5)
      -- R__10.00.ORACLE_TOOLS.VIEW.V_MY_SCHEMA_OBJECT_FILTER.sql (6)
      if l_parts_tab.count >= 5
      then
        p_owner := l_parts_tab(l_parts_tab.last - 3);
      end if;
      p_object_type := l_parts_tab(l_parts_tab.last - 2);
      p_object_name := l_parts_tab(l_parts_tab.last - 1);
    else
      raise_error
      ( $$PLSQL_LINE
      , utl_lms.format_message
        ( q'[raise_application_error(-20000, 'Base name (%s) has %s parts with the dot as the delimiter: should be at least')]'
        , l_base_name
        , to_char(l_parts_tab.count)
        )
      );
    end if;
    
    if p_object_type = 'PUBLIC_SYNONYM'
    then
      p_owner := 'PUBLIC';
      p_object_type := 'SYNONYM';
    else
      p_object_type :=
        case p_object_type
          when 'TYPE_SPEC'
          then 'TYPE'
          when 'PACKAGE_SPEC'
          then 'PACKAGE'
          else replace(p_object_type, '_', ' ')
        end;
    end if;
  end if;
end parse_repeatable_file;

function sql_statement_terminator
( p_file_path in varchar2
)
return varchar2
deterministic
is
  l_base_name constant varchar2(1000 byte) := base_name(p_file_path);
begin
  -- Is it a R__*.sql file?
  if substr(l_base_name, 1, 3) = 'R__' and substr(l_base_name, -4) = '.sql'
  then 
    for i_object_type_idx in c_md_object_types.first .. c_md_object_types.last
    loop
      if instr(l_base_name, '.' || c_md_object_types(i_object_type_idx) || '.') > 0
      then
        return case
                 when c_md_object_types(i_object_type_idx) in
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
  elsif is_flyway_file(l_base_name)
  then
    return '/'; -- incremental scripts should use PL/SQL blocks, not just DML statements ending with a semi-colon
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

function do_not_install_file
( p_github_access_handle in github_access_handle_t
, p_file_path in varchar2 -- The repository file path, for reference only
)
return boolean
deterministic
is
begin
  if p_github_access_handle = "paulissoft/oracle-tools"
  then
    -- files mentioned in ../../adb-install-bootstrap.sql
    return
      case p_file_path
        when 'db/app/admin/src/incr/V20251021102600__create_GITHUB_INSTALLED_PROJECTS.sql'
        then true
        when 'db/app/admin/src/incr/V20251021102600__create_GITHUB_INSTALLED_PROJECTS.sql'
        then true
        when 'db/app/admin/src/incr/V20251021103000__create_GITHUB_INSTALLED_VERSIONS.sql'
        then true
        when 'db/app/admin/src/incr/V20251021103400__create_GITHUB_INSTALLED_VERSIONS_OBJECTS.sql'
        then true
        when 'db/app/admin/src/full/R__09.PACKAGE_SPEC.ADMIN_INSTALL_PKG.sql'
        then true
        when 'db/app/admin/src/full/R__10.VIEW.GITHUB_INSTALLED_VERSIONS_V.sql'
        then true
        when 'db/app/admin/src/full/R__14.PACKAGE_BODY.ADMIN_INSTALL_PKG.sql'
        then true
        else false
      end;
  end if;
  return false;
end do_not_install_file;

procedure install_sql
( p_schema in varchar2
, p_content in clob
, p_base_name in varchar2
, p_project_rec in project_rec_t default g_empty_project_rec
)
is
  l_module_name constant varchar2(100) := $$PLSQL_UNIT || '.process_sql (1)';
  l_statement constant clob :=
    replace
    ( replace
      ( replace
        ( replace
          ( p_content
          , '${oracle_tools_schema}'
          , 'ORACLE_TOOLS'
          )
        , '${compile_all}'
        , 'false'
        )
      , '${reuse_settings}'
      , 'false'
      )
    , '${oracle_tools_schema_msg}'
    , 'ORACLE_TOOLS'
    );
begin
  dbug_enter(l_module_name);
  dbug_print('schema   : ' || p_schema);
  if p_project_rec.callback_tab.exists(p_base_name)
  then
    dbug_print('callback : ' || p_project_rec.callbacks_project_handle || '/' || p_project_rec.callback_tab(p_base_name));
  else
    dbug_print('base name: ' || p_base_name);
  end if;
  
/*
-- File: db/app/cfg/src/callbacks/afterMigrate.sql
--
-- begin
--   ${oracle_tools_schema}.cfg_install_pkg."afterMigrate"(p_compile_all => ${compile_all}, p_reuse_settings => ${reuse_settings}, p_oracle_tools_schema_msg => '${oracle_tools_schema_msg}');
-- exception
--   when others
--   then null;
-- end;
-- /
--
-- ./conf/src/docker/flyway-db.conf:1:flyway.placeholders.oracle_tools_schema=${oracle_tools_schema}
-- ./conf/src/env.properties:2:oracle_tools_schema=ORACLE_TOOLS
-- ./db/pom.xml:40:    <flyway.placeholders.compile_all>false</flyway.placeholders.compile_all>
-- ./db/pom.xml:41:    <flyway.placeholders.reuse_settings>false</flyway.placeholders.reuse_settings>
-- ./conf/src/env.properties:6:oracle_tools_schema_msg=ORACLE_TOOLS
-- ./conf/src/flyway-app.conf:4:flyway.placeholders.oracle_tools_schema_msg=${oracle_tools_schema_msg}
*/
  execute immediate q'[
declare
  l_target_schema constant all_objects.owner%type := upper(:b1);
begin
  if l_target_schema <> sys_context('USERENV', 'CURRENT_SCHEMA')
  then
    execute immediate 'alter session set current_schema = ' || l_target_schema;
    if l_target_schema <> sys_context('USERENV', 'CURRENT_SCHEMA')
    then
      raise_application_error(-20000, 'Could not switch current user from "' || sys_context('USERENV', 'CURRENT_SCHEMA') || '" to "' || l_target_schema || '"');
    end if;
  end if;
  dbms_cloud_repo.install_sql
  ( content => :b2
  , stop_on_error => :b3
  );
end;
]'
    using in p_schema
           , l_statement
           , g_options_rec.stop_on_error;

  dbug_leave(l_module_name);
exception
  when others
  then
    dbug_print('statement: ' || dbms_lob.substr(lob_loc => l_statement, amount => 256));
    dbug_leave(l_module_name);
    raise;
end install_sql;

procedure process_sql
( p_github_access_handle in github_access_handle_t
, p_schema in varchar2
, p_file_path in varchar2 -- The repository file path, for reference only
, p_content in clob -- The content from the repository file
)
is
  l_module_name constant varchar2(100) := $$PLSQL_UNIT || '.process_sql (1)';
  
  l_base_name constant varchar2(48 char) := substr(base_name(p_file_path), 1, 48);  
  l_statement_tab dbms_sql.varchar2a;
  l_owner all_objects.owner%type := upper(p_schema);
  l_object_type all_objects.object_type%type;
  l_object_name all_objects.object_name%type;

  l_delimiter constant varchar2(2) := ';' || chr(10);

  procedure process_sql
  ( p_content in clob -- The content from the repository file
  , p_statement_nr in positive default null
  )
  is
    l_module_name constant varchar2(100) := $$PLSQL_UNIT || '.process_sql (2)';
  begin
    dbug_enter(l_module_name);
    
    --/*DBUG
    dbug_print
    ( '[' || to_char(sysdate, 'yyyy-mm-dd hh24:mi:ss') || ']' ||
      ' Processing file ' ||
      p_file_path  ||
      case when p_statement_nr is not null then '; statement ' || p_statement_nr end ||
      '; target schema ' || p_schema
    );
    --/*DBUG*/

    dbms_application_info.set_module
    ( module_name => l_base_name
    , action_name => 'processing SQL' || case when p_statement_nr is not null then ' statement ' || p_statement_nr end
    );
    if not(g_options_rec.dry_run) or base_name(p_file_path) = 'pom.sql'
    then
      install_sql
      ( p_schema => p_schema
      , p_content => p_content
      , p_base_name => l_base_name
      );
    end if;
    
    dbms_application_info.set_module
    ( module_name => l_base_name
    , action_name => 'processed SQL' || case when p_statement_nr is not null then ' statement ' || p_statement_nr end
    );
    
    dbug_leave(l_module_name);
  exception
    when others
    then
      dbug_leave(l_module_name);
      raise;
  end process_sql;
begin
  if do_not_install_file(p_github_access_handle, p_file_path)
  then
    return;
  end if;

  dbug_enter(l_module_name);

  -- special handling
  PRAGMA INLINE (split, 'YES');
  split
  ( p_content
  , l_delimiter -- line ends with ;
  , l_statement_tab
  );

  if l_statement_tab.count > 0
  then
    -- Script db/app/ui/src/full/R__10.VIEW.UI_APEX_MESSAGES_V.sql contains a
    -- 1) CREATE OR REPLACE VIEW definition ending with ';'
    -- 2) CREATE OR REPLACE TRIGGER "UI_APEX_MESSAGES_TRG" ending with '/'

    -- determine object
    parse_repeatable_file
    ( p_file_path => p_file_path
    , p_owner => l_owner
    , p_object_type => l_object_type
    , p_object_name => l_object_name
    );

    if l_object_type = 'VIEW' and l_statement_tab.count > 2
    then
      dbms_lob.trim(g_clob, 0);

      -- l_statement_tab.first is CREATE OR REPLACE VIEW
      -- l_statement_tab.first + 1 is CREATE OR REPLACE TRIGGER
      for i_statement_idx in l_statement_tab.first + 1 .. l_statement_tab.last
      loop
        dbms_lob.writeappend
        ( lob_loc => g_clob
        , amount => length(l_statement_tab(i_statement_idx))
        , buffer => l_statement_tab(i_statement_idx)
        );
        if i_statement_idx < l_statement_tab.last
        then
          dbms_lob.writeappend
          ( lob_loc => g_clob
          , amount => length(l_delimiter)
          , buffer => l_delimiter
          );
        end if;
      end loop;
      
      process_sql
      ( p_content => to_clob(l_statement_tab(l_statement_tab.first))
      , p_statement_nr => l_statement_tab.first
      );
      process_sql
      ( p_content => g_clob
      , p_statement_nr => l_statement_tab.first + 1
      );
    else
      for i_statement_idx in l_statement_tab.first .. l_statement_tab.last
      loop
        if l_statement_tab(i_statement_idx) is null or
           l_statement_tab(i_statement_idx) = chr(10)          
        then
          null;
        else
          process_sql
          ( p_content => to_clob(l_statement_tab(i_statement_idx))
          , p_statement_nr => i_statement_idx
          );
        end if;
      end loop;
    end if;
  else
    -- normal handling
    process_sql
    ( p_content => p_content
    );
  end if;
  
  dbug_leave(l_module_name);
exception
  when others
  then
    dbug_leave(l_module_name);
    raise;
end process_sql;

procedure install_file
( p_github_access_handle in github_access_handle_t
, p_schema in varchar2
, p_repo in clob
, p_file_path in varchar2
, p_branch_name in varchar2
, p_tag_name in varchar2
, p_commit_id in varchar2
, p_stop_on_error in boolean
)
is
  l_module_name constant varchar2(100) := $$PLSQL_UNIT || '.install_file';
begin
  if do_not_install_file(p_github_access_handle, p_file_path)
  then
    return;
  end if;

  dbug_enter(l_module_name);

  if sql_statement_terminator(p_file_path) = ';'
  then
    process_sql
    ( p_github_access_handle => p_github_access_handle
    , p_schema => p_schema
    , p_file_path => p_file_path
    , p_content => dbms_cloud_repo.get_file
                   ( repo => p_repo
                   , file_path => p_file_path
                   , branch_name => p_branch_name
                   , tag_name => p_tag_name
                   , commit_id => p_commit_id
                   )
    );  
  else
    execute immediate q'[
declare
  l_target_schema constant all_objects.owner%type := upper(:b1);
begin
  if l_target_schema <> sys_context('USERENV', 'CURRENT_SCHEMA')
  then
    execute immediate 'alter session set current_schema = ' || l_target_schema;
    if l_target_schema <> sys_context('USERENV', 'CURRENT_SCHEMA')
    then
      raise_application_error(-20000, 'Could not switch current user from "' || sys_context('USERENV', 'CURRENT_SCHEMA') || '" to "' || l_target_schema || '"');
    end if;
  end if;  
  dbms_cloud_repo.install_file
  ( repo => :b2
  , file_path => :b3
  , branch_name => :b4
  , tag_name => :b5
  , commit_id => :b6
  , stop_on_error => :b7
  );
end;
]'
        using in p_schema
               , p_repo
               , p_file_path
               , p_branch_name
               , p_tag_name
               , p_commit_id
               , p_stop_on_error;
  end if;

  dbug_leave(l_module_name);
exception
  when others
  then
    dbug_leave(l_module_name);
    raise;
end install_file;               

procedure process_file
( p_github_access_handle in github_access_handle_t
, p_schema in varchar -- The database schema 
, p_file_path in varchar2 -- The repository file path
, p_file_id in varchar2 default null
, p_bytes in integer default null
, p_project_rec in project_rec_t default g_empty_project_rec
)
is
  pragma autonomous_transaction;

  l_module_name constant varchar2(100) := $$PLSQL_UNIT || '.process_file (1)';

  -- Only issue DML for PATO generated files
  l_github_installed_dml boolean :=
    p_github_access_handle is not null and
    p_schema is not null and
    p_file_path is not null and
    p_file_id is not null and
    p_bytes is not null and
    not(g_options_rec.dry_run) and
    is_flyway_file(p_file_path);

  l_github_access_rec github_access_rec_t;
  l_github_installed_projects_id github_installed_projects.id%type;
  l_directory_name constant github_installed_projects.directory_name%type := directory_name(p_file_path);
  l_github_installed_versions_id github_installed_versions.id%type;
  l_base_name constant github_installed_versions.base_name%type := base_name(p_file_path);
  l_error_msg github_installed_versions.error_msg%type;
  l_owner all_objects.owner%type := upper(p_schema);
  l_object_type all_objects.object_type%type;
  l_object_name all_objects.object_name%type;
  l_flyway_file_type constant varchar2(1) := flyway_file_type(p_file_path); -- R/V
begin
  if do_not_install_file(p_github_access_handle, p_file_path)
  then
    return;
  end if;

  dbug_enter(l_module_name);

  l_github_access_rec := g_github_access_tab(p_github_access_handle);

  -- only 'install' implemented
  if g_options_rec.operation = 'install' then null; else raise_error($$PLSQL_LINE, 'raise value_error'); end if;

  --/*DBUG
  dbug_print
  ( '[' || to_char(sysdate, 'yyyy-mm-dd hh24:mi:ss') || ']' ||
    ' Processing file ' ||
    p_file_path  ||
    '; target schema ' || p_schema
  );
  --/*DBUG*/
  
  if not(g_options_rec.dry_run) or base_name(p_file_path) = 'pom.sql'
  then
    if l_github_installed_dml
    then
      -- Update GITHUB tables

      -- insert/select github_installed_projects first
      insert into github_installed_projects(github_repo, directory_name, owner)
        select  p_github_access_handle
        ,       l_directory_name
        ,       u.username
        from    all_users u
        where   u.username in (p_schema, upper(p_schema))
        minus
        select  p.github_repo
        ,       p.directory_name
        ,       p.owner
        from    github_installed_projects p;

      select  p.id
      into    l_github_installed_projects_id
      from    github_installed_projects p
      where   p.github_repo = p_github_access_handle
      and     p.directory_name = l_directory_name
      and     p.owner in (p_schema, upper(p_schema));

      -- github_installed_versions next

      case l_flyway_file_type
        when 'R' -- repeatable
        then
          -- Is the last creation of this exact file (and checksum and # bytes) there?
          select  max(v.id)
          into    l_github_installed_versions_id
          from    github_installed_versions_v v
          where   v.github_installed_projects_id = l_github_installed_projects_id
          and     v.base_name = l_base_name      
          and     v.installed_rank = -1 /* last date_created */
          and     v.checksum = p_file_id
          and     v.bytes = p_bytes
          and     v.error_msg is null;

        when 'V' -- incremental
        then
          -- Is the last creation of this exact file there?
          select  max(v.id)
          into    l_github_installed_versions_id
          from    github_installed_versions_v v
          where   v.github_installed_projects_id = l_github_installed_projects_id
          and     v.base_name = l_base_name      
          and     v.installed_rank = -1 /* last date_created */
          and     v.error_msg is null;
          
        else
          null;
      end case;

      --/*DBUG
      if l_github_installed_versions_id is not null
      then
        dbug_print
        ( '[' || to_char(sysdate, 'yyyy-mm-dd hh24:mi:ss') || ']' ||
          ' Previous installed version id: ' || l_github_installed_versions_id
        );
      end if;
      --/*DBUG*/

      if l_github_installed_versions_id is not null
      then
        if l_flyway_file_type = 'V'
        then
          l_github_installed_dml := false; -- skip install once scripts
        elsif l_flyway_file_type = 'R'
        then
          -- check for a repeatable whether all the stored objects are still there with the same value for CREATED
          <<check_difference_loop>>
          for r in
          ( select  o.owner
            ,       o.object_type
            ,       o.object_name
            ,       o.created
            from    github_installed_versions_objects o
            where   o.github_installed_versions_id = l_github_installed_versions_id
            minus
            select  o.owner
            ,       o.object_type
            ,       o.object_name
            ,       o.created
            from    all_objects o
          )
          loop
            --/*DBUG
            dbug_print
            ( utl_lms.format_message
              ( '[%s] Must re-install due to %s "%s"."%s" with creation date "%s"'
              , to_char(sysdate, 'yyyy-mm-dd hh24:mi:ss')
              , r.object_type
              , r.owner
              , r.object_name
              , to_char(r.created, 'yyyy-mm-dd hh24:mi:ss')
              )
            );
            --/*DBUG*/
            
            -- there is at least one difference: stop and recreate again
            l_github_installed_versions_id := null;
            exit check_difference_loop;
          end loop check_difference_loop;

          l_github_installed_dml := l_github_installed_versions_id is null;
        end if; -- if l_flyway_file_type = 'V'
      end if; -- if l_github_installed_versions_id is not null
    end if; -- if l_github_installed_dml

    begin
      if l_github_installed_versions_id is null
      then
        -- Run Flyway callback before echo migration
        if l_flyway_file_type is not null and
           p_project_rec.callback_tab.exists('beforeEachMigrate.sql')
        then
          install_sql
          ( p_schema => p_schema
          , p_content => p_project_rec.callback_tab('beforeEachMigrate.sql')
          , p_base_name => 'beforeEachMigrate.sql'
          , p_project_rec => p_project_rec
          );
        end if;
      
        install_file
        ( p_github_access_handle => p_github_access_handle
        , p_schema => p_schema
        , p_repo => l_github_access_rec.repo
        , p_file_path => p_file_path
        , p_branch_name => l_github_access_rec.branch_name
        , p_tag_name => l_github_access_rec.tag_name
        , p_commit_id => l_github_access_rec.commit_id
        , p_stop_on_error => g_options_rec.stop_on_error
        );
        
        -- Run Flyway callback after each migration
        if l_flyway_file_type is not null and
           p_project_rec.callback_tab.exists('afterEachMigrate.sql')
        then
          install_sql
          ( p_schema => p_schema
          , p_content => p_project_rec.callback_tab('afterEachMigrate.sql')
          , p_base_name => 'afterEachMigrate.sql'
          , p_project_rec => p_project_rec
          );
        end if;
      end if;
    exception
      when others
      then
        if l_github_installed_dml
        then
          l_error_msg := sqlerrm;
          insert into github_installed_versions
          ( github_installed_projects_id
          , base_name
          , date_created
          , checksum
          , bytes
          , error_msg
          )
          values
          ( l_github_installed_projects_id
          , l_base_name
          , sysdate
          , p_file_id
          , p_bytes
          , l_error_msg
          );
        end if; -- if l_github_installed_dml
        raise;
    end;

    -- everything went fine and there is something to insert
    if l_github_installed_dml
    then
      if l_github_installed_versions_id is not null
      then
        raise_error
        ( $$PLSQL_LINE
        , utl_lms.format_message
          ( q'[raise_application_error(-20000, 'Expected l_github_installed_versions_id (%s) to be NULL')]'
          , to_char(l_github_installed_versions_id)
          )
        );
      end if;
      
      insert into github_installed_versions
      ( github_installed_projects_id
      , base_name
      , date_created
      , checksum
      , bytes
      )
      values
      ( l_github_installed_projects_id
      , l_base_name
      , sysdate
      , p_file_id
      , p_bytes
      )
      returning id into l_github_installed_versions_id;

      -- determine object
      parse_repeatable_file
      ( p_file_path => p_file_path
      , p_owner => l_owner
      , p_object_type => l_object_type
      , p_object_name => l_object_name
      );

      -- github_installed_versions_objects next:
      -- add the object based on the file name
      insert into github_installed_versions_objects
      ( github_installed_versions_id
      , owner
      , object_type
      , object_name
      , created
      )
        select  l_github_installed_versions_id as github_installed_versions_id
        ,       o.owner
        ,       o.object_type
        ,       o.object_name
        ,       o.created
        from    all_objects o
        where   o.owner = l_owner
        and     o.object_type = l_object_type
        and     o.object_name = l_object_name;
    end if; -- if l_github_installed_dml
  end if;

  commit;

  dbug_leave(l_module_name);
exception
  when others
  then
    commit;
    dbug_leave(l_module_name);    
    raise;
end process_file;

procedure process_file_apex
( p_github_access_handle in github_access_handle_t
, p_schema in varchar -- The database schema 
, p_file_path in varchar2 -- The repository file path
)
is
  pragma autonomous_transaction;

  l_module_name constant varchar2(100) := $$PLSQL_UNIT || '.process_file_apex';

  l_github_access_rec github_access_rec_t;
begin
  if do_not_install_file(p_github_access_handle, p_file_path)
  then
    return;
  end if;

  dbug_enter(l_module_name);

  l_github_access_rec := g_github_access_tab(p_github_access_handle);

  -- only 'install' implemented
  if g_options_rec.operation = 'install' then null; else raise_error($$PLSQL_LINE, 'raise value_error'); end if;

  --/*DBUG
  dbug_print
  ( '[' || to_char(sysdate, 'yyyy-mm-dd hh24:mi:ss') || ']' ||
    ' Processing APEX file ' ||
    p_file_path  ||
    '; target schema ' || p_schema
  );
  --/*DBUG*/
  
  if not(g_options_rec.dry_run)
  then
    install_file
    ( p_github_access_handle => p_github_access_handle
    , p_schema => p_schema
    , p_repo => l_github_access_rec.repo
    , p_file_path => p_file_path
    , p_branch_name => l_github_access_rec.branch_name
    , p_tag_name => l_github_access_rec.tag_name
    , p_commit_id => l_github_access_rec.commit_id
    , p_stop_on_error => g_options_rec.stop_on_error
    );
  end if;

  commit;

  dbug_leave(l_module_name);
exception
  when others
  then
    commit;
    dbug_leave(l_module_name);    
    raise;
end process_file_apex;

procedure process_project
( p_github_access_handle in github_access_handle_t
, p_path in varchar2 -- The repository file path
, p_project_rec in out nocopy project_rec_t
)
is
  l_module_name constant varchar2(100) := $$PLSQL_UNIT || '.process_project (1)';
  
  l_github_access_rec github_access_rec_t;

  l_path varchar2(1000 byte);
  l_base_name varchar2(1000 byte);
  l_base_name_wildcard varchar2(100 byte);

  cursor c_list_files
  ( b_path in varchar2
  , b_base_name_wildcard in varchar2
  )
  is
    select  t.id
    ,       t.name
    ,       t.bytes
    from    table
            ( dbms_cloud_repo.list_files
              ( repo => l_github_access_rec.repo
              , path => b_path
              , branch_name => l_github_access_rec.branch_name
              , tag_name => l_github_access_rec.tag_name
              , commit_id => l_github_access_rec.commit_id
              )
            ) t
    where   t.name like b_path || '/' || b_base_name_wildcard escape '\'
    order by
            t.name;

  type t_list_files is table of c_list_files%rowtype index by binary_integer;

  l_flyway_files t_list_files;
begin
  dbug_enter(l_module_name);

  l_github_access_rec := g_github_access_tab(p_github_access_handle);

  --/*DBUG
  dbug_print
  ( '[' || to_char(sysdate, 'yyyy-mm-dd hh24:mi:ss') || ']' ||
    ' Processing project ' ||
    p_path  ||
    '; target schema ' || p_project_rec.schema ||
    '; current schema ' || sys_context('USERENV', 'CURRENT_SCHEMA')
  );
  --/*DBUG*/

  if p_project_rec.project_type = 'db'
  then
    -- export not implemented yet
    if g_options_rec.operation = 'install'
    then
      <<file_type_loop>>
      for i_file_type in 0..4
      loop
        l_path :=   
          case i_file_type
            when 0
            then p_project_rec.src_callbacks
            when 1
            then p_project_rec.src_incr
            when 2
            then p_project_rec.src_full
            when 3
            then p_project_rec.src_dml
            when 4
            then p_project_rec.src_ords
          end;

        if i_file_type = 0
        then
          if l_path is null
          then
            -- p_project_rec.src_callbacks is null
            p_project_rec.callbacks_project_handle := g_pato_callbacks_project_handle; -- should be not null
            p_project_rec.callback_tab := g_project_tab(p_project_rec.callbacks_project_handle).callback_tab;
          else
            p_project_rec.callbacks_project_handle := p_github_access_handle || ':' || p_path;
          end if;

          if not(g_project_tab.exists(p_project_rec.callbacks_project_handle))
          then
            raise_error
            ( $$PLSQL_LINE
            , utl_lms.format_message
              ( q'[raise_application_error(-20000, 'No callbacks project handle (%s) defined.')]'
              , p_project_rec.callbacks_project_handle
              )
            );
          end if;
        end if;

        if l_path is null
        then
          continue; -- nothing to find
        end if;

        l_path := normalize_file_name(p_path || '/' || l_path);

        l_base_name_wildcard := 
          case i_file_type
            when 0
            then '%Migrate.sql'
            when 1
            then 'V_%\_\_%.sql' -- V<nr>__%.sql (<nr> can contain digits)
            else 'R\_\___.%.%.sql' -- R__<nr>.<type>.<name>.sql / R__<nr>.<owner>.<type>.<name>.sql (<nr> can contain digits)
          end;

        <<list_files_loop>>
        for r in c_list_files(l_path, l_base_name_wildcard)
        loop
          if i_file_type = 0
          then
            l_base_name := base_name(r.name);
            if l_base_name in ( 'beforeMigrate.sql'
                              , 'beforeEachMigrate.sql'
                              , 'afterEachMigrate.sql'
                              , 'afterMigrate.sql'
                              )
            then
              p_project_rec.callback_tab(l_base_name) :=
                dbms_cloud_repo.get_file
                ( repo => l_github_access_rec.repo
                , file_path => r.name
                , branch_name => l_github_access_rec.branch_name
                , tag_name => l_github_access_rec.tag_name
                , commit_id => l_github_access_rec.commit_id
                );
            end if;
          else
            l_flyway_files(l_flyway_files.count + 1) := r;
          end if;
        end loop list_files_loop;
      end loop file_type_loop;

      -- anything to install?
      if l_flyway_files.count > 0
      then
        -- Run Flyway callback before migration
        if p_project_rec.callback_tab.exists('beforeMigrate.sql')
        then
          install_sql
          ( p_schema => p_project_rec.schema
          , p_content => p_project_rec.callback_tab('beforeMigrate.sql')
          , p_base_name => 'beforeMigrate.sql'
          , p_project_rec => p_project_rec
          );
        end if;

        <<process_file_loop>>
        for i_file_idx in l_flyway_files.first .. l_flyway_files.last
        loop
          process_file
          ( p_github_access_handle => p_github_access_handle
          , p_schema => p_project_rec.schema
          , p_file_path => l_flyway_files(i_file_idx).name
          , p_file_id => l_flyway_files(i_file_idx).id
          , p_bytes => l_flyway_files(i_file_idx).bytes
          , p_project_rec => p_project_rec
          );
        end loop process_file_loop;
        
        -- Run Flyway callback after migration
        if p_project_rec.callback_tab.exists('afterMigrate.sql')
        then
          install_sql
          ( p_schema => p_project_rec.schema
          , p_content => p_project_rec.callback_tab('afterMigrate.sql')
          , p_base_name => 'afterMigrate.sql'
          , p_project_rec => p_project_rec
          );
        end if;
      end if;
    else
      raise_error($$PLSQL_LINE, 'raise value_error');
    end if;
  elsif p_project_rec.project_type = 'apex'
  then
    -- export not implemented yet
    if g_options_rec.operation = 'install'
    then 
      process_file_apex
      ( p_github_access_handle => p_github_access_handle
      , p_schema => p_project_rec.schema
      , p_file_path => p_path || '/src/export/install.sql'
      );
    else
      raise_error($$PLSQL_LINE, 'raise value_error');
    end if;
  else
    raise_error($$PLSQL_LINE, 'raise value_error');
  end if;

  dbug_leave(l_module_name);
exception
  when others
  then
    dbug_leave(l_module_name);
    raise;
end process_project;

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
    raise_error($$PLSQL_LINE, 'raise dup_val_on_index');
  end if;

  if g_github_access_tab.count = 0 and p_github_access_handle <> "paulissoft/oracle-tools"
  then
    raise_error
    ( $$PLSQL_LINE
    , utl_lms.format_message
      ( q'[raise_application_error(-20000, 'The first call for set_github_access() must be for repo owner "%s" and repo name "%s"']'
      , "paulissoft"
      , "oracle-tools"
      )
    );
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
begin
  l_github_access_rec := g_github_access_tab(p_github_access_handle);
  g_github_access_tab.delete(p_github_access_handle);
end delete_github_access;

procedure dbug_print
( p_line in varchar2
)
is
begin
  dbms_output.put_line(p_line);
end dbug_print;

procedure dbug_enter
( p_module in varchar2
)
is
begin
  if g_options_rec.verbose
  then
    dbug_print('>' || p_module);
  end if;
end dbug_enter;

procedure dbug_leave
( p_module in varchar2
, p_sqlcode in integer default sqlcode
, p_error_backtrace in varchar2
, p_call_stack in varchar2
)
is
begin
  if nvl(p_sqlcode, 0) <> 0
  then
    -- display the first error in a call chain
    if g_first_error
    then
      dbug_print('*** CALL STACK ***');
      dbug_print(p_call_stack);
      dbug_print('*** ERROR BACKTRACE ***');
      dbug_print(p_error_backtrace);
      g_first_error := false;
    end if;
  else
    g_first_error := true;
  end if;
  if g_options_rec.verbose
  then
    dbug_print('<' || p_module);
  end if;
end dbug_leave;

procedure process_project_db
( p_github_access_handle in github_access_handle_t -- The GitHub access handle
, p_path in varchar2 -- The repository file path
, p_schema in varchar -- The database schema
, p_parent_github_access_handle in github_access_handle_t
, p_parent_path in varchar2
, p_src_callbacks in varchar2
, p_src_incr in varchar2
, p_src_full in varchar2
, p_src_dml in varchar2
, p_src_ords in varchar2
)
is
  l_module_name constant varchar2(100) := $$PLSQL_UNIT || '.process_project_db';
  l_project_rec project_rec_t;
begin
  dbug_enter(l_module_name);
  
  l_project_rec.project_type := 'db';
  l_project_rec.schema := p_schema;
  l_project_rec.parent_github_access_handle := p_parent_github_access_handle;
  l_project_rec.parent_path := p_parent_path;
  l_project_rec.src_callbacks := p_src_callbacks;
  l_project_rec.src_incr := p_src_incr;
  l_project_rec.src_full := p_src_full;
  l_project_rec.src_dml := p_src_dml;
  l_project_rec.src_ords := p_src_ords;

  g_project_tab(p_github_access_handle || ':' || p_path ) := l_project_rec;

  process_project
  ( p_github_access_handle => p_github_access_handle
  , p_path => p_path
  , p_project_rec => l_project_rec
  );

  dbug_leave(l_module_name);
exception
  when others
  then
    dbug_leave(l_module_name);
    raise;
end process_project_db;

procedure process_project_apex
( p_github_access_handle in github_access_handle_t -- The GitHub access handle
, p_path in varchar2 -- The repository file path
, p_schema in varchar -- The database schema
, p_parent_github_access_handle in github_access_handle_t
, p_parent_path in varchar2
, p_application_id in integer
)
is
  l_module_name constant varchar2(100) := $$PLSQL_UNIT || '.process_project_apex';  
  l_project_rec project_rec_t;
begin
  dbug_enter(l_module_name);
  
  l_project_rec.project_type := 'apex';
  l_project_rec.schema := p_schema;
  l_project_rec.parent_github_access_handle := p_parent_github_access_handle;
  l_project_rec.parent_path := p_parent_path;
  l_project_rec.application_id := p_application_id;

  g_project_tab(p_github_access_handle || ':' || p_path ) := l_project_rec;

  process_project
  ( p_github_access_handle => p_github_access_handle
  , p_path => p_path
  , p_project_rec => l_project_rec
  );

  dbug_leave(l_module_name);
exception
  when others
  then
    dbug_leave(l_module_name);
    raise;
end process_project_apex;

procedure process_project
( p_github_access_handle in github_access_handle_t -- The GitHub access handle
, p_path in varchar2 -- The repository file path
, p_parent_github_access_handle in github_access_handle_t default null -- The parent GitHub access handle
, p_parent_path in varchar2 default null -- The parent repository file path
)
is
  l_module_name constant varchar2(100) := $$PLSQL_UNIT || '.process_project (2)';
  l_project_rec project_rec_t;
begin
  dbug_enter(l_module_name);
  
  l_project_rec.project_type := null;
  l_project_rec.parent_github_access_handle := p_parent_github_access_handle;
  l_project_rec.parent_path := p_parent_path;

  g_project_tab(p_github_access_handle || ':' || p_path ) := l_project_rec;

  -- process the pom.sql inside
  PRAGMA INLINE(normalize_file_name, 'YES');
  process_file
  ( p_github_access_handle => p_github_access_handle
  , p_schema => null
  , p_file_path => normalize_file_name(p_path || '/' || 'pom.sql')
  );

  dbug_leave(l_module_name);
exception
  when others
  then
    dbug_leave(l_module_name);
    raise;
end process_project;

procedure process_root_project
( p_github_access_handle in github_access_handle_t -- The GitHub access handle
, p_parent_github_access_handle in github_access_handle_t
, p_parent_path in varchar2
, p_operation in varchar2
, p_stop_on_error in boolean
, p_dry_run in boolean
, p_verbose in boolean
)
is
  l_module_name constant varchar2(100) := $$PLSQL_UNIT || '.process_root_project';
  l_project_rec project_rec_t;
begin
  l_project_rec.project_type := null;
  l_project_rec.parent_github_access_handle := p_parent_github_access_handle;
  l_project_rec.parent_path := p_parent_path;
  g_options_rec.operation := p_operation;
  g_options_rec.stop_on_error := p_stop_on_error;
  g_options_rec.dry_run := p_dry_run;
  g_options_rec.verbose := p_verbose;

  g_project_tab(p_github_access_handle || ':' || null ) := l_project_rec;

  /*
  -- gpaulissen@pc-803 oracle-tools % find . -name callbacks -print -exec ls {} \;
  -- ./db/app/admin/src/callbacks
  -- ./db/app/cfg/src/callbacks
  -- afterMigrate.sql  beforeEachMigrate.sql
  -- ./db/src/callbacks
  -- afterMigrate.sql  beforeEachMigrate.sql  beforeMigrate.sql  unused-afterEachMigrate.sql  unused-beforeMigrate.sql
  */
  g_pato_callbacks_project_handle := "paulissoft/oracle-tools" || ':' || 'db';
  process_project_db
  ( p_github_access_handle => "paulissoft/oracle-tools"
  , p_path => 'db'
  , p_src_callbacks => '/src/callbacks'
  , p_src_incr => null
  , p_src_full => null
  , p_src_dml => null
  , p_src_ords => null
  );
  
  -- process the pom.sql inside
  PRAGMA INLINE(normalize_file_name, 'YES');
  process_file
  ( p_github_access_handle => p_github_access_handle
  , p_schema => null
  , p_file_path => normalize_file_name('pom.sql')
  );

  dbug_leave(l_module_name);
exception
  when others
  then
    dbug_leave(l_module_name);
    raise;
end process_root_project;

begin
  dbms_lob.createtemporary(g_clob, true);
end;
/

