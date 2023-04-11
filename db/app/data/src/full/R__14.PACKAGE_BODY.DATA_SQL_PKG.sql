CREATE OR REPLACE PACKAGE BODY "DATA_SQL_PKG" 
is

function empty_column_value_tab
return column_value_tab_t
is
  l_column_value_tab column_value_tab_t;
begin
  return l_column_value_tab;
end;

procedure do
( p_operation in varchar2 -- (S)elect, (I)nsert, (U)pdate or (D)elete
, p_table_name in varchar2
, p_bind_variable_tab in column_value_tab_t -- only when an entry exists that table column will be used in the query or DML
, p_statement in statement_t -- if null it will default to 'select * from <table>'
, p_order_by in varchar2
, p_owner in varchar2 -- the owner of the table
, p_max_row_count in positive default null
, p_column_value_tab in out nocopy column_value_tab_t -- only when an entry exists that table column will be used in the query or DML
)
is
  l_where_clause statement_t := null;
  l_statement statement_t := null;
  l_stmt statement_t := null;
  l_cursor integer := null;
  l_nr_rows_processed pls_integer;
  l_column_name all_tab_columns.column_name%type;

$if data_sql_pkg.c_column_value_is_anydata $then

  type column_date_tab_t is table of dbms_sql.date_table index by binary_integer;
  type column_number_tab_t is table of dbms_sql.number_table index by binary_integer;
  type column_varchar2_tab_t is table of dbms_sql.varchar2_table index by binary_integer;

  l_column_date_tab column_date_tab_t;
  l_column_number_tab column_number_tab_t;
  l_column_varchar2_tab column_varchar2_tab_t;

$end -- $if data_sql_pkg.c_column_value_is_anydata $then

  cursor c_col is
    select  tc.column_name
    ,       tc.data_type
    ,       tc.data_length
    ,       cc.pk_key_position
    from    all_tab_columns tc
            left outer join 
            ( select  cc.owner
              ,       cc.table_name
              ,       cc.column_name
              ,       cc.position as pk_key_position
              from    all_cons_columns cc
                      inner join all_constraints c
                      on c.owner = cc.owner and c.table_name = cc.table_name and c.constraint_type = 'P'
            ) cc
            on cc.owner = tc.owner and cc.table_name = tc.table_name and cc.column_name = tc.column_name
    where   tc.owner = p_owner
    and     tc.table_name = p_table_name
    order by
            tc.column_id;

  type column_tab_t is table of c_col%rowtype index by binary_integer;

  l_column_tab column_tab_t;

  function bind_variable
  ( p_column_name in varchar2
  )
  return varchar2
  is
  begin
    return ':B_' || p_column_name || '$';
  end bind_variable;

  function empty_bind_variable
  ( p_column_value in anydata_t
  )
  return boolean
  is
  begin
    return p_column_value is null;
  end empty_bind_variable;

  procedure construct_statement
  is
  begin
    -- construct statement
    for r in c_col
    loop
      continue when not(p_column_value_tab.exists(r.column_name));

      l_column_tab(l_column_tab.count+1) := r;

      case p_operation
        when 'S'
        then
          if l_stmt is null
          then
            l_stmt := 'select  ';
          else
            l_stmt := l_stmt || chr(10) || ',       ';
          end if;
          l_stmt := l_stmt || '"' || r.column_name || '"';
        else
          raise e_unimplemented_feature;
      end case;
    end loop;

    case p_operation
      when 'S'
      then
        l_column_name := p_bind_variable_tab.first;
        while l_column_name is not null
        loop
          if not(empty_bind_variable(p_bind_variable_tab(l_column_name)))
          then
            l_where_clause := 
              utl_lms.format_message
              ( '%s"%s" = %s'
              , case when l_where_clause is null then ' where ' else ' and ' end
              , l_column_name
              , bind_variable(l_column_name)
              );
          end if;
          l_column_name := p_bind_variable_tab.next(l_column_name);
        end loop;

        l_statement :=
          nvl
          ( p_statement
          , utl_lms.format_message
            ( 'select * from "%s"."%s"%s'
            , p_owner
            , p_table_name
            , l_where_clause
            )
          ) ||
          case
            when p_order_by is not null
            then ' order by ' || p_order_by
          end;

        l_stmt := l_stmt || chr(10) || 'from    (' || l_statement || ')';
      else
        raise e_unimplemented_feature;
    end case;

$if cfg_pkg.c_debugging $then
    dbug.print(dbug."debug", 'statement: %s', l_stmt);
$end  
  end construct_statement;

  procedure set_bind_variables
  is
    procedure set_bind_variable
    ( p_column_name in varchar2
    , p_column_value in anydata_t
    )
    is
      l_bind_variable constant all_tab_columns.column_name%type := bind_variable(p_column_name);
    begin
      case p_column_value.gettypename()
        when 'SYS.DATE'     then dbms_sql.bind_variable(l_cursor, l_bind_variable, p_column_value.AccessDate());
        when 'SYS.NUMBER'   then dbms_sql.bind_variable(l_cursor, l_bind_variable, p_column_value.AccessNumber());
        when 'SYS.VARCHAR2' then dbms_sql.bind_variable(l_cursor, l_bind_variable, p_column_value.AccessVarchar2());
          
        else raise e_unimplemented_feature;
      end case;
    end set_bind_variable;
  begin
    l_column_name := p_bind_variable_tab.first;
    while l_column_name is not null
    loop
      if not(empty_bind_variable(p_bind_variable_tab(l_column_name)))
      then
        set_bind_variable
        ( l_column_name
        , p_bind_variable_tab(l_column_name)
        );
      end if;
      l_column_name := p_bind_variable_tab.next(l_column_name);
    end loop;
  end;

  function fetch_limit
  return positiven
  is
  begin
    return
      case
        when p_max_row_count is null
        then 100
        when p_max_row_count = 1
        then 2 -- to detect too many rows
        else least(100, p_max_row_count)
      end;        
  end fetch_limit;

  procedure define_columns
  is
    l_fetch_limit constant positiven := fetch_limit;
  begin
    <<column_loop>>
    for i_idx in l_column_tab.first .. l_column_tab.last
    loop
      case l_column_tab(i_idx).data_type
        when 'DATE'
        then
          l_column_date_tab(i_idx)(1) := null; -- column_value will put it in here
          l_column_date_tab(i_idx).delete;
          dbms_sql.define_array(c => l_cursor, position => i_idx, d_tab => l_column_date_tab(i_idx), cnt => l_fetch_limit, lower_bound => 1);
          
        when 'NUMBER'
        then
          l_column_number_tab(i_idx)(1) := null;
          l_column_number_tab(i_idx).delete;
          dbms_sql.define_array(c => l_cursor, position => i_idx, n_tab => l_column_number_tab(i_idx), cnt => l_fetch_limit, lower_bound => 1);

        when 'VARCHAR2'
        then
          l_column_varchar2_tab(i_idx)(1) := null;
          l_column_varchar2_tab(i_idx).delete;
          dbms_sql.define_array(c => l_cursor, position => i_idx, c_tab => l_column_varchar2_tab(i_idx), cnt => l_fetch_limit, lower_bound => 1);

        else
          raise e_unimplemented_feature;
      end case;
    end loop;    
  end define_columns;

  procedure fetch_rows_and_columns
  is
    l_rows_fetched pls_integer; -- # rows fetched for last dbms_sql.fetch_rows()
    l_row_count pls_integer := 0; -- total row count
    l_fetch_limit constant positiven := fetch_limit;
  begin
    <<fetch_loop>>
    loop
      l_rows_fetched := dbms_sql.fetch_rows(l_cursor);

$if cfg_pkg.c_debugging $then
      dbug.print(dbug."debug", '# rows fetched: %s', l_rows_fetched);
$end  

      exit fetch_loop when l_rows_fetched = 0;

      l_row_count := l_row_count + l_rows_fetched;
      
      if p_max_row_count = 1 and l_row_count > p_max_row_count -- must fetch one more than needed for too_many_rows
      then
        raise too_many_rows;
      end if;

      <<column_loop>>
      for i_idx in l_column_tab.first .. l_column_tab.last
      loop
        case l_column_tab(i_idx).data_type
          when 'DATE'
          then
            dbms_sql.column_value(l_cursor, i_idx, l_column_date_tab(i_idx));
              
$if cfg_pkg.c_debugging $then
            dbug.print
            ( dbug."debug"
            , 'row: %s; column: %s; value: %s'
            , l_row_count
            , l_column_tab(i_idx).column_name
            , to_char(l_column_date_tab(i_idx)(l_column_date_tab(i_idx).last), 'yyyy-mm-dd hh24:mi:ss')
            );
$end

            if l_column_date_tab(i_idx).count <> l_row_count
            then
              raise program_error;
            end if;
              
          when 'NUMBER'
          then
            dbms_sql.column_value(l_cursor, i_idx, l_column_number_tab(i_idx));

$if cfg_pkg.c_debugging $then
            dbug.print
            ( dbug."debug"
            , 'row: %s; column: %s; value: %s'
            , l_row_count
            , l_column_tab(i_idx).column_name
            , to_char(l_column_number_tab(i_idx)(l_column_number_tab(i_idx).last))
            );
$end  

            if l_column_number_tab(i_idx).count <> l_row_count
            then
              raise program_error;
            end if;

          when 'VARCHAR2'
          then
            dbms_sql.column_value(l_cursor, i_idx, l_column_varchar2_tab(i_idx));

$if cfg_pkg.c_debugging $then
            dbug.print
            ( dbug."debug"
            , 'row: %s; column: %s; value: %s'
            , l_row_count
            , l_column_tab(i_idx).column_name
            , l_column_varchar2_tab(i_idx)(l_column_varchar2_tab(i_idx).last)
            );
$end  

            if l_column_varchar2_tab(i_idx).count <> l_row_count
            then
              raise program_error;
            end if;

          else
            raise e_unimplemented_feature;
        end case;
      end loop column_loop;
      
      if p_max_row_count > 1 and l_row_count >= p_max_row_count -- no need to fetch more
      then
        exit fetch_loop;
      end if;      

      exit fetch_loop when l_rows_fetched < l_fetch_limit;
    end loop fetch_loop;

    -- now copy the arrays to p_column_value_tab
    <<column_loop>>
    for i_idx in l_column_tab.first .. l_column_tab.last
    loop
      case l_column_tab(i_idx).data_type
        when 'DATE'
        then
          if p_max_row_count = 1
          then
            case l_column_date_tab(i_idx).count
              when 0
              then raise no_data_found;
              when 1
              then null;
              else raise too_many_rows;
            end case;
            p_column_value_tab(l_column_tab(i_idx).column_name) := anydata.ConvertDate(l_column_date_tab(i_idx)(1));
          else
            p_column_value_tab(l_column_tab(i_idx).column_name) := anydata.ConvertCollection(l_column_date_tab(i_idx));
          end if;
          
        when 'NUMBER'
        then
          if p_max_row_count = 1
          then
            case l_column_number_tab(i_idx).count
              when 0
              then raise no_data_found;
              when 1
              then null;
              else raise too_many_rows;
            end case;
            p_column_value_tab(l_column_tab(i_idx).column_name) := anydata.ConvertNumber(l_column_number_tab(i_idx)(1));
          else
            p_column_value_tab(l_column_tab(i_idx).column_name) := anydata.ConvertCollection(l_column_number_tab(i_idx));
          end if;

        when 'VARCHAR2'
        then
          if p_max_row_count = 1
          then
            case l_column_varchar2_tab(i_idx).count
              when 0
              then raise no_data_found;
              when 1
              then null;
              else raise too_many_rows;
            end case;
            p_column_value_tab(l_column_tab(i_idx).column_name) := anydata.ConvertVarchar2(l_column_varchar2_tab(i_idx)(1));
          else
            p_column_value_tab(l_column_tab(i_idx).column_name) := anydata.ConvertCollection(l_column_varchar2_tab(i_idx));
          end if;
          
        else
          raise e_unimplemented_feature;
      end case;
    end loop column_loop;
  end fetch_rows_and_columns;

  procedure cleanup
  is
  begin
    if dbms_sql.is_open(l_cursor)
    then
      dbms_sql.close_cursor(l_cursor);
    end if;
  end cleanup;
begin
$if cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.DO (1)');
  dbug.print
  ( dbug."input"
  , 'p_operation: %s; table: %s; p_statement: %s; p_max_row_count: %s'
  , p_operation
  , '"' || p_owner || '"."' || p_table_name || '"'
  , p_statement
  , p_max_row_count
  );
$end

  construct_statement;
  
  l_cursor := dbms_sql.open_cursor;

  begin
    dbms_sql.parse(l_cursor, l_stmt, dbms_sql.native);
$if cfg_pkg.c_debugging $then
  exception
    when others
    then
      dbug.print(dbug."error", 'statement: %s', l_stmt);
      raise;
$end      
  end;

  if p_bind_variable_tab.count > 0
  then  
    set_bind_variables;
  end if;
  
  -- query? define columns
  case p_operation
    when 'S'
    then define_columns;
    else raise e_unimplemented_feature;
  end case;

  l_nr_rows_processed := dbms_sql.execute(l_cursor);

  -- query? fetch rows and columns
  case p_operation
    when 'S'
    then fetch_rows_and_columns;
    else raise e_unimplemented_feature;
  end case;

  cleanup;

$if cfg_pkg.c_debugging $then
  dbug.leave;
$end
exception
  when others
  then
    cleanup;
$if cfg_pkg.c_debugging $then
    dbug.leave_on_error;
$end
    raise;
end do;

function empty_statement_tab
return statement_tab_t
is
  l_statement_tab statement_tab_t;
begin
  return l_statement_tab;
end empty_statement_tab;

function empty_max_row_count_tab
return max_row_count_tab_t
is
  l_max_row_count_tab max_row_count_tab_t;
begin
  return l_max_row_count_tab;
end empty_max_row_count_tab;

procedure do
( p_operation in varchar2
, p_parent_table_name in varchar2
, p_table_bind_variable_tab in table_column_value_tab_t
, p_statement_tab in statement_tab_t
, p_order_by_tab in statement_tab_t
, p_owner in varchar2
, p_max_row_count_tab in max_row_count_tab_t
, p_table_column_value_tab in out nocopy table_column_value_tab_t
)
is
  l_table_name all_tab_columns.table_name%type;
  l_table_name_tab sys.odcivarchar2list := sys.odcivarchar2list();
begin
  -- parent at the beginning unless p_operation = 'D' -- Delete
  if p_operation <> 'D'
  then
    l_table_name_tab.extend(1);
    l_table_name_tab(l_table_name_tab.last) := p_parent_table_name;
  end if;

  l_table_name := p_table_column_value_tab.first;
  while l_table_name is not null
  loop
    if l_table_name <> p_parent_table_name
    then
      l_table_name_tab.extend(1);
      l_table_name_tab(l_table_name_tab.last) := l_table_name;
    end if;
    
    l_table_name := p_table_column_value_tab.next(l_table_name);
  end loop;

  -- parent at the beginning for p_operation = 'D' -- Delete
  if p_operation = 'D'
  then
    l_table_name_tab.extend(1);
    l_table_name_tab(l_table_name_tab.last) := p_parent_table_name;
  end if;

  for i_idx in l_table_name_tab.first .. l_table_name_tab.last
  loop
    l_table_name := l_table_name_tab(i_idx);
    do
    ( p_operation => p_operation
    , p_table_name => l_table_name
    , p_bind_variable_tab => case when p_table_bind_variable_tab.exists(l_table_name) then p_table_bind_variable_tab(l_table_name) else empty_column_value_tab end
    , p_statement => case when p_statement_tab.exists(l_table_name) then p_statement_tab(l_table_name) end
    , p_order_by => case when p_order_by_tab.exists(l_table_name) then p_order_by_tab(l_table_name) end
    , p_owner => p_owner
    , p_max_row_count => case when p_max_row_count_tab.exists(l_table_name) then p_max_row_count_tab(l_table_name) end
    , p_column_value_tab => p_table_column_value_tab(l_table_name)
    );
  end loop;
end do;

$if cfg_pkg.c_testing $then

--%suitepath(DATA)
--%suite

--%beforeall
procedure ut_setup
is
  pragma autonomous_transaction;
begin
  execute immediate '
CREATE TABLE MY_DEPT (
  DEPTNO NUMBER(2) CONSTRAINT PK_DEPT PRIMARY KEY,
  DNAME VARCHAR2(14),
  LOC VARCHAR2(13)
)';

  execute immediate '
CREATE TABLE MY_EMP (
  EMPNO NUMBER(4) CONSTRAINT PK_EMP PRIMARY KEY,
  ENAME VARCHAR2(10),
  JOB VARCHAR2(9),
  MGR NUMBER(4),
  HIREDATE DATE,
  SAL NUMBER(7,2),
  COMM NUMBER(7,2),
  DEPTNO NUMBER(2) CONSTRAINT FK_DEPTNO REFERENCES MY_DEPT
)';

execute immediate q'[
begin
  insert into my_dept values (10,'ACCOUNTING','NEW YORK');
  insert into my_dept values (20,'RESEARCH','DALLAS');
  insert into my_dept values (30,'SALES','CHICAGO');
  insert into my_dept values (40,'OPERATIONS','BOSTON');

  insert into my_emp values (7369,'SMITH','CLERK',7902,to_date('17-12-1980','dd-mm-yyyy'),800,null,20);
  insert into my_emp values (7499,'ALLEN','SALESMAN',7698,to_date('20-2-1981','dd-mm-yyyy'),1600,300,30);
  insert into my_emp values (7521,'WARD','SALESMAN',7698,to_date('22-2-1981','dd-mm-yyyy'),1250,500,30);
  insert into my_emp values (7566,'JONES','MANAGER',7839,to_date('2-4-1981','dd-mm-yyyy'),2975,null,20);
  insert into my_emp values (7654,'MARTIN','SALESMAN',7698,to_date('28-9-1981','dd-mm-yyyy'),1250,1400,30); 
  insert into my_emp values (7698,'BLAKE','MANAGER',7839,to_date('1-5-1981','dd-mm-yyyy'),2850,null,30);
  insert into my_emp values (7782,'CLARK','MANAGER',7839,to_date('9-6-1981','dd-mm-yyyy'),2450,null,10);
  insert into my_emp values (7788,'SCOTT','ANALYST',7566,to_date('13-JUL-87','dd-mm-rr')-85,3000,null,20);
  insert into my_emp values (7839,'KING','PRESIDENT',null,to_date('17-11-1981','dd-mm-yyyy'),5000,null,10);
  insert into my_emp values (7844,'TURNER','SALESMAN',7698,to_date('8-9-1981','dd-mm-yyyy'),1500,0,30);
  insert into my_emp values (7876,'ADAMS','CLERK',7788,to_date('13-JUL-87', 'dd-mm-rr')-51,1100,null,20);
  insert into my_emp values (7900,'JAMES','CLERK',7698,to_date('3-12-1981','dd-mm-yyyy'),950,null,30);
  insert into my_emp values (7902,'FORD','ANALYST',7566,to_date('3-12-1981','dd-mm-yyyy'),3000,null,20);
  insert into my_emp values (7934,'MILLER','CLERK',7782,to_date('23-1-1982','dd-mm-yyyy'),1300,null,10);
end;]';

  commit;
end ut_setup;

procedure ut_teardown
is
  pragma autonomous_transaction;
begin
  execute immediate 'drop table my_emp purge';
  execute immediate 'drop table my_dept purge';
  
  commit;
end ut_teardown;

procedure ut_do_emp
is
  l_bind_variable_tab column_value_tab_t;
  l_column_value_tab column_value_tab_t;
  l_column_value all_tab_columns.column_name%type;
  l_date_tab dbms_sql.date_table;
  l_number_tab dbms_sql.number_table;
  l_varchar2_tab dbms_sql.varchar2_table;
begin
$if cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.UT_DO_EMP');
$end


  l_bind_variable_tab('DEPTNO') := anydata.ConvertNumber(20);

  l_column_value_tab('EMPNO') := null;
  l_column_value_tab('JOB') := null;
  l_column_value_tab('HIREDATE') := null;
  l_column_value_tab('DEPTNO') := null;
  
  do
  ( p_operation => 'S'
  , p_table_name => 'MY_EMP'
  , p_bind_variable_tab => l_bind_variable_tab
  , p_order_by => 'EMPNO'
  , p_column_value_tab => l_column_value_tab
  );

  ut.expect(l_column_value_tab.count, '# columns').to_equal(4);

  l_column_value := l_column_value_tab.first;
  while l_column_value is not null
  loop
    case
      when l_column_value in ('EMPNO', 'DEPTNO')
      then
        ut.expect(l_column_value_tab(l_column_value).gettypename(), 'data type ' || l_column_value).to_equal('SYS.NUMBER_TABLE');
        ut.expect(l_column_value_tab(l_column_value).GetCollection(l_number_tab), 'get collection ' || l_column_value).to_equal(DBMS_TYPES.SUCCESS);
        ut.expect(l_number_tab.count, 'collection count ' || l_column_value).to_equal(5);
        ut.expect(l_number_tab(1), 'element #1 for column ' || l_column_value).to_equal(case l_column_value when 'EMPNO' then 7369 else 20 end);
        ut.expect(l_number_tab(5), 'element #5 for column ' || l_column_value).to_equal(case l_column_value when 'EMPNO' then 7902 else 20 end);
        
      when l_column_value in ('JOB')
      then
        ut.expect(l_column_value_tab(l_column_value).gettypename(), 'data type ' || l_column_value).to_equal('SYS.VARCHAR2_TABLE');
        ut.expect(l_column_value_tab(l_column_value).GetCollection(l_varchar2_tab), 'get collection ' || l_column_value).to_equal(DBMS_TYPES.SUCCESS);
        ut.expect(l_varchar2_tab.count, 'collection count ' || l_column_value).to_equal(5);
        ut.expect(l_varchar2_tab(1), 'element #1 for column ' || l_column_value).to_equal('CLERK');
        ut.expect(l_varchar2_tab(5), 'element #5 for column ' || l_column_value).to_equal('ANALYST');
        
      when l_column_value in ('HIREDATE')
      then
        ut.expect(l_column_value_tab(l_column_value).gettypename(), 'data type ' || l_column_value).to_equal('SYS.DATE_TABLE');
        ut.expect(l_column_value_tab(l_column_value).GetCollection(l_date_tab), 'get collection ' || l_column_value).to_equal(DBMS_TYPES.SUCCESS);
        ut.expect(l_date_tab.count, 'collection count ' || l_column_value).to_equal(5);
        ut.expect(l_date_tab(1), 'element #1 for column ' || l_column_value).to_equal(to_date('17-12-1980','dd-mm-yyyy'));
        ut.expect(l_date_tab(5), 'element #5 for column ' || l_column_value).to_equal(to_date('3-12-1981','dd-mm-yyyy'));
    end case;

    l_column_value := l_column_value_tab.next(l_column_value);
  end loop;

  -- get employees for department 0 (i_try 0), all (i_try 1) or 20 (i_try 2) check no_data_found / too_many_rows
  for i_try in 0..2
  loop
    begin
      l_bind_variable_tab('DEPTNO') := case when i_try <> 1 then anydata.ConvertNumber(i_try * 10) else null end;
      do
      ( p_operation => 'S'
      , p_table_name => 'MY_EMP'
      , p_bind_variable_tab => l_bind_variable_tab
      , p_max_row_count => case when i_try < 2 then 1 else 5 end
      , p_column_value_tab => l_column_value_tab
      );
      if i_try <> 2
      then
        raise program_error; -- should not come here
      end if;
    exception
      when no_data_found
      then if i_try <> 0 then raise; end if;
      when too_many_rows
      then if i_try <> 1 then raise; end if;
    end;
  end loop;

$if cfg_pkg.c_debugging $then
  dbug.leave;
$end
end;

procedure ut_do_dept
is
begin
$if cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.UT_DO_DEPT');
$end

  raise e_unimplemented_feature;

$if cfg_pkg.c_debugging $then
  dbug.leave;
$end
end;

--%test
procedure ut_do_emp_dept
is
begin
$if cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.UT_DO_EMP_DEPT');
$end

  raise e_unimplemented_feature;

$if cfg_pkg.c_debugging $then
  dbug.leave;
$end
end;

procedure ut_check_types
is
  l_clob_table1 dbms_sql.clob_table;
  l_clob_table2 dbms_sql.clob_table;
  l_binary_float_table1 dbms_sql.binary_float_table;
  l_binary_float_table2 dbms_sql.binary_float_table;
  l_binary_double_table1 dbms_sql.binary_double_table;
  l_binary_double_table2 dbms_sql.binary_double_table;
  l_blob_table1 dbms_sql.blob_table;
  l_blob_table2 dbms_sql.blob_table;
  l_bfile_table1 dbms_sql.bfile_table;
  l_bfile_table2 dbms_sql.bfile_table;
  l_date_table1 dbms_sql.date_table;
  l_date_table2 dbms_sql.date_table;
  l_number_table1 dbms_sql.number_table;
  l_number_table2 dbms_sql.number_table;
  l_urowid_table1 dbms_sql.urowid_table;
  l_urowid_table2 dbms_sql.urowid_table;
  l_varchar2_table1 dbms_sql.varchar2_table;
  l_varchar2_table2 dbms_sql.varchar2_table;
$if data_sql_pkg.c_support_time $then  
  l_time_table1 dbms_sql.time_table;
  l_time_table2 dbms_sql.time_table;
  l_time_with_time_zone_table1 dbms_sql.time_with_time_zone_table;
  l_time_with_time_zone_table2 dbms_sql.time_with_time_zone_table;
$end  
  l_timestamp_table1 dbms_sql.timestamp_table;
  l_timestamp_table2 dbms_sql.timestamp_table;
  l_timestamp_with_ltz_table1 dbms_sql.timestamp_with_ltz_table;
  l_timestamp_with_ltz_table2 dbms_sql.timestamp_with_ltz_table;
  l_timestamp_with_time_zone_table1 dbms_sql.timestamp_with_time_zone_table;
  l_timestamp_with_time_zone_table2 dbms_sql.timestamp_with_time_zone_table;
  l_interval_day_to_second_table1 dbms_sql.interval_day_to_second_table;
  l_interval_day_to_second_table2 dbms_sql.interval_day_to_second_table;
  l_interval_year_to_month_table1 dbms_sql.interval_year_to_month_table;
  l_interval_year_to_month_table2 dbms_sql.interval_year_to_month_table;
  l_data anydata_t;
begin
  for i_idx in 1..16
  loop
    case i_idx
      when  1 then l_clob_table1(i_idx) := null; l_clob_table1(i_idx+1) := null; l_clob_table1(i_idx+3) := null;
      when  2 then l_binary_float_table1(i_idx) := null; l_binary_float_table1(i_idx+1) := null; l_binary_float_table1(i_idx+3) := null;
      when  3 then l_binary_double_table1(i_idx) := null; l_binary_double_table1(i_idx+1) := null; l_binary_double_table1(i_idx+3) := null;
      when  4 then l_blob_table1(i_idx) := null; l_blob_table1(i_idx+1) := null; l_blob_table1(i_idx+3) := null;
      when  5 then l_bfile_table1(i_idx) := null; l_bfile_table1(i_idx+1) := null; l_bfile_table1(i_idx+3) := null;
      when  6 then l_date_table1(i_idx) := null; l_date_table1(i_idx+1) := null; l_date_table1(i_idx+3) := null;
      when  7 then l_number_table1(i_idx) := null; l_number_table1(i_idx+1) := null; l_number_table1(i_idx+3) := null;
      when  8 then l_urowid_table1(i_idx) := null; l_urowid_table1(i_idx+1) := null; l_urowid_table1(i_idx+3) := null;
      when  9 then l_varchar2_table1(i_idx) := null; l_varchar2_table1(i_idx+1) := null; l_varchar2_table1(i_idx+3) := null;
$if data_sql_pkg.c_support_time $then          
      when 10 then l_time_table1(i_idx) := null; l_time_table1(i_idx+1) := null; l_time_table1(i_idx+3) := null;
      when 11 then l_time_with_time_zone_table1(i_idx) := null; l_time_with_time_zone_table1(i_idx+1) := null; l_time_with_time_zone_table1(i_idx+3) := null;
$end        
      when 12 then l_timestamp_table1(i_idx) := null; l_timestamp_table1(i_idx+1) := null; l_timestamp_table1(i_idx+3) := null;
      when 13 then l_timestamp_with_ltz_table1(i_idx) := null; l_timestamp_with_ltz_table1(i_idx+1) := null; l_timestamp_with_ltz_table1(i_idx+3) := null;
      when 14 then l_timestamp_with_time_zone_table1(i_idx) := null; l_timestamp_with_time_zone_table1(i_idx+1) := null; l_timestamp_with_time_zone_table1(i_idx+3) := null;
      when 15 then l_interval_day_to_second_table1(i_idx) := null; l_interval_day_to_second_table1(i_idx+1) := null; l_interval_day_to_second_table1(i_idx+3) := null;
      when 16 then l_interval_year_to_month_table1(i_idx) := null; l_interval_year_to_month_table1(i_idx+1) := null; l_interval_year_to_month_table1(i_idx+3) := null;
$if not(data_sql_pkg.c_support_time) $then          
      else
        null;
$end        
    end case;
    
    case i_idx
      when  1
      then
        l_data := anydata.ConvertCollection(l_clob_table1); ut.expect(l_data.gettypename(), 'array ' || to_char(i_idx)).to_equal('SYS.CLOB_TABLE');
        ut.expect(l_data.GetCollection(l_clob_table2), 'collection ' || to_char(i_idx)).to_equal(DBMS_TYPES.SUCCESS);
        ut.expect(l_clob_table2.count, 'count ' || to_char(i_idx)).to_equal(3);
        ut.expect(l_clob_table2(i_idx), 'first element ' || to_char(i_idx)).to_be_null();
        ut.expect(l_clob_table2(i_idx+1), 'second element ' || to_char(i_idx)).to_be_null();
        ut.expect(l_clob_table2(i_idx+3), 'fourth element ' || to_char(i_idx)).to_be_null();
      when  2
      then
        l_data := anydata.ConvertCollection(l_binary_float_table1); ut.expect(l_data.gettypename(), 'array ' || to_char(i_idx)).to_equal('SYS.BINARY_FLOAT_TABLE');
        ut.expect(l_data.GetCollection(l_binary_float_table2), 'collection ' || to_char(i_idx)).to_equal(DBMS_TYPES.SUCCESS);
        ut.expect(l_binary_float_table2.count, 'count ' || to_char(i_idx)).to_equal(l_binary_float_table1.count);
        ut.expect(l_binary_float_table2(i_idx+0), 'first element ' || to_char(i_idx)).to_be_null();
        ut.expect(l_binary_float_table2(i_idx+1), 'second element ' || to_char(i_idx)).to_be_null();
        ut.expect(l_binary_float_table2(i_idx+3), 'fourth element ' || to_char(i_idx)).to_be_null();
      when  3
      then
        l_data := anydata.ConvertCollection(l_binary_double_table1); ut.expect(l_data.gettypename(), 'array ' || to_char(i_idx)).to_equal('SYS.BINARY_DOUBLE_TABLE');
        ut.expect(l_data.GetCollection(l_binary_double_table2), 'collection ' || to_char(i_idx)).to_equal(DBMS_TYPES.SUCCESS);
        ut.expect(l_binary_double_table2.count, 'count ' || to_char(i_idx)).to_equal(l_binary_double_table1.count);
        ut.expect(l_binary_double_table2(i_idx+0), 'first element ' || to_char(i_idx)).to_be_null();
        ut.expect(l_binary_double_table2(i_idx+1), 'second element ' || to_char(i_idx)).to_be_null();
        ut.expect(l_binary_double_table2(i_idx+3), 'fourth element ' || to_char(i_idx)).to_be_null();
      when  4
      then
        l_data := anydata.ConvertCollection(l_blob_table1); ut.expect(l_data.gettypename(), 'array ' || to_char(i_idx)).to_equal('SYS.BLOB_TABLE');
        ut.expect(l_data.GetCollection(l_blob_table2), 'collection ' || to_char(i_idx)).to_equal(DBMS_TYPES.SUCCESS);
        ut.expect(l_blob_table2.count, 'count ' || to_char(i_idx)).to_equal(l_blob_table1.count);
        ut.expect(l_blob_table2(i_idx+0), 'first element ' || to_char(i_idx)).to_be_null();
        ut.expect(l_blob_table2(i_idx+1), 'second element ' || to_char(i_idx)).to_be_null();
        ut.expect(l_blob_table2(i_idx+3), 'fourth element ' || to_char(i_idx)).to_be_null();
      when  5
      then
        l_data := anydata.ConvertCollection(l_bfile_table1); ut.expect(l_data.gettypename(), 'array ' || to_char(i_idx)).to_equal('SYS.BFILE_TABLE');
        ut.expect(l_data.GetCollection(l_bfile_table2), 'collection ' || to_char(i_idx)).to_equal(DBMS_TYPES.SUCCESS);
        ut.expect(l_bfile_table2.count, 'count ' || to_char(i_idx)).to_equal(l_bfile_table1.count);
        -- ut.expect does not support BFILE checks
        /*
        ut.expect(l_bfile_table2(i_idx+0), 'first element ' || to_char(i_idx)).to_be_null();
        ut.expect(l_bfile_table2(i_idx+1), 'second element ' || to_char(i_idx)).to_be_null();
        ut.expect(l_bfile_table2(i_idx+3), 'fourth element ' || to_char(i_idx)).to_be_null();
        */
      when  6
      then
        l_data := anydata.ConvertCollection(l_date_table1); ut.expect(l_data.gettypename(), 'array ' || to_char(i_idx)).to_equal('SYS.DATE_TABLE');
        ut.expect(l_data.GetCollection(l_date_table2), 'collection ' || to_char(i_idx)).to_equal(DBMS_TYPES.SUCCESS);
        ut.expect(l_date_table2.count, 'count ' || to_char(i_idx)).to_equal(l_date_table1.count);
        ut.expect(l_date_table2(i_idx+0), 'first element ' || to_char(i_idx)).to_be_null();
        ut.expect(l_date_table2(i_idx+1), 'second element ' || to_char(i_idx)).to_be_null();
        ut.expect(l_date_table2(i_idx+3), 'fourth element ' || to_char(i_idx)).to_be_null();
      when  7
      then
        l_data := anydata.ConvertCollection(l_number_table1); ut.expect(l_data.gettypename(), 'array ' || to_char(i_idx)).to_equal('SYS.NUMBER_TABLE');
        ut.expect(l_data.GetCollection(l_number_table2), 'collection ' || to_char(i_idx)).to_equal(DBMS_TYPES.SUCCESS);
        ut.expect(l_number_table2.count, 'count ' || to_char(i_idx)).to_equal(l_number_table1.count);
        ut.expect(l_number_table2(i_idx+0), 'first element ' || to_char(i_idx)).to_be_null();
        ut.expect(l_number_table2(i_idx+1), 'second element ' || to_char(i_idx)).to_be_null();
        ut.expect(l_number_table2(i_idx+3), 'fourth element ' || to_char(i_idx)).to_be_null();
      when  8
      then
        l_data := anydata.ConvertCollection(l_urowid_table1); ut.expect(l_data.gettypename(), 'array ' || to_char(i_idx)).to_equal('SYS.UROWID_TABLE');
        ut.expect(l_data.GetCollection(l_urowid_table2), 'collection ' || to_char(i_idx)).to_equal(DBMS_TYPES.SUCCESS);
        ut.expect(l_urowid_table2.count, 'count ' || to_char(i_idx)).to_equal(l_urowid_table1.count);
        ut.expect(l_urowid_table2(i_idx+0), 'first element ' || to_char(i_idx)).to_be_null();
        ut.expect(l_urowid_table2(i_idx+1), 'second element ' || to_char(i_idx)).to_be_null();
        ut.expect(l_urowid_table2(i_idx+3), 'fourth element ' || to_char(i_idx)).to_be_null();
      when  9
      then
        l_data := anydata.ConvertCollection(l_varchar2_table1); ut.expect(l_data.gettypename(), 'array ' || to_char(i_idx)).to_equal('SYS.VARCHAR2_TABLE');
        ut.expect(l_data.GetCollection(l_varchar2_table2), 'collection ' || to_char(i_idx)).to_equal(DBMS_TYPES.SUCCESS);
        ut.expect(l_varchar2_table2.count, 'count ' || to_char(i_idx)).to_equal(l_varchar2_table1.count);
        ut.expect(l_varchar2_table2(i_idx+0), 'first element ' || to_char(i_idx)).to_be_null();
        ut.expect(l_varchar2_table2(i_idx+1), 'second element ' || to_char(i_idx)).to_be_null();
        ut.expect(l_varchar2_table2(i_idx+3), 'fourth element ' || to_char(i_idx)).to_be_null();
      when 10
      then
$if data_sql_pkg.c_support_time $then          
        l_data := anydata.ConvertCollection(l_time_table1); ut.expect(l_data.gettypename(), 'array ' || to_char(i_idx)).to_equal('SYS.TIME_TABLE');
        ut.expect(l_data.GetCollection(l_time_table2), 'collection ' || to_char(i_idx)).to_equal(DBMS_TYPES.SUCCESS);
        ut.expect(l_time_table2.count, 'count ' || to_char(i_idx)).to_equal(l_time_table1.count);
        ut.expect(l_time_table2(i_idx+0), 'first element ' || to_char(i_idx)).to_be_null();
        ut.expect(l_time_table2(i_idx+1), 'second element ' || to_char(i_idx)).to_be_null();
        ut.expect(l_time_table2(i_idx+3), 'fourth element ' || to_char(i_idx)).to_be_null();
$else
        null;
$end        
      when 11
      then
$if data_sql_pkg.c_support_time $then          
        l_data := anydata.ConvertCollection(l_time_with_time_zone_table1); ut.expect(l_data.gettypename(), 'array ' || to_char(i_idx)).to_equal('SYS.TIME_WITH_TIME_ZONE_TABLE');
        ut.expect(l_data.GetCollection(l_time_with_time_zone_table2), 'collection ' || to_char(i_idx)).to_equal(DBMS_TYPES.SUCCESS);
        ut.expect(l_time_with_time_zone_table2.count, 'count ' || to_char(i_idx)).to_equal(l_time_with_time_zone_table1.count);
        ut.expect(l_time_with_time_zone_table2(i_idx+0), 'first element ' || to_char(i_idx)).to_be_null();
        ut.expect(l_time_with_time_zone_table2(i_idx+1), 'second element ' || to_char(i_idx)).to_be_null();
        ut.expect(l_time_with_time_zone_table2(i_idx+3), 'fourth element ' || to_char(i_idx)).to_be_null();
$else
        null;
$end        
      when 12
      then
        l_data := anydata.ConvertCollection(l_timestamp_table1); ut.expect(l_data.gettypename(), 'array ' || to_char(i_idx)).to_equal('SYS.TIMESTAMP_TABLE');
        ut.expect(l_data.GetCollection(l_timestamp_table2), 'collection ' || to_char(i_idx)).to_equal(DBMS_TYPES.SUCCESS);
        ut.expect(l_timestamp_table2.count, 'count ' || to_char(i_idx)).to_equal(l_timestamp_table1.count);
        ut.expect(l_timestamp_table2(i_idx+0), 'first element ' || to_char(i_idx)).to_be_null();
        ut.expect(l_timestamp_table2(i_idx+1), 'second element ' || to_char(i_idx)).to_be_null();
        ut.expect(l_timestamp_table2(i_idx+3), 'fourth element ' || to_char(i_idx)).to_be_null();
      when 13
      then
        l_data := anydata.ConvertCollection(l_timestamp_with_ltz_table1); ut.expect(l_data.gettypename(), 'array ' || to_char(i_idx)).to_equal('SYS.TIMESTAMP_WITH_LTZ_TABLE');
        ut.expect(l_data.GetCollection(l_timestamp_with_ltz_table2), 'collection ' || to_char(i_idx)).to_equal(DBMS_TYPES.SUCCESS);
        ut.expect(l_timestamp_with_ltz_table2.count, 'count ' || to_char(i_idx)).to_equal(l_timestamp_with_ltz_table1.count);
        ut.expect(l_timestamp_with_ltz_table2(i_idx+0), 'first element ' || to_char(i_idx)).to_be_null();
        ut.expect(l_timestamp_with_ltz_table2(i_idx+1), 'second element ' || to_char(i_idx)).to_be_null();
        ut.expect(l_timestamp_with_ltz_table2(i_idx+3), 'fourth element ' || to_char(i_idx)).to_be_null();
      when 14
      then
        l_data := anydata.ConvertCollection(l_timestamp_with_time_zone_table1); ut.expect(l_data.gettypename(), 'array ' || to_char(i_idx)).to_equal('SYS.TIMESTAMP_WITH_TIME_ZONE_TABLE');
        ut.expect(l_data.GetCollection(l_timestamp_with_time_zone_table2), 'collection ' || to_char(i_idx)).to_equal(DBMS_TYPES.SUCCESS);
        ut.expect(l_timestamp_with_time_zone_table2.count, 'count ' || to_char(i_idx)).to_equal(l_timestamp_with_time_zone_table1.count);
        ut.expect(l_timestamp_with_time_zone_table2(i_idx+0), 'first element ' || to_char(i_idx)).to_be_null();
        ut.expect(l_timestamp_with_time_zone_table2(i_idx+1), 'second element ' || to_char(i_idx)).to_be_null();
        ut.expect(l_timestamp_with_time_zone_table2(i_idx+3), 'fourth element ' || to_char(i_idx)).to_be_null();
      when 15
      then
        l_data := anydata.ConvertCollection(l_interval_day_to_second_table1); ut.expect(l_data.gettypename(), 'array ' || to_char(i_idx)).to_equal('SYS.INTERVAL_DAY_TO_SECOND_TABLE');
        ut.expect(l_data.GetCollection(l_interval_day_to_second_table2), 'collection ' || to_char(i_idx)).to_equal(DBMS_TYPES.SUCCESS);
        ut.expect(l_interval_day_to_second_table2.count, 'count ' || to_char(i_idx)).to_equal(l_interval_day_to_second_table1.count);
        ut.expect(l_interval_day_to_second_table2(i_idx+0), 'first element ' || to_char(i_idx)).to_be_null();
        ut.expect(l_interval_day_to_second_table2(i_idx+1), 'second element ' || to_char(i_idx)).to_be_null();
        ut.expect(l_interval_day_to_second_table2(i_idx+3), 'fourth element ' || to_char(i_idx)).to_be_null();
      when 16
      then
        l_data := anydata.ConvertCollection(l_interval_year_to_month_table1); ut.expect(l_data.gettypename(), 'array ' || to_char(i_idx)).to_equal('SYS.INTERVAL_YEAR_TO_MONTH_TABLE');
        ut.expect(l_data.GetCollection(l_interval_year_to_month_table2), 'collection ' || to_char(i_idx)).to_equal(DBMS_TYPES.SUCCESS);
        ut.expect(l_interval_year_to_month_table2.count, 'count ' || to_char(i_idx)).to_equal(l_interval_year_to_month_table1.count);
        ut.expect(l_interval_year_to_month_table2(i_idx+0), 'first element ' || to_char(i_idx)).to_be_null();
        ut.expect(l_interval_year_to_month_table2(i_idx+1), 'second element ' || to_char(i_idx)).to_be_null();
        ut.expect(l_interval_year_to_month_table2(i_idx+3), 'fourth element ' || to_char(i_idx)).to_be_null();
    end case;
    
    case i_idx
      when  1 then l_data := anydata.ConvertClob(l_clob_table1(i_idx)); ut.expect(l_data.gettypename(), 'scalar ' || to_char(i_idx)).to_equal('SYS.CLOB');
      when  2 then l_data := anydata.ConvertBFloat(l_binary_float_table1(i_idx)); ut.expect(l_data.gettypename(), 'scalar ' || to_char(i_idx)).to_equal('SYS.BINARY_FLOAT');
      when  3 then l_data := anydata.ConvertBDouble(l_binary_double_table1(i_idx)); ut.expect(l_data.gettypename(), 'scalar ' || to_char(i_idx)).to_equal('SYS.BINARY_DOUBLE');
      when  4 then l_data := anydata.ConvertBlob(l_blob_table1(i_idx)); ut.expect(l_data.gettypename(), 'scalar ' || to_char(i_idx)).to_equal('SYS.BLOB');
      when  5 then l_data := anydata.ConvertBfile(l_bfile_table1(i_idx)); ut.expect(l_data.gettypename(), 'scalar ' || to_char(i_idx)).to_equal('SYS.BFILE');
      when  6 then l_data := anydata.ConvertDate(l_date_table1(i_idx)); ut.expect(l_data.gettypename(), 'scalar ' || to_char(i_idx)).to_equal('SYS.DATE');
      when  7 then l_data := anydata.ConvertNumber(l_number_table1(i_idx)); ut.expect(l_data.gettypename(), 'scalar ' || to_char(i_idx)).to_equal('SYS.NUMBER');
      when  8 then l_data := anydata.ConvertURowid(l_urowid_table1(i_idx)); ut.expect(l_data.gettypename(), 'scalar ' || to_char(i_idx)).to_equal('SYS.UROWID');
      when  9 then l_data := anydata.ConvertVarchar2(l_varchar2_table1(i_idx)); ut.expect(l_data.gettypename(), 'scalar ' || to_char(i_idx)).to_equal('SYS.VARCHAR2');
$if data_sql_pkg.c_support_time $then          
      when 10 then l_data := anydata.ConvertTimestamp(l_time_table1(i_idx)); ut.expect(l_data.gettypename(), 'scalar ' || to_char(i_idx)).to_equal('SYS.TIME');
      when 11 then l_data := anydata.ConvertTimestampTZ(l_time_with_time_zone_table1(i_idx)); ut.expect(l_data.gettypename(), 'scalar ' || to_char(i_idx)).to_equal('SYS.TIME_WITH_TIME_ZONE');
$end        
      when 12 then l_data := anydata.ConvertTimestamp(l_timestamp_table1(i_idx)); ut.expect(l_data.gettypename(), 'scalar ' || to_char(i_idx)).to_equal('SYS.TIMESTAMP');
      when 13 then l_data := anydata.ConvertTimestampLTZ(l_timestamp_with_ltz_table1(i_idx)); ut.expect(l_data.gettypename(), 'scalar ' || to_char(i_idx)).to_equal('SYS.TIMESTAMP_WITH_LTZ');
      when 14 then l_data := anydata.ConvertTimestampTZ(l_timestamp_with_time_zone_table1(i_idx)); ut.expect(l_data.gettypename(), 'scalar ' || to_char(i_idx)).to_equal('SYS.TIMESTAMP_WITH_TIMEZONE');
      when 15 then l_data := anydata.ConvertIntervalDS(l_interval_day_to_second_table1(i_idx)); ut.expect(l_data.gettypename(), 'scalar ' || to_char(i_idx)).to_equal('SYS.INTERVAL_DAY_SECOND');
      when 16 then l_data := anydata.ConvertIntervalYM(l_interval_year_to_month_table1(i_idx)); ut.expect(l_data.gettypename(), 'scalar ' || to_char(i_idx)).to_equal('SYS.INTERVAL_YEAR_MONTH');
$if not(data_sql_pkg.c_support_time) $then
      else
        null;
$end        
    end case;
  end loop;
end;

$end

end data_sql_pkg;
/
