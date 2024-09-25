CREATE OR REPLACE PACKAGE BODY "CFG_INSTALL_DDL_PKG" 
is

-- must be initialized in begin block, see below
g_ddl_lock_timeout           naturaln := c_ddl_lock_timeout;
g_dry_run                    boolean  := c_dry_run;
g_reraise_original_exception boolean  := c_reraise_original_exception;
g_explicit_commit            boolean  := c_explicit_commit;

$if cfg_pkg.c_testing $then

c_test_base_name constant user_objects.object_name%type := 'test$' || $$PLSQL_UNIT || '$';
c_test_base_name_parent constant user_objects.object_name%type := c_test_base_name || 'parent$';
c_test_base_name_child constant user_objects.object_name%type := c_test_base_name || 'child$';

c_test_table_name_parent constant user_objects.object_name%type := c_test_base_name_parent || 'tab';
c_test_table_name_child constant user_objects.object_name%type := c_test_base_name_child || 'tab';
c_test_pk_name_parent constant user_objects.object_name%type := c_test_base_name_parent || 'pk';
c_test_pk_name_child constant user_objects.object_name%type := c_test_base_name_child || 'pk';
c_test_uk_name_parent constant user_objects.object_name%type := c_test_base_name_parent || 'uk';
c_test_uk_name_child constant user_objects.object_name%type := c_test_base_name_child || 'uk';
c_test_ck_name_parent constant user_objects.object_name%type := c_test_base_name_parent || 'ck';
c_test_ck_name_child constant user_objects.object_name%type := c_test_base_name_child || 'ck';
c_test_fk_name_child constant user_objects.object_name%type := c_test_base_name_child || 'fk';
c_test_index_name_parent constant user_objects.object_name%type := c_test_base_name_parent || 'ind';
c_test_index_name_child constant user_objects.object_name%type := c_test_base_name_child || 'ind';
c_test_trigger_name_parent constant user_objects.object_name%type := c_test_base_name_parent || 'trg';
c_test_trigger_name_child constant user_objects.object_name%type := c_test_base_name_child || 'trg';

$end

-- LOCAL
procedure do
( p_statement in varchar2
, p_ignore_sqlcode_tab in t_ignore_sqlcode_tab default null
)
is
begin
  if g_dry_run
  then
    dbms_output.put_line(p_statement);
  else
    commit; -- explicit commit
    execute immediate 'alter session set ddl_lock_timeout = ' || g_ddl_lock_timeout;
    execute immediate p_statement;
    commit; -- explicit commit
  end if;
exception
  when others
  then
    if p_ignore_sqlcode_tab is null or not(sqlcode member of p_ignore_sqlcode_tab)
    then
      if g_reraise_original_exception
      then
        raise;
      else
        raise_application_error(-20000, 'Statement causing an error: ' || p_statement, true);
      end if;
    end if;
end do;

-- GLOBAL
procedure set_ddl_execution_settings
( p_ddl_lock_timeout in natural
, p_dry_run in boolean
, p_reraise_original_exception in boolean
, p_explicit_commit in boolean
)
is
begin
  if p_ddl_lock_timeout is not null
  then
    g_ddl_lock_timeout := p_ddl_lock_timeout;
  end if;
  if p_dry_run is not null
  then
    g_dry_run := p_dry_run;
  end if;
  if p_reraise_original_exception is not null
  then
    g_reraise_original_exception := p_reraise_original_exception;
  end if;
  if p_explicit_commit is not null
  then
    g_explicit_commit := p_explicit_commit;
  end if;
end set_ddl_execution_settings;

procedure reset_ddl_execution_settings
is
begin
  set_ddl_execution_settings
  ( p_ddl_lock_timeout => c_ddl_lock_timeout
  , p_dry_run => c_dry_run
  , p_reraise_original_exception => c_reraise_original_exception
  , p_explicit_commit => c_explicit_commit
  );
end reset_ddl_execution_settings;

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

$if cfg_pkg.c_testing $then

procedure ut_init
is
begin
  -- parent
  do
  ( utl_lms.format_message
    ( 'create table %s
( id number constraint %s primary key -- implies not null
, name varchar2(30) constraint %s not null
, constraint %s unique(name)
)'
    , c_test_table_name_parent
    , c_test_pk_name_parent
    , c_test_ck_name_parent
    , c_test_uk_name_parent
    )
  );

  -- child
  do
  ( utl_lms.format_message
    ( 'create table %s
( id number constraint %s primary key -- implies not null
, name varchar2(30) constraint %s not null
, parent_id number not null
, constraint %s foreign key(parent_id) references %s(id)
, constraint %s unique(name)
)'
    , c_test_table_name_child
    , c_test_pk_name_child
    , c_test_ck_name_child
    , c_test_fk_name_child
    , c_test_table_name_parent
    , c_test_uk_name_child
    )
  );
end ut_init;

procedure ut_done
is
begin
  -- child
  do
  ( utl_lms.format_message
    ( 'drop table %s purge'
    , c_test_table_name_child
    )
  , t_ignore_sqlcode_tab(c_table_does_not_exist)
  );

  -- parent
  do
  ( utl_lms.format_message
    ( 'drop table %s purge'
    , c_test_table_name_parent
    )
  , t_ignore_sqlcode_tab(c_table_does_not_exist)
  );
end ut_done;

procedure ut_setup
is
begin
  set_ddl_execution_settings(p_reraise_original_exception => false); -- show statement as well when it fails
  ut_init;
  reset_ddl_execution_settings;
end ut_setup;

procedure ut_teardown
is
begin
  set_ddl_execution_settings(p_reraise_original_exception => false); -- show statement as well when it fails
  ut_done;
  reset_ddl_execution_settings;
end ut_teardown;

--%test
procedure ut_table_ddl
is
  l_lines dbms_output.chararr;
  l_nr_lines integer := 1000;
begin
  set_ddl_execution_settings(p_dry_run => true);
  -- clear the output cache
  dbms_output.get_lines
  ( lines => l_lines
  , numlines => l_nr_lines
  );
  table_ddl
  ( p_operation => 'CREATE'
  , p_table_name => 'TEST'
  , p_extra => 'XYZ'
  );
  l_nr_lines := 1000;
  dbms_output.get_lines
  ( lines => l_lines
  , numlines => l_nr_lines
  );
  ut.expect(l_nr_lines).to_equal(1);
  ut.expect(l_lines(1)).to_equal('CREATE TABLE TEST XYZ');
  reset_ddl_execution_settings;
end ut_table_ddl;

--%throws(cfg_install_ddl_pkg.c_table_already_exists)
procedure ut_table_already_exists
is
begin
  ut_init; -- twice
end ut_table_already_exists;

--%throws(cfg_install_ddl_pkg.c_table_does_not_exist)
procedure ut_table_does_not_exist
is
begin
  begin
    ut_done;
  exception
    when others
    then raise program_error;
  end;
  ut_done;
end ut_table_does_not_exist;

$end

end cfg_install_ddl_pkg;
/

