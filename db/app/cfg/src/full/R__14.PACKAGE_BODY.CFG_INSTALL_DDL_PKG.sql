CREATE OR REPLACE PACKAGE BODY "CFG_INSTALL_DDL_PKG" 
is

-- LOCAL
procedure do
( p_statement in varchar2
, p_ignore_sqlcode_tab in t_ignore_sqlcode_tab
, p_reraise_original_error in boolean default false
)
is
begin
  execute immediate p_statement;
exception
  when others
  then
    if not(sqlcode member of p_ignore_sqlcode_tab)
    then
      if p_reraise_original_error
      then
        raise;
      else
        raise_application_error(-20000, 'Statement causing an error: ' || p_statement, true);
      end if;
    end if;
end do;

-- GLOBAL
procedure column_ddl
( p_operation in varchar2
, p_table_name in user_tab_columns.table_name%type
, p_column_name in user_tab_columns.column_name%type
, p_extra in varchar2
, p_ignore_sqlcode_tab in t_ignore_sqlcode_tab 
)
is
begin
  if upper(p_operation) in ('ADD', 'MODIFY', 'DROP')
  then
    null;
  else
    raise value_error;
  end if;
  do
  ( p_statement => 'ALTER TABLE ' || p_table_name || ' ' || p_operation || ' ' || p_column_name || ' ' || p_extra
  , p_ignore_sqlcode_tab => p_ignore_sqlcode_tab
  );
end column_ddl;

procedure table_ddl
( p_operation in varchar2
, p_table_name in user_tab_columns.table_name%type
, p_extra in varchar2
, p_ignore_sqlcode_tab in t_ignore_sqlcode_tab
)
is
begin
  if upper(p_operation) in ('CREATE', 'ALTER', 'DROP')
  then
    null;
  else
    raise value_error;
  end if;
  do
  ( p_statement => p_operation || ' TABLE ' || p_table_name || ' ' || p_extra
  , p_ignore_sqlcode_tab => p_ignore_sqlcode_tab
  );
end table_ddl;

procedure constraint_ddl
( p_operation in varchar2
, p_table_name in user_constraints.table_name%type
, p_constraint_name in user_constraints.constraint_name%type
, p_extra in varchar2
, p_ignore_sqlcode_tab in t_ignore_sqlcode_tab
)
is
begin
  if upper(p_operation) in ('ADD', 'MODIFY', 'DROP')
  then
    null;
  else
    raise value_error;
  end if;
  do
  ( p_statement => 'ALTER TABLE ' || p_table_name || ' ' || p_operation || ' CONSTRAINT ' || p_constraint_name || ' ' || p_extra
  , p_ignore_sqlcode_tab => p_ignore_sqlcode_tab
  );
end constraint_ddl;

procedure comment_ddl
( p_table_name in user_tab_columns.table_name%type
, p_column_name in user_tab_columns.column_name%type
, p_comment in varchar2
, p_ignore_sqlcode_tab in t_ignore_sqlcode_tab
)
is
begin
  do
  ( p_statement =>
      case
        when p_column_name is not null
        then 'COMMENT ON COLUMN ' || p_table_name || '.' || p_column_name || ' IS ''' || p_comment || ''''
        else 'COMMENT ON TABLE ' || p_table_name || ' IS ''' || p_comment || ''''
      end
  , p_ignore_sqlcode_tab => p_ignore_sqlcode_tab
  );
end comment_ddl;    

procedure index_ddl
( p_operation in varchar2
, p_index_name in user_indexes.index_name%type
, p_table_name in user_indexes.table_name%type
, p_extra in varchar2
, p_ignore_sqlcode_tab in t_ignore_sqlcode_tab
)
is
begin
  if upper(p_operation) in ('CREATE', 'ALTER', 'DROP')
  then
    null;
  else
    raise value_error;
  end if;
  do
  ( p_statement =>
      case
        when p_table_name is not null
        then p_operation || ' ' || p_index_name || ' ON ' || p_table_name || ' ' || p_extra
        else p_operation || ' ' || p_index_name || p_extra
      end
  , p_ignore_sqlcode_tab => p_ignore_sqlcode_tab
  );
end index_ddl;    

procedure trigger_ddl
( p_operation in varchar2
, p_trigger_name in user_triggers.trigger_name%type
, p_trigger_extra in varchar2
, p_table_name in user_triggers.table_name%type
, p_extra in varchar2
, p_ignore_sqlcode_tab in t_ignore_sqlcode_tab
)
is
begin
  if upper(p_operation) in ('CREATE', 'CREATE OR REPLACE', 'ALTER', 'DROP')
  then
    null;
  else
    raise value_error;
  end if;
  do
  ( p_statement =>
      case
        when p_table_name is not null
        then p_operation || ' TRIGGER ' || p_trigger_name || ' ' || p_trigger_extra || ' ON ' || p_table_name || chr(10) || p_extra
        else p_operation || ' TRIGGER ' || p_trigger_name || ' ' || p_trigger_extra
      end
  , p_ignore_sqlcode_tab => p_ignore_sqlcode_tab
  );
end trigger_ddl;    

end cfg_install_ddl_pkg;
/

