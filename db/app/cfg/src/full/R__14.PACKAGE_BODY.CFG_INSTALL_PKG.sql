CREATE OR REPLACE PACKAGE BODY "CFG_INSTALL_PKG" 
is

-- LOCAL

function replace_clob
( p_clob in clob
, p_replace_from in varchar2
, p_replace_to in varchar2
)
return clob 
is    
  l_buffer varchar2 (32767);
  l_amount binary_integer := 32767;
  l_pos integer := 1;
  l_clob_len integer;
  l_clob clob := empty_clob;
begin
  -- initalize the new clob
  dbms_lob.createtemporary( l_clob, true );
  l_clob_len := dbms_lob.getlength (p_clob);
  while l_pos < l_clob_len
  loop
    dbms_lob.read(p_clob, l_amount, l_pos, l_buffer);
    if l_buffer is not null
    then
      -- replace the text
      l_buffer := replace(l_buffer, p_replace_from, p_replace_to);
      -- write it to the new clob
      dbms_lob.writeappend(l_clob, length(l_buffer), l_buffer);
    end if;
    l_pos := l_pos + l_amount;  
  end loop;
   
  return l_clob;
end replace_clob;
   
$if cfg_pkg.c_start_stop_msg_framework $then

procedure scheduler_do
( p_oracle_tools_schema_msg in varchar2
, p_command in varchar2
)
is
  l_found boolean := false;
begin
  for r in
  ( select  '"' || o.owner || '"."' || o.object_name || '"' as fq_object_name
    from    all_objects o
    where   o.owner in (p_oracle_tools_schema_msg, upper(p_oracle_tools_schema_msg))
    and     o.object_name = 'MSG_SCHEDULER_PKG'
    and     o.object_type = 'PACKAGE BODY'
    and     o.status = 'VALID'
  )
  loop
    l_found := true;
    -- start/stop the supervisor job
    execute immediate utl_lms.format_message(q'[begin %s.do(p_command => '%s'); end;]', r.fq_object_name, p_command);
  end loop;
  if not l_found
  then
    raise_application_error
    ( -20000
    , utl_lms.format_message('While connected as %s, I could not find a valid MSG_SCHEDULER_PKG package body in schema %s.', user, p_oracle_tools_schema_msg)
    );
  end if;
end scheduler_do;

$end  

-- GLOBAL

procedure "beforeMigrate"
( p_oracle_tools_schema_msg in varchar2
)
is
begin
$if cfg_pkg.c_start_stop_msg_framework $then
  scheduler_do(p_oracle_tools_schema_msg => p_oracle_tools_schema_msg, p_command => 'stop');
$else
  null;
$end  
end "beforeMigrate";

procedure "beforeEachMigrate"
is
begin
  setup_session;
end "beforeEachMigrate";

procedure "afterMigrate"
( p_compile_all in boolean
, p_reuse_settings in boolean
, p_oracle_tools_schema_msg in varchar2
)
is
$if cfg_pkg.c_start_stop_msg_framework $then
  l_found pls_integer;
$end  
begin
  setup_session;
  compile_objects(p_compile_all => p_compile_all, p_reuse_settings => p_reuse_settings);
$if cfg_pkg.c_start_stop_msg_framework $then
  scheduler_do(p_oracle_tools_schema_msg => p_oracle_tools_schema_msg, p_command => 'start');
$end
end "afterMigrate";

-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
--
-- This procedure must be in sync with the same procedure in ../callbacks/beforeEachMigrate.sql
--
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
procedure setup_session
( p_plsql_warnings in varchar2 default 'DISABLE:ALL'
, p_plscope_settings in varchar2 default null
)
is
  l_plsql_flags varchar2(4000) := null;
  l_statement varchar2(2000) := null;
  l_found pls_integer;
begin
  -- does dbug.activate exists?
  begin
    select  1
    into    l_found
    from    all_procedures
    where   object_name = 'DBUG'
    and     procedure_name = 'ACTIVATE';
    
    l_plsql_flags := 'Debugging:true';
  exception
    when no_data_found
    then
      l_plsql_flags := 'Debugging:false';
    when too_many_rows
    then
      l_plsql_flags := 'Debugging:true';
  end;
  
  -- does ut.version (utPLSQL V3) or utconfig.showfailuresonly (utPLSQL v1 and v2) exist?
  begin
    select  1
    into    l_found
    from    all_procedures
    where   ( object_name = 'UT' and procedure_name = 'VERSION' )
    or      ( object_name = 'UTCONFIG' and procedure_name = 'SHOWFAILURESONLY' );
    
    l_plsql_flags := l_plsql_flags || ',Testing:true';
  exception
    when no_data_found
    then
      l_plsql_flags := l_plsql_flags || ',Testing:false';
    when too_many_rows
    then
      l_plsql_flags := l_plsql_flags || ',Testing:true';
  end;
  
  -- It must be possible to install PATO in a database without APEX installed.
  
  begin
    execute immediate 'begin :v := WWV_FLOW_API.C_CURRENT; end;' using out l_found;

    if l_found >= 20100513
    then
      l_plsql_flags := l_plsql_flags || ',APEX:true';
    else
      raise no_data_found;
    end if;
  exception
    when others
    then
      l_plsql_flags := l_plsql_flags || ',APEX:false';
  end;

  if l_plsql_flags is not null
  then
    l_plsql_flags := ltrim(l_plsql_flags, ',');
    -- if so, alter the session PLSQL_CCFlags and compile with debug info
    l_statement := l_statement || q'[ PLSQL_CCFlags = ']' || l_plsql_flags || q'[']';
  end if;
  
  if p_plsql_warnings is not null
  then
    l_statement := l_statement || q'[ PLSQL_WARNINGS = ']' || p_plsql_warnings || q'[']';
  end if;
  
  if p_plscope_settings is not null
  then
    l_statement := l_statement || q'[ PLSCOPE_SETTINGS = ']' || p_plscope_settings || q'[']';
  end if;

  if l_statement is not null
  then
    l_statement := 'alter session set ' || l_statement;
    execute immediate l_statement;
  end if;
end setup_session;

procedure compile_objects
( p_compile_all in boolean
, p_reuse_settings in boolean
)
is
  l_message varchar2(2047) := null; -- one less than the maximum for raise_application_error because a newline is added later on
begin
  execute immediate 'purge recyclebin'; -- do not recompile recyclebin triggers

  if p_compile_all
  then
    declare
      l_found pls_integer;
    begin
      select  1
      into    l_found
      from    table(admin_system_pkg.show_locked_objects) l
      where   rownum = 1
      ;
      raise_application_error(-20000, 'We can not recompile all objects if there are locked objects.');
    exception
      when no_data_found
      then
        null; -- OK: we will not recompile this $$PLSQL_UNIT
    end;
  end if;

  dbms_utility.compile_schema(schema => user, compile_all => p_compile_all, reuse_settings => p_reuse_settings);
  
  for r_error in
  ( select  e.*
    from    ( select  e.*, rank() over (partition by e.owner order by e.name, e.type) as rnk
              from    all_errors e
              where   e.owner = user and e.attribute = 'ERROR' -- ignore WARNINGS
              order by
                      e.owner, e.name, e.type, e.line, e.position
            ) e
    where   e.rnk = 1 -- show only the first object which contains errors
  )
  loop
    begin
      if l_message is null
      then
        l_message := r_error.type||' '||r_error.owner||'.'||r_error.name||' has errors:'||chr(10)||chr(10);
      end if;
      l_message := l_message || 'at (' || r_error.line || ',' || r_error.position || '): ' || r_error.text || chr(10);
    exception
      when value_error
      then exit;
    end;
  end loop;
  if not(l_message is null or l_message like '%Unable to set values for index UTL_RECOMP_SORT_%: does not exist or insufficient privileges%')
  then
    raise_application_error(-20000, l_message || chr(10));
  end if;
end compile_objects;

function show_compiler_messages
( p_object_schema in varchar2
, p_object_type in varchar2
, p_object_names in varchar2
, p_object_names_include in integer
, p_exclude_objects in clob
, p_include_objects in clob
, p_recompile in integer
, p_plsql_warnings in varchar2
, p_plscope_settings in varchar2
)
return t_compiler_message_tab
pipelined
is
  pragma autonomous_transaction; -- DDL is issued

  type t_obj_rec is record
  ( owner all_objects.owner%type
  , object_name all_objects.object_name%type
  , object_type all_objects.object_type%type
  , command varchar2(1000)
  , nr_deps integer
  , locked integer
  );

  c_obj sys_refcursor;

  type t_obj_tab is table of t_obj_rec;

  l_obj_tab t_obj_tab;

  r_obj t_obj_rec;

  cursor c_compiler_messages
  ( b_owner in varchar2
  , b_object_name in varchar2
  , b_object_type in varchar2
  )
  is
    with src0 as (
      select  owner
      ,       object_name
      ,       object_type
      ,       name
      ,       type
      ,       usage
      ,       usage_context_id
      ,       usage_id
      ,       line
      ,       col
      from    all_identifiers
      where   owner = b_owner
      and     object_name = b_object_name
      and     object_type = b_object_type
    ), src1 as (
      select  owner
      ,       object_name
      ,       object_type
      ,       name
      ,       type
      ,       usage
              -- Sometimes a usage_context_id does not exists as a usage_id, often when it refers to a context SYS object.
              -- In such a case use the latest definition as usage context id.
      ,       ( select  nvl(max(p.usage_id), 0)
                from    src0 p
                where   p.owner = c.owner
                and     p.object_name = c.object_name
                and     p.object_type = c.object_type
                and     ( p.usage_id = c.usage_context_id or
                          ( p.usage_id < c.usage_context_id and p.usage = 'DEFINITION' )
                        )
              ) as usage_context_id
      ,       usage_id
      ,       line
      ,       col
      from    src0 c
    )
    , src2 as (
      select  src1.*
      ,       rtrim(replace(sys_connect_by_path(case when usage = 'DEFINITION' then usage_id || '.' end, '|'), '|'), '.') as usage_id_scope
      from    src1
      start with
              usage_id = 1
      connect by  
              usage_context_id = prior usage_id
    )
    , src3 as (
      select  owner
      ,       object_name
      ,       object_type
      ,       name
      ,       type
      ,       usage
      ,       usage_context_id
      ,       usage_id
      ,       line
      ,       col
      ,       usage_id_scope
      ,       row_number() over (partition by owner, object_name, object_type, name, type, usage_id order by length(usage_id_scope) desc nulls last) as seq -- longest usage_id_scope first
      from    src2
    ), identifiers as (
      select  owner
      ,       object_name
      ,       object_type
      ,       name
      ,       type
      ,       usage
      ,       usage_context_id
      ,       usage_id
      ,       line
      ,       col
      ,       usage_id_scope
      from    src3
      where   seq = 1
    )
    , declarations as (
      select  *
      from    identifiers
      where   usage = 'DECLARATION'
    )
    , non_declarations as (
      select  i.*
      ,       di.usage_id_scope as declaration_usage_id_scope
      from    identifiers i
              left outer join declarations di
              on di.owner = i.owner and
                 di.object_name = i.object_name and
                 di.object_type = i.object_type and
                 di.name = i.name and
                 di.type = i.type and
                 i.usage_id_scope like di.usage_id_scope || '%'
      where   i.usage != 'DECLARATION'        
    )
    , unused_identifiers as (
      select  d.*
      ,       1 as message_number
      ,       'is declared but never used' as text
      from    declarations d
              left outer join non_declarations nd              
              on nd.owner = d.owner and
                 nd.object_name = d.object_name and
                 nd.object_type = d.object_type and
                 nd.name = d.name and
                 nd.type = d.type and
                 nd.declaration_usage_id_scope = d.usage_id_scope and
                 -- skip assignments to a variable/constant but not for instance to a parameter
                 not(nd.usage = 'ASSIGNMENT' and nd.type in ('VARIABLE', 'CONSTANT'))
      where   d.object_type not in ('PACKAGE', 'TYPE')
      and     d.type not in ('FUNCTION', 'PROCEDURE') -- skip unused functions/procedures
      and     nd.name is null
    )
    , assignments as (
      select  nd.*
      ,       first_value(usage_id) over (partition by owner, object_name, object_type, name, type, usage, usage_context_id order by line desc) last_usage_id
      from    non_declarations nd
      where   nd.usage = 'ASSIGNMENT'
    )
    , references as (
      select  nd.*
      ,       first_value(usage_id) over (partition by owner, object_name, object_type, name, type, usage, usage_context_id order by line asc) first_usage_id
      from    non_declarations nd
      where   nd.usage = 'REFERENCE'
    )
    , unset_identifiers as (
      -- Variables that are referenced but never assigned a value (before that reference)
      select  r.*
      ,       2 as message_number
      ,       'is referenced but never assigned a value (before that reference)' as text
      from    declarations d
              inner join non_declarations td -- type declaration via usage_context_id
              on td.usage_context_id = d.usage_id and td.type != 'REFCURSOR' -- ignore REFCURSOR variables since they are not assigned a value
              inner join references r
              on r.owner = d.owner and
                 r.object_name = d.object_name and
                 r.object_type = d.object_type and
                 r.name = d.name and
                 r.type = d.type and
                 r.declaration_usage_id_scope = d.usage_id_scope and
                 r.usage_id = r.first_usage_id -- first reference
              left outer join assignments a
              on a.owner = d.owner and
                 a.object_name = d.object_name and
                 a.object_type = d.object_type and
                 a.name = d.name and
                 a.type = d.type and
                 a.declaration_usage_id_scope = d.usage_id_scope and
                 a.usage_id < r.usage_id -- the assignment is before the (first) reference
      where   d.type in ('CONSTANT', 'VARIABLE')
      and     d.object_type not in ('PACKAGE', 'TYPE')
      and     a.name is null -- there is nu such an assignment
    )
    , assigned_unused_identifiers as (
      select  a.*
      ,       3 as message_number
      ,       'is assigned a value but never used (after that assignment)' as text
      from    declarations d
              inner join assignments a
              on a.owner = d.owner and
                 a.object_name = d.object_name and
                 a.object_type = d.object_type and
                 a.name = d.name and
                 a.type = d.type and
                 a.declaration_usage_id_scope = d.usage_id_scope and
                 a.usage_id = a.last_usage_id and
                 a.usage_context_id != d.usage_id -- last assignment (but not initialization)
              left outer join references r
              on r.owner = d.owner and
                 r.object_name = d.object_name and
                 r.object_type = d.object_type and
                 r.name = d.name and
                 r.type = d.type and
                 r.declaration_usage_id_scope = d.usage_id_scope and
                 r.usage_id > a.usage_id -- after last assignment
      where   d.type in ('CONSTANT', 'VARIABLE')
      and     d.object_type not in ('PACKAGE', 'TYPE')
      and     r.name is null -- there is none
    )
    , unset_output_parameters as (
      select  d.*
      ,       4 as message_number
      ,       '(' || replace(d.type, 'FORMAL ') || ') should be assigned a value' as text
      from    declarations d
              left outer join assignments a
              on a.owner = d.owner and
                 a.object_name = d.object_name and
                 a.object_type = d.object_type and
                 a.name = d.name and
                 a.type = d.type and
                 a.declaration_usage_id_scope = d.usage_id_scope
      where   d.type in ('FORMAL IN OUT', 'FORMAL OUT')
      and     d.object_type not in ('PACKAGE', 'TYPE')
      and     a.name is null -- there is none
    )
    , function_output_parameters as (
      select  d.*
      ,       5 as message_number
      ,       '(' || replace(d.type, 'FORMAL ') || ') should not be used in a function' as text
      from    declarations d
              inner join identifiers i
              on i.owner = d.owner and
                 i.object_name = d.object_name and
                 i.object_type = d.object_type and
                 i.usage_id = d.usage_context_id and
                 i.type = 'FUNCTION'
      where   d.type in ('FORMAL IN OUT', 'FORMAL OUT')
    )
    , shadowing_identifiers as (
      select  d2.*
      ,       6 as message_number
      ,       'may shadow another identifier with the same name declared at (' || d1.line || ',' || d1.col || ')' as text
      from    declarations d1
              inner join declarations d2
              on d2.owner = d1.owner and
                 d2.object_name = d1.object_name and
                 d2.object_type = d1.object_type and
                 d2.name = d1.name and
                 d2.usage_context_id = d1.usage_context_id and
                 d2.usage_id > d1.usage_id
      where   d1.object_type not in ('PACKAGE', 'TYPE')
      --and     d1.type not in ('ITERATOR', 'RECORD ITERATOR')
      and     d2.object_type not in ('PACKAGE', 'TYPE')
    )
    , checks as (
      select  owner
      ,       object_name
      ,       object_type
      ,       line
      ,       col
      ,       name
      ,       type
      ,       usage
      ,       usage_id
      ,       usage_context_id
      ,       message_number
      ,       text
      from    unused_identifiers
      union
      select  owner
      ,       object_name
      ,       object_type
      ,       line
      ,       col
      ,       name
      ,       type
      ,       usage
      ,       usage_id
      ,       usage_context_id
      ,       message_number
      ,       text
      from    unset_identifiers
      union
      select  owner
      ,       object_name
      ,       object_type
      ,       line
      ,       col
      ,       name
      ,       type
      ,       usage
      ,       usage_id
      ,       usage_context_id
      ,       message_number
      ,       text
      from    assigned_unused_identifiers
      union
      select  owner
      ,       object_name
      ,       object_type
      ,       line
      ,       col
      ,       name
      ,       type
      ,       usage
      ,       usage_id
      ,       usage_context_id
      ,       message_number
      ,       text
      from    unset_output_parameters 
      union
      select  owner
      ,       object_name
      ,       object_type
      ,       line
      ,       col
      ,       name
      ,       type
      ,       usage
      ,       usage_id
      ,       usage_context_id
      ,       message_number
      ,       text
      from    function_output_parameters 
      union
      select  owner
      ,       object_name
      ,       object_type
      ,       line
      ,       col
      ,       name
      ,       type
      ,       usage
      ,       usage_id
      ,       usage_context_id
      ,       message_number
      ,       text
      from    shadowing_identifiers
      order by
              owner
      ,       object_name
      ,       object_type
      ,       line
      ,       col
      ,       message_number
    )
    -- turn it into all_errors
    select  owner
    ,       object_name as name
    ,       object_type as type
    ,       rownum as sequence
    ,       line
    ,       col as position
    ,       'PLC-' || to_char(c.message_number, 'FM00000') || ': ' || case when c.type like 'FORMAL %' then 'parameter' else lower(c.type) end || ' "' || c.name || '" ' || c.text as text
    ,       'CHECK' as attribute
    ,       message_number
    from    checks c
  ;
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'SHOW_COMPILER_MESSAGES');
  dbug.print
  ( dbug."input"
  , 'p_recompile: %s; p_plsql_warnings: %s; p_plscope_settings: %s'
  , p_recompile
  , p_plsql_warnings
  , p_plscope_settings
  );
$end

  if p_recompile != 0
  then
    setup_session(p_plsql_warnings => p_plsql_warnings, p_plscope_settings => p_plscope_settings);
  end if;

  -- bulk fetch instead of loop because DDL is issued inside the loop which may impact the open cursor
  open c_obj for q'[
with obj as
( select  /*+ materialize */
          o.object_schema() as owner
  ,       o.object_name() as object_name
  ,       o.dict_object_type() as object_type
  from    table
          ( ]' || $$PLSQL_UNIT_OWNER || q'[.pkg_schema_object_filter.get_schema_objects
            ( p_schema => :p_object_schema
            , p_object_type => :p_object_type
            , p_object_names => :p_object_names
            , p_object_names_include => :p_object_names_include
            , p_grantor_is_schema => 0
            , p_exclude_objects => :p_exclude_objects 
            , p_include_objects => :p_include_objects
            )
          ) o
  where   o.dict_object_type() in
          ( 'VIEW'
          , 'PROCEDURE'
          , 'FUNCTION'
          , 'PACKAGE'
          , 'PACKAGE BODY'
          , 'TRIGGER'
          , 'TYPE'
          , 'TYPE BODY'
          , 'JAVA SOURCE'
          , 'JAVA CLASS'
          )
  and     o.object_name() not like 'BIN$%' -- Oracle 10g Recycle Bin
)
select  o.owner
,       o.object_name
,       o.object_type
,       case
          when o.object_type in ('FUNCTION', 'PACKAGE', 'PROCEDURE', 'TRIGGER', 'TYPE', 'VIEW')
          then 'ALTER ' || o.object_type || ' "' || o.object_name || '" COMPILE'
          when o.object_type in ('JAVA CLASS', 'JAVA SOURCE')
          then 'ALTER ' || o.object_type || ' "' || o.object_name || '" COMPILE'
          when instr(o.object_type, ' BODY') > 0
          then 'ALTER ' || replace(o.object_type, ' BODY') || ' "' || o.object_name || '" COMPILE BODY'
        end as command
,       ( select count(*) from all_dependencies d where d.owner = o.owner and d.type = o.object_type and d.name = o.object_name ) as nr_deps
,       l.locked
from    obj o
        left outer join ( select l.owner, l.object_name, l.object_type, 1 as locked from table(admin_system_pkg.show_locked_objects) l ) l
        on l.owner = o.owner and l.object_name = o.object_name and l.object_type = o.object_type
order by
        -- it is better to recompile first those objects that have the least number of dependencies,
        -- i.e. that impact least their dependent objects
        nr_deps
,       o.owner
,       o.object_name
,       o.object_type]'
    using p_object_schema
    ,     p_object_type
    ,     p_object_names
    ,     p_object_names_include
    ,     replace_clob(p_exclude_objects, ' ', chr(10))
    ,     replace_clob(p_include_objects, ' ', chr(10));

  fetch c_obj bulk collect into l_obj_tab;
  close c_obj;

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.print(dbug."info", '# objects: %s', l_obj_tab.count);
$end

  if l_obj_tab.count > 0
  then
    for i_idx in l_obj_tab.first .. l_obj_tab.last
    loop
      r_obj := l_obj_tab(i_idx);

$if oracle_tools.cfg_pkg.c_debugging $then
      dbug.print
      ( dbug."info"
      , 'owner: %s; object type: %s; object name: %s; command: %s; # deps: %s'
      , r_obj.owner
      , r_obj.object_type
      , r_obj.object_name
      , r_obj.command
      , r_obj.nr_deps
      );
      dbug.print
      ( dbug."info"
      , 'locked: %s'
      , r_obj.locked
      );
$end

      if p_recompile != 0 and r_obj.locked is null
      then
        begin
          execute immediate r_obj.command;
        exception
          when others
          then null;
        end;
      end if;

      for r_compiler_messages in
      ( select  e.owner
        ,       e.name
        ,       e.type
        ,       e.sequence
        ,       e.line
        ,       e.position
        ,       e.text
        ,       e.attribute
        ,       e.message_number
        from    all_errors e
        where   e.owner = r_obj.owner
        and     e.name = r_obj.object_name
        and     e.type = r_obj.object_type
        order by
                e.owner
        ,       e.name
        ,       e.type
        ,       e.sequence
        ,       e.line
        ,       e.position
      )
      loop
$if oracle_tools.cfg_pkg.c_debugging $then
        dbug.print
        ( dbug."error"
        , 'line: %s; position: %s; text: %s'
        , r_compiler_messages.line
        , r_compiler_messages.position
        , r_compiler_messages.text
        );
$end
        pipe row (r_compiler_messages);
      end loop;
      
      for r_compiler_messages in c_compiler_messages(r_obj.owner, r_obj.object_name, r_obj.object_type)
      loop
$if oracle_tools.cfg_pkg.c_debugging $then
        dbug.print
        ( dbug."warning"
        , 'line: %s; position: %s; text: %s'
        , r_compiler_messages.line
        , r_compiler_messages.position
        , r_compiler_messages.text
        );
$end
        pipe row (r_compiler_messages);
      end loop;        
    end loop;
  end if;

  commit;

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
$end

  return; -- essential
end show_compiler_messages;

function format_compiler_messages
( p_object_schema in varchar2
, p_object_type in varchar2
, p_object_names in varchar2
, p_object_names_include in integer
, p_exclude_objects in clob
, p_include_objects in clob
, p_recompile in integer
, p_plsql_warnings in varchar2
, p_plscope_settings in varchar2
)
return t_message_tab
pipelined
is
begin
  for r_message in
  ( select  lower(t.type) || ' ' || t.owner || '.' || t.name || ' ' ||
            '(' || to_char(t.line, 'FM00000') ||
            case when t.position is not null then ',' || to_char(t.position, 'FM000') end ||
            ') ' ||
            case
              when t.sequence is not null
              then 'PL/SQL'
              else 'PL/SCOPE'
            end || ' ' ||
            t.attribute || ' ' ||
            t.text as text
    from    table
            ( oracle_tools.cfg_install_pkg.show_compiler_messages
              ( p_object_schema => p_object_schema
              , p_object_type => p_object_type
              , p_object_names => p_object_names 
              , p_object_names_include => p_object_names_include 
              , p_exclude_objects => p_exclude_objects
              , p_include_objects => p_include_objects
              , p_recompile => p_recompile 
              , p_plsql_warnings => p_plsql_warnings
              , p_plscope_settings => p_plscope_settings
              )
            ) t
  )
  loop
    pipe row (r_message.text);
  end loop;

  return;
end format_compiler_messages;

end cfg_install_pkg;
/

