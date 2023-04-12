CREATE OR REPLACE PACKAGE BODY "DATA_SQL_PKG" 
is

-- private

type column_tab_t is table of column_info_rec_t index by binary_integer;

function bind_variable
( p_column_name in varchar2
, p_bind_variable_type in varchar2 default 'I' -- (I)nput / (O)utput
)
return varchar2
deterministic
is
begin
  return ':' || p_bind_variable_type || '_' || p_column_name || '$';
end bind_variable;

function empty_bind_variable
( p_column_value in anydata_t
)
return boolean
deterministic
is
begin
  return p_column_value.data_type is null;
end empty_bind_variable;

procedure set_bind_variable
( p_cursor in integer
, p_column_name in varchar2
, p_column_value in anydata_t
, p_bind_variable_type in varchar2 default 'I' -- (I)nput / (O)utput
)
is
  l_bind_variable constant all_tab_columns.column_name%type := bind_variable(p_column_name, p_bind_variable_type);
begin
$if cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.SET_BIND_VARIABLE');
  dbug.print
  ( dbug."input"
  , 'p_column_name: %s; p_column_value.data_type: %s; p_column_value.is_table: %s; p_bind_variable_type: %s'
  , p_column_name
  , p_column_value.data_type
  , dbug.cast_to_varchar2(p_column_value.is_table)
  , p_bind_variable_type
  );
$end

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

$if cfg_pkg.c_debugging $then
  dbug.leave;
$end
end set_bind_variable;

procedure construct_statement
( p_operation in varchar2
, p_owner in varchar2
, p_table_name in varchar2
, p_statement in varchar2
, p_order_by in varchar2
, p_bind_variable_tab in column_value_tab_t
, p_column_value_tab in out nocopy column_value_tab_t
, p_statement_lines out nocopy dbms_sql.varchar2a
, p_input_column_tab out nocopy column_tab_t
, p_output_column_tab out nocopy column_tab_t
)
is
  l_first boolean;
  l_where_clause statement_t := null;
  l_column_name all_tab_columns.column_name%type;
  l_column_idx pls_integer;
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

  -- Merge does not allow for a RETURNING clause
  if p_operation = 'M'
  then
    p_column_value_tab.delete;
  end if;

  -- construct statement while defining the column table
  for r in
  ( select  *
    from    table(oracle_tools.data_sql_pkg.get_column_info(p_owner, p_table_name))
  )
  loop
    if p_bind_variable_tab.exists(r.column_name)
    then
      if empty_bind_variable(p_bind_variable_tab(r.column_name))
      then
        raise value_error;
      end if;
      
      p_input_column_tab(p_input_column_tab.count+1) := r;

      if p_operation = 'S'
      then
        l_where_clause := 
          l_where_clause ||
          utl_lms.format_message
          ( '%s"%s" = %s'
          , case
              when l_where_clause is not null
              then ' and '
            end
          , r.column_name
          , bind_variable(r.column_name)
          );
      elsif p_operation = 'M'
      then
        if r.pk_key_position is not null
        then
          l_where_clause :=
            l_where_clause ||
            case
              when l_where_clause is not null
              then ' and '
            end ||
            'd."' || r.column_name || '" = ' || 's."' || r.column_name || '"';
        end if;
      elsif p_operation in ('I', 'U', 'D')
      then
        if r.pk_key_position is not null
        then
          l_where_clause :=
            l_where_clause ||
            case
              when l_where_clause is not null
              then ' and '
            end ||
            'd."' || r.column_name || '" = ' || bind_variable(r.column_name);
        end if;
      end if;
    end if;

    if p_column_value_tab.exists(r.column_name)
    then
      p_output_column_tab(p_output_column_tab.count+1) := r;

      if p_operation = 'S'
      then
        p_statement_lines(p_statement_lines.count+1) :=
          case
            when p_statement_lines.count = 0
            then 'select  '
            else ',       '
          end ||
          's."' || r.column_name || '"';
      end if;
    end if;          
$if cfg_pkg.c_debugging $then
    dbug.print
    ( dbug."debug"
    , 'r.column_name: %s; r.pk_key_position: %s; bind variable?: %s; column value?: %s; where clause: "%s"'
    , r.column_name
    , r.pk_key_position
    , dbug.cast_to_varchar2(p_bind_variable_tab.exists(r.column_name))
    , dbug.cast_to_varchar2(p_column_value_tab.exists(r.column_name))
    , l_where_clause
    );
$end
  end loop;

$if cfg_pkg.c_debugging $then
  dbug.print
  ( dbug."debug"
  , 'where clause after get_column_info: "%s"'
  , l_where_clause
  );
$end

  case p_operation
    when 'S'
    then
      p_statement_lines(p_statement_lines.count+1) :=
        'from    (' ||
        nvl
        ( p_statement
        , utl_lms.format_message
          ( 'select * from "%s"."%s"%s'
          , p_owner
          , p_table_name
          , case
              when l_where_clause is not null
              then ' where ' || l_where_clause
            end
          )
        ) ||
        case
          when p_order_by is not null
          then ' order by ' || p_order_by
        end ||
        ') s';       

    when 'I'
    then
      if p_statement is not null
      then
        p_statement_lines(p_statement_lines.count+1) := p_statement;
      else
        p_statement_lines(p_statement_lines.count+1) :=
          'insert into ' || '"' || p_owner || '"."' || p_table_name || '"';

        -- list columns
        l_column_idx := p_input_column_tab.first;
        while l_column_idx is not null
        loop
          l_column_name := p_input_column_tab(l_column_idx).column_name;
          p_statement_lines(p_statement_lines.count+1) :=
            utl_lms.format_message
            ( '%s "%s"'
            , case
                when l_column_idx = p_input_column_tab.first
                then '('
                else ','
              end            
            , l_column_name
            );
          l_column_idx := p_input_column_tab.next(l_column_idx);
        end loop;
        p_statement_lines(p_statement_lines.count+1) :=
          ')';
          
        p_statement_lines(p_statement_lines.count+1) :=
          'values';
        l_column_idx := p_input_column_tab.first;
        while l_column_idx is not null
        loop
          l_column_name := p_input_column_tab(l_column_idx).column_name;
          p_statement_lines(p_statement_lines.count+1) :=
            utl_lms.format_message
            ( '%s %s'
            , case
                when l_column_idx = p_input_column_tab.first
                then '('
                else ','
              end            
            , bind_variable(l_column_name)
            );
          l_column_idx := p_input_column_tab.next(l_column_idx);
        end loop;
        p_statement_lines(p_statement_lines.count+1) :=
          ')';
      end if;

    when 'U'
    then
      if p_statement is not null
      then
        p_statement_lines(p_statement_lines.count+1) := p_statement;
      else
        p_statement_lines(p_statement_lines.count+1) :=
          'update  ' || '"' || p_owner || '"."' || p_table_name || '" d';

        l_column_idx := p_input_column_tab.first;
        l_first := true;
        while l_column_idx is not null
        loop
          l_column_name := p_input_column_tab(l_column_idx).column_name;
          if p_input_column_tab(l_column_idx).pk_key_position is null -- will not update key columns
          then
            p_statement_lines(p_statement_lines.count+1) :=
              utl_lms.format_message
              ( '%s     d."%s" = %s'
              , case
                  when l_first
                  then 'set'
                  else ',  '
                end
              , l_column_name
              , bind_variable(l_column_name)
              );
            l_first := false;
          end if;
          l_column_idx := p_input_column_tab.next(l_column_idx);
        end loop;
        p_statement_lines(p_statement_lines.count+1) :=
          'where   ' || l_where_clause;
      end if;

    when 'M'
    then
      if p_statement is not null
      then
        p_statement_lines(p_statement_lines.count+1) := p_statement;
      else
        p_statement_lines(p_statement_lines.count+1) :=
          'merge into ' || '"' || p_owner || '"."' || p_table_name || '" d';
        p_statement_lines(p_statement_lines.count+1) :=
          'using';
          
        -- set up USING with bind variables
        l_column_idx := p_input_column_tab.first;
        while l_column_idx is not null
        loop
          l_column_name := p_input_column_tab(l_column_idx).column_name;
          p_statement_lines(p_statement_lines.count+1) :=
            utl_lms.format_message
            ( '%s  %s as "%s"'
            , case
                when l_column_idx = p_input_column_tab.first
                then '( select'
                else '  ,     '
              end            
            , bind_variable(l_column_name)
            , l_column_name
            );
          l_column_idx := p_input_column_tab.next(l_column_idx);
        end loop;
        p_statement_lines(p_statement_lines.count+1) :=
          '  from    dual';
        p_statement_lines(p_statement_lines.count+1) :=
          ') s';
        p_statement_lines(p_statement_lines.count+1) :=
          'on ( ' || l_where_clause || ' )';

        /*
        -- use bind variables for insert clause (when not matched)
        */
        -- insert
        p_statement_lines(p_statement_lines.count+1) :=
          'when not matched then';
        l_column_idx := p_input_column_tab.first;
        while l_column_idx is not null
        loop
          l_column_name := p_input_column_tab(l_column_idx).column_name;
          p_statement_lines(p_statement_lines.count+1) :=
            utl_lms.format_message
            ( '%s "%s"'
            , case
                when l_column_idx = p_input_column_tab.first
                then '  insert ('
                else '         ,'
              end
            , l_column_name
            , l_column_name
            );
          l_column_idx := p_input_column_tab.next(l_column_idx);
        end loop;
        p_statement_lines(p_statement_lines.count+1) :=
          '         )';

        -- values
        l_column_idx := p_input_column_tab.first;
        while l_column_idx is not null
        loop
          l_column_name := p_input_column_tab(l_column_idx).column_name;
          p_statement_lines(p_statement_lines.count+1) :=
            utl_lms.format_message
            ( '%s s."%s"'
            , case
                when l_column_idx = p_input_column_tab.first
                then '  values ('
                else '         ,'
              end
            , l_column_name
            , l_column_name
            );
          l_column_idx := p_input_column_tab.next(l_column_idx);
        end loop;
        p_statement_lines(p_statement_lines.count+1) :=
          '         )';

        /*
        -- use bind variables for update clause (when matched)
        */
        p_statement_lines(p_statement_lines.count+1) :=
          'when matched then';
        l_column_idx := p_input_column_tab.first;
        l_first := true;
        while l_column_idx is not null
        loop
          l_column_name := p_input_column_tab(l_column_idx).column_name;
          if p_input_column_tab(l_column_idx).pk_key_position is null -- can not update columns from ON clause
          then
            p_statement_lines(p_statement_lines.count+1) :=
              utl_lms.format_message
              ( '%s d."%s" = s."%s"'
              , case
                  when l_first
                  then '  update  set'
                  else '          ,  '
                end
              , l_column_name
              , l_column_name
              );
            l_first := false;
          end if;
          l_column_idx := p_input_column_tab.next(l_column_idx);
        end loop;
      end if;

    when 'D'
    then
      if p_statement is not null
      then
        p_statement_lines(p_statement_lines.count+1) := p_statement;
      else
        p_statement_lines(p_statement_lines.count+1) :=
          'delete from ' || '"' || p_owner || '"."' || p_table_name || '" d';
        p_statement_lines(p_statement_lines.count+1) :=
          'where ' || l_where_clause;
      end if;

    else
      raise e_unimplemented_feature;
  end case;

  -- returning into clause for Insert, Update and Delete
  -- for merge it is not allowed
  if p_operation in ('I', 'U', 'D') and p_column_value_tab.count > 0 and p_statement is null
  then
    -- returning
    l_column_name := p_column_value_tab.first;
    while l_column_name is not null
    loop
      p_statement_lines(p_statement_lines.count+1) := 
        utl_lms.format_message
        ( '%s "%s"'
        , case
            when l_column_name = p_column_value_tab.first
            then 'returning         '
            else ',                 '
          end
        , l_column_name
        );
      l_column_name := p_column_value_tab.next(l_column_name);
    end loop;  

    -- into
    l_column_name := p_column_value_tab.first;
    while l_column_name is not null
    loop
      p_statement_lines(p_statement_lines.count+1) := 
        utl_lms.format_message
        ( '%s %s'
        , case
            when l_column_name = p_column_value_tab.first
            then 'into              '
            else ',                 '
          end
        , bind_variable(l_column_name, 'O')
        );
      l_column_name := p_column_value_tab.next(l_column_name);
    end loop;  
  end if;

$if cfg_pkg.c_debugging $then
  for i_idx in p_statement_lines.first .. p_statement_lines.last
  loop
    dbug.print(dbug."debug", 'p_statement_lines(%s): %s', to_char(i_idx, 'FM000'), p_statement_lines(i_idx));
  end loop;
  dbug.leave;
$end
end construct_statement;

-- public routines

function empty_anydata
return anydata_t
is
  l_anydata anydata_t;
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
, p_row_count in out nocopy natural
, p_column_value_tab in out nocopy column_value_tab_t
)
is
  l_max_row_count positive := null;
  l_statement_lines dbms_sql.varchar2a;
  l_cursor integer := null;
  l_column_name all_tab_columns.column_name%type;
  l_input_column_tab column_tab_t;
  l_output_column_tab column_tab_t;

  procedure set_bind_variables
  is
    l_column_idx pls_integer;
  begin
    l_column_idx := l_input_column_tab.first;
    while l_column_idx is not null
    loop
      l_column_name := l_input_column_tab(l_column_idx).column_name;
      set_bind_variable
      ( l_cursor
      , l_column_name
      , p_bind_variable_tab(l_column_name)
      );
      l_column_idx := l_input_column_tab.next(l_column_idx);
    end loop;

    -- for DML, l_output_column_tab defines output variables (RETURNING clause)
    if p_operation in ('I', 'U', 'D') and l_output_column_tab.count > 0
    then
      l_column_idx := l_output_column_tab.first;
      while l_column_idx is not null
      loop
        l_column_name := l_output_column_tab(l_column_idx).column_name;
        set_column_value
        ( p_data_type => l_output_column_tab(l_column_idx).data_type
        , p_is_table => true
        , p_column_value => p_column_value_tab(l_column_name)
        );

        -- Use empty values for output bind variable
        set_column_value    
        ( p_data_type => p_column_value_tab(l_column_name).data_type
        , p_is_table => p_column_value_tab(l_column_name).is_table
        , p_column_value => p_column_value_tab(l_column_name)
        );

        set_bind_variable
        ( l_cursor
        , l_column_name
        , p_column_value_tab(l_column_name)
        , 'O' -- output
        );

        l_column_idx := l_output_column_tab.next(l_column_idx);
      end loop;
    end if;
  end set_bind_variables;

  function fetch_limit
  return positiven
  is
  begin
    return
      case
        when l_max_row_count is null
        then 100
        when l_max_row_count = 1
        then 2 -- to detect too many rows
        else least(100, l_max_row_count)
      end;        
  end fetch_limit;

  procedure define_columns
  is
    l_fetch_limit constant positiven := fetch_limit;
  begin
    <<column_loop>>
    for i_idx in l_output_column_tab.first .. l_output_column_tab.last
    loop
      case l_output_column_tab(i_idx).data_type
        when 'CLOB'
        then
          p_column_value_tab(l_output_column_tab(i_idx).column_name).clob$_table.delete;
          dbms_sql.define_array(l_cursor, i_idx, p_column_value_tab(l_output_column_tab(i_idx).column_name).clob$_table, l_fetch_limit, 1);
          
        when 'BINARY_FLOAT'
        then
          p_column_value_tab(l_output_column_tab(i_idx).column_name).binary_float$_table.delete;
          dbms_sql.define_array(l_cursor, i_idx, p_column_value_tab(l_output_column_tab(i_idx).column_name).binary_float$_table, l_fetch_limit, 1);
          
        when 'BINARY_DOUBLE'
        then
          p_column_value_tab(l_output_column_tab(i_idx).column_name).binary_double$_table.delete;
          dbms_sql.define_array(l_cursor, i_idx, p_column_value_tab(l_output_column_tab(i_idx).column_name).binary_double$_table, l_fetch_limit, 1);
          
        when 'BLOB'
        then
          p_column_value_tab(l_output_column_tab(i_idx).column_name).blob$_table.delete;
          dbms_sql.define_array(l_cursor, i_idx, p_column_value_tab(l_output_column_tab(i_idx).column_name).blob$_table, l_fetch_limit, 1);
          
        when 'BFILE'
        then
          p_column_value_tab(l_output_column_tab(i_idx).column_name).bfile$_table.delete;
          dbms_sql.define_array(l_cursor, i_idx, p_column_value_tab(l_output_column_tab(i_idx).column_name).bfile$_table, l_fetch_limit, 1);
          
        when 'DATE'
        then
          p_column_value_tab(l_output_column_tab(i_idx).column_name).date$_table.delete;
          dbms_sql.define_array(l_cursor, i_idx, p_column_value_tab(l_output_column_tab(i_idx).column_name).date$_table, l_fetch_limit, 1);

        when 'NUMBER'
        then
          p_column_value_tab(l_output_column_tab(i_idx).column_name).number$_table.delete;
          dbms_sql.define_array(l_cursor, i_idx, p_column_value_tab(l_output_column_tab(i_idx).column_name).number$_table, l_fetch_limit, 1);

        when 'UROWID'
        then
          p_column_value_tab(l_output_column_tab(i_idx).column_name).urowid$_table.delete;
          dbms_sql.define_array(l_cursor, i_idx, p_column_value_tab(l_output_column_tab(i_idx).column_name).urowid$_table, l_fetch_limit, 1);
          
        when 'VARCHAR2'
        then
          p_column_value_tab(l_output_column_tab(i_idx).column_name).varchar2$_table.delete;
          dbms_sql.define_array(l_cursor, i_idx, p_column_value_tab(l_output_column_tab(i_idx).column_name).varchar2$_table, l_fetch_limit, 1);

        when 'TIMESTAMP'
        then
          p_column_value_tab(l_output_column_tab(i_idx).column_name).timestamp$_table.delete;
          dbms_sql.define_array(l_cursor, i_idx, p_column_value_tab(l_output_column_tab(i_idx).column_name).timestamp$_table, l_fetch_limit, 1);

        else
          case
            when l_output_column_tab(i_idx).data_type like 'TIMESTAMP(_%) WITH LOCAL TIME ZONE'
            then
              p_column_value_tab(l_output_column_tab(i_idx).column_name).timestamp_ltz$_table.delete;
              dbms_sql.define_array(l_cursor, i_idx, p_column_value_tab(l_output_column_tab(i_idx).column_name).timestamp_ltz$_table, l_fetch_limit, 1);
              
            when l_output_column_tab(i_idx).data_type like 'TIMESTAMP(_%) WITH TIME ZONE'
            then
              p_column_value_tab(l_output_column_tab(i_idx).column_name).timestamp_tz$_table.delete;
              dbms_sql.define_array(l_cursor, i_idx, p_column_value_tab(l_output_column_tab(i_idx).column_name).timestamp_tz$_table, l_fetch_limit, 1);
              
            when l_output_column_tab(i_idx).data_type like 'INTERVAL DAY(_%) TO SECOND(_%)'
            then
              p_column_value_tab(l_output_column_tab(i_idx).column_name).interval_ds$_table.delete;
              dbms_sql.define_array(l_cursor, i_idx, p_column_value_tab(l_output_column_tab(i_idx).column_name).interval_ds$_table, l_fetch_limit, 1);
              
            when l_output_column_tab(i_idx).data_type like 'INTERVAL YEAR(_%) TO MONTH'
            then
              p_column_value_tab(l_output_column_tab(i_idx).column_name).interval_ym$_table.delete;
              dbms_sql.define_array(l_cursor, i_idx, p_column_value_tab(l_output_column_tab(i_idx).column_name).interval_ym$_table, l_fetch_limit, 1);
            
            else
              raise_application_error(-20000, 'Unknown data type "' || l_output_column_tab(i_idx).data_type || '"');
          end case;
      end case;
    end loop;    
  end define_columns;

  procedure fetch_rows_and_columns
  is
    l_rows_fetched pls_integer; -- # rows fetched for last dbms_sql.fetch_rows()
    l_fetch_limit constant positiven := fetch_limit;

    procedure check_row_count
    ( p_count in naturaln
    )
    is
    begin
$if cfg_pkg.c_debugging $then
      dbug.print(dbug."debug", 'p_count: %s', p_count);
$end  
      case p_count
        when 0
        then raise no_data_found;
        when 1
        then null;
        else raise too_many_rows;
      end case;
    end check_row_count;
  begin
    p_row_count := 0; -- total row count
    
    <<fetch_loop>>
    loop
      l_rows_fetched := dbms_sql.fetch_rows(l_cursor);

$if cfg_pkg.c_debugging $then
      dbug.print(dbug."debug", '# rows fetched: %s', l_rows_fetched);
$end  

      exit fetch_loop when l_rows_fetched = 0;

      p_row_count := p_row_count + l_rows_fetched;
      
      if l_max_row_count = 1 and p_row_count > l_max_row_count -- must fetch one more than needed for too_many_rows
      then
        raise too_many_rows;
      end if;

      <<column_loop>>
      for i_idx in l_output_column_tab.first .. l_output_column_tab.last
      loop
        case l_output_column_tab(i_idx).data_type
          when 'CLOB'
          then
            dbms_sql.column_value(l_cursor, i_idx, p_column_value_tab(l_output_column_tab(i_idx).column_name).clob$_table);
            
          when 'BINARY_FLOAT'
          then
            dbms_sql.column_value(l_cursor, i_idx, p_column_value_tab(l_output_column_tab(i_idx).column_name).binary_float$_table);
            
          when 'BINARY_DOUBLE'
          then
            dbms_sql.column_value(l_cursor, i_idx, p_column_value_tab(l_output_column_tab(i_idx).column_name).binary_double$_table);
            
          when 'BLOB'
          then
            dbms_sql.column_value(l_cursor, i_idx, p_column_value_tab(l_output_column_tab(i_idx).column_name).blob$_table);
            
          when 'BFILE'
          then
            dbms_sql.column_value(l_cursor, i_idx, p_column_value_tab(l_output_column_tab(i_idx).column_name).bfile$_table);
            
          when 'DATE'
          then
            dbms_sql.column_value(l_cursor, i_idx, p_column_value_tab(l_output_column_tab(i_idx).column_name).date$_table);
              
          when 'NUMBER'
          then
            dbms_sql.column_value(l_cursor, i_idx, p_column_value_tab(l_output_column_tab(i_idx).column_name).number$_table);

          when 'UROWID'
          then
            dbms_sql.column_value(l_cursor, i_idx, p_column_value_tab(l_output_column_tab(i_idx).column_name).urowid$_table);
            
          when 'VARCHAR2'
          then
            dbms_sql.column_value(l_cursor, i_idx, p_column_value_tab(l_output_column_tab(i_idx).column_name).varchar2$_table);

          when 'TIMESTAMP'
          then
            dbms_sql.column_value(l_cursor, i_idx, p_column_value_tab(l_output_column_tab(i_idx).column_name).timestamp$_table);

          else
            case
              when l_output_column_tab(i_idx).data_type like 'TIMESTAMP(_%) WITH LOCAL TIME ZONE'
              then
                dbms_sql.column_value(l_cursor, i_idx, p_column_value_tab(l_output_column_tab(i_idx).column_name).timestamp_ltz$_table);
                
              when l_output_column_tab(i_idx).data_type like 'TIMESTAMP(_%) WITH TIME ZONE'
              then
                dbms_sql.column_value(l_cursor, i_idx, p_column_value_tab(l_output_column_tab(i_idx).column_name).timestamp_tz$_table);
                
              when l_output_column_tab(i_idx).data_type like 'INTERVAL DAY(_%) TO SECOND(_%)'
              then
                dbms_sql.column_value(l_cursor, i_idx, p_column_value_tab(l_output_column_tab(i_idx).column_name).interval_ds$_table);
                
              when l_output_column_tab(i_idx).data_type like 'INTERVAL YEAR(_%) TO MONTH'
              then
                dbms_sql.column_value(l_cursor, i_idx, p_column_value_tab(l_output_column_tab(i_idx).column_name).interval_ym$_table);
              
              else
                raise_application_error(-20000, 'Unknown data type "' || l_output_column_tab(i_idx).data_type || '"');
            end case;
        end case;
      end loop column_loop;
      
      if l_max_row_count > 1 and p_row_count >= l_max_row_count -- no need to fetch more
      then
        exit fetch_loop;
      end if;      

      exit fetch_loop when l_rows_fetched < l_fetch_limit;
    end loop fetch_loop;

    <<column_loop>>
    for i_idx in l_output_column_tab.first .. l_output_column_tab.last
    loop
      l_column_name := l_output_column_tab(i_idx).column_name;

      p_column_value_tab(l_column_name).data_type := l_output_column_tab(i_idx).data_type;
      p_column_value_tab(l_column_name).is_table := case when l_max_row_count = 1 then false else true end;

$if cfg_pkg.c_debugging $then
      dbug.print
      ( dbug."info"
      , 'l_column_name: %s; data type: %s'
      , l_column_name
      , p_column_value_tab(l_column_name).data_type
      );
$end

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
              else
                raise_application_error(-20000, 'Unknown data type "' || p_column_value_tab(l_column_name).data_type || '"');
            end case;
        end case;
      end if;
    end loop column_loop;
  end fetch_rows_and_columns;

  procedure variable_values
  is
  begin
$if cfg_pkg.c_debugging $then
    dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.VARIABLE_VALUES');
$end

    if l_output_column_tab.count > 0
    then
      <<column_loop>>
      for i_idx in l_output_column_tab.first .. l_output_column_tab.last
      loop
        case l_output_column_tab(i_idx).data_type
          when 'CLOB'
          then
            dbms_sql.variable_value(l_cursor, bind_variable(l_output_column_tab(i_idx).column_name, 'O'), p_column_value_tab(l_output_column_tab(i_idx).column_name).clob$_table);
            
          when 'BINARY_FLOAT'
          then
            dbms_sql.variable_value(l_cursor, bind_variable(l_output_column_tab(i_idx).column_name, 'O'), p_column_value_tab(l_output_column_tab(i_idx).column_name).binary_float$_table);
            
          when 'BINARY_DOUBLE'
          then
            dbms_sql.variable_value(l_cursor, bind_variable(l_output_column_tab(i_idx).column_name, 'O'), p_column_value_tab(l_output_column_tab(i_idx).column_name).binary_double$_table);
            
          when 'BLOB'
          then
            dbms_sql.variable_value(l_cursor, bind_variable(l_output_column_tab(i_idx).column_name, 'O'), p_column_value_tab(l_output_column_tab(i_idx).column_name).blob$_table);
            
          when 'BFILE'
          then
            dbms_sql.variable_value(l_cursor, bind_variable(l_output_column_tab(i_idx).column_name, 'O'), p_column_value_tab(l_output_column_tab(i_idx).column_name).bfile$_table);
            
          when 'DATE'
          then
            dbms_sql.variable_value(l_cursor, bind_variable(l_output_column_tab(i_idx).column_name, 'O'), p_column_value_tab(l_output_column_tab(i_idx).column_name).date$_table);

          when 'NUMBER'
          then
            dbms_sql.variable_value(l_cursor, bind_variable(l_output_column_tab(i_idx).column_name, 'O'), p_column_value_tab(l_output_column_tab(i_idx).column_name).number$_table);

          when 'UROWID'
          then
            dbms_sql.variable_value(l_cursor, bind_variable(l_output_column_tab(i_idx).column_name, 'O'), p_column_value_tab(l_output_column_tab(i_idx).column_name).urowid$_table);
            
          when 'VARCHAR2'
          then
            dbms_sql.variable_value(l_cursor, bind_variable(l_output_column_tab(i_idx).column_name, 'O'), p_column_value_tab(l_output_column_tab(i_idx).column_name).varchar2$_table);

          when 'TIMESTAMP'
          then
            dbms_sql.variable_value(l_cursor, bind_variable(l_output_column_tab(i_idx).column_name, 'O'), p_column_value_tab(l_output_column_tab(i_idx).column_name).timestamp$_table);

          else
            case
              when l_output_column_tab(i_idx).data_type like 'TIMESTAMP(_%) WITH LOCAL TIME ZONE'
              then
                dbms_sql.variable_value(l_cursor, bind_variable(l_output_column_tab(i_idx).column_name, 'O'), p_column_value_tab(l_output_column_tab(i_idx).column_name).timestamp_ltz$_table);
                
              when l_output_column_tab(i_idx).data_type like 'TIMESTAMP(_%) WITH TIME ZONE'
              then
                dbms_sql.variable_value(l_cursor, bind_variable(l_output_column_tab(i_idx).column_name, 'O'), p_column_value_tab(l_output_column_tab(i_idx).column_name).timestamp_tz$_table);
                
              when l_output_column_tab(i_idx).data_type like 'INTERVAL DAY(_%) TO SECOND(_%)'
              then
                dbms_sql.variable_value(l_cursor, bind_variable(l_output_column_tab(i_idx).column_name, 'O'), p_column_value_tab(l_output_column_tab(i_idx).column_name).interval_ds$_table);
                
              when l_output_column_tab(i_idx).data_type like 'INTERVAL YEAR(_%) TO MONTH'
              then
                dbms_sql.variable_value(l_cursor, bind_variable(l_output_column_tab(i_idx).column_name, 'O'), p_column_value_tab(l_output_column_tab(i_idx).column_name).interval_ym$_table);
              
              else
                raise_application_error(-20000, 'Unknown data type "' || l_output_column_tab(i_idx).data_type || '"');
            end case;
        end case;
      end loop;
    end if;
    
$if cfg_pkg.c_debugging $then
    dbug.leave;
$end
  end variable_values;

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
  , 'p_operation: %s; table: %s; p_statement: %s; p_row_count: %s'
  , p_operation
  , '"' || p_owner || '"."' || p_table_name || '"'
  , p_statement
  , p_row_count
  );
$end

  if p_operation = 'S'
  then
    l_max_row_count := p_row_count;
  end if;

  construct_statement
  ( p_operation => p_operation
  , p_owner => p_owner
  , p_table_name => p_table_name
  , p_statement => p_statement
  , p_order_by => p_order_by
  , p_bind_variable_tab => p_bind_variable_tab
  , p_column_value_tab => p_column_value_tab
  , p_statement_lines => l_statement_lines
  , p_input_column_tab => l_input_column_tab
  , p_output_column_tab => l_output_column_tab
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
$if cfg_pkg.c_debugging $then
  exception
    when others
    then
      dbug.on_error;
      dbug.print(dbug."error", 'error at position: %s', dbms_sql.last_error_position);
      if l_statement_lines.count > 0
      then
        for i_idx in l_statement_lines.first .. l_statement_lines.last
        loop
          dbug.print(dbug."error", 'statement line %s: %s', to_char(i_idx, 'FM000'), l_statement_lines(i_idx));
        end loop;
      end if;
      raise;
$end      
  end;

  set_bind_variables;
  
  -- query? define columns
  case p_operation
    when 'S'
    then define_columns;
    when 'I'
    then null;
    when 'U'
    then null;
    when 'M'
    then null;
    when 'D'
    then null;
    else raise e_unimplemented_feature;
  end case;

  p_row_count := dbms_sql.execute(l_cursor);

  -- query? fetch rows and columns
  case 
    when p_operation = 'S'
    then fetch_rows_and_columns;
    when p_operation in ('I', 'U', 'M', 'D')
    then variable_values;
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

procedure do
( p_operation in varchar2
, p_parent_table_name in varchar2
, p_table_bind_variable_tab in table_column_value_tab_t
, p_statement_tab in statement_tab_t
, p_order_by_tab in statement_tab_t
, p_owner in varchar2
, p_row_count_tab in out nocopy row_count_tab_t
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
    if not(p_row_count_tab.exists(l_table_name))
    then
      p_row_count_tab(l_table_name) := null;
    end if;
    do
    ( p_operation => p_operation
    , p_table_name => l_table_name
    , p_bind_variable_tab => case when p_table_bind_variable_tab.exists(l_table_name) then p_table_bind_variable_tab(l_table_name) else empty_column_value_tab end
    , p_statement => case when p_statement_tab.exists(l_table_name) then p_statement_tab(l_table_name) end
    , p_order_by => case when p_order_by_tab.exists(l_table_name) then p_order_by_tab(l_table_name) end
    , p_owner => p_owner
    , p_row_count => p_row_count_tab(l_table_name)
    , p_column_value_tab => p_table_column_value_tab(l_table_name)
    );
  end loop;
end do;

function get_column_info
( p_owner in all_tab_columns.owner%type
, p_table_name in all_tab_columns.table_name%type
, p_column_name_list in all_tab_columns.column_name%type
)
return column_info_tab_t
pipelined
is
begin
  for r in
  ( select  tc.owner
    ,       tc.table_name
    ,       tc.column_name
    ,       tc.data_type
    ,       tc.data_length
    ,       cc.pk_key_position
    from    all_tab_columns tc
            inner join
            ( select  e.column_value as column_name_expr
              from    table
                      ( oracle_tools.api_pkg.list2collection
                        ( p_value_list => p_column_name_list
                        , p_sep => ','
                        , p_ignore_null => 1
                        )
                      ) e
            ) e
            on tc.column_name like e.column_name_expr escape '\'
            left outer join 
            ( select  cc.owner
              ,       cc.table_name
              ,       cc.column_name
              ,       cc.position as pk_key_position
              from    all_cons_columns cc
                      inner join all_constraints c
                      on c.owner = cc.owner and
                         c.table_name = cc.table_name and
                         c.constraint_name = cc.constraint_name and
                         c.constraint_type = 'P'
            ) cc
            on cc.owner = tc.owner and cc.table_name = tc.table_name and cc.column_name = tc.column_name
    where   tc.owner = p_owner
    and     tc.table_name = p_table_name
    order by
            cc.pk_key_position nulls last
    ,       tc.column_id
  )
  loop
    pipe row (r);
  end loop;

  return;
end get_column_info;

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
  l_row_count natural := null;
begin
$if cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.UT_DO_EMP');
$end

  set_column_value( p_data_type => 'NUMBER', p_number$ => 20, p_column_value => l_bind_variable_tab('DEPTNO') );

  l_column_value_tab('EMPNO') := null;
  l_column_value_tab('JOB') := null;
  l_column_value_tab('HIREDATE') := null;
  l_column_value_tab('DEPTNO') := null;
  
  do
  ( p_operation => 'S'
  , p_table_name => 'MY_EMP'
  , p_bind_variable_tab => l_bind_variable_tab
  , p_order_by => 'EMPNO'
  , p_row_count => l_row_count
  , p_column_value_tab => l_column_value_tab
  );

  ut.expect(l_column_value_tab.count, '# columns').to_equal(4);
  ut.expect(l_row_count, 'fetch count').to_equal(5);

  l_column_value := l_column_value_tab.first;
  while l_column_value is not null
  loop
    case
      when l_column_value in ('EMPNO', 'DEPTNO')
      then
        ut.expect(l_column_value_tab(l_column_value).data_type, 'data type ' || l_column_value).to_equal('NUMBER');
        ut.expect(l_column_value_tab(l_column_value).is_table, 'is table ' || l_column_value).to_be_true();
        l_number_tab := l_column_value_tab(l_column_value).number$_table;
        ut.expect(l_number_tab.count, 'collection count ' || l_column_value).to_equal(l_row_count);
        ut.expect(l_number_tab(1), 'element #1 for column ' || l_column_value).to_equal(case l_column_value when 'EMPNO' then 7369 else 20 end);
        ut.expect(l_number_tab(5), 'element #5 for column ' || l_column_value).to_equal(case l_column_value when 'EMPNO' then 7902 else 20 end);
        
      when l_column_value in ('JOB')
      then
        ut.expect(l_column_value_tab(l_column_value).data_type, 'data type ' || l_column_value).to_equal('VARCHAR2');
        ut.expect(l_column_value_tab(l_column_value).is_table, 'is table ' || l_column_value).to_be_true();
        l_varchar2_tab := l_column_value_tab(l_column_value).varchar2$_table;
        ut.expect(l_varchar2_tab.count, 'collection count ' || l_column_value).to_equal(l_row_count);
        ut.expect(l_varchar2_tab(1), 'element #1 for column ' || l_column_value).to_equal('CLERK');
        ut.expect(l_varchar2_tab(5), 'element #5 for column ' || l_column_value).to_equal('ANALYST');
        
      when l_column_value in ('HIREDATE')
      then
        ut.expect(l_column_value_tab(l_column_value).data_type, 'data type ' || l_column_value).to_equal('DATE');
        ut.expect(l_column_value_tab(l_column_value).is_table, 'is table ' || l_column_value).to_be_true();
        l_date_tab := l_column_value_tab(l_column_value).date$_table;
        ut.expect(l_date_tab.count, 'collection count ' || l_column_value).to_equal(l_row_count);
        ut.expect(l_date_tab(1), 'element #1 for column ' || l_column_value).to_equal(to_date('17-12-1980','dd-mm-yyyy'));
        ut.expect(l_date_tab(5), 'element #5 for column ' || l_column_value).to_equal(to_date('3-12-1981','dd-mm-yyyy'));
    end case;

    l_column_value := l_column_value_tab.next(l_column_value);
  end loop;

  -- get employees for department 0 (i_try 0), all (i_try 1) or 20 (i_try 2) check no_data_found / too_many_rows
  for i_try in 0..2
  loop
    begin
      case
        when i_try <> 1
        then set_column_value( p_data_type => 'NUMBER', p_number$ => i_try * 10, p_column_value => l_bind_variable_tab('DEPTNO') );
        else l_bind_variable_tab.delete;
      end case;      

      l_row_count := case when i_try < 2 then 1 else 5 end;
      do
      ( p_operation => 'S'
      , p_table_name => 'MY_EMP'
      , p_bind_variable_tab => l_bind_variable_tab
      , p_row_count => l_row_count
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
end ut_do_emp;

procedure ut_do_dept
is
  l_bind_variable_tab column_value_tab_t;
  l_column_value_sel_tab column_value_tab_t;
  l_column_value_upd_tab column_value_tab_t;
  l_column_value all_tab_columns.column_name%type;
  l_date_tab dbms_sql.date_table;
  l_number_tab dbms_sql.number_table;
  l_varchar2_tab dbms_sql.varchar2_table;
  l_row_count natural := null;
  l_query constant varchar2(4000) := 'select deptno, lower(dname) as dname, lower(loc) as loc from my_dept';
  l_actual   sys_refcursor;
  l_expected sys_refcursor;
  l_statement_lines dbms_sql.varchar2a;
  l_input_column_tab column_tab_t;
  l_output_column_tab column_tab_t;
begin
$if cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.UT_DO_DEPT');
$end

  l_column_value_sel_tab('DEPTNO') := null;
  l_column_value_sel_tab('DNAME') := null;
  l_column_value_sel_tab('LOC') := null;

  open l_expected for l_query;
  
  do
  ( p_operation => 'S'
  , p_table_name => 'MY_DEPT'
  , p_bind_variable_tab => l_bind_variable_tab
  , p_statement => l_query
  , p_row_count => l_row_count
  , p_column_value_tab => l_column_value_sel_tab
  );

  ut.expect(l_column_value_sel_tab.count, '# columns').to_equal(3);
  ut.expect(l_row_count, 'fetch count').to_equal(4);

  -- use previous select output as input for update
  l_row_count := null;
  do
  ( p_operation => 'U'
  , p_table_name => 'MY_DEPT'
  , p_bind_variable_tab => l_column_value_sel_tab
  , p_row_count => l_row_count
  , p_column_value_tab => l_column_value_upd_tab
  );

  construct_statement
  ( p_operation => 'U'
  , p_owner => user
  , p_table_name => 'MY_DEPT'
  , p_statement => null
  , p_order_by => null
  , p_bind_variable_tab => l_column_value_sel_tab
  , p_column_value_tab => l_column_value_upd_tab
  , p_statement_lines => l_statement_lines
  , p_input_column_tab => l_input_column_tab
  , p_output_column_tab => l_output_column_tab
  );

  ut.expect(l_statement_lines(1), 'statement line #1').to_equal('update  "ORACLE_TOOLS"."MY_DEPT" d');
  ut.expect(l_statement_lines(2), 'statement line #2').to_equal('set     d."DNAME" = :I_DNAME$');
  ut.expect(l_statement_lines(3), 'statement line #3').to_equal(',       d."LOC" = :I_LOC$');
  ut.expect(l_statement_lines(4), 'statement line #4').to_equal('where   d."DEPTNO" = :I_DEPTNO$');

  ut.expect(l_column_value_upd_tab.count, '# columns').to_equal(0);
  ut.expect(l_row_count, 'update count').to_equal(4);

  open l_actual for 'select * from my_dept';

  ut.expect(l_actual).to_equal(l_expected);

$if cfg_pkg.c_debugging $then
  dbug.leave;
$end
end;

procedure ut_do_emp_dept
is
  l_table_bind_variable_tab table_column_value_tab_t;
  l_row_count_tab row_count_tab_t;
  l_table_column_value_tab table_column_value_tab_t;
  l_count pls_integer;
  l_cursor sys_refcursor;
  l_table_name all_tab_columns.table_name%type;
begin
$if cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.UT_DO_EMP_DEPT');
$end

  set_column_value
  ( p_data_type => 'NUMBER'
  , p_number$ => 20
  , p_column_value => l_table_bind_variable_tab('MY_DEPT')('DEPTNO')
  );
  l_row_count_tab('MY_DEPT') := 1;
  for r_col in ( select * from table(data_sql_pkg.get_column_info(user, 'MY_DEPT')) )
  loop
    set_column_value( p_column_value => l_table_column_value_tab(r_col.table_name)(r_col.column_name) );
  end loop;
  
  set_column_value
  ( p_data_type => 'NUMBER'
  , p_number$ => 20
  , p_column_value => l_table_bind_variable_tab('MY_EMP')('DEPTNO')
  );
  l_row_count_tab('MY_EMP') := null;
  for r_col in ( select * from table(data_sql_pkg.get_column_info(user, 'MY_EMP')) )
  loop
    set_column_value( p_column_value => l_table_column_value_tab(r_col.table_name)(r_col.column_name) );
  end loop;

  do
  ( p_operation => 'S'
  , p_parent_table_name => 'MY_DEPT'
  , p_table_bind_variable_tab => l_table_bind_variable_tab
  , p_row_count_tab => l_row_count_tab
  , p_table_column_value_tab => l_table_column_value_tab
  );

  -- use output from previous call as input for bind variables but just the PK columns
  l_table_bind_variable_tab.delete;
  l_table_bind_variable_tab('MY_DEPT')('DEPTNO') := l_table_column_value_tab('MY_DEPT')('DEPTNO');
  l_table_bind_variable_tab('MY_EMP')('EMPNO') := l_table_column_value_tab('MY_EMP')('EMPNO');
  l_row_count_tab.delete;
  do
  ( p_operation => 'D'
  , p_parent_table_name => 'MY_DEPT'
  , p_table_bind_variable_tab => l_table_bind_variable_tab
  , p_row_count_tab => l_row_count_tab
  , p_table_column_value_tab => l_table_column_value_tab
  );

  for i_idx in 1..2
  loop
    l_table_name := case i_idx when 1 then 'MY_DEPT' else 'MY_EMP' end;
    open l_cursor for 'select count(*) from ' || l_table_name || ' where deptno = 20';
    fetch l_cursor into l_count;
    close l_cursor;

    ut.expect(l_count, l_table_name || ' count after delete').to_equal(0);
  end loop;

  -- use output from previous call as input for bind variables but just the PK columns
  l_table_bind_variable_tab := l_table_column_value_tab;
  l_row_count_tab.delete;
  do
  ( p_operation => 'I'
  , p_parent_table_name => 'MY_DEPT'
  , p_table_bind_variable_tab => l_table_bind_variable_tab
  , p_row_count_tab => l_row_count_tab
  , p_table_column_value_tab => l_table_column_value_tab
  );

  for i_idx in 1..2
  loop
    l_table_name := case i_idx when 1 then 'MY_DEPT' else 'MY_EMP' end;
    open l_cursor for 'select count(*) from ' || l_table_name || ' where deptno = 20';
    fetch l_cursor into l_count;
    close l_cursor;

    ut.expect(l_count, l_table_name || ' count after delete').to_equal(case i_idx when 1 then 1 else 5 end);
  end loop;
  
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
