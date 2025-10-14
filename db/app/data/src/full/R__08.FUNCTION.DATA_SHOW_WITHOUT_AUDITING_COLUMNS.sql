CREATE OR REPLACE FUNCTION DATA_SHOW_WITHOUT_AUDITING_COLUMNS
( p_tab in dbms_tf.table_t -- The table
)
RETURN CLOB SQL_MACRO(TABLE)
/**

Use a SQL macro to show the table with auditing columns (starting with AUD$INS$ or AUD$UPD$).

Usage: select * from ORACLE_TOOLS.DATA_SHOW_WITHOUT_AUDITING_COLUMNS(<table>)

**/
is
  l_columns varchar2(32767 byte) := null;
begin
  for i_idx in 1 .. p_tab.column.count 
  loop
    if substr(trim(both '"' from p_tab.column(i_idx).description.name), 1, 8) in ('AUD$INS$', 'AUD$UPD$')
    then
      null;
    else
      l_columns := l_columns || case when i_idx > 1 then ',' end || p_tab.column(i_idx).description.name;
    end if;  
  end loop;

  return 'select ' || l_columns || ' from p_tab';
END DATA_SHOW_WITHOUT_AUDITING_COLUMNS;
/
