declare
  l_count pls_integer;
begin
  select  1
  into    l_count
  from    user_tab_columns
  where   table_name = 'ALL_SCHEMA_OBJECTS'
  and     column_name = 'OBJ';
end;
/
