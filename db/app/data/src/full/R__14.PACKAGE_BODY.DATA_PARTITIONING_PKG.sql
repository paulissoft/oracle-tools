CREATE OR REPLACE PACKAGE BODY "DATA_PARTITIONING_PKG" 
is

-- PRIVATE section

c_high_value_timestamp_expr constant varchar2(100 char) := q'[TIMESTAMP' ____-__-__ __:__:__']' ;
"yyyy-mm-dd hh24:mi:ss" constant varchar2(100) := 'yyyy-mm-dd hh24:mi:ss';
"yyyy-mm-dd hh24:mi:ss.ff9" constant varchar2(100) := 'yyyy-mm-dd hh24:mi:ss.ff9';
"yyyymmdd" constant varchar2(100) := 'yyyymmdd';

$if cfg_pkg.c_debugging $then

procedure print(p_range_rec in t_range_rec)
is
begin
  dbug.print
  ( dbug."info"
  , 'partition_name: %s; partition_position: %s; interval: %s; lwb_incl: %s; upb_excl: %s'
  , p_range_rec.partition_name
  , p_range_rec.partition_position
  , p_range_rec.interval
  , p_range_rec.lwb_incl
  , p_range_rec.upb_excl
  );
end print;  

$end

procedure execute_immediate
( p_ddl in varchar2
)
is
begin
$if cfg_pkg.c_debugging $then
  dbug.print(dbug."info", 'p_ddl: %s', p_ddl);
$end

  execute immediate p_ddl;
end execute_immediate;

-- PUBLIC routines

function alter_table_range_partitioning
( p_table_owner in varchar2
, p_table_name in varchar2
, p_partition_by in varchar2
, p_interval in varchar2
, p_subpartition_by in varchar2
, p_partition_clause in varchar2
, p_online in boolean
, p_update_indexes in varchar2
)
return varchar2
is
  l_ddl varchar2(32767 char);
begin
$if cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.ALTER_TABLE_RANGE_PARTITIONING');
  dbug.print
  ( dbug."input"
  , 'p_table_owner: %s; p_table_name: %s; p_partition_by: %s; p_interval: %s; p_subpartition_by: %s'
  , p_table_owner
  , p_table_name
  , p_partition_by
  , p_interval
  , p_subpartition_by
  );
  dbug.print
  ( dbug."input"
  , 'p_partition_clause: %s; p_online: %s; p_update_indexes: %s'
  , p_partition_clause
  , dbug.cast_to_varchar2(p_online)
  , p_update_indexes
  );
$end

  l_ddl := utl_lms.format_message
           ( 'ALTER TABLE %s.%s MODIFY %s%s%s%s%s%s'
           , oracle_tools.data_api_pkg.dbms_assert$enquote_name(p_table_owner, 'owner')
           , oracle_tools.data_api_pkg.dbms_assert$enquote_name(p_table_name, 'table')
           , case when p_partition_by is not null then chr(10) || 'PARTITION BY ' || p_partition_by end
           , case when p_interval is not null then chr(10) || 'INTERVAL ' || p_interval end
           , case when p_subpartition_by is not null then chr(10) || 'SUBPARTITION BY ' || p_subpartition_by end
           , case when p_partition_clause is not null then chr(10) || p_partition_clause end
           , case when p_online then chr(10) || 'ONLINE' end
           , case when p_update_indexes is not null then chr(10) || 'UPDATE INDEXES ' || p_update_indexes end
           );

$if cfg_pkg.c_debugging $then
  dbug.print(dbug."output", 'return: %s', l_ddl);
  dbug.leave;
$end

  return l_ddl;           
end alter_table_range_partitioning;

function show_partitions_range
( p_table_owner in varchar2
, p_table_name in varchar2
)
return t_range_tab
pipelined
is
  l_table_owner constant all_tab_partitions.table_owner%type :=
    trim('"' from oracle_tools.data_api_pkg.dbms_assert$enquote_name(p_table_owner, 'owner'));
  l_table_name constant all_tab_partitions.table_name%type :=
    trim('"' from oracle_tools.data_api_pkg.dbms_assert$enquote_name(p_table_name, 'table'));
  l_query constant varchar2(4000 char) :=
    utl_lms.format_message
    ( q'[
select  p.high_value
,       p.partition_name
,       p.partition_position
,       p.interval
from    all_tab_partitions p
        inner join all_part_tables t
        on t.owner = p.table_owner and 
           t.table_name = p.table_name and
           t.partitioning_type = 'RANGE'
where   p.table_owner = '%s'
and     p.table_name = '%s'
]'
    , l_table_owner
    , l_table_name
    );
  l_cnt simple_integer := 0;
begin
$if cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.SHOW_PARTITIONS_RANGE');
  dbug.print(dbug."input", 'p_table_owner: %s; p_table_name: %s', p_table_owner, p_table_name);
  dbug.print(dbug."info", 'l_query: %s', l_query);
$end

  for r in
  ( with high_values as
    ( select  dbms_xmlgen.getxmltype(l_query) as xml
      from    dual
    ), rng as
    ( select  partition_name
      ,       partition_position
      ,       interval
      ,       lag(high_value) over (order by partition_position) lwb_incl
      ,       high_value as upb_excl
      from    high_values p
      ,       xmltable
              ( '/ROWSET/ROW'
                passing p.xml
                columns partition_name varchar2(128) path '/ROW/PARTITION_NAME'
                ,       partition_position integer path '/ROW/PARTITION_POSITION'
                ,       interval varchar2(3) path '/ROW/INTERVAL'
                ,       high_value varchar2(4000 char) path '/ROW/HIGH_VALUE'
              )
    )
    select  rng.*
    from    rng
    order by
            rng.partition_position 
  )
  loop
    pipe row (r);
    l_cnt := l_cnt + 1;
  end loop;

$if cfg_pkg.c_debugging $then
  dbug.print(dbug."info", 'l_cnt: %s', l_cnt);
  dbug.leave;
$end

  return; -- essential
end show_partitions_range;

function find_partitions_range
( p_table_owner in varchar2
, p_table_name in varchar2
, p_reference_timestamp in timestamp
, p_operator in varchar2
)
return t_range_tab
pipelined
is
  l_lwb_incl_timestamp timestamp;
  l_upb_excl_timestamp timestamp;
begin
$if cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.FIND_PARTITIONS_RANGE');
  dbug.print
  ( dbug."input"
  , 'p_table_name: %s; p_reference_timestamp: %s; p_operator: %s'
  , p_table_name
  , to_char(p_reference_timestamp, "yyyy-mm-dd hh24:mi:ss.ff9")
  , p_operator
  );
$end

  <<find_loop>>
  for r in
  ( select  t.*
    from    table(oracle_tools.data_partitioning_pkg.show_partitions_range(p_table_owner, p_table_name)) t
  )
  loop
    -- Both r.lwb_incl and r.upb_excl can be empty, MAXVALUE or something like TIMESTAMP' 2000-01-01 00:00:00'.
    l_lwb_incl_timestamp := case when r.lwb_incl like c_high_value_timestamp_expr then to_timestamp(substr(r.lwb_incl, 12, 19), "yyyy-mm-dd hh24:mi:ss") end;
    l_upb_excl_timestamp := case when r.upb_excl like c_high_value_timestamp_expr then to_timestamp(substr(r.upb_excl, 12, 19), "yyyy-mm-dd hh24:mi:ss") end;

    -- Possible ranges with respect to R (reference date). [] means a closed range (both ends not null)
    -- 1a. (]R
    -- 1b. []R
    -- 2a. (R)
    -- 2b. [R]
    -- 2c. (R]
    -- 2d. [R)
    -- 3a. R[)
    -- 3b. R[]
    if ( p_operator = '<' and
         -- 1a. and 1b.
         ( l_upb_excl_timestamp is not null and l_upb_excl_timestamp <= p_reference_timestamp ) 
       ) or
       ( p_operator = '=' and
         -- 2a. 2b. 2c. and 2d.
         ( l_lwb_incl_timestamp is null or l_lwb_incl_timestamp <= p_reference_timestamp ) and
         ( l_upb_excl_timestamp is null or l_upb_excl_timestamp  > p_reference_timestamp )
       ) or
       ( p_operator = '>' and
         -- 3a. and 3b.
         ( l_lwb_incl_timestamp is not null and l_lwb_incl_timestamp > p_reference_timestamp )
       )
    then
$if cfg_pkg.c_debugging $then
      print(r);
$end
      pipe row (r);

      exit find_loop when p_operator = '='; -- small optimalization
    end if;
  end loop find_loop;

$if cfg_pkg.c_debugging $then
  dbug.leave;
$end

  return; -- essential
end find_partitions_range;

procedure create_new_partitions 
( p_table_owner in varchar2 -- checked by DATA_API_PKG.DBMS_ASSERT$SIMPLE_SQL_NAME()
, p_table_name in varchar2 -- checked by DATA_API_PKG.DBMS_ASSERT$SIMPLE_SQL_NAME()
, p_reference_timestamp in timestamp -- create partitions where the last one created will includes this timestamp
, p_update_index_clauses in varchar2 -- can be empty or UPDATE GLOBAL INDEXES
, p_nr_days_per_partition in positiven -- the number of days per partition
)
is
  l_table_owner constant all_tab_partitions.table_owner%type :=
    oracle_tools.data_api_pkg.dbms_assert$enquote_name(p_table_owner, 'owner');
  l_table_name constant all_tab_partitions.table_name%type :=
    oracle_tools.data_api_pkg.dbms_assert$enquote_name(p_table_name, 'table');
  l_found pls_integer;
  l_partition_last_rec t_range_rec;
  l_upb_excl_timestamp timestamp;
  l_ddl varchar2(32767 char) := null;

  -- ORA-14074: partition bound must collate higher than that of the last partition
  -- See also https://community.oracle.com/tech/developers/discussion/2194501/ora-14074-partition-bound-must-collate-higher-than-that-of-the-last-partit
  e_partition_must_be_split exception;

  procedure cleanup
  is
  begin
    if l_ddl is not null -- something has been dropped?
    then
      -- Recalculate statistics for (sub)partitions
      dbms_stats.gather_table_stats
      ( ownname => l_table_owner
      , tabname => l_table_name
      , granularity => 'PARTITION'
      );
      dbms_stats.gather_table_stats
      ( ownname => l_table_owner
      , tabname => l_table_name
      , granularity => 'SUBPARTITION'
      );
    end if;
  end cleanup;
begin
$if cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.CREATE_NEW_PARTITIONS');
  dbug.print
  ( dbug."input"
  , 'p_table_owner: %s; p_table_name: %s; p_reference_timestamp: %s; p_update_index_clauses: %s; p_nr_days_per_partition: %s'
  , p_table_owner
  , p_table_name
  , to_char(p_reference_timestamp, "yyyy-mm-dd hh24:mi:ss.ff9")
  , p_update_index_clauses
  , p_nr_days_per_partition
  );
$end

  -- We must only add partitions if it is a table without an interval range partition.
  select  1
  into    l_found
  from    all_part_tables t
  where   t.owner = trim('"' from l_table_owner)
  and     t.table_name = trim('"' from l_table_name)
  and     t.partitioning_type = 'RANGE'
  and     t.interval is null -- partitioned table but no interval
  ;

  -- There are three cases:
  -- 1) there is a partition with a range where the reference date lies inside
  --    a) if the upper bound is MAXVALUE: we have to split since MAXVALUE is only meant as last resort
  --    b) else, we are done since there is a bounded upper bound
  -- 2) there is a partition with a range higher than the reference date: we are done
  -- 3) there are no partitions with a range equal or higher
  --    a) there is a partition with a range less then the reference date: we must create partitions upwards starting from the last found
  --    b) there are no partitions at all: create a MAXVALUE partition

  <<case_loop>>
  for i_case in 1..3
  loop
    begin
      select  p.* 
      into    l_partition_last_rec
      from    ( select  p.*
                from    table
                        ( oracle_tools.data_partitioning_pkg.find_partitions_range
                          ( l_table_owner
                          , l_table_name
                          , p_reference_timestamp
                          , case i_case
                              when 1 then '='
                              when 2 then '>'
                              when 3 then '<'
                            end
                          )
                        ) p
                order by
                        case i_case
                          when 3
                          then -1 -- order by decreasing p.partition_position for <
                          else +1 -- order by increasing p.partition_position for = and >
                        end * p.partition_position asc
              ) p
      where   rownum = 1
      ;


$if cfg_pkg.c_debugging $then
      print(l_partition_last_rec);
$end

      case i_case
        when 1
        then
          case
            when l_partition_last_rec.upb_excl = 'MAXVALUE' -- case 1a
            then
              -- remove time info
              l_upb_excl_timestamp :=
                to_timestamp
                ( to_char
                  ( p_reference_timestamp + numtodsinterval(p_nr_days_per_partition, 'DAY')
                  , "yyyymmdd"
                  )
                , "yyyymmdd"
                );
              l_ddl :=
                utl_lms.format_message
                ( q'[ALTER TABLE %s.%s SPLIT PARTITION "%s" AT (TIMESTAMP '%s') INTO (PARTITION %s, PARTITION "%s") %s]'
                , l_table_owner
                , l_table_name
                , l_partition_last_rec.partition_name
                , to_char(l_upb_excl_timestamp, "yyyy-mm-dd hh24:mi:ss")
                , oracle_tools.data_api_pkg.dbms_assert$enquote_name
                  ( 'P_LT_' || to_char(l_upb_excl_timestamp, "yyyymmdd")
                  , 'partition'
                  )
                , l_partition_last_rec.partition_name
                , p_update_index_clauses
                );
              execute_immediate(l_ddl);
              
            when l_partition_last_rec.upb_excl like c_high_value_timestamp_expr -- case 1b
            then
              null;
              
          end case;
          
        when 2
        then
          null;
        
        when 3
        then
          -- 3a
          -- upb_excl is something like TIMESTAMP' 2000-01-01 00:00:00'.
          l_upb_excl_timestamp := to_timestamp(substr(l_partition_last_rec.upb_excl, 12, 19), "yyyy-mm-dd hh24:mi:ss");

          loop
            l_upb_excl_timestamp := l_upb_excl_timestamp + numtodsinterval(p_nr_days_per_partition, 'DAY');

$if cfg_pkg.c_debugging $then
            dbug.print(dbug."info", 'partition high value: %s', to_char(l_upb_excl_timestamp, "yyyy-mm-dd hh24:mi:ss.ff9"));
$end

            exit when l_upb_excl_timestamp > p_reference_timestamp;

            l_ddl := utl_lms.format_message
                     ( q'[ALTER TABLE %s.%s ADD PARTITION %s VALUES LESS THAN (TIMESTAMP '%s') %s]'
                     , l_table_owner
                     , l_table_name
                     , oracle_tools.data_api_pkg.dbms_assert$enquote_name
                       ( 'P_LT_' || to_char(l_upb_excl_timestamp, "yyyymmdd")
                       , 'partition'
                       )
                     , to_char(l_upb_excl_timestamp, "yyyy-mm-dd hh24:mi:ss")
                     , p_update_index_clauses
                     );
                      
            execute_immediate(l_ddl);
          end loop;
      end case;
      
      exit case_loop; -- case found: stop
    exception
      when no_data_found
      then
        if i_case = 3
        then
          -- 3b        
          l_ddl := utl_lms.format_message
                   ( q'[ALTER TABLE %s.%s ADD PARTITION P_LAST VALUES LESS THAN (MAXVALUE) %s]'
                   , l_table_owner
                   , l_table_name
                   , p_update_index_clauses
                   );
          execute_immediate(l_ddl);
        end if;
    end;    
  end loop case_loop;

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
end create_new_partitions;

procedure drop_old_partitions 
( p_table_owner in varchar2
, p_table_name in varchar2
, p_reference_timestamp in timestamp
, p_update_index_clauses in varchar2
, p_backup in boolean
)
is
  l_table_owner constant all_tab_partitions.table_owner%type :=
    oracle_tools.data_api_pkg.dbms_assert$enquote_name(p_table_owner, 'owner');
  l_table_name constant all_tab_partitions.table_name%type :=
    oracle_tools.data_api_pkg.dbms_assert$enquote_name(p_table_name, 'table');
  l_timestamp constant varchar2(8) := to_char(sysdate, "yyyymmdd");
  l_table_name_backup all_tab_partitions.table_name%type;
  l_partition_lt_reference_tab t_range_tab := t_range_tab();
  l_ddl varchar2(32767 char) := null;
  l_tablespace_name all_tables.tablespace_name%type;
  l_partition_name all_tab_partitions.partition_name%type;

  procedure cleanup
  is
  begin
    if l_ddl is not null -- something has been dropped?
    then
      -- See also Asynchronous Global Index Maintenance for Dropping and Truncating Partitions
      begin
      dbms_part.cleanup_gidx
      ( schema_name_in => trim('"' from l_table_owner)
      , table_name_in => trim('"' from l_table_name)
      , options => 'COALESCE'
      );
      exception
        when others
        then
          -- Misspelling, see https://www.morganslibrary.org/reference/pkgs/dbms_part.html
          if sqlerrm in ( 'ORA-20000: No global index segments were cleaned'
                        , 'ORA-20000: No gloabl index segments were cleaned'
                        )
          then
            null;
          else
            raise;
          end if;
      end;

      -- As a last resort rebuild unusable indexes
      oracle_tools.data_table_mgmt_pkg.rebuild_indexes
      ( p_table_owner => l_table_owner
      , p_table_name => l_table_name
      , p_index_name => null
      , p_index_status => 'UNUSABLE'
      );

      -- Recalculate statistics for table, indexes and (sub)partitions
      dbms_stats.gather_table_stats
      ( ownname => l_table_owner
      , tabname => l_table_name
      , granularity => 'ALL'
      );
    end if;
  end cleanup;
begin
$if cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.DROP_OLD_PARTITIONS');
  dbug.print
  ( dbug."input"
  , 'p_table_owner: %s; p_table_name: %s; p_reference_timestamp: %s; p_update_index_clauses: %s; p_backup: %s'
  , p_table_owner
  , p_table_name
  , to_char(p_reference_timestamp, "yyyy-mm-dd hh24:mi:ss.ff9")
  , p_update_index_clauses
  , dbug.cast_to_varchar2(p_backup)
  );
$end

  -- retrieve the partition list before dropping them so we are 100% sure the list won't change while dropping
  select  p.* 
  bulk collect
  into    l_partition_lt_reference_tab
  from    table
          ( oracle_tools.data_partitioning_pkg.find_partitions_range
            ( l_table_owner
            , l_table_name
            , p_reference_timestamp
            , '<'
            )
          ) p
          cross join all_part_tables t
  where   t.owner = trim('"' from l_table_owner)
  and     t.table_name = trim('"' from l_table_name)
  and     t.partitioning_type = 'RANGE'
  and     (t.interval is null or p.interval = 'YES')
  ;

  if l_partition_lt_reference_tab.count > 0
  then
    for i_idx in l_partition_lt_reference_tab.first .. l_partition_lt_reference_tab.last
    loop
      if p_backup
      then
        l_partition_name :=
          oracle_tools.data_api_pkg.dbms_assert$enquote_name
          ( l_partition_lt_reference_tab(i_idx).partition_name
          , 'partition'
          );
        l_table_name_backup :=
          utl_lms.format_message
          ( '"%s_%s_%s"'
          , trim('"' from l_table_name)
          , l_timestamp
          , trim('"' from l_partition_name)
          );
        select  p.tablespace_name
        into    l_tablespace_name
        from    all_tab_partitions p
        where   p.table_owner = trim('"' from l_table_owner)
        and     p.table_name = trim('"' from l_table_name)
        and     p.partition_name = trim('"' from l_partition_name);
          
        l_ddl := utl_lms.format_message
                 ( 'CREATE TABLE %s.%s TABLESPACE "%s" FOR EXCHANGE WITH TABLE %s.%s'
                 , l_table_owner
                 , l_table_name_backup
                 , l_tablespace_name
                 , l_table_owner
                 , l_table_name
                 );
        execute_immediate(l_ddl);

        l_ddl := utl_lms.format_message
                 ( 'ALTER TABLE %s.%s EXCHANGE PARTITION %s WITH TABLE %s.%s WITHOUT VALIDATION %s'
                 , l_table_owner
                 , l_table_name
                 , l_partition_name
                 , l_table_owner
                 , l_table_name_backup
                 , p_update_index_clauses
                 );
        execute_immediate(l_ddl);
      end if;

      -- must drop partition anyway even if p_backup is true
      l_ddl := utl_lms.format_message
               ( 'ALTER TABLE %s.%s DROP PARTITION %s %s'
               , l_table_owner
               , l_table_name
               , oracle_tools.data_api_pkg.dbms_assert$enquote_name
                 ( l_partition_lt_reference_tab(i_idx).partition_name
                 , 'partition'
                 )
               , p_update_index_clauses
               );
      execute_immediate(l_ddl);
    end loop;
  end if;

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
end drop_old_partitions;

end DATA_PARTITIONING_PKG;
/

