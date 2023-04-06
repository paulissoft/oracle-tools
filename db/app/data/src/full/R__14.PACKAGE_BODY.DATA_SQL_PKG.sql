CREATE OR REPLACE PACKAGE BODY "DATA_SQL_PKG" 
is

procedure do
( p_operation in varchar2 -- (S)elect, (I)nsert, (U)pdate or (D)elete
, p_table_name in varchar2
, p_column_name in varchar2 -- the column name to query
, p_column_value in anydata -- the column value to query
, p_query in statement_t -- if null it will default to 'select * from <table>'
, p_owner in varchar2 -- the owner of the table
, p_max_row_count in positive default null
, p_column_value_tab in out nocopy column_value_tab_t -- only when an entry exists that table column will be used in the query or DML
)
is
  l_bind_variable constant all_tab_columns.column_name%type := ':' || p_column_name;
  l_query statement_t :=
    nvl
    ( p_query
    , utl_lms.format_message
      ( 'select * from "%s"."%s"%s'
      , p_owner
      , p_table_name
      , case
          when p_column_name is not null and p_column_value is not null
          then utl_lms.format_message(' where "%s" = %s', p_column_name, l_bind_variable)
        end
      )
    );
  l_stmt statement_t := null;
  l_cursor integer := null;
  l_nr_rows_processed pls_integer;
  l_column_name all_tab_columns.column_name%type;

  type column_date_tab_t is table of sys.odcidatelist index by binary_integer;
  type column_number_tab_t is table of sys.odcinumberlist index by binary_integer;
  type column_varchar2_tab_t is table of sys.odcivarchar2list index by binary_integer;

  l_column_date_tab column_date_tab_t;
  l_column_number_tab column_number_tab_t;
  l_column_varchar2_tab column_varchar2_tab_t;

  cursor c_col is
    select  c.column_name
    ,       c.data_type
    ,       c.data_length
    from    all_tab_columns c
    where   c.owner = p_owner
    and     c.table_name = p_table_name
    order by
            c.column_id;

  type column_tab_t is table of c_col%rowtype index by binary_integer;

  l_column_tab column_tab_t;

  procedure construct_statement
  is
  begin
    -- construct statement
    for r in c_col
    loop
      continue when not(p_column_value_tab.exists(r.column_name));
      
      case p_operation
        when 'S'
        then
          if l_stmt is null
          then
            l_stmt := 'select ';
          else
            l_stmt := l_stmt || ',';
          end if;
          l_stmt := l_stmt || '"' || r.column_name || '"';
        else
          raise e_unimplemented_feature;
      end case;
    end loop;

    case p_operation
      when 'S'
      then
        l_stmt := l_stmt || ' from (' || l_query || ')';
      else
        raise e_unimplemented_feature;
    end case;
  end construct_statement;

  procedure set_bind_variable
  is
  begin
    case p_column_value.gettypename()
      when 'SYS.DATE'     then dbms_sql.bind_variable(l_cursor, l_bind_variable, p_column_value.AccessDate());
      when 'SYS.NUMBER'   then dbms_sql.bind_variable(l_cursor, l_bind_variable, p_column_value.AccessNumber());
      when 'SYS.VARCHAR2' then dbms_sql.bind_variable(l_cursor, l_bind_variable, p_column_value.AccessVarchar2());
        
      else raise e_unimplemented_feature;
    end case;
  end;

  procedure define_columns
  is
    l_column_id all_tab_columns.column_id%type;
    l_date date;
    l_number number;
    l_varchar2 varchar2(4000);
  begin
    l_column_id := 1;
    for r in c_col
    loop
      continue when not(p_column_value_tab.exists(r.column_name));

      l_column_tab(l_column_id) := r;

      case r.data_type
        when 'DATE'
        then
          dbms_sql.define_column(l_cursor, l_column_id, l_date);
          l_column_date_tab(l_column_id) := sys.odcidatelist(); -- column_value will put it in here
          
        when 'NUMBER'
        then
          dbms_sql.define_column(l_cursor, l_column_id, l_number);
          l_column_number_tab(l_column_id) := sys.odcinumberlist();

        when 'VARCHAR2'
        then
          dbms_sql.define_column(l_cursor, l_column_id, l_varchar2, r.data_length);
          l_column_varchar2_tab(l_column_id) := sys.odcivarchar2list();
          
        else
          raise e_unimplemented_feature;
      end case;
    
      l_column_id := l_column_id + 1;
    end loop;    
  end define_columns;

  procedure fetch_rows_and_columns
  is
    l_rows pls_integer;
    l_row_nr pls_integer := 0;
  begin
    <<fetch_loop>>
    loop
      l_rows := dbms_sql.fetch_rows(l_cursor);

$if cfg_pkg.c_debugging $then
      dbug.print(dbug."debug", '# rows fetched: %s', l_rows);
$end  

      exit fetch_loop when l_rows = 0;

      <<row_loop>>
      while l_rows > 0
      loop
        l_rows := l_rows - 1;
        l_row_nr := l_row_nr + 1; -- current row number
        
        if l_row_nr > p_max_row_count -- fetch one more than needed for too_many_rows
        then
          if p_max_row_count = 1
          then
            raise too_many_rows;
          else
            exit fetch_loop;
          end if;
        end if;

        <<column_loop>>
        for i_idx in l_column_tab.first .. l_column_tab.last
        loop
          case l_column_tab(i_idx).data_type
            when 'DATE'
            then
              l_column_date_tab(i_idx).extend(1);
              dbms_sql.column_value(l_cursor, i_idx, l_column_date_tab(i_idx)(l_column_date_tab(i_idx).last));
$if cfg_pkg.c_debugging $then
              dbug.print
              ( dbug."debug"
              , 'row: %s; column: %s; value: %s'
              , l_row_nr
              , l_column_tab(i_idx).column_name
              , to_char(l_column_date_tab(i_idx)(l_column_date_tab(i_idx).last), 'yyyy-mm-dd hh24:mi:ss')
              );
$end  
              
            when 'NUMBER'
            then
              l_column_number_tab(i_idx).extend(1);
              dbms_sql.column_value(l_cursor, i_idx, l_column_number_tab(i_idx)(l_column_number_tab(i_idx).last));
$if cfg_pkg.c_debugging $then
              dbug.print
              ( dbug."debug"
              , 'row: %s; column: %s; value: %s'
              , l_row_nr
              , l_column_tab(i_idx).column_name
              , to_char(l_column_number_tab(i_idx)(l_column_number_tab(i_idx).last))
              );
$end  

            when 'VARCHAR2'
            then
              l_column_varchar2_tab(i_idx).extend(1);
              dbms_sql.column_value(l_cursor, i_idx, l_column_varchar2_tab(i_idx)(l_column_varchar2_tab(i_idx).last));
$if cfg_pkg.c_debugging $then
              dbug.print
              ( dbug."debug"
              , 'row: %s; column: %s; value: %s'
              , l_row_nr
              , l_column_tab(i_idx).column_name
              , l_column_varchar2_tab(i_idx)(l_column_varchar2_tab(i_idx).last)
              );
$end  
              
            else
              raise e_unimplemented_feature;
          end case;
        end loop column_loop;
      end loop row_loop;
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
  , 'p_operation: %s; table: %s; column filter: %s; p_query: %s; p_max_row_count: %s'
  , p_operation
  , '"' || p_owner || '"."' || p_table_name || '"'
  , case
      when p_column_name is not null and p_column_value is not null
      then
        p_column_name ||
        ' = ' ||
        case p_column_value.gettypename()
          when 'SYS.DATE'     then dbms_assert.enquote_literal(to_char(p_column_value.AccessDate(), 'yyyy-mm-dd hh24:mi:ss'))
          when 'SYS.NUMBER'   then p_column_value.AccessNumber()
          when 'SYS.VARCHAR2' then dbms_assert.enquote_literal(p_column_value.AccessVarchar2())
        end
    end      
  , p_query
  , p_max_row_count
  );
$end

  construct_statement;
  
  l_cursor := dbms_sql.open_cursor;
 
  dbms_sql.parse(l_cursor, l_stmt, dbms_sql.native);

  if p_column_name is not null and p_column_value is not null
  then
    set_bind_variable;
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

procedure do
( p_operation in varchar2 -- (S)elect, (I)nsert, (U)pdate or (D)elete
, p_common_key_name_tab in common_key_name_tab_t -- per table the common key column name
, p_common_key_value in anydata -- tables are related by this common key value
, p_query_tab in query_tab_t -- per table a query: if null it will default to 'select * from <table>'
, p_owner in varchar2 -- the owner of the table
, p_max_row_count_tab in max_row_count_tab_t
, p_table_column_value_tab in out nocopy table_column_value_tab_t -- only when an entry exists that table column will be used in the query or DML
)
is
begin
  raise e_unimplemented_feature;
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
  l_column_value_tab column_value_tab_t;
  l_column_value all_tab_columns.column_name%type;
  l_date_tab sys.odcidatelist;
  l_number_tab sys.odcinumberlist;
  l_varchar2_tab sys.odcivarchar2list;
begin
$if cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.UT_DO_EMP');
$end

  l_column_value_tab('EMPNO') := null;
  l_column_value_tab('JOB') := null;
  l_column_value_tab('HIREDATE') := null;
  l_column_value_tab('DEPTNO') := null;
  
  do
  ( p_operation => 'S'
  , p_table_name => 'MY_EMP'
  , p_column_name => 'DEPTNO'
  , p_column_value => anydata.ConvertNumber(20)
  , p_column_value_tab => l_column_value_tab
  );

  ut.expect(l_column_value_tab.count, '# columns').to_equal(4);

  l_column_value := l_column_value_tab.first;
  while l_column_value is not null
  loop
    case
      when l_column_value in ('EMPNO', 'DEPTNO')
      then
        ut.expect(l_column_value_tab(l_column_value).gettypename(), 'data type ' || l_column_value).to_equal('SYS.ODCINUMBERLIST');
        ut.expect(l_column_value_tab(l_column_value).GetCollection(l_number_tab), 'get collection ' || l_column_value).to_equal(DBMS_TYPES.SUCCESS);
        ut.expect(l_number_tab.count, 'collection count ' || l_column_value).to_equal(5);
        
      when l_column_value in ('JOB')
      then
        ut.expect(l_column_value_tab(l_column_value).gettypename(), 'data type ' || l_column_value).to_equal('SYS.ODCIVARCHAR2LIST');
        ut.expect(l_column_value_tab(l_column_value).GetCollection(l_varchar2_tab), 'get collection ' || l_column_value).to_equal(DBMS_TYPES.SUCCESS);
        ut.expect(l_varchar2_tab.count, 'collection count ' || l_column_value).to_equal(5);
        
      when l_column_value in ('HIREDATE')
      then
        ut.expect(l_column_value_tab(l_column_value).gettypename(), 'data type ' || l_column_value).to_equal('SYS.ODCIDATELIST');
        ut.expect(l_column_value_tab(l_column_value).GetCollection(l_date_tab), 'get collection ' || l_column_value).to_equal(DBMS_TYPES.SUCCESS);
        ut.expect(l_date_tab.count, 'collection count ' || l_column_value).to_equal(5);
    end case;

    l_column_value := l_column_value_tab.next(l_column_value);
  end loop;

  -- get employees for department 0 (i_try 0), all (i_try 1) or 20 (i_try 2) check no_data_found / too_many_rows
  for i_try in 0..2
  loop
    begin
      do
      ( p_operation => 'S'
      , p_table_name => 'MY_EMP'
      , p_column_name => 'DEPTNO'
      , p_column_value => case when i_try <> 1 then anydata.ConvertNumber(i_try * 10) else null end
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

$end

end data_sql_pkg;
/
