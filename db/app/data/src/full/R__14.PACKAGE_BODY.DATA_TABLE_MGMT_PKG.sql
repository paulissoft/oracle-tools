CREATE OR REPLACE PACKAGE BODY "DATA_TABLE_MGMT_PKG" IS

procedure rebuild_indexes
( p_table_owner in all_indexes.table_owner%type
, p_table_name in all_indexes.table_name%type
, p_index_name in all_indexes.index_name%type
, p_index_status in all_indexes.status%type
)
is
  cursor c_ind
  ( b_table_owner in all_indexes.table_owner%type
  , b_table_name in all_indexes.table_name%type
  , b_index_name in all_indexes.index_name%type
  , b_index_status in all_indexes.status%type
  )
  is
    with ind as
    ( select  i.index_name
      ,       i.status
      from    user_indexes i
      where   ( b_table_owner is null or i.table_owner = b_table_owner )
      and     ( b_table_name is null or i.table_name = b_table_name )
      and     ( b_index_name is null or i.index_name = b_index_name )
    )
    select  'ALTER INDEX "' || i.index_name || '" REBUILD' as DDL
    from    ind i
    where   i.status like b_index_status escape '\'
    union all
    select  'ALTER INDEX "' || t.index_name || '" MODIFY ' || t.ddl_type || ' "' || t.partition_name || '" REBUILD' as DDL
    from    ( select  p.index_name
              ,       p.partition_name
              ,       'PARTITION' as ddl_type
              from    user_ind_partitions p
                      inner join ind i
                      on i.index_name = p.index_name
              where   p.status like b_index_status escape '\'
              union all
              select  s.index_name
              ,       s.subpartition_name as partition_name
              ,       'SUBPARTITION' as ddl_type
              from    user_ind_subpartitions s
                      inner join ind i
                      on i.index_name = s.index_name
              where   s.status like b_index_status escape '\'
            ) t;

  l_ddl_tab dbms_sql.varchar2a;
            
  c_fetch_limit constant simple_integer := 100;
begin
$if cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.REBUILD_INDEXES');
  dbug.print
  ( dbug."input"
  , 'p_table_owner: %s; p_table_name: %s; p_index_name: %s; p_index_status: %s'
  , p_table_owner
  , p_table_name
  , p_index_name
  , p_index_status
  );
$end

  open c_ind
  ( case
      when p_table_owner is not null
      then trim('"' from oracle_tools.data_api_pkg.dbms_assert$enquote_name(p_table_owner, 'owner'))
    end
  , case
      when p_table_name is not null
      then trim('"' from oracle_tools.data_api_pkg.dbms_assert$enquote_name(p_table_name, 'table'))
    end
  , case
      when p_index_name is not null
      then trim('"' from oracle_tools.data_api_pkg.dbms_assert$enquote_name(p_index_name, 'index'))
    end
  , p_index_status
  );
  
  loop
    fetch c_ind bulk collect into l_ddl_tab limit c_fetch_limit;

    exit when l_ddl_tab.count = 0;

    for i_idx in l_ddl_tab.first .. l_ddl_tab.last
    loop
$if cfg_pkg.c_debugging $then
      dbug.print(dbug."info", 'l_ddl_tab(%s): %s', i_idx, l_ddl_tab(i_idx));
$end
    
      execute immediate l_ddl_tab(i_idx);
    end loop;
    
    exit when l_ddl_tab.count < c_fetch_limit; -- next fetch will return 0 rows
  end loop;

  close c_ind;

$if cfg_pkg.c_debugging $then
  dbug.leave;
$end
exception
  when others
  then
    if c_ind%isopen then close c_ind; end if;
$if cfg_pkg.c_debugging $then
    dbug.leave_on_error;
$end
    raise;
end rebuild_indexes;

end DATA_TABLE_MGMT_PKG;
/

