declare
  l_count pls_integer;
begin
  select  count(*)
  into    l_count
  from    user_tab_columns
  where   (table_name = 'ALL_SCHEMA_OBJECTS' and column_name = 'OBJ')
  or      (table_name = 'ALL_SCHEMA_DDLS' and column_name = 'DDL');
  if l_count <> 2
  then
    raise program_error;
  end if;
end;
/
