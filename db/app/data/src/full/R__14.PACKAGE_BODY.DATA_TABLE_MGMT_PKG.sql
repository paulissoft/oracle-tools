CREATE OR REPLACE PACKAGE BODY "DATA_TABLE_MGMT_PKG" IS

procedure rebuild_indexes
( p_table_owner in all_indexes.table_owner%type
, p_table_name in all_indexes.table_name%type
, p_index_name in all_indexes.index_name%type
, p_index_status in all_indexes.status%type
)
is
  l_table_owner constant all_indexes.table_owner%type :=
    case
      when p_table_owner is not null
      then trim('"' from oracle_tools.data_api_pkg.dbms_assert$enquote_name(p_table_owner, 'owner'))
    end;
  l_table_name constant all_indexes.table_name%type :=
    case
      when p_table_name is not null
      then trim('"' from oracle_tools.data_api_pkg.dbms_assert$enquote_name(p_table_name, 'table'))
    end;
  l_index_name constant all_indexes.index_name%type :=
    case
      when p_index_name is not null
      then trim('"' from oracle_tools.data_api_pkg.dbms_assert$enquote_name(p_index_name, 'index'))
    end;
  l_ddl_tab dbms_sql.varchar2a;
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

  select  'ALTER INDEX "' || i.index_name || '" REBUILD' as DDL
  bulk collect
  into    l_ddl_tab
  from    user_indexes i
  where   ( l_table_owner is null or i.table_owner = l_table_owner )
  and     ( l_table_name is null or i.table_name = l_table_name )
  and     ( l_index_name is null or i.index_name = l_index_name )
  and     i.status like p_index_status escape '\';

  if l_ddl_tab.count > 0
  then
    for i_idx in l_ddl_tab.first .. l_ddl_tab.last
    loop
$if cfg_pkg.c_debugging $then
      dbug.print(dbug."info", 'l_ddl_tab(%s): %s', i_idx, l_ddl_tab(i_idx));
$end
    
      execute immediate l_ddl_tab(i_idx);
    end loop;
  end if;

$if cfg_pkg.c_debugging $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end rebuild_indexes;

end DATA_TABLE_MGMT_PKG;
/

