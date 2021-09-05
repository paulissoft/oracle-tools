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
  if l_message is not null
  then
    raise_application_error(-20000, l_message || chr(10));
  end if;
end compile_objects;

function show_compiler_messages
( p_object_schema in varchar2 default user
, p_object_names in varchar2 default null
, p_object_names_include in integer default null
, p_recompile in integer default 0
, p_plsql_warnings in varchar2 default 'ENABLE:ALL'
, p_plscope_settings in varchar2 default 'IDENTIFIERS:ALL'
)
return t_compiler_messages_tab
pipelined
is
  pragma autonomous_transaction; -- DDL is issued

  l_object_name_tab constant sys.odcivarchar2list :=
    list2collection
    ( p_value_list => replace(replace(replace(p_object_names, chr(9)), chr(10)), chr(13))
    , p_sep => ','
    , p_ignore_null => 1
    );
    
  cursor c_obj is
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
    and     o.owner = p_object_schema
    and     ( p_object_names_include is null or
              ( p_object_names_include  = 0 and o.object_name not in ( select trim(t.column_value) from table(l_object_name_tab) t ) ) or
              ( p_object_names_include != 0 and o.object_name     in ( select trim(t.column_value) from table(l_object_name_tab) t ) )
            )
    order by
            case when p_recompile != 0 then nr_deps end
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
    with identifiers as
    ( select  name
      ,       type
      ,       usage
      ,       line
      ,       first_value(line) over (partition by name, usage order by line asc) first_line
      ,       first_value(line) over (partition by name, usage order by line desc) last_line
      from    all_identifiers
      where   owner = b_owner
      and     object_name = b_object_name
      and     object_type = b_object_type
      and     type in ('VARIABLE', 'CONSTANT', 'EXCEPTION')
    ), last_assignments as -- the last assignment of every identifier
    ( select  *
      from    identifiers
      where   usage = 'ASSIGNMENT'
      and     line = last_line
    ), last_references as  -- the last reference of every identifier
    ( select  *
      from    identifiers
      where   usage = 'REFERENCE'
      and     line = last_line
    ), first_references as -- the first reference of every identifier
    ( select  *
      from    identifiers
      where   usage = 'REFERENCE'
      and     line = first_line
    ), first_assignments as -- the first assignment of every identifier
    ( select  *
      from    identifiers
      where   usage = 'ASSIGNMENT'
      and     line = first_line
    )
    , declarations     -- the declaration for every identifier
    as
    ( select  *
      from    identifiers
      where   usage = 'DECLARATION'
    )
    select  b_owner as owner
    ,       b_object_name as name
    ,       b_object_type as type
    ,       to_number(null) as sequence
    ,       case
              when lr.line is null
              then la.line
              when la.line > lr.line
              then la.line
              else lr.line
            end as line
    ,       to_number(null) as position       
    ,       case
              when lr.line is null or la.line > lr.line
              then la.type || ' ' || la.name || ' has not been used after this assignment'
            end as text
    ,       'WARNING' as attribute
    ,       to_number(null) as message_number
    from    last_assignments la
            left outer join
            last_references  lr
            on lr.name = la.name
    where   la.type != 'CONSTANT'
    and     ( lr.line is null or la.line > lr.line )
    union all
    select  b_owner as owner
    ,       b_object_name as name
    ,       b_object_type as type
    ,       null as sequence
    ,       case
              when la.line is null
              then lr.line
            end as line
    ,       to_number(null) as position       
    ,       case
              when la.line is null
              then lr.type || ' ' || lr.name || ' has not been initialized (assigned a value)'
            end as text
    ,       'WARNING' as attribute
    ,       to_number(null) as message_number
    from    last_assignments la
            right outer join
            last_references  lr
            on lr.name = la.name
            inner join declarations de
            on de.name = lr.name
    where   la.line is null
    union all
    select  b_owner as owner
    ,       b_object_name as name
    ,       b_object_type as type
    ,       null as sequence
    ,       case
              when fa.line > fr.line
              then fr.line
            end as line
    ,       null as position       
    ,       case
              when fa.line > fr.line
              then fa.type || ' ' || fa.name || ' has not been been initialized (assigned a value)'
            end as text
    ,       'WARNING' as attribute
    ,       null as message_number
    from    first_assignments fa
            inner join
            first_references  fr
            on fr.name = fa.name
    where   fa.line > fr.line       
    union all
    select  b_owner as owner
    ,       b_object_name as name
    ,       b_object_type as type
    ,       null as sequence
    ,       case
              when fr.line is null
              then de.line
            end as line
    ,       null as position       
    ,       case
              when fr.line is null
              then de.type || ' ' || de.name || ' has been declared but never used'
            end as text
    ,       'WARNING' as attribute
    ,       null as message_number
    from    declarations de
            left outer join
            last_references fr
            on fr.name = de.name
    where   fr.line is null
    order by
            owner
    ,       name
    ,       type
    ,       sequence
    ,       line
    ,       position
  ;
begin
  if p_object_names is not null and p_object_names_include is null
  then
    raise value_error;
  end if;
  
  if p_recompile != 0
  then
    setup_session(p_plsql_warnings => p_plsql_warnings, p_plscope_settings => p_plscope_settings);
  end if;

  open c_obj;
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

end cfg_install_pkg;
/

