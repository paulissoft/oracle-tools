CREATE OR REPLACE PACKAGE BODY "DATA_SQL_PKG" 
is

-- private

cursor c_col
( b_owner in varchar2
, b_table_name in varchar2
)
is
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
  where   tc.owner = b_owner
  and     tc.table_name = b_table_name
  order by
          tc.column_id;

type column_tab_t is table of c_col%rowtype index by binary_integer;

function bind_variable
( p_column_name in varchar2
)
return varchar2
deterministic
is
begin
  return ':B_' || p_column_name || '$';
end bind_variable;

function empty_bind_variable
( p_column_value in anydata_t
)
return boolean
deterministic
is
begin
$if data_sql_pkg.c_column_value_is_anydata $then
  return p_column_value is null;
$else  
  return p_column_value.data_type is null;
$end  
end empty_bind_variable;

procedure set_bind_variable
( p_cursor in integer
, p_column_name in varchar2
, p_column_value in anydata_t
)
is
  l_bind_variable constant all_tab_columns.column_name%type := bind_variable(p_column_name);
begin
$if data_sql_pkg.c_column_value_is_anydata $then

  case p_column_value.gettypename()
    when 'SYS.DATE'     then dbms_sql.bind_variable(p_cursor, l_bind_variable, p_column_value.AccessDate());
    when 'SYS.NUMBER'   then dbms_sql.bind_variable(p_cursor, l_bind_variable, p_column_value.AccessNumber());
    when 'SYS.VARCHAR2' then dbms_sql.bind_variable(p_cursor, l_bind_variable, p_column_value.AccessVarchar2());
      
    else raise e_unimplemented_feature;
  end case;
  
$else

  case p_column_value.data_type
    when 'CLOB'
    then
      if p_column_value.is_table
      then dbms_sql.bind_array(p_cursor, l_bind_variable, p_column_value.clob$_table);
      else dbms_sql.bind_variable(p_cursor, l_bind_variable, p_column_value.clob$);
      end if;
    when 'BINARY_FLOAT'
    then
      if p_column_value.is_table
      then dbms_sql.bind_array(p_cursor, l_bind_variable, p_column_value.binary_float$_table);
      else dbms_sql.bind_variable(p_cursor, l_bind_variable, p_column_value.binary_float$);
      end if;
    when 'BINARY_DOUBLE'
    then
      if p_column_value.is_table
      then dbms_sql.bind_array(p_cursor, l_bind_variable, p_column_value.binary_double$_table);
      else dbms_sql.bind_variable(p_cursor, l_bind_variable, p_column_value.binary_double$);
      end if;
    when 'BLOB'
    then
      if p_column_value.is_table
      then dbms_sql.bind_array(p_cursor, l_bind_variable, p_column_value.blob$_table);
      else dbms_sql.bind_variable(p_cursor, l_bind_variable, p_column_value.blob$);
      end if;
    when 'BFILE'
    then
      if p_column_value.is_table
      then dbms_sql.bind_array(p_cursor, l_bind_variable, p_column_value.bfile$_table);
      else dbms_sql.bind_variable(p_cursor, l_bind_variable, p_column_value.bfile$);
      end if;
    when 'DATE'
    then
      if p_column_value.is_table
      then dbms_sql.bind_array(p_cursor, l_bind_variable, p_column_value.date$_table);
      else dbms_sql.bind_variable(p_cursor, l_bind_variable, p_column_value.date$);
      end if;
    when 'NUMBER'
    then
      if p_column_value.is_table
      then dbms_sql.bind_array(p_cursor, l_bind_variable, p_column_value.number$_table);
      else dbms_sql.bind_variable(p_cursor, l_bind_variable, p_column_value.number$);
      end if;
    when 'UROWID'
    then
      if p_column_value.is_table
      then dbms_sql.bind_array(p_cursor, l_bind_variable, p_column_value.urowid$_table);
      else dbms_sql.bind_variable(p_cursor, l_bind_variable, p_column_value.urowid$);
      end if;
    when 'VARCHAR2'
    then
      if p_column_value.is_table
      then dbms_sql.bind_array(p_cursor, l_bind_variable, p_column_value.varchar2$_table);
      else dbms_sql.bind_variable(p_cursor, l_bind_variable, p_column_value.varchar2$);
      end if;
    when 'TIMESTAMP'
    then
      if p_column_value.is_table
      then dbms_sql.bind_array(p_cursor, l_bind_variable, p_column_value.timestamp$_table);
      else dbms_sql.bind_variable(p_cursor, l_bind_variable, p_column_value.timestamp$);
      end if;
    else
      case
        when p_column_value.data_type like 'TIMESTAMP(_%) WITH LOCAL TIME ZONE'
        then
          if p_column_value.is_table
          then dbms_sql.bind_array(p_cursor, l_bind_variable, p_column_value.timestamp_ltz$_table);
          else dbms_sql.bind_variable(p_cursor, l_bind_variable, p_column_value.timestamp_ltz$);
          end if;
        when p_column_value.data_type like 'TIMESTAMP(_%) WITH TIME ZONE'
        then
          if p_column_value.is_table
          then dbms_sql.bind_array(p_cursor, l_bind_variable, p_column_value.timestamp_tz$_table);
          else dbms_sql.bind_variable(p_cursor, l_bind_variable, p_column_value.timestamp_tz$);
          end if;
        when p_column_value.data_type like 'INTERVAL DAY(_%) TO SECOND(_%)'
        then
          if p_column_value.is_table
          then dbms_sql.bind_array(p_cursor, l_bind_variable, p_column_value.interval_ds$_table);
          else dbms_sql.bind_variable(p_cursor, l_bind_variable, p_column_value.interval_ds$);
          end if;
        when p_column_value.data_type like 'INTERVAL YEAR(_%) TO MONTH'
        then
          if p_column_value.is_table
          then dbms_sql.bind_array(p_cursor, l_bind_variable, p_column_value.interval_ym$_table);
          else dbms_sql.bind_variable(p_cursor, l_bind_variable, p_column_value.interval_ym$);
          end if;
      end case;
  end case;
  
$end -- $if data_sql_pkg.c_column_value_is_anydata $then  
end set_bind_variable;

procedure construct_statement
( p_operation in varchar2
, p_owner in varchar2
, p_table_name in varchar2
, p_statement in varchar2
, p_order_by in varchar2
, p_bind_variable_tab in column_value_tab_t
, p_column_value_tab in column_value_tab_t
, p_statement_lines out nocopy dbms_sql.varchar2a
, p_column_tab out nocopy column_tab_t
)
is
  l_where_clause statement_t := null;
  l_statement statement_t := null;
  l_column_name all_tab_columns.column_name%type;
begin
$if cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.CONSTRUCT_STATEMENT');
  dbug.print
  ( dbug."input"
  , 'p_operation: %s; p_owner: %s; p_table_name: %s; p_statement: %s; p_order_by: %s'
  , p_operation
  , p_owner
  , p_table_name
  , p_statement
  , p_order_by
  );
$end

  -- construct statement
  for r in c_col(p_owner, p_table_name)
  loop
    continue when not(p_column_value_tab.exists(r.column_name));

    p_column_tab(p_column_tab.count+1) := r;

    case p_operation
      when 'S'
      then
        p_statement_lines(p_statement_lines.count+1) :=
          case
            when p_statement_lines.count = 0
            then 'select  '
            else ',       '
          end ||
          '"' ||
          r.column_name ||
          '"';
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

      p_statement_lines(p_statement_lines.count+1) := 'from    (' || l_statement || ')';
    else
      raise e_unimplemented_feature;
  end case;

$if cfg_pkg.c_debugging $then
  for i_idx in p_statement_lines.first .. p_statement_lines.last
  loop
    dbug.print(dbug."debug", 'p_statement_lines(%s): %s', i_idx, p_statement_lines(i_idx));
  end loop;
  dbug.leave;
$end
exception
  when others
  then
    if c_col%isopen then close c_col; end if;
end construct_statement;

-- public routines

function empty_clob_table
return dbms_sql.clob_table
is
  l_table dbms_sql.clob_table;
begin
  return l_table;
end;

function empty_binary_float_table
return dbms_sql.binary_float_table
is
  l_table dbms_sql.binary_float_table;
begin
  return l_table;
end;

function empty_binary_double_table
return dbms_sql.binary_double_table
is
  l_table dbms_sql.binary_double_table;
begin
  return l_table;
end;

function empty_blob_table
return dbms_sql.blob_table
is
  l_table dbms_sql.blob_table;
begin
  return l_table;
end;

function empty_bfile_table
return dbms_sql.bfile_table
is
  l_table dbms_sql.bfile_table;
begin
  return l_table;
end;

function empty_date_table
return dbms_sql.date_table
is
  l_table dbms_sql.date_table;
begin
  return l_table;
end;

function empty_number_table
return dbms_sql.number_table
is
  l_table dbms_sql.number_table;
begin
  return l_table;
end;

function empty_urowid_table
return dbms_sql.urowid_table
is
  l_table dbms_sql.urowid_table;
begin
  return l_table;
end;

function empty_varchar2_table
return dbms_sql.varchar2_table
is
  l_table dbms_sql.varchar2_table;
begin
  return l_table;
end;

function empty_timestamp_table
return dbms_sql.timestamp_table
is
  l_table dbms_sql.timestamp_table;
begin
  return l_table;
end;

function empty_timestamp_ltz_table
return dbms_sql.timestamp_with_ltz_table
is
  l_table dbms_sql.timestamp_with_ltz_table;
begin
  return l_table;
end;

function empty_timestamp_tz_table
return dbms_sql.timestamp_with_time_zone_table
is
  l_table dbms_sql.timestamp_with_time_zone_table;
begin
  return l_table;
end;

function empty_interval_ds_table
return dbms_sql.interval_day_to_second_table
is
  l_table dbms_sql.interval_day_to_second_table;
begin
  return l_table;
end;

function empty_interval_ym_table
return dbms_sql.interval_year_to_month_table
is
  l_table dbms_sql.interval_year_to_month_table;
begin
  return l_table;
end;

procedure set_column_value
( p_data_type in all_tab_columns.data_type%type
, p_is_table in boolean
, p_pk_key_position in all_cons_columns.position%type
, p_clob$ in clob
, p_clob$_table in dbms_sql.clob_table
, p_binary_float$ in binary_float
, p_binary_float$_table in dbms_sql.binary_float_table
, p_binary_double$ in binary_double
, p_binary_double$_table in dbms_sql.binary_double_table
, p_blob$ in blob
, p_blob$_table in dbms_sql.blob_table
, p_bfile$ in bfile
, p_bfile$_table in dbms_sql.bfile_table
, p_date$ in date
, p_date$_table in dbms_sql.date_table
, p_number$ in number
, p_number$_table in dbms_sql.number_table
, p_urowid$ in urowid
, p_urowid$_table in dbms_sql.urowid_table
, p_varchar2$ in varchar2
, p_varchar2$_table in dbms_sql.varchar2_table
, p_timestamp$ in timestamp
, p_timestamp$_table in dbms_sql.timestamp_table
, p_timestamp_ltz$ in timestamp with local time zone
, p_timestamp_ltz$_table in dbms_sql.timestamp_with_ltz_table
, p_timestamp_tz$ in timestamp with time zone
, p_timestamp_tz$_table in dbms_sql.timestamp_with_time_zone_table
, p_interval_ds$ in interval day to second
, p_interval_ds$_table in dbms_sql.interval_day_to_second_table
, p_interval_ym$ in interval year to month
, p_interval_ym$_table in dbms_sql.interval_year_to_month_table
, p_column_value out nocopy column_value_t
)
is
begin
  p_column_value.data_type:= p_data_type;
  p_column_value.is_table:= p_is_table;
  p_column_value.pk_key_position:= p_pk_key_position;
  p_column_value.clob$ := p_clob$;
  p_column_value.clob$_table := p_clob$_table;
  p_column_value.binary_float$ := p_binary_float$;
  p_column_value.binary_float$_table := p_binary_float$_table;
  p_column_value.binary_double$ := p_binary_double$;
  p_column_value.binary_double$_table := p_binary_double$_table;
  p_column_value.blob$ := p_blob$;
  p_column_value.blob$_table := p_blob$_table;
  p_column_value.bfile$ := p_bfile$;
  p_column_value.bfile$_table := p_bfile$_table;
  p_column_value.date$ := p_date$;
  p_column_value.date$_table := p_date$_table;
  p_column_value.number$ := p_number$;
  p_column_value.number$_table := p_number$_table;
  p_column_value.urowid$ := p_urowid$;
  p_column_value.urowid$_table := p_urowid$_table;
  p_column_value.varchar2$ := p_varchar2$;
  p_column_value.varchar2$_table := p_varchar2$_table;
  p_column_value.timestamp$ := p_timestamp$;
  p_column_value.timestamp$_table := p_timestamp$_table;
  p_column_value.timestamp_ltz$ := p_timestamp_ltz$;
  p_column_value.timestamp_ltz$_table := p_timestamp_ltz$_table;
  p_column_value.timestamp_tz$ := p_timestamp_tz$;
  p_column_value.timestamp_tz$_table := p_timestamp_tz$_table;
  p_column_value.interval_ds$ := p_interval_ds$;
  p_column_value.interval_ds$_table := p_interval_ds$_table;
  p_column_value.interval_ym$ := p_interval_ym$;
  p_column_value.interval_ym$_table := p_interval_ym$_table;
end set_column_value;

function empty_anydata
return anydata_t
is
$if data_sql_pkg.c_column_value_is_anydata $then
  l_anydata anydata_t := null;
$else  
  l_anydata anydata_t;
$end  
begin
  return l_anydata;
end empty_anydata;

function empty_column_value_tab
return column_value_tab_t
is
  l_column_value_tab column_value_tab_t;
begin
  return l_column_value_tab;
end;

procedure do
( p_operation in varchar2
, p_table_name in varchar2
, p_bind_variable_tab in column_value_tab_t
, p_statement in statement_t
, p_order_by in varchar2
, p_owner in varchar2
, p_max_row_count in positive default null
, p_column_value_tab in out nocopy column_value_tab_t
)
is
  l_statement_lines dbms_sql.varchar2a;
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

  l_column_tab column_tab_t;

  procedure set_bind_variables
  is
  begin
    l_column_name := p_bind_variable_tab.first;
    while l_column_name is not null
    loop
      if not(empty_bind_variable(p_bind_variable_tab(l_column_name)))
      then
        set_bind_variable
        ( l_cursor
        , l_column_name
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
$if not(data_sql_pkg.c_column_value_is_anydata) $then
      set_column_value
      ( p_data_type => l_column_tab(i_idx).data_type
      , p_pk_key_position => l_column_tab(i_idx).pk_key_position
      , p_column_value => p_column_value_tab(l_column_tab(i_idx).column_name)
      );
$end

      case l_column_tab(i_idx).data_type
        when 'DATE'
        then
$if data_sql_pkg.c_column_value_is_anydata $then
          l_column_date_tab(i_idx)(1) := null; -- column_value will put it in here
          l_column_date_tab(i_idx).delete;
          dbms_sql.define_array(c => l_cursor, position => i_idx, d_tab => l_column_date_tab(i_idx), cnt => l_fetch_limit, lower_bound => 1);
$else
          dbms_sql.define_array(c => l_cursor, position => i_idx, d_tab => p_column_value_tab(l_column_tab(i_idx).column_name).date$_table, cnt => l_fetch_limit, lower_bound => 1);
$end

        when 'NUMBER'
        then
$if data_sql_pkg.c_column_value_is_anydata $then
          l_column_number_tab(i_idx)(1) := null;
          l_column_number_tab(i_idx).delete;
          dbms_sql.define_array(c => l_cursor, position => i_idx, n_tab => l_column_number_tab(i_idx), cnt => l_fetch_limit, lower_bound => 1);
$else          
          dbms_sql.define_array(c => l_cursor, position => i_idx, n_tab => p_column_value_tab(l_column_tab(i_idx).column_name).number$_table, cnt => l_fetch_limit, lower_bound => 1);
$end

        when 'VARCHAR2'
        then
$if data_sql_pkg.c_column_value_is_anydata $then
          l_column_varchar2_tab(i_idx)(1) := null;
          l_column_varchar2_tab(i_idx).delete;
          dbms_sql.define_array(c => l_cursor, position => i_idx, c_tab => l_column_varchar2_tab(i_idx), cnt => l_fetch_limit, lower_bound => 1);
$else          
          dbms_sql.define_array(c => l_cursor, position => i_idx, c_tab => p_column_value_tab(l_column_tab(i_idx).column_name).varchar2$_table, cnt => l_fetch_limit, lower_bound => 1);
$end          

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

    procedure check_row_count
    ( p_count in naturaln
    )
    is
    begin
      case p_count
        when 0
        then raise no_data_found;
        when 1
        then null;
        else raise too_many_rows;
      end case;
    end check_row_count;
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
$if data_sql_pkg.c_column_value_is_anydata $then          
            dbms_sql.column_value(l_cursor, i_idx, l_column_date_tab(i_idx));
$else
            dbms_sql.column_value(l_cursor, i_idx, p_column_value_tab(l_column_tab(i_idx).column_name).date$_table);
$end            
              
          when 'NUMBER'
          then
$if data_sql_pkg.c_column_value_is_anydata $then          
            dbms_sql.column_value(l_cursor, i_idx, l_column_number_tab(i_idx));
$else
            dbms_sql.column_value(l_cursor, i_idx, p_column_value_tab(l_column_tab(i_idx).column_name).number$_table);
$end            

          when 'VARCHAR2'
          then
$if data_sql_pkg.c_column_value_is_anydata $then          
            dbms_sql.column_value(l_cursor, i_idx, l_column_varchar2_tab(i_idx));
$else
            dbms_sql.column_value(l_cursor, i_idx, p_column_value_tab(l_column_tab(i_idx).column_name).varchar2$_table);
$end            

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

$if data_sql_pkg.c_column_value_is_anydata $then

    -- now copy the arrays to p_column_value_tab
    <<column_loop>>
    for i_idx in l_column_tab.first .. l_column_tab.last
    loop
      case l_column_tab(i_idx).data_type
        when 'DATE'
        then
          if p_max_row_count = 1
          then
            check_row_count(l_column_date_tab(i_idx).count);
            p_column_value_tab(l_column_tab(i_idx).column_name) := anydata.ConvertDate(l_column_date_tab(i_idx)(1));
          else
            p_column_value_tab(l_column_tab(i_idx).column_name) := anydata.ConvertCollection(l_column_date_tab(i_idx));
          end if;
          
        when 'NUMBER'
        then
          if p_max_row_count = 1
          then
            check_row_count(l_column_number_tab(i_idx).count);
            p_column_value_tab(l_column_tab(i_idx).column_name) := anydata.ConvertNumber(l_column_number_tab(i_idx)(1));
          else
            p_column_value_tab(l_column_tab(i_idx).column_name) := anydata.ConvertCollection(l_column_number_tab(i_idx));
          end if;

        when 'VARCHAR2'
        then
          if p_max_row_count = 1
          then
            check_row_count(l_column_varchar2_tab(i_idx).count);
            p_column_value_tab(l_column_tab(i_idx).column_name) := anydata.ConvertVarchar2(l_column_varchar2_tab(i_idx)(1));
          else
            p_column_value_tab(l_column_tab(i_idx).column_name) := anydata.ConvertCollection(l_column_varchar2_tab(i_idx));
          end if;
          
        else
          raise e_unimplemented_feature;
      end case;
    end loop column_loop;

$else

    l_column_name := p_column_value_tab.first;
    <<column_loop>>
    while l_column_name is not null
    loop
      p_column_value_tab(l_column_name).is_table := case when p_max_row_count = 1 then false else true end;

      if not(p_column_value_tab(l_column_name).is_table)
      then
        -- now copy the first array element to the scalar
        case p_column_value_tab(l_column_name).data_type
          when 'CLOB'
          then
            check_row_count(p_column_value_tab(l_column_name).clob$_table.count);
            p_column_value_tab(l_column_name).clob$ := p_column_value_tab(l_column_name).clob$_table(1);
          when 'BINARY_FLOAT'
          then
            check_row_count(p_column_value_tab(l_column_name).binary_float$_table.count);
            p_column_value_tab(l_column_name).binary_float$ := p_column_value_tab(l_column_name).binary_float$_table(1);
          when 'BINARY_DOUBLE'
          then
            check_row_count(p_column_value_tab(l_column_name).binary_double$_table.count);
            p_column_value_tab(l_column_name).binary_double$ := p_column_value_tab(l_column_name).binary_double$_table(1);
          when 'BLOB'
          then
            check_row_count(p_column_value_tab(l_column_name).blob$_table.count);
            p_column_value_tab(l_column_name).blob$ := p_column_value_tab(l_column_name).blob$_table(1);
          when 'BFILE'
          then
            check_row_count(p_column_value_tab(l_column_name).bfile$_table.count);
            p_column_value_tab(l_column_name).bfile$ := p_column_value_tab(l_column_name).bfile$_table(1);
          when 'DATE'
          then
            check_row_count(p_column_value_tab(l_column_name).date$_table.count);
            p_column_value_tab(l_column_name).date$ := p_column_value_tab(l_column_name).date$_table(1);
          when 'NUMBER'
          then
            check_row_count(p_column_value_tab(l_column_name).number$_table.count);
            p_column_value_tab(l_column_name).number$ := p_column_value_tab(l_column_name).number$_table(1);
          when 'UROWID'
          then
            check_row_count(p_column_value_tab(l_column_name).urowid$_table.count);
            p_column_value_tab(l_column_name).urowid$ := p_column_value_tab(l_column_name).urowid$_table(1);
          when 'VARCHAR2'
          then
            check_row_count(p_column_value_tab(l_column_name).varchar2$_table.count);
            p_column_value_tab(l_column_name).varchar2$ := p_column_value_tab(l_column_name).varchar2$_table(1);
          when 'TIMESTAMP'
          then
            check_row_count(p_column_value_tab(l_column_name).timestamp$_table.count);
            p_column_value_tab(l_column_name).timestamp$ := p_column_value_tab(l_column_name).timestamp$_table(1);
          else
            case
              when p_column_value_tab(l_column_name).data_type like 'TIMESTAMP(_%) WITH LOCAL TIME ZONE'
              then
                check_row_count(p_column_value_tab(l_column_name).timestamp_ltz$_table.count);
                p_column_value_tab(l_column_name).timestamp_ltz$ := p_column_value_tab(l_column_name).timestamp_ltz$_table(1);
              when p_column_value_tab(l_column_name).data_type like 'TIMESTAMP(_%) WITH TIME ZONE'
              then
                check_row_count(p_column_value_tab(l_column_name).timestamp_tz$_table.count);
                p_column_value_tab(l_column_name).timestamp_tz$ := p_column_value_tab(l_column_name).timestamp_tz$_table(1);
              when p_column_value_tab(l_column_name).data_type like 'INTERVAL DAY(_%) TO SECOND(_%)'
              then
                check_row_count(p_column_value_tab(l_column_name).interval_ds$_table.count);
                p_column_value_tab(l_column_name).interval_ds$ := p_column_value_tab(l_column_name).interval_ds$_table(1);
              when p_column_value_tab(l_column_name).data_type like 'INTERVAL YEAR(_%) TO MONTH'
              then
                check_row_count(p_column_value_tab(l_column_name).interval_ym$_table.count);
                p_column_value_tab(l_column_name).interval_ym$ := p_column_value_tab(l_column_name).interval_ym$_table(1);
            end case;
        end case;
      end if;

      l_column_name := p_column_value_tab.next(l_column_name);
    end loop column_loop;
    
$end -- $if data_sql_pkg.c_column_value_is_anydata $then

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

  construct_statement
  ( p_operation => p_operation
  , p_owner => p_owner
  , p_table_name => p_table_name
  , p_statement => p_statement
  , p_order_by => p_order_by
  , p_bind_variable_tab => p_bind_variable_tab
  , p_column_value_tab => p_column_value_tab
  , p_statement_lines => l_statement_lines
  , p_column_tab => l_column_tab
  );
  
  l_cursor := dbms_sql.open_cursor;

  begin
    dbms_sql.parse
    ( c => l_cursor
    , statement => l_statement_lines
    , lb => l_statement_lines.first
    , ub => l_statement_lines.last
    , lfflg => true
    , language_flag => dbms_sql.native
    );    
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

$if data_sql_pkg.c_column_value_is_anydata $then

  l_bind_variable_tab('DEPTNO') := anydata.ConvertNumber(20);

$else

  set_column_value( p_data_type => 'NUMBER', p_number$ => 20, p_column_value => l_bind_variable_tab('DEPTNO') );

$end -- $if data_sql_pkg.c_column_value_is_anydata $then

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
$if data_sql_pkg.c_column_value_is_anydata $then
        ut.expect(l_column_value_tab(l_column_value).gettypename(), 'data type ' || l_column_value).to_equal('SYS.NUMBER_TABLE');
        ut.expect(l_column_value_tab(l_column_value).GetCollection(l_number_tab), 'get collection ' || l_column_value).to_equal(DBMS_TYPES.SUCCESS);
$else        
        ut.expect(l_column_value_tab(l_column_value).data_type, 'data type ' || l_column_value).to_equal('NUMBER');
        ut.expect(l_column_value_tab(l_column_value).is_table, 'is table ' || l_column_value).to_be_true();
        l_number_tab := l_column_value_tab(l_column_value).number$_table;
$end        
        ut.expect(l_number_tab.count, 'collection count ' || l_column_value).to_equal(5);
        ut.expect(l_number_tab(1), 'element #1 for column ' || l_column_value).to_equal(case l_column_value when 'EMPNO' then 7369 else 20 end);
        ut.expect(l_number_tab(5), 'element #5 for column ' || l_column_value).to_equal(case l_column_value when 'EMPNO' then 7902 else 20 end);
        
      when l_column_value in ('JOB')
      then
$if data_sql_pkg.c_column_value_is_anydata $then
        ut.expect(l_column_value_tab(l_column_value).gettypename(), 'data type ' || l_column_value).to_equal('SYS.VARCHAR2_TABLE');
        ut.expect(l_column_value_tab(l_column_value).GetCollection(l_varchar2_tab), 'get collection ' || l_column_value).to_equal(DBMS_TYPES.SUCCESS);
$else        
        ut.expect(l_column_value_tab(l_column_value).data_type, 'data type ' || l_column_value).to_equal('VARCHAR2');
        ut.expect(l_column_value_tab(l_column_value).is_table, 'is table ' || l_column_value).to_be_true();
        l_varchar2_tab := l_column_value_tab(l_column_value).varchar2$_table;
$end        
        ut.expect(l_varchar2_tab.count, 'collection count ' || l_column_value).to_equal(5);
        ut.expect(l_varchar2_tab(1), 'element #1 for column ' || l_column_value).to_equal('CLERK');
        ut.expect(l_varchar2_tab(5), 'element #5 for column ' || l_column_value).to_equal('ANALYST');
        
      when l_column_value in ('HIREDATE')
      then
$if data_sql_pkg.c_column_value_is_anydata $then
        ut.expect(l_column_value_tab(l_column_value).gettypename(), 'data type ' || l_column_value).to_equal('SYS.DATE_TABLE');
        ut.expect(l_column_value_tab(l_column_value).GetCollection(l_date_tab), 'get collection ' || l_column_value).to_equal(DBMS_TYPES.SUCCESS);
$else        
        ut.expect(l_column_value_tab(l_column_value).data_type, 'data type ' || l_column_value).to_equal('DATE');
        ut.expect(l_column_value_tab(l_column_value).is_table, 'is table ' || l_column_value).to_be_true();
        l_date_tab := l_column_value_tab(l_column_value).date$_table;
$end        
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
$if data_sql_pkg.c_column_value_is_anydata $then

      l_bind_variable_tab('DEPTNO') := case when i_try <> 1 then anydata.ConvertNumber(i_try * 10) else empty_anydata end;

$else
     
      case
        when i_try <> 1
        then set_column_value( p_data_type => 'NUMBER', p_number$ => i_try * 10, p_column_value => l_bind_variable_tab('DEPTNO') );
        else set_column_value( p_column_value => l_bind_variable_tab('DEPTNO') );
      end case;      

$end -- $if data_sql_pkg.c_column_value_is_anydata $then

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
  l_data anydata;
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