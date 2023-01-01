CREATE OR REPLACE PACKAGE BODY "DATA_PARTITIONING_PKG" 
is

function alter_table_range_partitioning
( p_table in varchar2  -- checked by ORACLE_TOOLS.DATA_API_PKG.DBMS_ASSERT$SIMPLE_SQL_NAME()
, p_column in varchar2 -- checked by ORACLE_TOOLS.DATA_API_PKG.DBMS_ASSERT$SIMPLE_SQL_NAME()
, p_interval in varchar2 default null -- to undo the interval partitioning
, p_partition_clause in varchar2 default null -- when you just want to undo interval partitioning
, p_online in boolean default true
)
return varchar2
is
begin
  return utl_lms.format_message
         ( 'ALTER TABLE %s PARTITION BY RANGE (%s) INTERVAL (%s) %s %s'
         , oracle_tools.data_api_pkg.dbms_assert$simple_sql_name(p_table, 'table')
         , oracle_tools.data_api_pkg.dbms_assert$simple_sql_name(p_column, 'column')
         , p_interval
         , case when p_partition_clause is not null then '(' || p_partition_clause || ')' end
         , case when p_online then 'ONLINE' end
         );
end alter_table_range_partitioning;

function show_partitions
( p_table in varchar2  -- checked by ORACLE_TOOLS.DATA_API_PKG.DBMS_ASSERT$SIMPLE_SQL_NAME()
)
return t_value_tab
pipelined
is
  l_table constant user_tab_partitions.table_name%type :=
    trim('"' from oracle_tools.data_api_pkg.dbms_assert$enquote_name(p_table, 'table'));
begin
  for r in
  ( with high_values as
    ( select  dbms_xmlgen.getxmltype
              ( utl_lms.format_message
                ( q'[select p.high_value, p.partition_name from user_tab_partitions p where p.table_name = '%s']'
                , l_table
                )
              ) as xml
      from    dual
    ), rng as
    ( select x.partition_name
      ,      lag(x.high_value) over (order by x.high_value) as value_lwb_incl
      ,      x.high_value as value_upb_excl
      from   high_values p
      ,      xmltable
             ( '/ROWSET/ROW'
               passing p.xml
               columns partition_name varchar2(128 char) path '/ROW/PARTITION_NAME'
               ,       high_value varchar2(4000 char) path '/ROW/HIGH_VALUE'
             ) x
     )
     select  *
     from    rng
   )
   loop
     pipe row (r);
   end loop;
end show_partitions;

/*
create or replace procedure drop_old_partitions 
                            (p_table_name IN VARCHAR2
                           , p_threshold IN NUMBER)
   is
    
     cursor tab_interval IS
      select partition_name
                  , high_value
            from user_tab_partitions
           where table_name = p_table_name
             and interval = 'YES';
     
   begin
   for part in tab_interval
   loop
     execute immediate 
       'begin
          if months_between(sysdate
             , '||part.high_value||') > ' 
                || p_threshold || 'then
            execute immediate
              ''alter table '|| p_table_name ||' drop partition ' 
            || part.partition_name
            ||''';
          end if;
         end;';
   end loop;
   end;
*/

end DATA_PARTITIONING_PKG;
/

