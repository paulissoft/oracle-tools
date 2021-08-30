CREATE OR REPLACE PACKAGE BODY "CFG_INSTALL_PKG" 
is

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

end cfg_install_pkg;
/

