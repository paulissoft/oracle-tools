CREATE OR REPLACE PACKAGE BODY "UTIL_DICT_PKG" IS

function fkey_search
( p_table_name in varchar2 default '%'
)
return fkey_search_tab_t
pipelined
is
  l_fkey_search_tab fkey_search_tab_t := fkey_search_tab_t();
  
  procedure process_index_in_other_table(
    p_ind_table_name in varchar2
  , p_ind_index_name in varchar2
  , p_tab_table_name in varchar2 /* other table (not equal to p_ind_table_name) */
  , p_master_table_name in varchar2
  , p_detail_table_name in varchar2
  , p_remark in varchar2
  , p_fkey_search_tab in out nocopy fkey_search_tab_t
  )
  is
    l_cnt pls_integer;
    l_constraint_name user_constraints.constraint_name%type;
    l_fkey_search_rec fkey_search_rec_t;
  begin
    select  count(*)
    into    l_cnt
    from    ( select  column_name
              from    user_ind_columns 
              where   table_name = p_ind_table_name
              and     index_name = p_ind_index_name
              minus
              select  column_name
              from    user_tab_columns
              where   table_name = p_tab_table_name
            );

    if l_cnt != 0
    then
      /* not all index columns part of the other table */
      null;
    else
      l_constraint_name := null;

      /* is there any foreign key constraint which has the same set of columns? */
      for r_con in
      ( select  con1.constraint_name
        from    user_constraints con1
        ,       user_constraints con2
        where   con1.r_constraint_name = con2.constraint_name
        and     con1.table_name = p_detail_table_name
        and     con1.constraint_type = 'R'
        and     con2.table_name = p_master_table_name
      ) 
      loop
        select  count(*)
        into    l_cnt
        from    ( select  column_name
                  from    user_ind_columns 
                  where   table_name = p_ind_table_name
                  and     index_name = p_ind_index_name
                  minus
                  select  column_name
                  from    user_cons_columns
                  where   table_name = p_detail_table_name
                  and     constraint_name = r_con.constraint_name
                );
        if l_cnt = 0
        then
          /* all columns of the index are contained in the constraint */

          select  count(*)
          into    l_cnt
          from    ( select  column_name
                    from    user_cons_columns
                    where   table_name = p_detail_table_name
                    and     constraint_name = r_con.constraint_name
                    minus                  
                    select  column_name
                    from    user_ind_columns 
                    where   table_name = p_ind_table_name
                    and     index_name = p_ind_index_name
                  );
          if l_cnt = 0
          then
            /* all columns of the constraint are contained in the index */
            /* set of constraint columns is equal to set of index columns */
            l_constraint_name := r_con.constraint_name;
            exit;
          end if;
        end if;
      end loop;

      /* all columns of index are part of master table: possible foreign key */
      for r_col in
      ( select  column_name
        from    user_ind_columns
        where   table_name = p_ind_table_name
        and     index_name = p_ind_index_name
        order by
                column_position
      )
      loop
        l_fkey_search_rec.master_table_name := p_master_table_name;
        l_fkey_search_rec.master_index_name := 
          case
            when p_master_table_name = p_ind_table_name
            then p_ind_index_name
          end;
        l_fkey_search_rec.detail_table_name := p_detail_table_name;
        l_fkey_search_rec.detail_index_name :=
          case
            when p_detail_table_name = p_ind_table_name
            then p_ind_index_name
          end;
        l_fkey_search_rec.detail_constraint_name := l_constraint_name;
        l_fkey_search_rec.column_name := r_col.column_name;
        l_fkey_search_rec.remark := p_remark;
        
        p_fkey_search_tab.extend(1);
        p_fkey_search_tab(p_fkey_search_tab.last) := l_fkey_search_rec;
      end loop;
    end if;
  end;
begin

  /* check whether indexes in detail tables are contained by other master
  tables */
  for r_ind in
  ( select  ind.table_name
    ,       ind.index_name
    ,       tab.table_name r_table_name
    from    user_indexes ind
    ,       user_ind_columns col
    ,       user_tables tab
    where   col.index_name = ind.index_name
    and     col.table_name = ind.table_name
    and     col.column_position = 1
    and     col.column_name not in ('ID', 'DATE_CREATED', 'TIMESTAMP_CREATED') -- no primary keys on ID nor audit columns
    and     tab.table_name != ind.table_name
    and     tab.table_name like upper(p_table_name)
    and     tab.table_name not like 'BIN$%' -- Oracle 10g Recycle Bin
    order by 
            tab.table_name
    ,       ind.table_name
    ,       ind.index_name
  )
  loop
    process_index_in_other_table( p_ind_table_name => r_ind.table_name
                                , p_ind_index_name => r_ind.index_name
                                , p_tab_table_name => r_ind.r_table_name
                                , p_master_table_name => r_ind.r_table_name
                                , p_detail_table_name => r_ind.table_name
                                , p_remark => 'check whether indexes in detail tables are contained by other master tables'
                                , p_fkey_search_tab => l_fkey_search_tab
                                );
  end loop;

  /* when all columns of a unique index are contained 
     within an other table, there might be a foreign key missing */
  for r_ind in
  ( select  ind.table_name r_table_name
    ,       ind.index_name r_index_name
    ,       tab.table_name table_name
    from    user_indexes ind
    ,       user_ind_columns col
    ,       user_tables tab
    where   col.index_name = ind.index_name
    and     col.table_name = ind.table_name
    and     col.column_position = 1
    and     col.column_name not in ('ID', 'DATE_CREATED', 'TIMESTAMP_CREATED') -- no primary keys on ID nor audit columns
    and     tab.table_name != ind.table_name 
    and     ind.table_name like upper(p_table_name)
    and     ind.table_name not like 'BIN$%' -- Oracle 10g Recycle Bin
    and     ind.uniqueness = 'UNIQUE'
    order by 
            ind.table_name
    ,       tab.table_name
    ,       ind.index_name
  )
  loop
    process_index_in_other_table( p_ind_table_name => r_ind.r_table_name
                                , p_ind_index_name => r_ind.r_index_name
                                , p_tab_table_name => r_ind.table_name
                                , p_master_table_name => r_ind.r_table_name
                                , p_detail_table_name => r_ind.table_name
                                , p_remark => 'when all columns of a unique index are contained within an other table, there might be a foreign key missing'
                                , p_fkey_search_tab => l_fkey_search_tab
                                );
  end loop;

  for i_idx in 1 .. l_fkey_search_tab.count
  loop
    pipe row (l_fkey_search_tab(i_idx));
  end loop;

  return;
end fkey_search;

end util_dict_pkg;
/

