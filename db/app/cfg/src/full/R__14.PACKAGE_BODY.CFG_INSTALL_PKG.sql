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

procedure "afterMigrate"
( p_compile_all in boolean
, p_reuse_settings in boolean
)
is
begin
  setup_session;
  compile_objects(p_compile_all => p_compile_all, p_reuse_settings => p_reuse_settings);
end "afterMigrate";

procedure "beforeEachMigrate"
is
begin
  setup_session;
end "beforeEachMigrate";

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

end cfg_install_pkg;
/

