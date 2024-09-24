CREATE OR REPLACE PACKAGE BODY "CFG_INSTALL_DDL_PKG" 
is

-- must be initialized in begin block, see below
g_ddl_lock_timeout pls_integer := 60;
g_dry_run boolean := false;

-- LOCAL
procedure do
( p_statement in varchar2
, p_ignore_sqlcode_tab in t_ignore_sqlcode_tab
, p_reraise_original_error in boolean default false
)
is
begin
  if g_dry_run
  then
    dbms_output.put_line(p_statement);
  else
    execute immediate 'alter session set ddl_lock_timeout = ' || g_ddl_lock_timeout;
    commit; -- explicit commit
    execute immediate p_statement;
  end if;
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
procedure ddl_execution_settings
( p_ddl_lock_timeout in pls_integer
, p_dry_run in boolean
)
is
begin
  g_ddl_lock_timeout := p_ddl_lock_timeout;
  g_dry_run := p_dry_run;
end ddl_execution_settings;

/**
Change DDL execution settings.
**/

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
, p_constraint_type in user_constraints.constraint_type%type
, p_extra in varchar2
, p_ignore_sqlcode_tab in t_ignore_sqlcode_tab
)
is
  l_constraint_name user_constraints.constraint_name%type := p_constraint_name;

  procedure determine_constraint_name
  is
  begin
    if upper(p_constraint_type) in ( 'P', 'R', 'C' )
    then
      null;
    else
      raise value_error;
    end if;
    if instr(p_constraint_name, '%') > 0
    then
      select  con.constraint_name
      into    l_constraint_name
      from    user_constraints con
      where   con.owner = user
      and     con.table_name in ( p_table_name, upper(p_table_name) )
      and     ( con.constraint_name like p_constraint_name escape '\' or
                con.constraint_name like upper(p_constraint_name) escape '\'
              )
      and     con.constraint_type = upper(p_constraint_type);
    end if;    
  end determine_constraint_name;
begin
  case upper(p_operation)
    when 'ADD'
    then null;
    when 'MODIFY'
    then null;
    when 'RENAME'
    then determine_constraint_name;
    when 'DROP'
    then determine_constraint_name;
      
    else
      raise value_error;
  end case;
  do
  ( p_statement => 'ALTER TABLE ' || p_table_name || ' ' || p_operation || ' CONSTRAINT ' || l_constraint_name || ' ' || p_extra
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
        then p_operation || ' INDEX ' || p_index_name || ' ON ' || p_table_name || ' ' || p_extra
        else p_operation || ' INDEX ' || p_index_name || ' ' || p_extra          
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

