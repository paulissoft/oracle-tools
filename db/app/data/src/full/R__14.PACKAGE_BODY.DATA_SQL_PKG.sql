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
  begin
    <<fetch_loop>>
    loop
      l_rows := dbms_sql.fetch_rows(l_cursor);

      <<row_loop>>
      while l_rows > 0
      loop
        <<column_loop>>
        for i_idx in l_column_tab.first .. l_column_tab.last
        loop
          case l_column_tab(i_idx).data_type
            when 'DATE'
            then
              l_column_date_tab(i_idx).extend(1);
              dbms_sql.column_value(l_cursor, i_idx, l_column_date_tab(i_idx)(l_column_date_tab(i_idx).last));
              
            when 'NUMBER'
            then
              l_column_number_tab(i_idx).extend(1);
              dbms_sql.column_value(l_cursor, i_idx, l_column_number_tab(i_idx)(l_column_number_tab(i_idx).last));

            when 'VARCHAR2'
            then
              l_column_varchar2_tab(i_idx).extend(1);
              dbms_sql.column_value(l_cursor, i_idx, l_column_varchar2_tab(i_idx)(l_column_varchar2_tab(i_idx).last));
              
            else
              raise e_unimplemented_feature;
          end case;
        end loop column_loop;
        l_rows := l_rows - 1;
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
            p_column_value_tab(l_column_tab(i_idx).column_name) := anydata.ConvertVarchar2(l_column_number_tab(i_idx)(1));
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
            p_column_value_tab(l_column_tab(i_idx).column_name) := anydata.ConvertNumber(l_column_varchar2_tab(i_idx)(1));
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
exception
  when others
  then
    cleanup;
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

end data_sql_pkg;
/
