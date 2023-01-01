CREATE OR REPLACE PACKAGE BODY "DATA_PARTITIONING_PKG" 
is

function alter_table_range_partitioning
( p_table in varchar2  -- checked by ORACLE_TOOLS.DATA_API_PKG.DBMS_ASSERT$SIMPLE_SQL_NAME()
, p_partition_by in varchar2
, p_interval in varchar2 default null -- to undo the interval partitioning
, p_subpartition_by in varchar2
, p_partition_clause in varchar2 default null -- when you just want to undo interval partitioning
, p_online in boolean default true
)
return varchar2
is
begin
  return utl_lms.format_message
         ( 'ALTER TABLE %s MODIFY %s %s %s %s %s'
         , oracle_tools.data_api_pkg.dbms_assert$simple_sql_name(p_table, 'table')
         , p_partition_by
         , p_interval
         , p_subpartition_by
         , case when p_partition_clause is not null then '(' || p_partition_clause || ')' end
         , case when p_online then 'ONLINE' end
         );
end alter_table_range_partitioning;

function show_partitions_range
( p_table in varchar2  -- checked by ORACLE_TOOLS.DATA_API_PKG.DBMS_ASSERT$SIMPLE_SQL_NAME()
)
return t_range_tab
pipelined
is
  l_table constant user_tab_partitions.table_name%type :=
    trim('"' from oracle_tools.data_api_pkg.dbms_assert$enquote_name(p_table, 'table'));
  l_query constant varchar2(4000 char) :=
    utl_lms.format_message
    ( q'[
select  p.high_value
,       p.partition_name
,       p.partition_position
from    user_tab_partitions p
where   p.table_name = '%s']'
    , l_table
    );
begin
  for r in
  ( with high_values as
    ( select  dbms_xmlgen.getxmltype(l_query) as xml
      from    dual
    ), rng as
    ( select  partition_name
      ,       partition_position
      ,       lag(high_value) over (order by high_value) lwb_incl
      ,       high_value as upb_excl
      from    high_values p
      ,       xmltable
              ( '/ROWSET/ROW'
                passing p.xml
                columns partition_name varchar2(128) path '/ROW/PARTITION_NAME'
                ,       partition_position integer path '/ROW/PARTITION_POSITION'
                ,       high_value varchar2(4000 char) path '/ROW/HIGH_VALUE'
              )
    )
    select  *
    from    rng
  )
  loop
    pipe row (r);
  end loop;
end show_partitions_range;

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

