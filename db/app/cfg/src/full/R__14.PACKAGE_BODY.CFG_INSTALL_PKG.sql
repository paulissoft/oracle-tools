CREATE OR REPLACE PACKAGE BODY "CFG_INSTALL_PKG" 
is

-- LOCAL

function list2collection
( p_value_list in varchar2
, p_sep in varchar2
, p_ignore_null in naturaln
)
return sys.odcivarchar2list
is
  l_collection sys.odcivarchar2list;
  l_max_pos constant integer := 32767; -- or 4000
begin
$if cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT || '.LIST2COLLECTION');
  dbug.print(dbug."input", 'p_sep: %s; p_value_list: %s; p_ignore_null: %s', p_sep, p_value_list, p_ignore_null);
$end

  select  t.value
  bulk collect
  into    l_collection
  from    ( select  substr(str, pos + 1, lead(pos, 1, l_max_pos) over(order by pos) - pos - 1) value
            from    ( select  str
                      ,       instr(str, p_sep, 1, level) pos
                      from    ( select  p_value_list as str
                                from    dual
                                where   rownum <= 1
                              )
                      connect by
                              level <= length(str) - nvl(length(replace(str, p_sep)), 0) /* number of separators */ + 1
                    )
          ) t
  where   ( p_ignore_null = 0 or t.value is not null );

$if cfg_pkg.c_debugging $then
  dbug.print(dbug."output", 'l_collection.count: %s', case when l_collection is not null then l_collection.count end);
  dbug.leave;
$end

  return l_collection;
end list2collection;

-- GLOBAL

procedure afterMigrate
( p_compile_all in boolean
, p_reuse_settings in boolean
)
is
begin
  setup_session;
  compile_objects(p_compile_all => p_compile_all, p_reuse_settings => p_reuse_settings);
end afterMigrate;

procedure beforeEachMigrate
is
begin
  setup_session;
end beforeEachMigrate;

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

-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
--
-- This procedure must be in sync with the same procedure in ../callbacks/afterMigrate.sql
--
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
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
      from    user_objects o
      where   o.object_type = 'PACKAGE'
      and     o.object_name = $$PLSQL_UNIT
      ;
      raise_application_error(-20000, 'We can not recompile all objects if this package (' || $$PLSQL_UNIT || ') is part of the objects to recompile.');
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
( p_object_schema in varchar2 default user
, p_object_type in varchar2 default null
, p_object_names in varchar2 default null
, p_object_names_include in integer default null
, p_recompile in integer default 0
, p_plsql_warnings in varchar2 default 'ENABLE:ALL'
, p_plscope_settings in varchar2 default 'IDENTIFIERS:ALL'
)
return t_compiler_message_tab
pipelined
is
  pragma autonomous_transaction; -- DDL is issued

  l_object_type constant all_objects.object_type%type :=
    case
      when p_object_type like '%\_SPEC' escape '\' -- meta
      then replace(p_object_type, '_SPEC', null)
      when p_object_type like '%\_BODY' escape '\' -- meta
      then replace(p_object_type, '_', ' ')
      else p_object_type
    end;
    
  l_object_name_tab constant sys.odcivarchar2list :=
    list2collection
    ( p_value_list => replace(replace(replace(p_object_names, chr(9)), chr(10)), chr(13))
    , p_sep => ','
    , p_ignore_null => 1
    );

  cursor c_obj
  ( b_object_schema in varchar2
  , b_object_type in varchar2
  , b_object_name_tab in sys.odcivarchar2list
  , b_object_names_include in integer
  , b_recompile in integer
  )
  is
    select  o.owner
    ,       o.object_name
    ,       o.object_type
    ,       case
              when o.object_type in ('FUNCTION', 'PACKAGE', 'PROCEDURE', 'TRIGGER', 'TYPE', 'VIEW')
              then 'ALTER ' || o.object_type || ' ' || o.object_name || ' COMPILE'
              when o.object_type in ('JAVA CLASS', 'JAVA SOURCE')
              then 'ALTER ' || o.object_type || ' "' || o.object_name || '" COMPILE'
              when instr(o.object_type, ' BODY') > 0
              then 'ALTER ' || replace(o.object_type, ' BODY') || ' ' || o.object_name || ' COMPILE BODY'
            end as command
    ,       ( select count(*) from all_dependencies d where d.owner = o.owner and d.type = o.object_type and d.name = o.object_name ) as nr_deps
    from    all_objects o
    where   o.object_type in
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
    and     o.object_name not like 'BIN$%' -- Oracle 10g Recycle Bin
    and     o.owner = b_object_schema
    and     ( b_object_type is null or o.object_type = b_object_type )                  
    and     ( b_object_names_include is null or
              ( b_object_names_include  = 0 and o.object_name not in ( select trim(t.column_value) from table(b_object_name_tab) t ) ) or
              ( b_object_names_include != 0 and o.object_name     in ( select trim(t.column_value) from table(b_object_name_tab) t ) )
            )
    order by
            -- it is better to recompile first those objects that have the least number of dependencies,
            -- i.e. that impact least their dependent objects
            case when b_recompile != 0 then nr_deps end
    ,       o.owner
    ,       o.object_name
    ,       o.object_type
    ;

  type t_obj_tab is table of c_obj%rowtype;

  l_obj_tab t_obj_tab;

  r_obj c_obj%rowtype;

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
  if p_recompile != 0
  then
    setup_session(p_plsql_warnings => p_plsql_warnings, p_plscope_settings => p_plscope_settings);
  end if;

  -- bulk fetch instead of loop because DDL is issued inside the loop which may impact the open cursor
  open c_obj(p_object_schema, l_object_type, l_object_name_tab, nvl(p_object_names_include, 1), p_recompile);
  fetch c_obj bulk collect into l_obj_tab;
  close c_obj;

  if l_obj_tab.count > 0
  then
    for i_idx in l_obj_tab.first .. l_obj_tab.last
    loop
      r_obj := l_obj_tab(i_idx);

      if p_recompile != 0 and r_obj.object_name != $$PLSQL_UNIT -- do not recompile this package (body)
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
        pipe row (r_compiler_messages);
      end loop;
      
      for r_compiler_messages in c_compiler_messages(r_obj.owner, r_obj.object_name, r_obj.object_type)
      loop
        pipe row (r_compiler_messages);
      end loop;        
    end loop;
  end if;

  commit;

  return; -- essential
end show_compiler_messages;

function format_compiler_messages
( p_object_schema in varchar2 default user
, p_object_type in varchar2 default null
, p_object_names in varchar2 default null
, p_object_names_include in integer default null
, p_recompile in integer default 0
, p_plsql_warnings in varchar2 default 'ENABLE:ALL'
, p_plscope_settings in varchar2 default 'IDENTIFIERS:ALL'
)
return t_message_tab
pipelined
is
begin
  for r_message in
  ( select  lower(t.type) || ' ' || t.owner || '.' || t.name || ' ' ||
            '(' || t.line ||
            case when t.position is not null then ',' || t.position end ||
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

