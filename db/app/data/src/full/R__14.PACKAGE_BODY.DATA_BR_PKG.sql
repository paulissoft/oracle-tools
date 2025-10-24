CREATE OR REPLACE PACKAGE BODY "DATA_BR_PKG" 
is

-- LOCAL

-- ORA-55610: Invalid DDL statement on history-tracked table
e_invalid_ddl_statement_on_history_tracked_table exception;
pragma exception_init(e_invalid_ddl_statement_on_history_tracked_table, -55610);

-- ORA-02297: cannot disable constraint (BONUS_DATA.CFN_PK) - dependencies exist
e_cannot_disable_constraint exception;
pragma exception_init(e_cannot_disable_constraint, -2297);

procedure enable_disable_constraint
( p_owner in varchar2
, p_table_name in varchar2
, p_enable in boolean
, p_validate_clause in varchar2
, p_constraint_name in varchar2
)
is
  l_cmd varchar2(4000 byte);
  l_sqlerrm varchar2(4000 byte);
begin
  l_cmd := utl_lms.format_message
           ( 'alter table "%s"."%s" %s %s constraint "%s"'
           , p_owner
           , p_table_name
           , case when p_enable then 'enable' else 'disable' end
           , p_validate_clause
           , p_constraint_name
           );
  execute immediate l_cmd;
exception
  when e_invalid_ddl_statement_on_history_tracked_table
  then
    l_sqlerrm := sqlerrm;
    begin
      execute immediate 'call DBMS_FLASHBACK_ARCHIVE.DISASSOCIATE_FBA(:b1, :b2)' using p_owner, p_table_name;
      execute immediate l_cmd;    
      execute immediate 'call DBMS_FLASHBACK_ARCHIVE.REASSOCIATE_FBA(:b1, :b2)' using p_owner, p_table_name;
    exception
      when others
      then
        execute immediate 'call DBMS_FLASHBACK_ARCHIVE.REASSOCIATE_FBA(:b1, :b2)' using p_owner, p_table_name;
        raise_application_error(-20000, l_cmd || ': ' || l_sqlerrm, true);
    end;
  when e_cannot_disable_constraint
  then
    null;
  when others
  then
    l_sqlerrm := sqlerrm;
    raise_application_error(-20000, l_cmd || ': ' || l_sqlerrm, true);
end enable_disable_constraint;

-- PUBLIC

procedure enable_br
( p_owner in varchar2
, p_br_name in varchar2
, p_enable in boolean
)
is
  pragma autonomous_transaction;

  l_cmd varchar2(4000 byte);
  
  l_count pls_integer := 0;
begin
$if cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT || '.ENABLE_BR');
  dbug.print
  ( dbug."input"
  , 'p_owner: %s; p_br_name: %s; p_enable: %s'
  , p_owner
  , p_br_name
  , dbug.cast_to_varchar2(p_enable)
  );
$end

  for r in
  ( select  trg.owner
    ,       trg.trigger_name
    ,       trg.status
    from    all_triggers trg
    where   trg.owner = p_owner
    and     ( trg.trigger_name like p_br_name escape '\' -- accept triggers like "my_trigger"
              or
              trg.trigger_name like upper(p_br_name) escape '\' -- normally the name is in uppercase
            )
  )
  loop
    l_count := l_count + 1;
    if ( p_enable and r.status = 'ENABLED' )
    or ( not(p_enable) and r.status = 'DISABLED' )
    then
      null; -- no action needed
    else
      begin
        l_cmd := utl_lms.format_message
                 ( 'alter trigger "%s"."%s" %s'
                 , r.owner
                 , r.trigger_name
                 , case when p_enable then 'enable' else 'disable' end
                 );
        execute immediate l_cmd;
      exception
        when e_cannot_disable_constraint
        then
          null;
        when others
        then
          raise_application_error(-20000, l_cmd || ': ' || sqlerrm, true);
      end;
    end if;
  end loop;

  for r in
  ( select  con.owner
    ,       con.table_name
    ,       con.constraint_name
    ,       con.status
    from    all_constraints con
    where   con.owner = p_owner
    and     ( con.constraint_name like p_br_name escape '\' -- accept constraints like "my_constraint"
              or
              con.constraint_name like upper(p_br_name) escape '\' -- normally the name is in uppercase
            )
    order by
            case con.constraint_type
              when 'P' then 1
              when 'U' then 2
              when 'R' then 3
              else 4
            end
  )
  loop
    l_count := l_count + 1;
    if ( p_enable and r.status = 'ENABLED' )
    or ( not(p_enable) and r.status = 'DISABLED' )
    then
      null; -- no action needed
    else
      enable_disable_constraint
      ( p_owner => r.owner
      , p_table_name => r.table_name
      , p_enable => p_enable
      , p_validate_clause => null
      , p_constraint_name => r.constraint_name
      );
    end if;
  end loop;

  if l_count = 0
  then
    raise no_data_found;
  end if;

  commit; -- for the pragma

$if cfg_pkg.c_debugging $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end enable_br;

procedure enable_br
( p_br_package_tab in t_br_package_tab
, p_br_name in varchar2
, p_enable in boolean
)
is
  l_br_found boolean := false;
  l_owner all_procedures.owner%type;
begin  
  l_owner := p_br_package_tab.first;
  while l_owner is not null
  loop
    begin
      execute immediate 'call ' || oracle_tools.data_api_pkg.dbms_assert$sql_object_name(l_owner || '.' || p_br_package_tab(l_owner) || '.enable_br', 'procedure') || '(p_br_name => :1, p_enable => :2)' using p_br_name, p_enable;
      l_br_found := true;
    exception
      when no_data_found
      then
        null;
    end;
    l_owner := p_br_package_tab.next(l_owner);
  end loop;
  if not l_br_found
  then
    raise no_data_found;
  end if;
end enable_br;  

procedure check_br
( p_owner in varchar2
, p_br_name in varchar2
, p_enable in boolean
)
is
  l_count pls_integer := 0;
begin
$if cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT || '.CHECK_BR');
  dbug.print
  ( dbug."input"
  , 'p_owner: %s; p_br_name: %s; p_enable: %s'
  , p_owner
  , p_br_name
  , dbug.cast_to_varchar2(p_enable)
  );
$end

  for r in
  ( select  trg.trigger_name
    ,       trg.status
    from    all_triggers trg
    where   trg.owner = p_owner
    and     ( trg.trigger_name like p_br_name escape '\' -- accept triggers like "my_trigger"
              or
              trg.trigger_name like upper(p_br_name) escape '\' -- normally the name is in uppercase
            )
  )
  loop
    l_count := l_count + 1;
    if ( p_enable and r.status = 'ENABLED' )
    or ( not(p_enable) and r.status = 'DISABLED' )
    then
      null; -- no action needed
    else
      raise_application_error(-20000, 'Trigger "' || r.trigger_name || '" NOT ' || case when p_enable then 'enabled' else 'disabled' end);
    end if;
  end loop;

  for r in
  ( select  con.constraint_name
    ,       con.table_name
    ,       con.status
    from    all_constraints con
    where   con.owner = p_owner
    and     ( con.constraint_name like p_br_name escape '\' -- accept constraints like "my_constraint"
              or
              con.constraint_name like upper(p_br_name) escape '\' -- normally the name is in uppercase
            )
    order by
            case con.constraint_type
              when 'P' then 1
              when 'U' then 2
              when 'R' then 3
              else 4
            end
  )
  loop
    l_count := l_count + 1;
    if ( p_enable and r.status = 'ENABLED' )
    or ( not(p_enable) and r.status = 'DISABLED' )
    then
      null; -- no action needed
    else
      raise_application_error
      ( -20000
      , 'Constraint "' || r.constraint_name || '" for table "' || r.table_name || '" NOT ' || case when p_enable then 'enabled' else 'disabled' end
      );
    end if;
  end loop;

  if l_count = 0
  then
    raise no_data_found;
  end if;

$if cfg_pkg.c_debugging $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end check_br;

procedure check_br
( p_br_package_tab in t_br_package_tab
, p_br_name in varchar2
, p_enable in boolean
)
is
  l_br_found boolean := false;
  l_owner all_procedures.owner%type;
begin  
  l_owner := p_br_package_tab.first;
  while l_owner is not null
  loop
    begin
      execute immediate 'call ' || oracle_tools.data_api_pkg.dbms_assert$sql_object_name(l_owner || '.' || p_br_package_tab(l_owner) || '.check_br', 'procedure') || '(p_br_name => :1, p_enable => :2)' using p_br_name, p_enable;
      l_br_found := true;
    exception
      when no_data_found
      then
        null;
    end;
    l_owner := p_br_package_tab.next(l_owner);
  end loop;
  if not l_br_found
  then
    raise no_data_found;
  end if;
end check_br;  

procedure refresh_mv
( p_owner in varchar2
, p_mview_name in varchar2
)
is
begin
$if cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT || '.REFRESH_MV');
  dbug.print
  ( dbug."input"
  , 'p_mview_name: %s'
  , p_mview_name
  );
$end

  for r in
  ( select  mv.mview_name
    from    all_mviews mv
    where   mv.owner = p_owner
    and     ( mv.mview_name like p_mview_name escape '\' -- accept "my_mview"
              or
              mv.mview_name like upper(p_mview_name) escape '\' -- normally the name is in uppercase
            )
  )
  loop
$if cfg_pkg.c_debugging $then
    dbug.print(dbug."info", 'r.mview_name: %s', r.mview_name);
$end
    begin
      dbms_mview.refresh(r.mview_name, 'F'); -- just checking
    exception
      when others
      then
$if cfg_pkg.c_debugging $then
        dbug.on_error;
$end
        dbms_mview.refresh(r.mview_name, 'C'); -- force a complete refresh
        dbms_mview.refresh(r.mview_name, 'F'); -- should work now
    end;
  end loop;

$if cfg_pkg.c_debugging $then
  dbug.leave;
$end
end refresh_mv;

function get_tables
( p_owner in varchar2
, p_constraint_name in varchar2
)
return sys_refcursor
is
  l_cursor sys_refcursor;
begin
$if cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT || '.GET_TABLES');
  dbug.print
  ( dbug."input"
  , 'p_owner: %s; p_constraint_name: %s'
  , p_owner
  , p_constraint_name
  );
$end

  open l_cursor for
    -- Get the table(s) with a column VALID associated with the constraint.
    -- Please note that a materialized view has dependencies on tables (including itself).
    select  distinct
            nvl(dep.referenced_owner, col1.owner) as owner
    ,       nvl(dep.referenced_name, col1.table_name) as table_name
    from    all_cons_columns col1 -- find a constraint depending on VALID
            left outer join
            ( -- get all tables with a VALID column on which a materialized view depends (except itself)
              select  dep.*
              from    all_dependencies dep
                      inner join all_tab_columns col2
                      on col2.owner = dep.referenced_owner and
                         col2.table_name = dep.referenced_name and
                         col2.column_name = 'VALID'
            ) dep
            on dep.owner = col1.owner and
               dep.name = col1.table_name and
               dep.type = 'MATERIALIZED VIEW' and
               dep.referenced_type = 'TABLE' and
               ( dep.referenced_owner != dep.owner or dep.referenced_name != dep.name )
    where   col1.owner = p_owner
    and     col1.constraint_name = p_constraint_name
    and     col1.column_name = 'VALID';

$if cfg_pkg.c_debugging $then
  dbug.leave;
$end

  return l_cursor;
end get_tables;    

function show_valid_count
( p_owner in varchar2
, p_table_name in varchar2
)
return t_valid_count_tab
pipelined
is
  l_limit constant pls_integer := 100;
  l_valid_count_tab t_valid_count_tab;
  l_cursor sys_refcursor;
begin
$if cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT || '.SHOW_VALID_COUNT');
  dbug.print
  ( dbug."input"
  , 'p_owner: %s; p_table_name: %s'
  , p_owner
  , p_table_name
  );
$end

  -- get all the tables with a column VALID
  <<table_loop>>
  for r in
  ( select  col.owner
    ,       col.table_name
    from    all_tab_columns col
    where   col.owner like upper(p_owner)
    and     col.table_name like upper(p_table_name)
    and     col.column_name = 'VALID'
    intersect -- it must be a table, not a view
    select  tab.owner
    ,       tab.table_name
    from    all_tables tab
    where   tab.owner like upper(p_owner)
  )
  loop
    open l_cursor for
      'select :owner as owner, :table_name as table_name, valid, count(*) as cnt from ' || r.owner || '.' || r.table_name || ' group by valid'
      using r.owner, r.table_name;

    <<record_loop>>
    loop
      fetch l_cursor bulk collect into l_valid_count_tab limit l_limit;

      exit record_loop when l_valid_count_tab.count = 0;

      for i_idx in l_valid_count_tab.first .. l_valid_count_tab.last
      loop
        pipe row (l_valid_count_tab(i_idx));
      end loop;

      exit when l_cursor%notfound;
    end loop record_loop;

    close l_cursor;
  end loop table_loop;

$if cfg_pkg.c_debugging $then
  dbug.leave;
$end

  return; -- essential for a pipelined function
exception
  when no_data_needed
  then
$if cfg_pkg.c_debugging $then
    dbug.leave_on_error;
$end
    null; -- not a real error, just a way to some cleanup

  when no_data_found -- verdwijnt anders in het niets omdat het een pipelined function betreft die al data ophaalt
  then
$if cfg_pkg.c_debugging $then
    dbug.leave_on_error;
$end
    raise program_error;

  when others
  then
$if cfg_pkg.c_debugging $then
    dbug.leave_on_error;
$end
    raise;
end show_valid_count;

procedure validate_table
( p_owner in varchar2
, p_table_name in varchar2
, p_commit in boolean
, p_valid in naturaln
, p_error_tab out nocopy dbms_sql.varchar2_table
)
is
  l_tab dbms_sql.urowid_table;
  l_error_count pls_integer;
  l_lwb constant pls_integer := 1;
  l_upb constant pls_integer := case when p_commit then 2 else 1 end;

  e_dml_errors exception;
  pragma exception_init(e_dml_errors, -24381);
  --   -) ORA-12048: error encountered while refreshing materialized view "BONUS_DATA"."BNS_MV_BR_OPN_5" followed by
  --      ORA-02290: check constraint (BONUS_DATA.BR_OPN_5) violated
  --   -) ORA-12008: error in materialized view or zonemap refresh path
  --      ORA-02290: check constraint (BONUS_DATA.BR_OPN_3) violated
  e_error_while_refreshing_mv exception;
  pragma exception_init(e_error_while_refreshing_mv, -12048);
  e_error_mv_refresh_path exception;
  pragma exception_init(e_error_mv_refresh_path, -12008);

  procedure add_error(p_error_message in varchar2)
  is
  begin
$if cfg_pkg.c_debugging $then
    dbug.print(dbug."info", 'p_error_message: %s', p_error_message);
$end
    p_error_tab(p_error_tab.count + 1) := p_error_message;
  end add_error;

  function validate_table_bulk(p_owner in varchar2, p_table_name in varchar2, p_last_try in boolean)
  return boolean
  is
    l_result boolean := null;
  -- Perform a bulk operation.
  begin
$if cfg_pkg.c_debugging $then
    dbug.enter($$PLSQL_UNIT || '.VALIDATE_TABLE.VALIDATE_TABLE_BULK('''||p_owner||''', '''||p_table_name||''')');
    dbug.print(dbug."input", 'p_last_try: %s', p_last_try);
$end

    -- do bulk update with save exceptions without commit first
    begin
      forall i in l_tab.first .. l_tab.last save exceptions
        execute immediate
          'update ' || oracle_tools.data_api_pkg.dbms_assert$qualified_sql_name('"' || p_owner || '"."' || p_table_name || '"', 'table') || ' t set t.valid = ' || p_valid || ' where t.rowid = :1'
          using l_tab(i);
    exception
      when e_dml_errors
      then
$if cfg_pkg.c_debugging $then
        dbug.on_error;
$end
        l_error_count := sql%bulk_exceptions.count;
        <<error_loop>>
        for i in 1 .. l_error_count
        loop
          add_error
          ( 'owner: ' ||
            p_owner ||
            '; table: ' ||
            p_table_name ||
            '; error #: ' ||
            i ||
            '; rowid: ' ||
            /*rowidtochar*/(l_tab(sql%bulk_exceptions(i).error_index)) ||
            '; error message: ' ||
            sqlerrm(-sql%bulk_exceptions(i).error_code)
          );
        end loop error_loop;
    end;

    -- now commit if specified
    begin
      if p_commit
      then
$if cfg_pkg.c_debugging $then
        dbug.print(dbug."info", 'about to commit');
$end
        commit;
      end if;
      l_result := true; -- no errors after commit (no MV exceptions)
    exception
      when others
      then
$if cfg_pkg.c_debugging $then
        dbug.on_error;
$end
        if not(p_last_try)
        then
          l_result := false; -- next try
        else
          raise; -- there is no next try so must raise
        end if;
    end;

$if cfg_pkg.c_debugging $then
    dbug.print(dbug."output", 'return: %s', l_result);
    dbug.leave;
$end

    return l_result;

$if cfg_pkg.c_debugging $then
  exception
    when others
    then
      dbug.leave_on_error;
      raise;
$end
  end validate_table_bulk;

  procedure validate_table_slow(p_owner in varchar2, p_table_name in varchar2)
  is
  -- Perform a bulk operation.
  begin
$if cfg_pkg.c_debugging $then
    dbug.enter($$PLSQL_UNIT || '.VALIDATE_TABLE.VALIDATE_TABLE_SLOW('''||p_owner||''', '''||p_table_name||''')');
$end
    /*
     * If an exception is raised due to refreshing MVs, do the update individually and commit/rollback.
     */
    <<slow_loop>>
    for i in l_tab.first .. l_tab.last
    loop
      begin
        execute immediate
          'update ' || oracle_tools.data_api_pkg.dbms_assert$qualified_sql_name('"' || p_owner || '"."' || p_table_name || '"', 'table') || ' t set t.valid = ' || p_valid || ' where t.rowid = :1'
          using l_tab(i);

$if cfg_pkg.c_debugging $then
        dbug.print(dbug."info", 'about to commit');
$end
        commit;
      exception
        when e_error_while_refreshing_mv or e_error_mv_refresh_path
        then
$if cfg_pkg.c_debugging $then
          dbug.on_error;
$end
          add_error
          ( 'table: ' ||
            p_table_name ||
            '; error #: ' ||
            i ||
            '; rowid: ' ||
            /*rowidtochar*/(l_tab(i)) ||
            '; error message: ' ||
            substr(sqlerrm, nvl(instr(sqlerrm, chr(10)), 0) + 1)
          ); -- get the second ORA error

        when others
        then
$if cfg_pkg.c_debugging $then
          dbug.on_error;
$end
          add_error
          ( 'owner: ' ||
            p_owner ||
            '; table: ' ||
            p_table_name ||
            '; error #: ' ||
            i ||
            '; rowid: ' ||
            /*rowidtochar*/(l_tab(i)) ||
            '; error message: ' ||
            sqlerrm
          );
      end;
    end loop slow_loop;

$if cfg_pkg.c_debugging $then
    dbug.leave;
  exception
    when others
    then
      dbug.leave_on_error;
      raise;
$end
  end validate_table_slow;
begin
$if cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT || '.VALIDATE_TABLE');
  dbug.print
  ( dbug."input"
  , 'p_owner: %s; p_table_name: %s; p_commit: %s'
  , p_owner
  , p_table_name
  , dbug.cast_to_varchar2(p_commit)
  );
$end

  -- get all the tables with a column VALID
  <<table_loop>>
  for r in
  ( select  col.owner
    ,       col.table_name
    from    all_tab_columns col
    where   col.owner = p_owner
    and     col.table_name like upper(p_table_name)
    and     col.column_name = 'VALID'
    intersect -- it must be an updateable table, not a view
    select  tab.owner
    ,       tab.table_name
    from    all_tables tab
            inner join all_tab_privs prv
            on prv.table_schema = tab.owner and prv.table_name = tab.table_name and prv.privilege = 'UPDATE'
    where   tab.owner = p_owner
  )
  loop
$if cfg_pkg.c_debugging $then
    dbug.print
    ( dbug."info"
    , 'owner: %s; table_name: %s'
    , r.owner
    , r.table_name
    );
$end

    execute immediate
      'select t.rowid from ' || oracle_tools.data_api_pkg.dbms_assert$qualified_sql_name('"' || r.owner || '"."' || r.table_name || '"', 'table') || ' t where t.valid != ' || p_valid
      bulk collect into l_tab;

    if l_tab.count = 0
    then
      null;
    else
      -- try bulk operation first since it is faster
      <<try_loop>>
      for i_try in l_lwb .. l_upb
      loop
        case i_try
          when 1
          then
            exit try_loop when validate_table_bulk(r.owner, r.table_name, i_try = l_upb);            

          when 2
          then
            validate_table_slow(r.owner, r.table_name);

        end case;
      end loop try_loop;
    end if; -- if l_tab.count = 0
  end loop table_loop;

$if cfg_pkg.c_debugging $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end validate_table;

procedure enable_constraints
( p_owner in varchar2
, p_table_name in varchar2
, p_constraint_name in varchar2
, p_validate_clause in varchar2
, p_stop_on_error in boolean
, p_error_tab out nocopy dbms_sql.varchar2_table -- An array of error messages for constraints that could not be enabled
)
is
begin
$if cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT || '.ENABLE_CONSTRAINTS');
  dbug.print
  ( dbug."input"
  , 'p_owner: %s; p_table_name: %s; p_table_name: %s; p_validate_clause: %s; p_stop_on_error: %s'
  , p_owner
  , p_table_name
  , p_table_name
  , p_validate_clause
  , dbug.cast_to_varchar2(p_stop_on_error)
  );
$end

  for r in 
  ( select  c.owner
    ,       c.table_name
    ,       c.constraint_name
    from    all_constraints c
    where   c.owner = p_owner
    and     c.table_name like p_table_name escape '\'
    and     c.constraint_name like p_constraint_name escape '\'
    and     c.status = 'DISABLED'
    order by
            case c.constraint_type
              when 'R'
              then 1 -- foreign keys last
              else 0
            end asc
  )
  loop
    begin
      enable_disable_constraint
      ( p_owner => r.owner
      , p_table_name => r.table_name
      , p_enable => true
      , p_validate_clause => p_validate_clause
      , p_constraint_name => r.constraint_name
      );
    exception
      when others
      then
$if cfg_pkg.c_debugging $then
        dbug.on_error;
$end        
        p_error_tab(p_error_tab.count + 1) := r.owner || '|' || r.table_name || '|' || r.constraint_name || '|' || sqlerrm;
        if p_stop_on_error then raise; end if;
    end;
  end loop;

$if cfg_pkg.c_debugging $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end enable_constraints;

procedure disable_constraints
( p_owner in varchar2
, p_table_name in varchar2
, p_constraint_name in varchar2
, p_validate_clause in varchar2
, p_stop_on_error in boolean
, p_error_tab out nocopy dbms_sql.varchar2_table -- An array of error messages for constraints that could not be enabled
)
is
begin
$if cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT || '.DISABLE_CONSTRAINTS');
  dbug.print
  ( dbug."input"
  , 'p_owner: %s; p_table_name: %s; p_table_name: %s; p_validate_clause: %s; p_stop_on_error: %s'
  , p_owner
  , p_table_name
  , p_table_name
  , p_validate_clause
  , dbug.cast_to_varchar2(p_stop_on_error)
  );
$end

  for r in 
  ( select  c.owner
    ,       c.table_name
    ,       c.constraint_name
    from    all_constraints c
    where   c.owner = p_owner
    and     c.table_name like p_table_name escape '\'
    and     c.constraint_name like p_constraint_name escape '\'
    and     c.status = 'ENABLED'
    order by
            case c.constraint_type
              when 'R'
              then 0 -- foreign keys first
              else 1
            end asc
  )
  loop
    begin
      enable_disable_constraint
      ( p_owner => r.owner
      , p_table_name => r.table_name
      , p_enable => false
      , p_validate_clause => p_validate_clause
      , p_constraint_name => r.constraint_name
      );
    exception
      when others
      then
$if cfg_pkg.c_debugging $then
        dbug.on_error;
$end        
        p_error_tab(p_error_tab.count + 1) := r.owner || '|' || r.table_name || '|' || r.constraint_name || '|' || sqlerrm;
        if p_stop_on_error then raise; end if;
    end;
  end loop;

$if cfg_pkg.c_debugging $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end disable_constraints;

procedure restore_data_integrity
( p_br_package_tab in t_br_package_tab
)
is
  l_error_tab dbms_sql.varchar2_table;
  l_fq_constraint_name varchar2(100);
  l_owner all_constraints.owner%type;
  l_table_name all_constraints.table_name%type;
  l_constraint_name all_constraints.constraint_name%type;
  l_cursor sys_refcursor;
  l_everything_ok boolean := false;

begin
$if cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT || '.RESTORE_DATA_INTEGRITY');
$end

  l_owner := p_br_package_tab.first;
  while l_owner is not null
  loop
    execute immediate 'call ' || oracle_tools.data_api_pkg.dbms_assert$sql_object_name(l_owner || '.' || p_br_package_tab(l_owner) || '.refresh_mv', 'procedure') || '(p_mview_name => ''%_MV_BR_%'')'; -- should succeed
    l_owner := p_br_package_tab.next(l_owner);
  end loop;

  <<enable_loop>>
  while not(l_everything_ok)
  loop
    begin
      enable_br(p_br_package_tab, '%', true);
      l_everything_ok := true;
    exception
      when others
      then
$if cfg_pkg.c_debugging $then
        dbug.on_error;
$end

        -- ORA-02293: cannot validate (BONUS_DATA.BR_FTN_2) - check constraint violated
        if sqlerrm not like '%ORA-02293%'
        then
          raise;
        end if;

        l_fq_constraint_name := rtrim(ltrim(regexp_substr(sqlerrm, '\([^\)]+\)'), '('), ')');
        l_owner := substr(l_fq_constraint_name, 1, instr(l_fq_constraint_name, '.')-1);
        l_constraint_name := substr(l_fq_constraint_name, instr(l_fq_constraint_name, '.')+1);

$if cfg_pkg.c_debugging $then
        dbug.print(dbug."info", 'constraint owner: %s; constraint name: %s', l_owner, l_constraint_name);
$end

        if not(l_everything_ok)
        then
          null;
        else
          raise program_error;
        end if;

        -- Get the table(s) with a column VALID associated with the constraint.
        -- Please note that a materialized view has dependencies on tables (including itself).
        l_cursor := data_br_pkg.get_tables(l_owner, l_constraint_name);

        <<table_to_validate_loop>>
        loop
          fetch l_cursor into l_owner, l_table_name;

          exit table_to_validate_loop when l_cursor%notfound;

$if cfg_pkg.c_debugging $then
          dbug.print(dbug."info", 'table name: %s.%s', l_owner, l_table_name);
$end

          execute immediate '
declare
  l_error_tab dbms_sql.varchar2_table;
begin
  ' || oracle_tools.data_api_pkg.dbms_assert$sql_object_name(l_owner || '.' || p_br_package_tab(l_owner) || '.validate_table', 'procedure') || '(p_table_name => :1, p_commit => true, p_valid => 0, p_error_tab => l_error_tab);
end;' using l_table_name;

          l_everything_ok := true; -- to signal that the constraint may be enabled successfully below
        end loop table_to_validate_loop;

        close l_cursor;

        if l_everything_ok
        then
          -- enable the constraint again: may be OK now
          -- if constraint can not be enabled an exception will be raised and we can not recover, at least not here

          l_everything_ok := false; -- for the enable_loop above
          
          enable_br(p_br_package_tab, l_constraint_name, true);
        else
          -- no data has changed so the constraint can not be enabled: just reraise
          raise;
        end if;
    end;
  end loop;

  l_owner := p_br_package_tab.first;
  while l_owner is not null
  loop
    execute immediate '
declare
  l_error_tab dbms_sql.varchar2_table;
begin
  ' || oracle_tools.data_api_pkg.dbms_assert$sql_object_name(l_owner || '.' || p_br_package_tab(l_owner) || '.validate_table', 'procedure') || '(p_commit => true, p_error_tab => l_error_tab);
end;';
    l_owner := p_br_package_tab.next(l_owner);
  end loop;

$if cfg_pkg.c_debugging $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end restore_data_integrity;

/*
function get_denormalisation_errors
( p_table_name in varchar2 default '%'
)
return t_denormalisation_error_tab
pipelined
is
  l_denormalisation_error_rec t_denormalisation_error_rec;
begin
  for r_tab in
  ( select  tab.table_name
    from    user_tables tab
    where   tab.table_name like p_table_name
    order by
            tab.table_name
  )
  loop
    l_denormalisation_error_rec.table_name := r_tab.table_name;
    
    case r_tab.table_name
      when 'BNS_COLLABORATOR_FUNCTIONS'
      then
        for r_cfn in
        ( with cfn1 as
          ( select  rowidtochar(cfn.rowid) as row_id
            ,       to_char(cfn.clr_birth_date) as value_denormalized1
            ,       ( select to_char(clr.birth_date) from bns_collaborators clr where clr.id = cfn.clr_id ) as value_calculated1
            from    bns_collaborator_functions cfn
          ), cfn2 as
          ( select  cfn.*
            ,       case
                      when cfn.value_denormalized1 || 'X' != cfn.value_calculated1 || 'X'
                      then 'CLR_BIRTH_DATE'
                    end as column_name1
            from    cfn1 cfn
          )
          select  *
          from    cfn2 cfn
          where   column_name1 is not null
        )
        loop
          l_denormalisation_error_rec.row_id := r_cfn.row_id;
          l_denormalisation_error_rec.column_name := r_cfn.column_name1;
          l_denormalisation_error_rec.value_denormalized := r_cfn.value_denormalized1;
          l_denormalisation_error_rec.value_calculated := r_cfn.value_calculated1;
          pipe row (l_denormalisation_error_rec);
        end loop;

      when 'BNS_COLLABORATORS'
      then
        -- LAST_START_DATE, LAST_CLASSIFICATION
        for r_clr in
        ( with cfn as
          ( select  cfn.clr_id
            ,       cfn.start_date
            ,       csn.code as csn_code
            ,       row_number() over (partition by cfn.clr_id order by cfn.start_date desc) as seq
            from    bns_collaborator_functions cfn
                    inner join bns_classifications csn
                    on csn.id = cfn.csn_id
          ), clr as 
          ( select  rowidtochar(clr.rowid) as row_id
            ,       case
                      when to_char(clr.last_start_date) || 'X' != to_char(cfn.start_date) || 'X'
                      then 'LAST_START_DATE'
                    end as column_name1
            ,       to_char(clr.last_start_date) as value_denormalized1
            ,       to_char(cfn.start_date) as value_calculated1
            ,       case
                      when to_char(clr.last_classification) || 'X' != to_char(cfn.csn_code) || 'X'
                      then 'LAST_CLASSIFICATION'
                    end as column_name2
            ,       to_char(clr.last_classification) as value_denormalized2
            ,       to_char(cfn.csn_code) as value_calculated2
            from    bns_collaborators clr
                    left outer join cfn on cfn.clr_id = clr.id and cfn.seq = 1
          )
          select  *
          from    clr
          where   column_name1 is not null
          or      column_name2 is not null
        )
        loop
          l_denormalisation_error_rec.row_id := r_clr.row_id;
          if r_clr.column_name1 is not null
          then
            l_denormalisation_error_rec.column_name := r_clr.column_name1;
            l_denormalisation_error_rec.value_denormalized := r_clr.value_denormalized1;
            l_denormalisation_error_rec.value_calculated := r_clr.value_calculated1;
            pipe row (l_denormalisation_error_rec);
          end if;
          if r_clr.column_name2 is not null
          then
            l_denormalisation_error_rec.column_name := r_clr.column_name2;
            l_denormalisation_error_rec.value_denormalized := r_clr.value_denormalized2;
            l_denormalisation_error_rec.value_calculated := r_clr.value_calculated2;
            pipe row (l_denormalisation_error_rec);
          end if;
        end loop;

      when 'BNS_FUNCTION_COMPANIES'
      then
        -- CPN_COUNT_WITHOUT_HRR
        for r_fcy in
        ( with fcy1 as
          ( select  rowidtochar(fcy.rowid) as row_id
            ,       to_char(fcy.cpn_count_without_hrr) as value_denormalized1
            ,       ( select  to_char(count(distinct case when hrr.id is null then cpn.id end)) -- count() does not count nulls
                      from    bns_campaigns cpn
                              left outer join bns_human_resources_advisors hrr
                              on hrr.ftn_id = fcy.ftn_id and
                                 hrr.cpy_id = fcy.cpy_id and
                                 cpn.start_date between hrr.start_date and nvl(hrr.end_date, cpn.start_date)
                    ) as value_calculated1
            from    bns_function_companies fcy
          ), fcy2 as
          ( select  fcy.*
            ,       case
                      when fcy.value_denormalized1 || 'X' != fcy.value_calculated1 || 'X'
                      then 'CPN_COUNT_WITHOUT_HRR'
                    end as column_name1
            from    fcy1 fcy
          )
          select  *
          from    fcy2 fcy
          where   fcy.column_name1 is not null
        )
        loop
          l_denormalisation_error_rec.row_id := r_fcy.row_id;
          l_denormalisation_error_rec.column_name := r_fcy.column_name1;
          l_denormalisation_error_rec.value_denormalized := r_fcy.value_denormalized1;
          l_denormalisation_error_rec.value_calculated := r_fcy.value_calculated1;
          pipe row (l_denormalisation_error_rec);
        end loop;

      when 'BNS_FUNCTIONS'
      then
        -- CPN_COUNT_WITHOUT_FDR
        for r_ftn in
        ( with ftn1 as
          ( select  rowidtochar(ftn.rowid) as row_id
            ,       to_char(ftn.cpn_count_without_fdr) as value_denormalized1
            ,       ( select  to_char(count(distinct case when fdr.id is null then cpn.id end)) -- count() does not count nulls
                      from    bns_campaigns cpn
                              left outer join bns_function_directors fdr
                              on fdr.ftn_id = ftn.id and
                                 cpn.start_date between fdr.start_date and nvl(fdr.end_date, cpn.start_date)
                    ) as value_calculated1
            from    bns_functions ftn
          ), ftn2 as
          ( select  ftn.*
            ,       case
                      when ftn.value_denormalized1 || 'X' != ftn.value_calculated1 || 'X'
                      then 'CPN_COUNT_WITHOUT_FDR'
                    end as column_name1
            from    ftn1 ftn
          )
          select  *
          from    ftn2 ftn
          where   ftn.column_name1 is not null
        )
        loop
          l_denormalisation_error_rec.row_id := r_ftn.row_id;
          l_denormalisation_error_rec.column_name := r_ftn.column_name1;
          l_denormalisation_error_rec.value_denormalized := r_ftn.value_denormalized1;
          l_denormalisation_error_rec.value_calculated := r_ftn.value_calculated1;
          pipe row (l_denormalisation_error_rec);
        end loop;

      when 'BNS_OBJECTIVE_PLANS'
      then
        -- TOTAL_WEIGHT, CPN_START_DATE, CPN_END_DATE, CFN_START_DATE, CFN_END_DATE
        for r_opn in
        ( with opn1 as 
          ( select  rowidtochar(opn.rowid) as row_id
            ,       to_char(opn.total_weight) as value_denormalized1
            ,       ( select  to_char(nvl(sum(opl.weight), 0))
                      from    bns_objective_plan_details opl
                      where   opl.opn_id = opn.id
                    ) as value_calculated1
            ,       to_char(opn.cpn_start_date) as value_denormalized2
            ,       to_char(cpn.start_date) as value_calculated2
            ,       to_char(opn.cpn_end_date) as value_denormalized3
            ,       to_char(cpn.end_date) as value_calculated3
            ,       to_char(opn.cfn_start_date) as value_denormalized4
            ,       to_char(cfn.start_date) as value_calculated4
            ,       to_char(opn.cfn_end_date) as value_denormalized5
            ,       to_char(cfn.end_date) as value_calculated5
            from    bns_objective_plans opn
                    inner join bns_collaborator_functions cfn
                    on cfn.id = opn.cfn_id
                    inner join bns_campaigns cpn
                    on cpn.id = opn.cpn_id
          ), opn2 as
          ( select  opn.*
            ,       case
                      when opn.value_denormalized1 || 'X' != opn.value_calculated1 || 'X'
                      then 'TOTAL_WEIGHT'
                    end as column_name1
            ,       case
                      when opn.value_denormalized2 || 'X' != opn.value_calculated2 || 'X'
                      then 'CPN_START_DATE'
                    end as column_name2
            ,       case
                      when opn.value_denormalized3 || 'X' != opn.value_calculated3 || 'X'
                      then 'CPN_END_DATE'
                    end as column_name3
            ,       case
                      when opn.value_denormalized4 || 'X' != opn.value_calculated4 || 'X'
                      then 'CFN_START_DATE'
                    end as column_name4
            ,       case
                      when opn.value_denormalized5 || 'X' != opn.value_calculated5 || 'X'
                      then 'CFN_END_DATE'
                    end as column_name5
            from    opn1 opn
          )
          select  *
          from    opn2 opn
          where   column_name1 is not null
          or      column_name2 is not null
          or      column_name3 is not null
          or      column_name4 is not null
          or      column_name5 is not null
        )
        loop
          l_denormalisation_error_rec.row_id := r_opn.row_id;
          if r_opn.column_name1 is not null
          then
            l_denormalisation_error_rec.column_name := r_opn.column_name1;
            l_denormalisation_error_rec.value_denormalized := r_opn.value_denormalized1;
            l_denormalisation_error_rec.value_calculated := r_opn.value_calculated1;
            pipe row (l_denormalisation_error_rec);
          end if;
          if r_opn.column_name2 is not null
          then
            l_denormalisation_error_rec.column_name := r_opn.column_name2;
            l_denormalisation_error_rec.value_denormalized := r_opn.value_denormalized2;
            l_denormalisation_error_rec.value_calculated := r_opn.value_calculated2;
            pipe row (l_denormalisation_error_rec);
          end if;
          if r_opn.column_name3 is not null
          then
            l_denormalisation_error_rec.column_name := r_opn.column_name3;
            l_denormalisation_error_rec.value_denormalized := r_opn.value_denormalized3;
            l_denormalisation_error_rec.value_calculated := r_opn.value_calculated3;
            pipe row (l_denormalisation_error_rec);
          end if;
          if r_opn.column_name4 is not null
          then
            l_denormalisation_error_rec.column_name := r_opn.column_name4;
            l_denormalisation_error_rec.value_denormalized := r_opn.value_denormalized4;
            l_denormalisation_error_rec.value_calculated := r_opn.value_calculated4;
            pipe row (l_denormalisation_error_rec);
          end if;
          if r_opn.column_name5 is not null
          then
            l_denormalisation_error_rec.column_name := r_opn.column_name5;
            l_denormalisation_error_rec.value_denormalized := r_opn.value_denormalized5;
            l_denormalisation_error_rec.value_calculated := r_opn.value_calculated5;
            pipe row (l_denormalisation_error_rec);
          end if;
        end loop;
        
      when 'BNS_SCALES'
      then
        -- SRE_COUNT, SRE_COUNT_ADJACENT
        for r_sle in
        ( with sle1 as
          ( select  rowidtochar(sle.rowid) as row_id
            ,       to_char(sle.sre_count_adjacent) as value_denormalized1
            ,       ( select  to_char(count(*))
                      from    bns_scale_ranges sre
                      connect by
                              prior sre.sle_id = sre.sle_id
                      and     prior sre.upper_limit_excl = sre.lower_limit_incl
                      start with
                              -- the next condition is a little bit intuitive but it works
                              -- (would expect "sre.upper_limit_excl is null" to work, but no)
                              sre.lower_limit_incl = 0 
                      and     sre.sle_id = sle.id
                    ) as value_calculated1
            ,       to_char(sle.sre_count) as value_denormalized2
            ,       ( select  to_char(count(*))
                      from    bns_scale_ranges sre
                      where   sre.sle_id = sle.id
                    ) as value_calculated2
            from    bns_scales sle
          ), sle2 as
          ( select  sle.*
            ,       case
                      when sle.value_denormalized1 || 'X' != sle.value_calculated1 || 'X'
                      then 'SRE_COUNT_ADJACENT'
                    end as column_name1
            ,       case
                      when sle.value_denormalized2 || 'X' != sle.value_calculated2 || 'X'
                      then 'SRE_COUNT'
                    end as column_name2
            from    sle1 sle
          )
          select  *
          from    sle2 sle
          where   column_name1 is not null
          or      column_name2 is not null
        )
        loop
          l_denormalisation_error_rec.row_id := r_sle.row_id;
          if r_sle.column_name1 is not null
          then
            l_denormalisation_error_rec.column_name := r_sle.column_name1;
            l_denormalisation_error_rec.value_denormalized := r_sle.value_denormalized1;
            l_denormalisation_error_rec.value_calculated := r_sle.value_calculated1;
            pipe row (l_denormalisation_error_rec);
          end if;
          if r_sle.column_name2 is not null
          then
            l_denormalisation_error_rec.column_name := r_sle.column_name2;
            l_denormalisation_error_rec.value_denormalized := r_sle.value_denormalized2;
            l_denormalisation_error_rec.value_calculated := r_sle.value_calculated2;
            pipe row (l_denormalisation_error_rec);
          end if;
        end loop;
        
      when 'BNS_TEMPLATE_OBJECTIVE_PLANS'
      then
        -- TOTAL_WEIGHT
        for r_ton in
        ( with ton1 as 
          ( select  rowidtochar(ton.rowid) as row_id
            ,       to_char(ton.total_weight) as value_denormalized1
            ,       ( select  to_char(nvl(sum(tol.weight), 0))
                      from    bns_tpl_objective_plan_details tol
                      where   tol.ton_id = ton.id
                    ) as value_calculated1
            from    bns_template_objective_plans ton
          ), ton2 as
          ( select  ton.*
            ,       case
                      when ton.value_denormalized1 || 'X' != ton.value_calculated1 || 'X'
                      then 'TOTAL_WEIGHT'
                    end as column_name1
            from    ton1 ton
          )
          select  *
          from    ton2 ton
          where   column_name1 is not null
        )
        loop
          l_denormalisation_error_rec.row_id := r_ton.row_id;
          if r_ton.column_name1 is not null
          then
            l_denormalisation_error_rec.column_name := r_ton.column_name1;
            l_denormalisation_error_rec.value_denormalized := r_ton.value_denormalized1;
            l_denormalisation_error_rec.value_calculated := r_ton.value_calculated1;
            pipe row (l_denormalisation_error_rec);
          end if;
        end loop;
        
      else
        null;
    end case;
  end loop;

  return; -- essential for a pipelined function
end get_denormalisation_errors;

function denormalisation_error_count
( p_table_name in varchar2 default '%'
)
return integer
is
  l_count pls_integer;
begin
  select  count(*)
  into    l_count
  from    table(data_api_pkg.get_denormalisation_errors(p_table_name));
  
  return l_count;
end denormalisation_error_count;
*/

end DATA_BR_PKG;
/

