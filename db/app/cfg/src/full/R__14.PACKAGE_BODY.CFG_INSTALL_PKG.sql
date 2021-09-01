CREATE OR REPLACE PACKAGE BODY "CFG_INSTALL_PKG" 
is

-- LOCAL

type t_longops_rec is record (
  rindex binary_integer
, slno binary_integer
, sofar binary_integer
, totalwork binary_integer
, op_name varchar2(64 char)
, units varchar2(10 char)
, target_desc varchar2(32 char)
);

-- forward declaration
procedure longops_show
( p_longops_rec in out nocopy t_longops_rec
, p_increment in naturaln default 1
);

function longops_init
( p_target_desc in varchar2
, p_totalwork in binary_integer default 0
, p_op_name in varchar2 default 'fetch'
, p_units in varchar2 default 'rows'
)
return t_longops_rec
is
  l_longops_rec t_longops_rec;
begin
  l_longops_rec.rindex := dbms_application_info.set_session_longops_nohint;
  l_longops_rec.slno := null;
  l_longops_rec.sofar := 0;
  l_longops_rec.totalwork := p_totalwork;
  l_longops_rec.op_name := p_op_name;
  l_longops_rec.units := p_units;
  l_longops_rec.target_desc := p_target_desc;

  longops_show(l_longops_rec, 0);

  return l_longops_rec;
end longops_init;

procedure longops_show
( p_longops_rec in out nocopy t_longops_rec
, p_increment in naturaln default 1
)
is
begin
  p_longops_rec.sofar := p_longops_rec.sofar + p_increment;
  dbms_application_info.set_session_longops( rindex => p_longops_rec.rindex
                                           , slno => p_longops_rec.slno
                                           , op_name => p_longops_rec.op_name
                                           , sofar => p_longops_rec.sofar
                                           , totalwork => p_longops_rec.totalwork
                                           , target_desc => p_longops_rec.target_desc
                                           , units => p_longops_rec.units
                                           );
end longops_show;                                             

procedure longops_done
( p_longops_rec in out nocopy t_longops_rec
)
is
begin
  if p_longops_rec.totalwork = p_longops_rec.sofar
  then
    null; -- nothing has changed and dbms_application_info.set_session_longops() would show a duplicate
  else
    p_longops_rec.totalwork := p_longops_rec.sofar;
    longops_show(p_longops_rec, 0);
  end if;
end longops_done;

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

function show_compile_errors
( p_object_names in varchar2
, p_object_names_include in integer
, p_plsql_warnings in varchar2
)
return t_errors_tab
pipelined
is
  pragma autonomous_transaction; -- DDL is issued

  l_object_name_tab constant sys.odcivarchar2list :=
    list2collection
    ( p_value_list => replace(replace(replace(p_object_names, chr(9)), chr(10)), chr(13))
    , p_sep => ','
    , p_ignore_null => 1
    );
    
  l_object_name_type_tab sys.odcivarchar2list := sys.odcivarchar2list();
  
  cursor c_obj is
    select  o.object_name
    ,       o.object_type
    ,       case
              when o.object_type in ('FUNCTION', 'PACKAGE', 'PROCEDURE', 'TRIGGER', 'TYPE', 'VIEW')
              then 'ALTER ' || o.object_type || ' ' || o.object_name || ' COMPILE'
              when o.object_type in ('JAVA CLASS', 'JAVA SOURCE')
              then 'ALTER ' || o.object_type || ' "' || o.object_name || '" COMPILE'
              when instr(o.object_type, ' BODY') > 0
              then 'ALTER ' || replace(o.object_type, ' BODY') || ' ' || o.object_name || ' COMPILE BODY'
            end as command
    ,       ( select count(*) from user_dependencies d where d.type = o.object_type and d.name = o.object_name ) as nr_deps
    from    user_objects o
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
    and     o.object_name != $$PLSQL_UNIT -- do not recompile this package (body)
    and     ( p_object_names_include is null or
              ( p_object_names_include  = 0 and o.object_name not in ( select trim(t.column_value) from table(l_object_name_tab) t ) ) or
              ( p_object_names_include != 0 and o.object_name     in ( select trim(t.column_value) from table(l_object_name_tab) t ) )
            )
    order by
            nr_deps;

  type t_obj_tab is table of c_obj%rowtype;

  l_obj_tab t_obj_tab;

  r_obj c_obj%rowtype;

  -- dbms_application_info stuff
  l_longops_rec t_longops_rec;
begin
  setup_session(p_plsql_warnings => p_plsql_warnings);

  open c_obj;
  fetch c_obj bulk collect into l_obj_tab;
  close c_obj;

  l_longops_rec := longops_init(p_target_desc => 'SHOW_COMPILE_ERRORS', p_totalwork => l_obj_tab.count, p_op_name => 'compile', p_units => 'objects');

  if l_obj_tab.count > 0
  then
    for i_idx in l_obj_tab.first .. l_obj_tab.last
    loop
      r_obj := l_obj_tab(i_idx);
      
      l_object_name_type_tab.extend(1);
      l_object_name_type_tab(l_object_name_type_tab.last) := r_obj.object_name || '|' || r_obj.object_type;

      begin
        execute immediate r_obj.command;
      exception
        when others
        then null;
      end;

      longops_show(l_longops_rec);
    end loop;
  end if;

  longops_done(l_longops_rec);

  for r_err in
  ( select  e.*
    from    user_errors e
    where   e.name || '|' || e.type in ( select trim(t.column_value) from table(l_object_name_type_tab) t )
    order by
            e.name
    ,       e.type
    ,       e.sequence
  )
  loop
    pipe row (r_err);
  end loop;

  commit;

  return; -- essential
end show_compile_errors;

end cfg_install_pkg;
/

