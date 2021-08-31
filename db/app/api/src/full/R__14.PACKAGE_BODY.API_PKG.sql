CREATE OR REPLACE PACKAGE BODY "API_PKG" -- -*-coding: utf-8-*-
is

-- LOCAL

$if cfg_pkg.c_testing $then

function called_by_utplsql
return boolean
is
  l_dynamic_depth pls_integer := utl_call_stack.dynamic_depth;
begin
  -- API_PKG.UT_SETUP
  -- API_PKG.UT_SETUP_AUTONOMOUS_TRANSACTION
  -- API_PKG.UT_SETUP
  -- BNS_PKG_CPN.UT_SETUP
  -- __anonymous_block
  -- DBMS_SQL.EXECUTE
  -- UT_EXECUTABLE.DO_EXECUTE
  -- UT_SUITE.DO_EXECUTE
  -- UT_SUITE_ITEM.DO_EXECUTE
  -- UT_LOGICAL_SUITE.DO_EXECUTE
  -- UT_RUN.DO_EXECUTE
  -- UT_SUITE_ITEM.DO_EXECUTE
  -- UT_RUNNER.RUN
  -- __anonymous_block

  for i_idx in 1 .. l_dynamic_depth
  loop
    if utl_call_stack.subprogram(i_idx)(1) = 'UT_EXECUTABLE'
    then
      return true;
    end if;
  end loop;

  return false;
end called_by_utplsql;

procedure ut_setup
( p_br_package_tab in data_br_pkg.t_br_package_tab
, p_insert_procedure in all_procedures.object_name%type
)
is
  l_dynamic_depth pls_integer := utl_call_stack.dynamic_depth;
begin
$if cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT || '.UT_SETUP');

  for i_idx in 1 .. l_dynamic_depth
  loop
    dbug.print
    ( dbug."info"
    , 'dynamic depth: %s; lexical depth: %s; owner: %s; unit line: %s; subprogram: %s'
    , i_idx
    , utl_call_stack.lexical_depth(i_idx)
    , utl_call_stack.owner(i_idx)
    , utl_call_stack.unit_line(i_idx)
    , utl_call_stack.concatenate_subprogram(utl_call_stack.subprogram(i_idx))
    );
  end loop;
$end

  data_br_pkg.check_br(p_br_package_tab => p_br_package_tab, p_br_name => '%', p_enable => true);
  
  if p_insert_procedure is not null
  then
    execute immediate 'begin ' || p_insert_procedure || '; end;';
  end if;

$if cfg_pkg.c_debugging $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end ut_setup;

procedure ut_setup_at -- ut_setup_autonomous_transaction too long before Oracle 12CR2
( p_br_package_tab in data_br_pkg.t_br_package_tab
, p_insert_procedure in all_procedures.object_name%type
)
is
  pragma autonomous_transaction;
begin
  -- enable_br('%', true);
  data_br_pkg.restore_data_integrity(p_br_package_tab => p_br_package_tab);
  ut_setup(p_br_package_tab, p_insert_procedure);
  commit;
end ut_setup_at;

procedure ut_teardown
( p_br_package_tab in data_br_pkg.t_br_package_tab
, p_delete_procedure in all_procedures.object_name%type
)
is
begin
  data_br_pkg.check_br(p_br_package_tab => p_br_package_tab, p_br_name => '%', p_enable => true);
  if p_delete_procedure is not null
  then
    execute immediate 'begin ' || p_delete_procedure || '; end;';
  end if;
end ut_teardown;

procedure ut_teardown_at -- ut_teardown_autonomous_transaction too long before Oracle 12CR2
( p_br_package_tab in data_br_pkg.t_br_package_tab
, p_delete_procedure in all_procedures.object_name%type
)
is
begin
  data_br_pkg.enable_br(p_br_package_tab => p_br_package_tab, p_br_name => '%', p_enable => true);
  ut_teardown(p_br_package_tab, p_delete_procedure);
  commit;
end ut_teardown_at;

$end -- $if cfg_pkg.c_testing $then

-- GLOBAL

function get_data_owner
return all_objects.owner%type
is
begin
  return data_api_pkg.get_owner;
end get_data_owner;

function show_cursor
( p_cursor in t_cur
)
return t_tab
pipelined
is
  l_limit constant pls_integer := 100;
  l_tab t_tab;
begin
$if cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT || '.SHOW_CURSOR');
$end

  loop
    fetch p_cursor bulk collect into l_tab limit l_limit;

    exit when l_tab.count = 0;

    for i_idx in l_tab.first .. l_tab.last
    loop
      pipe row (l_tab(i_idx));
    end loop;

    exit when p_cursor%notfound;
  end loop;

$if cfg_pkg.c_debugging $then
  dbug.leave;
$end

  return;
end show_cursor;

function translate_error
( p_sqlerrm in varchar2
, p_function in varchar2
)
return varchar2
is
  l_sqlerrm constant varchar2(32767 char) := utl_i18n.unescape_reference(p_sqlerrm);
  l_generic_exception constant varchar2(100 char) := 'ORA' || to_char(data_api_pkg.c_exception) || ': %';
  l_separator_expr constant varchar2(100 char) := '[^' || data_api_pkg."#" || ']+';
  l_error_code varchar2(2000 char) := null;
  l_error_message varchar2(2000 char) := null;
begin
$if cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT || '.TRANSLATE_ERROR');
  dbug.print
  ( dbug."input"
  , 'p_function: %s; l_sqlerrm: %s'
  , p_function
  , l_sqlerrm
  );
$end

  if l_sqlerrm like l_generic_exception
  then
$if cfg_pkg.c_debugging $then
    dbug.print(dbug."info", 'Generic exception; l_separator_expr: %s; first txt: %s', l_separator_expr, regexp_substr(l_sqlerrm, l_separator_expr, 1, 1)); 
$end

    for r in
    ( select  regexp_substr(l_sqlerrm, l_separator_expr, 1, level) as txt
      ,       (level-2) as nr
      from    dual
      connect by
              regexp_substr(l_sqlerrm, l_separator_expr, 1, level) is not null
    )
    loop
$if cfg_pkg.c_debugging $then
      dbug.print(dbug."info", 'r.nr: %s; r.txt: %s', r.nr, r.txt);
$end

      case r.nr
        when -1 -- ORA-20001:
        then
          null;

        when 0 -- the error code
        then
          l_error_code := r.txt;

          execute immediate 'begin :1 := ' || p_function || '(:2); end;' using out l_error_message, in l_error_code;

$if cfg_pkg.c_debugging $then
          dbug.print(dbug."info", 'l_error_code: %s; l_error_message: %s', l_error_code, l_error_message); 
$end

        else -- param 1, 2, 3, etcetera
          l_error_message := replace(l_error_message, '<p' || r.nr || '>', r.txt);

$if cfg_pkg.c_debugging $then
          dbug.print(dbug."info", 'l_error_message: %s', l_error_message);
$end

      end case;
    end loop;
$if cfg_pkg.c_debugging $then
  else
    dbug.print(dbug."info", 'Error does not match: %s', l_generic_exception); 
$end
  end if;

  if l_error_message is not null
  then
    -- GJP 2020-03-02  Preprend the error code to get a better error message
    l_error_message := l_error_code || ': ' || l_error_message;
  else
    l_error_message := l_sqlerrm;
  end if;

$if cfg_pkg.c_debugging $then
  dbug.print(dbug."output", 'return: %s', nvl(l_error_message, l_sqlerrm));
  dbug.leave;
$end

  return nvl(l_error_message, l_sqlerrm);

$if cfg_pkg.c_debugging $then
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end translate_error;

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

function excel_date_number2date
( p_date_number in integer
)
return date
deterministic
is
begin
  /*
  --
  -- Excel gives each date a numeric value starting at 1st January 1900.
  -- 1st January 1900 has a numeric value of 1, the 2nd January 1900 has a numeric value of 2 and so on.
  -- These are called ‘date serial numbers’, and they enable us to do math calculations and use dates in formulas.
  --
  -- Caution! Excel dates after 28th February 1900 are actually one day out. Excel behaves as though the date 29th February 1900 existed, which it didn't.
  */
  return ( to_date('01/01/1900', 'dd/mm/yyyy') - case when p_date_number <= 31 + 28 then 1 else 2 end ) + p_date_number;
end excel_date_number2date;

procedure ut_expect_violation
( p_br_name in varchar2
, p_sqlcode in integer
, p_sqlerrm in varchar2
, p_data_owner in all_tables.owner%type
)
is
begin
$if cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT || '.UT_EXPECT_VIOLATION');
  dbug.print
  ( dbug."input"
  , 'p_br_name: %s; p_sqlcode: %s; p_sqlerrm: %s; p_data_owner: %s'
  , p_br_name
  , p_sqlcode
  , p_sqlerrm
  , p_data_owner
  );
$end

  case
    when p_sqlcode in (data_api_pkg.c_exception, data_api_pkg.c_check_constraint, data_api_pkg.c_unique_constraint, data_api_pkg.c_fk_non_transferable)
    then
      if p_sqlcode = data_api_pkg.c_exception and
         -- ORA-20001: #BR_CFN_5#[08-DEC-14, ]#[08-NOV-14, 08-DEC-14]#2907
         ( substr(p_sqlerrm, instr(p_sqlerrm, ':')+2) = '#' || p_br_name or
           substr(p_sqlerrm, instr(p_sqlerrm, ':')+2) like '#' || p_br_name || '#_%'
         )
      then
        null;
      elsif p_sqlcode in (data_api_pkg.c_check_constraint, data_api_pkg.c_unique_constraint) and
            p_sqlerrm like '%(' || p_data_owner || '.' || p_br_name || ')%'
      then
        null;
      elsif p_sqlcode in (data_api_pkg.c_fk_non_transferable, data_api_pkg.c_cannot_update_to_null) and
            p_sqlerrm like '%' || p_br_name || '%'
      then
        -- RAISE_APPLICATION_ERROR(-20225, 'Non Transferable FK constraint  on table BNS_TPL_OBJECTIVE_PLAN_DETAILS is violated');
        null;
      else
        raise_application_error(-20000, 'The business rule "' || p_br_name || '" is not part of the error "' || p_sqlerrm || '"');
      end if;

    else
      raise_application_error(-20000, 'Unknown sqlcode: ' || p_sqlcode);
  end case;

$if cfg_pkg.c_debugging $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end ut_expect_violation;

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
begin
  cfg_install_pkg.setup_session(p_plsql_warnings => p_plsql_warnings);

  for r_obj in
  ( select  o.object_name
    ,       o.object_type
    ,       case
              when o.object_type in ('FUNCTION', 'PACKAGE', 'PROCEDURE', 'TRIGGER', 'TYPE', 'VIEW')
              then 'ALTER ' || o.object_type || ' ' || o.object_name || ' COMPILE'
              when o.object_type in ('JAVA CLASS', 'JAVA SOURCE')
              then 'ALTER ' || o.object_type || ' "' || o.object_name || '" COMPILE'
              when instr(o.object_type, ' BODY') > 0
              then 'ALTER ' || replace(o.object_type, ' BODY') || ' ' || o.object_name || ' COMPILE BODY'
            end as command
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
  )
  loop
    l_object_name_type_tab.extend(1);
    l_object_name_type_tab(l_object_name_type_tab.last) := r_obj.object_name || '|' || r_obj.object_type;
    
    execute immediate r_obj.command;    
  end loop;

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

procedure dbms_output_enable
( p_db_link in varchar2
, p_buffer_size in integer default null
)
is
begin
  -- check SQL injection
  if dbms_assert.simple_sql_name(p_db_link) is null
  then
    raise value_error;
  end if;

  execute immediate
    utl_lms.format_message('call dbms_output.enable@%s(:b1)', p_db_link)
    using p_buffer_size;
end dbms_output_enable;

procedure dbms_output_clear
( p_db_link in varchar2
)
is
begin
  -- check SQL injection
  if dbms_assert.simple_sql_name(p_db_link) is null
  then
    raise value_error;
  end if;

  execute immediate
    utl_lms.format_message
    ( '
declare 
  l_line varchar2(32767 char); 
  l_status integer; 
begin 
  dbms_output.get_line@%s(l_line, l_status);
end;'
    , p_db_link
    );
end dbms_output_clear;    

procedure dbms_output_flush
( p_db_link in varchar2
)
is
begin
  -- check SQL injection
  if dbms_assert.simple_sql_name(p_db_link) is null
  then
    raise value_error;
  end if;

  execute immediate
    utl_lms.format_message
    ( '
declare
  l_line varchar2(32767 char);
  l_status integer;
begin
  loop
    dbms_output.get_line@%s(line => l_line, status => l_status);
    exit when l_status != 0;
    dbms_output.put_line(l_line);
  end loop;
end;'
    , p_db_link
    );
end dbms_output_flush;

$if cfg_pkg.c_testing $then

procedure ut_setup
( p_autonomous_transaction in boolean
, p_br_package_tab in data_br_pkg.t_br_package_tab
, p_init_procedure in all_procedures.object_name%type
, p_insert_procedure in all_procedures.object_name%type
)
is
begin
$if cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT || '.UT_SETUP');
  dbug.print
  ( dbug."input"
  , 'p_autonomous_transaction: %s; p_br_package_tab.count; p_init_procedure: %s; p_insert_procedure: %s'
  , dbug.cast_to_varchar2(p_autonomous_transaction)
  , p_br_package_tab.count
  , p_init_procedure
  , p_insert_procedure
  );
$end

  if p_init_procedure is not null
  then
    execute immediate 'begin ' || p_init_procedure || '; end;';
  end if;

  case
    when p_autonomous_transaction
    then ut_setup_at(p_br_package_tab, p_insert_procedure);
    else ut_setup(p_br_package_tab, p_insert_procedure);
  end case;

$if cfg_pkg.c_debugging $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end ut_setup;

procedure ut_teardown
( p_autonomous_transaction in boolean
, p_br_package_tab in data_br_pkg.t_br_package_tab
, p_init_procedure in all_procedures.object_name%type
, p_delete_procedure in all_procedures.object_name%type
)
is
begin
$if cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT || '.UT_TEARDOWN');
  dbug.print
  ( dbug."input"
  , 'p_autonomous_transaction: %s; p_br_package_tab: %s; p_init_procedure: %s; p_delete_procedure: %s'
  , dbug.cast_to_varchar2(p_autonomous_transaction)
  , p_br_package_tab.count
  , p_init_procedure
  , p_delete_procedure
  );
$end

  if p_init_procedure is not null
  then
    execute immediate 'begin ' || p_init_procedure || '; end;';
  end if;

  case
    when p_autonomous_transaction
    then ut_teardown_at(p_br_package_tab, p_delete_procedure);
    when called_by_utplsql
    then null; -- a rollback to savepoint will be executed by UTPLSQL
    else ut_teardown(p_br_package_tab, p_delete_procedure);
  end case;

$if cfg_pkg.c_debugging $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end ut_teardown;

-- UNIT TEST

procedure ut_excel_date_number2date
is
begin
  -- 1 is 01/01/1900
  ut.expect(excel_date_number2date(1)).to_equal(to_date('01/01/1900', 'dd/mm/yyyy'));
  -- 31 jan 1990
  ut.expect(excel_date_number2date(31)).to_equal(to_date('31/01/1900', 'dd/mm/yyyy'));
  -- 28 feb 1990
  ut.expect(excel_date_number2date(31+28)).to_equal(to_date('28/02/1900', 'dd/mm/yyyy'));
  -- 29 february 1990 exists according to Excel but not for Oracle
  ut.expect(excel_date_number2date(31+29)).to_equal(to_date('28/02/1900', 'dd/mm/yyyy'));
  -- 1 mar 1990
  ut.expect(excel_date_number2date(31+30)).to_equal(to_date('01/03/1900', 'dd/mm/yyyy'));
  ut.expect(excel_date_number2date(44123)).to_equal(to_date('19/10/2020', 'dd/mm/yyyy'));
  ut.expect(excel_date_number2date(44124)).to_equal(to_date('20/10/2020', 'dd/mm/yyyy'));
  ut.expect(excel_date_number2date(44125)).to_equal(to_date('21/10/2020', 'dd/mm/yyyy'));
end ut_excel_date_number2date;

$end -- $if cfg_pkg.c_testing $then

end API_PKG;
/

