CREATE OR REPLACE PACKAGE BODY "CFG_INSTALL_DDL_PKG" 
is

-- must be initialized in begin block, see below
g_ddl_lock_timeout           naturaln := c_ddl_lock_timeout;
g_dry_run                    boolean  := c_dry_run;
g_reraise_original_exception boolean  := c_reraise_original_exception;
g_explicit_commit            boolean  := c_explicit_commit;
g_verbose           constant boolean  := cfg_pkg.c_testing;

g_testing                    boolean := false;
g_dbug_dbms_output_active    boolean := null;

$if cfg_pkg.c_testing $then

c_test_base_name constant user_objects.object_name%type := 'test$' || $$PLSQL_UNIT || '$';
c_test_base_name_parent constant user_objects.object_name%type := c_test_base_name || 'parent$';
c_test_base_name_child constant user_objects.object_name%type := c_test_base_name || 'child$';

c_test_table_name_parent constant user_objects.object_name%type := c_test_base_name_parent || 'tab';
c_test_table_name_child constant user_objects.object_name%type := c_test_base_name_child || 'tab';
c_test_pk_name_parent constant user_objects.object_name%type := c_test_base_name_parent || 'pk';
c_test_pk_name_child constant user_objects.object_name%type := c_test_base_name_child || 'pk';
c_test_uk_name_parent constant user_objects.object_name%type := c_test_base_name_parent || 'uk';
-- uk for child is unnamed (i.e. like SYS\_%)
c_test_ck_name_parent constant user_objects.object_name%type := c_test_base_name_parent || 'ck';
c_test_ck1_name_child constant user_objects.object_name%type := c_test_base_name_child || 'ck1';
c_test_ck2_name_child constant user_objects.object_name%type := c_test_base_name_child || 'ck2';
c_test_fk_name_child constant user_objects.object_name%type := c_test_base_name_child || 'fk';
c_test_index_name_parent constant user_objects.object_name%type := c_test_base_name_parent || 'ind';
c_test_index_name_child constant user_objects.object_name%type := c_test_base_name_child || 'ind';
c_test_trigger_name_parent constant user_objects.object_name%type := c_test_base_name_parent || 'trg';
c_test_trigger_name_child constant user_objects.object_name%type := c_test_base_name_child || 'trg';
c_test_view_name constant user_objects.object_name%type := c_test_base_name_parent || 'vw';

$end

-- LOCAL

procedure check_condition
( p_condition in boolean
, p_error_message in varchar2
)
is
begin
  if p_condition
  then
    null;
  else
    if g_testing
    then
      raise value_error;
    else
      raise_application_error(-20000, p_error_message);
    end if;
  end if;
end check_condition;

procedure enter
( p_routine in varchar2
)
is
begin
  if g_testing then return; end if;
  if g_dry_run or g_verbose then null; else return; end if;
  
$if oracle_tools.cfg_pkg.c_debugging
$then
  dbug.enter
  (
$else
  dbms_output.put_line
  ( 'Entering ' ||
$end
    $$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || p_routine
  );
end enter;  

procedure print
( p_line in varchar2
, p_do_print in boolean default true
)
is
begin
  if p_do_print then null; else return; end if;
  
$if oracle_tools.cfg_pkg.c_debugging
$then
  dbug.print
  ( dbug."info"
  , p_line
  );
$end

  dbms_output.put_line(p_line);
end print;

procedure print
( p_description in varchar2
, p_what in varchar2
)
is
begin
  print(p_description || ': ' || p_what, g_dry_run or g_verbose);
end print;

procedure print
( p_description in varchar2
, p_column_tab in t_column_tab
)
is
begin
  if g_dry_run or g_verbose then null; else return; end if;
  
  if cardinality(p_column_tab) > 0
  then
    for i_idx in p_column_tab.first .. p_column_tab.last
    loop
      print
      ( p_description => p_description || '(' || i_idx || ')'
      , p_what => p_column_tab(i_idx)
      );
    end loop;
  else
    print
    ( p_description => p_description
    , p_what => 'empty'
    );
  end if;
end print;

procedure print
( p_description in varchar2
, p_ignore_sqlcode_tab in t_ignore_sqlcode_tab 
)
is
begin
  if g_dry_run or g_verbose then null; else return; end if;
  
  if cardinality(p_ignore_sqlcode_tab) > 0
  then
    for i_idx in p_ignore_sqlcode_tab.first .. p_ignore_sqlcode_tab.last
    loop
      print
      ( p_description => p_description || '(' || i_idx || ')'
      , p_what => p_ignore_sqlcode_tab(i_idx)
      );
    end loop;
  else
    print
    ( p_description => p_description
    , p_what => 'empty'
    );
  end if;
end print;

procedure leave
( p_routine in varchar2
)
is
begin
  if g_testing then return; end if;
  if g_dry_run or g_verbose then null; else return; end if;
  
$if oracle_tools.cfg_pkg.c_debugging
$then
  dbug.leave
  (
$else
  dbms_output.put_line
  ( 'Leaving ' || $$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || p_routine
$end  
  );
end leave;

procedure leave_on_error
( p_routine in varchar2
)
is
begin
  if g_testing then return; end if;
  if g_dry_run or g_verbose then null; else return; end if;
  
$if oracle_tools.cfg_pkg.c_debugging
$then
  dbug.leave_on_error
  (
$else
  dbms_output.put_line
  ( 'Leaving ' || $$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || p_routine || ' with error ' || sqlerrm
$end  
  );
end leave_on_error;

function ignore_error
( p_ignore_sqlcode_tab in t_ignore_sqlcode_tab
, p_sqlerrm in varchar2 default null
, p_sqlcode in integer default sqlcode
)
return boolean
is
  l_routine constant varchar2(30 byte) := 'ignore_error';
  l_result boolean := null;
begin
  enter(l_routine);
  print('p_ignore_sqlcode_tab', p_ignore_sqlcode_tab);
  print('p_sqlcode', p_sqlcode);
  print('p_sqlerrm', p_sqlerrm);

  if p_ignore_sqlcode_tab is null or not(p_sqlcode member of p_ignore_sqlcode_tab)
  then
    if not(g_reraise_original_exception) and p_sqlerrm is not null
    then
      raise_application_error(-20000, p_sqlerrm, true);
    end if;
    l_result := false;
  else
    l_result := true;
  end if;

  print('return', case l_result when true then 'TRUE' when false then 'FALSE' else 'NULL' end);
  
  leave(l_routine);

  return l_result;

/*
exception
  when others
  then
    leave_on_error(l_routine);
    raise;*/
end ignore_error;

procedure do
( p_statement in varchar2
, p_ignore_sqlcode_tab in t_ignore_sqlcode_tab default null
)
is
  l_routine constant varchar2(30 byte) := 'do';
begin
  enter(l_routine);
  print('p_statement', p_statement);
  print('p_ignore_sqlcode_tab', p_ignore_sqlcode_tab);

  print(p_statement); -- will always print this one

  if not(g_dry_run)
  then
    if g_explicit_commit
    then
      commit; -- explicit commit
    end if;
    execute immediate 'alter session set ddl_lock_timeout = ' || g_ddl_lock_timeout;
    execute immediate p_statement;
    if g_explicit_commit
    then
      commit; -- explicit commit
    end if;
  end if;

  leave(l_routine);
exception
  when others
  then
    if not(g_dry_run) and g_explicit_commit
    then
      rollback;
    end if;

    leave_on_error(l_routine);

    if not
       ( ignore_error
         ( p_ignore_sqlcode_tab => p_ignore_sqlcode_tab
         , p_sqlerrm => 'Statement causing an error: ' || p_statement
         )
       )
    then
      raise;
    end if;
end do;

function columns_match
( p_act_column_tab in t_column_tab
, p_exp_column_tab in t_column_tab
, p_must_match_exactly in boolean
)
return boolean
deterministic
is
begin
  print('p_act_column_tab', p_act_column_tab);
  
  if cardinality(p_act_column_tab) = cardinality(p_exp_column_tab)
  then
    for i_idx in p_act_column_tab.first .. p_act_column_tab.last
    loop
      if ( p_must_match_exactly and p_act_column_tab(i_idx) = p_exp_column_tab(i_idx) ) or
         ( not(p_must_match_exactly) and p_act_column_tab(i_idx) member of p_exp_column_tab )
      then
        null; -- continue the search
      else
        return false;
      end if;
    end loop;
    return true;
  else
    return false; -- sizes don't match
  end if;
end columns_match;

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
  l_routine constant varchar2(30 byte) := 'column_ddl';
begin
  enter(l_routine);
  print('p_operation', p_operation);
  print('p_table_name', p_table_name);
  print('p_column_name', p_column_name);
  print('p_extra', p_extra);
  print('p_ignore_sqlcode_tab', p_ignore_sqlcode_tab);
  
  check_condition
  ( upper(p_operation) in ('ADD', 'MODIFY', 'DROP')
  , 'Parameter "p_operation" must be one of "ADD", "MODIFY" or "DROP"'
  );
  
  do
  ( p_statement => 'ALTER TABLE "' || p_table_name || '" ' || p_operation || ' ("' || p_column_name || '" ' || p_extra || ')'
  , p_ignore_sqlcode_tab => p_ignore_sqlcode_tab
  );

  leave(l_routine);
exception
  when others
  then
    leave_on_error(l_routine);
    raise;
end column_ddl;

procedure table_ddl
( p_operation in varchar2
, p_table_name in user_tab_columns.table_name%type
, p_extra in varchar2
, p_ignore_sqlcode_tab in t_ignore_sqlcode_tab
)
is
  l_routine constant varchar2(30 byte) := 'table_ddl';
begin
  enter(l_routine);
  print('p_operation', p_operation);
  print('p_table_name', p_table_name);
  print('p_extra', p_extra);
  print('p_ignore_sqlcode_tab', p_ignore_sqlcode_tab);
  
  check_condition
  ( upper(p_operation) in ('CREATE', 'ALTER', 'DROP')
  , 'Parameter "p_operation" must be one of "CREATE", "ALTER" or "DROP"'
  );
  
  do
  ( p_statement => p_operation || ' TABLE "' || p_table_name || '" ' || p_extra
  , p_ignore_sqlcode_tab => p_ignore_sqlcode_tab
  );

  leave(l_routine);
exception
  when others
  then
    leave_on_error(l_routine);
    raise;
end table_ddl;

procedure constraint_ddl
( p_operation in varchar2
, p_table_name in user_constraints.table_name%type
, p_constraint_name in user_constraints.constraint_name%type
, p_constraint_type in user_constraints.constraint_type%type
, p_column_tab in t_column_tab
, p_extra in varchar2
, p_ignore_sqlcode_tab in t_ignore_sqlcode_tab
)
is
  l_routine constant varchar2(30 byte) := 'constraint_ddl';
  l_constraint_name user_constraints.constraint_name%type := p_constraint_name;
  l_statement varchar2(32767 byte) := null;

  procedure determine_constraint_name
  is
    l_routine constant varchar2(60 byte) := 'constraint_ddl.determine_constraint_name';
    l_nr_constraints_found naturaln := 0;
    l_column_tab t_column_tab;    
  begin
    enter(l_routine);
  
    if instr(p_constraint_name, '%') > 0
    then
      check_condition
      ( upper(p_constraint_type) in ( 'P', 'U', 'R', 'C' )
      , 'Parameter "p_constraint_type" must be one of "P", "U", "R" or "C"'
      );
      
      -- 1. Find the one and only constraint that matches the filter criteria p_table_name, p_constraint_name and p_constraint_type.
      -- 2. But also all the constraint columns must match p_column_tab (when not null).
      for r_con in
      ( select  con.owner
        ,       con.table_name
        ,       con.constraint_name
        ,       con.constraint_type
        from    user_constraints con
        where   con.owner = user
        and     con.table_name in ( p_table_name, upper(p_table_name) )
        and     ( con.constraint_name like p_constraint_name escape '\' or
                  con.constraint_name like upper(p_constraint_name) escape '\'
                )
        and     con.constraint_type = upper(p_constraint_type)
      )
      loop
        print('r_con.owner', r_con.owner);
        print('r_con.table_name', r_con.table_name);
        print('r_con.constraint_name', r_con.constraint_name);
        print('r_con.constraint_type', r_con.constraint_type);

        -- See 2. Can probably better but this is fine.
        if cardinality(p_column_tab) > 0
        then
          select  cons.column_name
          bulk collect
          into    l_column_tab          
          from    user_cons_columns cons
          where   cons.owner = r_con.owner
          and     cons.constraint_name = r_con.constraint_name
          order by
                  cons.position; -- can be null for Check constraints

          if columns_match
             ( p_act_column_tab => l_column_tab
             , p_exp_column_tab => p_column_tab
             , p_must_match_exactly => (r_con.constraint_type <> 'C')
             )
          then
            print('constraint', 'candidate (' || r_con.constraint_name || ')');
            l_nr_constraints_found := l_nr_constraints_found + 1;
          else
            print('constraint', 'NO candidate');
          end if;
        else
          -- assume this one is OK
          print('constraint', 'candidate (' || r_con.constraint_name || ')');
          l_nr_constraints_found := l_nr_constraints_found + 1;
        end if;

        if l_nr_constraints_found > 1 then raise too_many_rows; end if;
        l_constraint_name := r_con.constraint_name;
      end loop;
      
      case l_nr_constraints_found
        when 0
        then raise no_data_found;
        when 1
        then null; -- OK
      end case;
    end if;
    
    leave(l_routine);
  exception
    when others
    then
      leave_on_error(l_routine);
      raise;
  end determine_constraint_name;
begin
  enter(l_routine);
  print('p_operation', p_operation);
  print('p_table_name', p_table_name);
  print('p_constraint_name', p_constraint_name);
  print('p_constraint_type', p_constraint_type);
  print('p_column_tab', p_column_tab);
  print('p_extra', p_extra);
  print('p_ignore_sqlcode_tab', p_ignore_sqlcode_tab);

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
        check_condition(false, 'Parameter "p_operation" must be one of "ADD", "MODIFY", "RENAME" or "DROP"');
    end case;
    
    l_statement := 'ALTER TABLE ' || p_table_name || ' ' || p_operation || ' CONSTRAINT ' || l_constraint_name || ' ' || p_extra;
  exception
    when others
    then
      if not
         ( ignore_error
           ( p_ignore_sqlcode_tab => p_ignore_sqlcode_tab
           )
         )
      then
        raise;
      else
        l_statement := null;
      end if;
  end;

  if l_statement is not null
  then
    do
    ( p_statement => l_statement
    , p_ignore_sqlcode_tab => p_ignore_sqlcode_tab
    );
  end if;
  
  leave(l_routine);
exception
  when others
  then
    leave_on_error(l_routine);
    raise;
end constraint_ddl;

procedure comment_ddl
( p_table_name in user_tab_columns.table_name%type
, p_column_name in user_tab_columns.column_name%type
, p_comment in varchar2
, p_ignore_sqlcode_tab in t_ignore_sqlcode_tab
)
is
  l_routine constant varchar2(30 byte) := 'comment_ddl';
begin
  enter(l_routine);
  print('p_table_name', p_table_name);
  print('p_column_name', p_column_name);
  print('p_comment', p_comment);
  print('p_ignore_sqlcode_tab', p_ignore_sqlcode_tab);
  
  do
  ( p_statement =>
      case
        when p_column_name is not null
        then 'COMMENT ON COLUMN "' || p_table_name || '"."' || p_column_name || '" IS ''' || p_comment || ''''
        else 'COMMENT ON TABLE "' || p_table_name || '" IS ''' || p_comment || ''''
      end
  , p_ignore_sqlcode_tab => p_ignore_sqlcode_tab
  );

  leave(l_routine);
exception
  when others
  then
    leave_on_error(l_routine);
    raise;
end comment_ddl;    

procedure index_ddl
( p_operation in varchar2
, p_index_name in user_indexes.index_name%type
, p_table_name in user_indexes.table_name%type
, p_column_tab in t_column_tab
, p_extra in varchar2
, p_ignore_sqlcode_tab in t_ignore_sqlcode_tab
)
is
  l_routine constant varchar2(30 byte) := 'index_ddl';
  l_index_name user_indexes.index_name%type := p_index_name;
  l_index_name_list varchar2(32767) := null; -- used in CREATE
  l_statement varchar2(32767 byte) := null;

  procedure determine_index_name
  is
    l_routine constant varchar2(60 byte) := 'index_ddl.determine_index_name';
    l_nr_indexes_found naturaln := 0;
    l_column_tab t_column_tab;    
  begin
    enter(l_routine);
    
    if instr(p_index_name, '%') > 0
    then
      check_condition(p_table_name is not null, 'Parameter "p_table_name" should NOT be empty');
    
      -- 1. Find the one and only index that matches the filter criteria p_table_name and p_index_name.
      -- 2. But also all the index columns must match p_column_tab (when not null and in that order).
      for r_ind in
      ( select  ind.index_name
        from    user_indexes ind
        where   ind.table_owner = user
        and     ind.table_name in ( p_table_name, upper(p_table_name) )
        and     ( ind.index_name like p_index_name escape '\' or
                  ind.index_name like upper(p_index_name) escape '\'
                )
      )
      loop
        print('r_ind.index_name', r_ind.index_name);
        
        -- See 2. Can probably better but this is fine.
        if cardinality(p_column_tab) > 0
        then
          select  inds.column_name
          bulk collect
          into    l_column_tab
          from    user_ind_columns inds
          where   inds.index_name = r_ind.index_name
          order by
                  inds.column_position;

          if columns_match
             ( p_act_column_tab => l_column_tab
             , p_exp_column_tab => p_column_tab
             , p_must_match_exactly => true
             )
          then
            print('index', 'candidate (' || r_ind.index_name || ')');
            l_nr_indexes_found := l_nr_indexes_found + 1;
          else
            print('index', 'NO candidate (' || r_ind.index_name || ')');
          end if;
        else
          -- assume this is OK
          print('index', 'candidate (' || r_ind.index_name || ')');
          l_nr_indexes_found := l_nr_indexes_found + 1;
        end if;

        if l_nr_indexes_found > 1 then raise too_many_rows; end if;
        l_index_name := r_ind.index_name;
      end loop;
      
      case l_nr_indexes_found
        when 0
        then raise no_data_found;
        when 1
        then null; -- OK
      end case;
    end if;
    leave(l_routine);
  exception
    when others
    then
      leave_on_error(l_routine);
      raise;
  end determine_index_name;
begin
  enter(l_routine);
  print('p_operation', p_operation);
  print('p_index_name', p_index_name);
  print('p_table_name', p_table_name);
  print('p_column_tab', p_column_tab);
  print('p_extra', p_extra);
  print('p_ignore_sqlcode_tab', p_ignore_sqlcode_tab);

  begin
    check_condition
    ( upper(p_operation) in ('CREATE', 'ALTER', 'DROP')
    , 'Parameter "p_operation" must be one of "CREATE", "ALTER" or "DROP"'
    );
    
    if upper(p_operation) = 'ALTER'
    then
      if instr(p_index_name, '%') > 0 and upper(p_extra) like 'RENAME TO %'
      then
        determine_index_name;
      end if;

      l_statement := p_operation || ' INDEX ' || l_index_name || ' ' || p_extra;
    else
      if upper(p_operation) = 'CREATE'
      then
        check_condition
        ( p_table_name is not null and cardinality(p_column_tab) > 0
        , 'Parameter "p_table_name" and "p_column_tab" should NOT be empty'
        );
        
        l_index_name_list := ' (';
        for i_idx in p_column_tab.first .. p_column_tab.last
        loop
          if i_idx <> p_column_tab.first
          then
            l_index_name_list := l_index_name_list || ',';
          end if;
          l_index_name_list := l_index_name_list || p_column_tab(i_idx);
        end loop;
        l_index_name_list := l_index_name_list || ')';
      end if;
      
      l_statement := p_operation || ' INDEX ' || l_index_name || case when p_table_name is not null then ' ON ' || p_table_name || l_index_name_list end || ' ' || p_extra;
    end if;
  exception
    when others
    then
      if not
         ( ignore_error
           ( p_ignore_sqlcode_tab => p_ignore_sqlcode_tab
           )
         )
      then
        raise;
      else
        l_statement := null;
      end if;
  end;

  if l_statement is not null
  then
    do
    ( p_statement => l_statement
    , p_ignore_sqlcode_tab => p_ignore_sqlcode_tab
    );
  end if;

  leave(l_routine);
exception
  when others
  then
    leave_on_error(l_routine);
    raise;
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
  l_routine constant varchar2(30 byte) := 'trigger_ddl';
begin
  enter(l_routine);
  print('p_operation', p_operation);
  print('p_trigger_name', p_trigger_name);
  print('p_trigger_extra', p_trigger_extra);
  print('p_table_name', p_table_name);
  print('p_extra', p_extra);
  print('p_ignore_sqlcode_tab', p_ignore_sqlcode_tab);

  check_condition
  ( upper(p_operation) in ('CREATE', 'CREATE OR REPLACE', 'ALTER', 'DROP')
  , 'Parameter "p_operation" must be one of "CREATE", "CREATE OR REPLACE", "ALTER" or "DROP"'
  );
  
  do
  ( p_statement =>
      case
        when p_table_name is not null
        then p_operation || ' TRIGGER "' || p_trigger_name || '" ' || p_trigger_extra || ' ON "' || p_table_name || '"' || chr(10) || p_extra
        else p_operation || ' TRIGGER "' || p_trigger_name || '" ' || p_trigger_extra
      end
  , p_ignore_sqlcode_tab => p_ignore_sqlcode_tab
  );

  leave(l_routine);
exception
  when others
  then
    leave_on_error(l_routine);
    raise;
end trigger_ddl;    

procedure view_ddl
( p_operation in varchar2 -- The operation: usually CREATE, ALTER or DROP
, p_view_name in user_views.view_name%type -- The view name
, p_extra in varchar2 default null -- To add after the view name
, p_ignore_sqlcode_tab in t_ignore_sqlcode_tab default c_ignore_sqlcodes_view_ddl -- SQL codes to ignore
)
is
  l_routine constant varchar2(30 byte) := 'view_ddl';
begin
  enter(l_routine);
  print('p_operation', p_operation);
  print('p_view_name', p_view_name);
  print('p_extra', p_extra);
  print('p_ignore_sqlcode_tab', p_ignore_sqlcode_tab);
  
  check_condition
  ( upper(p_operation) in ('CREATE', 'CREATE OR REPLACE', 'ALTER', 'DROP')
  , 'Parameter "p_operation" must be one of "CREATE", "CREATE OR REPLACE", "ALTER" or "DROP"'
  );
  
  do
  ( p_statement => p_operation || ' VIEW "' || p_view_name || '" ' || p_extra
  , p_ignore_sqlcode_tab => p_ignore_sqlcode_tab
  );

  leave(l_routine);
exception
  when others
  then
    leave_on_error(l_routine);
    raise;
end view_ddl;

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
, unique(name)
)'
    , c_test_table_name_child
    , c_test_pk_name_child
    , c_test_ck1_name_child
    , c_test_fk_name_child
    , c_test_table_name_parent
    )
  );
  -- view
  do
  ( utl_lms.format_message
    ( 'create view %s as select * from dual'
    , c_test_view_name
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
  
  -- view
  do
  ( utl_lms.format_message
    ( 'drop view %s'
    , c_test_view_name
    )
  );
end ut_done;

procedure ut_drop_constraints
( p_table_name in varchar2
, p_constraint_name in varchar2 default null
)
is
begin
  for r_con in
  ( select  con.constraint_name
    from    user_constraints con
    where   table_name = upper(p_table_name)
    and     ( p_constraint_name is null or con.constraint_name in ( p_constraint_name, upper(p_constraint_name) ) )
  )
  loop
    begin
      constraint_ddl
      ( p_operation => 'DROP'
      , p_table_name => p_table_name
      , p_constraint_name => r_con.constraint_name
      , p_ignore_sqlcode_tab => null
      );
    exception
      when others
      then raise program_error; -- should not come here
    end;
  end loop;
end ut_drop_constraints;

procedure ut_setup
is
begin
  g_testing := true;
$if oracle_tools.cfg_pkg.c_debugging $then
  g_dbug_dbms_output_active := dbug.active('dbms_output');
  if g_dbug_dbms_output_active
  then
    dbug.activate('dbms_output', false);
  end if;
$end  
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
$if oracle_tools.cfg_pkg.c_debugging $then
  if g_dbug_dbms_output_active
  then
    dbug.activate('dbms_output', true);
    g_dbug_dbms_output_active := null;
  end if;
$end  
  g_testing := false;
end ut_teardown;

procedure ut_column_ddl
is
  l_lines dbms_output.chararr;
  l_nr_lines integer := 1000;
begin
  set_ddl_execution_settings(p_dry_run => true);
  
  -- check parameters
  for i_idx in 1..8
  loop
    begin
      column_ddl
      ( p_operation => case i_idx
                         -- OK
                         when 1 then 'ADD'
                         when 2 then 'modify'
                         when 3 then 'Drop'
                         -- FAIL
                         when 4 then 'create'
                         when 5 then 'create or replace'
                         when 6 then 'alter'
                         when 7 then 'rename'
                         when 8 then null
                       end
      , p_table_name => 'TEST'
      , p_column_name => 'ABC'
      , p_extra => 'XYZ'
      );
    exception
      when value_error
      then if i_idx >= 4 then null; else raise; end if;
    end;
  end loop;

  -- clear the output cache
  dbms_output.get_lines
  ( lines => l_lines
  , numlines => l_nr_lines
  );
  column_ddl
  ( p_operation => 'Add'
  , p_table_name => 'test'
  , p_column_name => 'abc'
  , p_extra => 'xyz '
  );
  l_nr_lines := 1000;
  dbms_output.get_lines
  ( lines => l_lines
  , numlines => l_nr_lines
  );
  ut.expect(l_nr_lines).to_equal(1);
  ut.expect(l_lines(1)).to_equal('ALTER TABLE test Add (abc xyz )');
  reset_ddl_execution_settings;
end ut_column_ddl;

procedure ut_column_already_exists
is
begin
  column_ddl
  ( p_operation => 'Add'
  , p_table_name => c_test_table_name_parent
  , p_column_name => 'ID'
  , p_extra => 'number'
  , p_ignore_sqlcode_tab => null
  );
end ut_column_already_exists;

procedure ut_column_does_not_exist
is
begin
  column_ddl
  ( p_operation => 'drop'
  , p_table_name => c_test_table_name_child
  , p_column_name => 'xyz'
  , p_ignore_sqlcode_tab => null
  );
end ut_column_does_not_exist;

procedure ut_table_ddl
is
  l_lines dbms_output.chararr;
  l_nr_lines integer := 1000;
begin
  set_ddl_execution_settings(p_dry_run => true);

  -- check parameters
  for i_idx in 1..8
  loop
    begin
      table_ddl
      ( p_operation => case i_idx
                         -- OK
                         when 1 then 'create'
                         when 2 then 'ALTER'
                         when 3 then 'Drop'
                         -- FAIL
                         when 4 then 'add'
                         when 5 then 'create or replace'
                         when 6 then 'modify'
                         when 7 then 'rename'
                         when 8 then null
                       end
      , p_table_name => 'TEST'
      , p_extra => 'XYZ'
      );
    exception
      when value_error
      then if i_idx >= 4 then null; else raise; end if;
    end;
  end loop;

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

procedure ut_table_already_exists
is
begin
  table_ddl
  ( p_operation => 'CREATE'
  , p_table_name => c_test_table_name_parent
  , p_extra => '( id number )'
  , p_ignore_sqlcode_tab => null
  );
end ut_table_already_exists;

procedure ut_table_does_not_exist
is
begin
  table_ddl
  ( p_operation => 'DROP'
  , p_table_name => c_test_table_name_child || 'XYZ'
  , p_extra => 'purge'
  , p_ignore_sqlcode_tab => null
  );
end ut_table_does_not_exist;

procedure ut_constraint_ddl
is
  l_lines dbms_output.chararr;
  l_nr_lines integer := 1000;
begin
  set_ddl_execution_settings(p_dry_run => true);
  
  -- check parameters
  for i_idx in 1..8
  loop
    begin
      constraint_ddl
      ( p_operation => case i_idx
                         -- OK
                         when 1 then 'ADD'
                         when 2 then 'modify'
                         when 3 then 'rename'
                         when 4 then 'Drop'
                         -- FAIL
                         when 5 then 'create'
                         when 6 then 'create or replace'
                         when 7 then 'alter'
                         when 8 then null
                       end
      , p_table_name => 'TEST'
      , p_constraint_name => 'ABC'
      , p_extra => 'XYZ'
      );
    exception
      when value_error
      then if i_idx >= 5 then null; else raise_application_error(-20000, 'idx: ' || i_idx, true); end if;
    end;
  end loop;

  -- clear the output cache
  dbms_output.get_lines
  ( lines => l_lines
  , numlines => l_nr_lines
  );
  constraint_ddl
  ( p_operation => 'Add'
  , p_table_name => 'test'
  , p_constraint_name => 'abc'
  , p_extra => 'xyz '
  );
  l_nr_lines := 1000;
  dbms_output.get_lines
  ( lines => l_lines
  , numlines => l_nr_lines
  );
  ut.expect(l_nr_lines).to_equal(1);
  ut.expect(l_lines(1)).to_equal('ALTER TABLE test Add CONSTRAINT abc xyz ');
  reset_ddl_execution_settings;
end ut_constraint_ddl;

procedure ut_pk_constraint_already_exists
is
begin
  constraint_ddl
  ( p_operation => 'ADD'
  , p_table_name => c_test_table_name_parent
  , p_constraint_name => c_test_pk_name_parent
  , p_extra => 'PRIMARY KEY (ID)'
  , p_ignore_sqlcode_tab => null
  );
end ut_pk_constraint_already_exists;

procedure ut_uk_constraint_already_exists
is
begin
  constraint_ddl
  ( p_operation => 'ADD'
  , p_table_name => c_test_table_name_parent
  , p_constraint_name => c_test_uk_name_parent
  , p_extra => 'UNIQUE (NAME)'
  , p_ignore_sqlcode_tab => null
  );
end ut_uk_constraint_already_exists;

procedure ut_fk_constraint_already_exists
is
begin
  constraint_ddl
  ( p_operation => 'ADD'
  , p_table_name => c_test_table_name_child
  , p_constraint_name => c_test_fk_name_child
  , p_extra => 'FOREIGN KEY (PARENT_ID) REFERENCES ' || c_test_table_name_parent || '(ID)'
  , p_ignore_sqlcode_tab => null
  );
end ut_fk_constraint_already_exists;

procedure ut_ck_constraint_already_exists
is
begin
  constraint_ddl
  ( p_operation => 'ADD'
  , p_table_name => c_test_table_name_child
  , p_constraint_name => c_test_ck1_name_child
  , p_extra => 'CHECK (NAME IS NOT NULL)'
  , p_ignore_sqlcode_tab => null
  );
end ut_ck_constraint_already_exists;

procedure ut_pk_constraint_does_not_exist
is
begin
  ut_drop_constraints(c_test_table_name_child);
  
  -- this should be the second drop
  constraint_ddl
  ( p_operation => 'DROP'
  , p_table_name => c_test_table_name_child
  , p_constraint_name => c_test_pk_name_child
  , p_ignore_sqlcode_tab => null
  );
end ut_pk_constraint_does_not_exist;

procedure ut_uk_constraint_does_not_exist
is
begin
  ut_drop_constraints(c_test_table_name_parent, c_test_uk_name_parent);
  
  -- this should be the second drop
  constraint_ddl
  ( p_operation => 'DROP'
  , p_table_name => c_test_table_name_parent
  , p_constraint_name => c_test_uk_name_parent
  , p_ignore_sqlcode_tab => null
  );
end ut_uk_constraint_does_not_exist;

procedure ut_fk_constraint_does_not_exist
is
begin
  ut_drop_constraints(c_test_table_name_child);
  
  -- this should be the second drop
  constraint_ddl
  ( p_operation => 'DROP'
  , p_table_name => c_test_table_name_child
  , p_constraint_name => c_test_fk_name_child
  , p_ignore_sqlcode_tab => null
  );
end ut_fk_constraint_does_not_exist;

procedure ut_ck_constraint_does_not_exist
is
begin
  ut_drop_constraints(c_test_table_name_child);
  
  -- this should be the second drop
  constraint_ddl
  ( p_operation => 'DROP'
  , p_table_name => c_test_table_name_child
  , p_constraint_name => c_test_ck1_name_child
  , p_ignore_sqlcode_tab => null
  );
end ut_ck_constraint_does_not_exist;

procedure ut_rename_constraint
is
  l_lines dbms_output.chararr;
  l_nr_lines integer := 1000;
begin
  -- clear the output cache
  dbms_output.get_lines
  ( lines => l_lines
  , numlines => l_nr_lines
  );  
  constraint_ddl
  ( p_operation => 'RENAME'
  , p_table_name => c_test_table_name_child
  , p_constraint_name => 'sys\_%'
  , p_constraint_type => 'C'
  , p_extra => 'TO ' || c_test_ck2_name_child
  , p_ignore_sqlcode_tab => null
  );
  l_nr_lines := 1000;
  dbms_output.get_lines
  ( lines => l_lines
  , numlines => l_nr_lines
  );
  ut.expect(l_nr_lines).to_be_greater_or_equal(1);
  -- 
  ut.expect(l_lines(l_lines.first)).to_be_like('ALTER TABLE test$CFG_INSTALL_DDL_PKG$child$tab RENAME CONSTRAINT SYS\_% TO test$CFG_INSTALL_DDL_PKG$child$ck2', '\');
end ut_rename_constraint;

procedure ut_rename_index
is
  l_lines dbms_output.chararr;
  l_nr_lines integer := 1000;
begin
  -- clear the output cache
  dbms_output.get_lines
  ( lines => l_lines
  , numlines => l_nr_lines
  );  
  index_ddl
  ( p_operation => 'ALTER'
  , p_table_name => c_test_table_name_child
  , p_index_name => 'sys\_%'
  , p_column_tab => t_column_tab('NAME')
  , p_extra => 'RENAME TO XYZ'
  , p_ignore_sqlcode_tab => null
  );
  l_nr_lines := 1000;
  dbms_output.get_lines
  ( lines => l_lines
  , numlines => l_nr_lines
  );
  ut.expect(l_nr_lines).to_be_greater_or_equal(1);
  -- 
  ut.expect(l_lines(l_lines.first)).to_be_like('ALTER INDEX SYS\_% RENAME TO XYZ', '\');
end ut_rename_index;

procedure ut_view_ddl
is
  l_lines dbms_output.chararr;
  l_nr_lines integer := 1000;
begin
  set_ddl_execution_settings(p_dry_run => true);

  -- check parameters
  for i_idx in 1..8
  loop
    begin
      view_ddl
      ( p_operation => case i_idx
                         -- OK
                         when 1 then 'create'
                         when 2 then 'create or replace'
                         when 3 then 'ALTER'
                         when 4 then 'Drop'
                         -- FAIL
                         when 5 then 'add'
                         when 6 then 'modify'
                         when 7 then 'rename'
                         when 8 then null
                       end
      , p_view_name => 'TEST'
      , p_extra => 'XYZ'
      );
    exception
      when value_error
      then if i_idx >= 5 then null; else raise; end if;
    end;
  end loop;

  -- clear the output cache
  dbms_output.get_lines
  ( lines => l_lines
  , numlines => l_nr_lines
  );
  view_ddl
  ( p_operation => 'CREATE'
  , p_view_name => 'TEST'
  , p_extra => 'XYZ'
  );
  l_nr_lines := 1000;
  dbms_output.get_lines
  ( lines => l_lines
  , numlines => l_nr_lines
  );
  ut.expect(l_nr_lines).to_equal(1);
  ut.expect(l_lines(1)).to_equal('CREATE VIEW TEST XYZ');
  reset_ddl_execution_settings;
end ut_view_ddl;

procedure ut_view_already_exists
is
begin
  -- either one will fail
  view_ddl
  ( p_operation => 'CREATE'
  , p_view_name => c_test_view_name
  , p_extra => 'AS SELECT * FROM DUAL'
  , p_ignore_sqlcode_tab => null
  );
  view_ddl
  ( p_operation => 'CREATE'
  , p_view_name => c_test_view_name
  , p_extra => 'AS SELECT * FROM DUAL'
  , p_ignore_sqlcode_tab => null
  );
end ut_view_already_exists;

procedure ut_view_does_not_exist
is
begin
  view_ddl
  ( p_operation => 'DROP'
  , p_view_name => c_test_view_name || 'XYZ'
  , p_extra => null
  , p_ignore_sqlcode_tab => null
  );
end ut_view_does_not_exist;

$end -- $if cfg_pkg.c_testing $then

end cfg_install_ddl_pkg;
/

