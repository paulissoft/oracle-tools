declare

-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
--
-- This procedure must be in sync with the same procedure in ../full/R__14.PACKAGE_BODY.CFG_INSTALL_PKG.sql
--
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
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

begin
  setup_session;
end;
/
