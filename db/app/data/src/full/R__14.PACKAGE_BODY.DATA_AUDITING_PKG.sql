CREATE OR REPLACE PACKAGE BODY DATA_AUDITING_PKG IS

procedure add_columns
( p_table_name in all_tab_columns.table_name%type -- Table name, may be surrounded by double quotes
, p_column_aud$ins$who in all_tab_columns.column_name%type -- When not null this column will be renamed to AUD$INS$WHO
, p_column_aud$ins$when in all_tab_columns.column_name%type -- When not null this column will be renamed to AUD$INS$WHEN
, p_column_aud$ins$where in all_tab_columns.column_name%type -- When not null this column will be renamed to AUD$INS$WHERE
, p_column_aud$upd$who in all_tab_columns.column_name%type -- When not null this column will be renamed to AUD$UPD$WHO
, p_column_aud$upd$when in all_tab_columns.column_name%type -- When not null this column will be renamed to AUD$UPD$WHEN
, p_column_aud$upd$where in all_tab_columns.column_name%type -- When not null this column will be renamed to AUD$UPD$WHERE
, p_owner in all_tab_columns.owner%type
)
is
  -- all_tab_columns does not provide info about virtual columns but all_tab_cols does
  type t_column_tab is table of all_tab_cols%rowtype index by all_tab_cols.column_name%type; -- index by column name

  l_owner_no_qq constant all_tab_columns.owner%type :=
    case
      when p_owner like '"%"'
      then replace(substr(p_owner, 2, length(p_owner) - 2), '""', '"')
      else p_owner
    end;
  l_table_name_no_qq constant all_tab_columns.table_name%type :=
    case
      when p_table_name like '"%"'
      then replace(substr(p_table_name, 2, length(p_table_name) - 2), '""', '"')
      else p_table_name
    end;
  l_table_name_exact constant naturaln :=
    case
      when p_table_name like '"%"'
      then 1
      else 0
    end;

  procedure add_column
  ( p_existing_column_name in all_tab_columns.column_name%type
  , p_audit_column_name in all_tab_columns.column_name%type -- always exact
  )
  is
    l_existing_column_name_no_qq constant all_tab_columns.column_name%type :=
      case
        when p_existing_column_name like '"%"'
        then replace(substr(p_existing_column_name, 2, length(p_existing_column_name) - 2), '""', '"')
        else p_existing_column_name
      end;
    l_existing_column_name_exact constant naturaln :=
      case
        when p_existing_column_name like '"%"'
        then 1
        else 0
      end;    
    l_data_type constant all_tab_columns.data_type%type :=
      case
        when substr(p_audit_column_name, -3) = 'WHO'
        then 'VARCHAR2(128 CHAR)'
        when substr(p_audit_column_name, -4) = 'WHEN'
        then 'TIMESTAMP WITH TIME ZONE'
        when substr(p_audit_column_name, -5) = 'WHERE'
        then 'VARCHAR2(1000 CHAR)'
      end;

    l_column_tab t_column_tab;

    procedure get_column_info
    is
    begin
      l_column_tab.delete; -- refresh
      
      for r in
      ( select  tc.*
        from    all_tab_cols tc
        where   tc.owner = nvl(l_owner_no_qq, sys_context('USERENV', 'CURRENT_SCHEMA'))
        and     ( tc.table_name = l_table_name_no_qq or
                  ( l_table_name_exact = 0 and tc.table_name = upper(l_table_name_no_qq) )
                )
        and     ( tc.column_name = p_audit_column_name or
                  ( tc.column_name = l_existing_column_name_no_qq or
                    ( l_existing_column_name_exact = 0 and tc.column_name = upper(l_existing_column_name_no_qq) )
                  )
                )
      )
      loop
        case
          when r.column_name = p_audit_column_name
          then l_column_tab(p_audit_column_name) := r;
          else l_column_tab(p_existing_column_name) := r;
        end case;
      end loop;
    end get_column_info;
  begin
    get_column_info;
    
    if p_existing_column_name is not null
    then
      -- rename existing (non-virtual) column to audit column?
      if l_column_tab.exists(p_existing_column_name) and
         l_column_tab(p_existing_column_name).virtual_column = 'NO'
      then
        cfg_install_ddl_pkg.column_ddl
        ( p_operation => 'RENAME'
        , p_table_name => p_table_name
        , p_column_name => p_existing_column_name
        , p_extra => 'TO ' || p_audit_column_name
        , p_owner => p_owner
        );
        get_column_info; -- refresh
      end if;
      
      -- create virtual (previously) existing column as audit column?
      if not(l_column_tab.exists(p_existing_column_name))
      then
        cfg_install_ddl_pkg.column_ddl
        ( p_operation => 'ADD'
        , p_table_name => p_table_name
        , p_column_name => p_existing_column_name
        , p_extra => -- must be an expression, not just the column so add an empty string or zero seconds
                     utl_lms.format_message
                     ( 'GENERATED ALWAYS AS (%s%s) VIRTUAL'
                     , p_audit_column_name
                     , case l_column_tab(p_audit_column_name).data_type
                         when 'DATE'
                         then ' + 0' -- add 0 seconds
                         when 'VARCHAR2'
                         then ' || NULL' -- append NULL
                         else -- timestamp
                              q'< + INTERVAL '0' SECOND>' -- add 0 seconds
                       end
                     )
        , p_owner => p_owner
        );
        get_column_info; -- refresh
      end if;
    end if;

    if not(l_column_tab.exists(p_audit_column_name))
    then
      cfg_install_ddl_pkg.column_ddl
      ( p_operation => 'ADD'
      , p_table_name => p_table_name
      , p_column_name => p_audit_column_name
      , p_extra => l_data_type
      , p_owner => p_owner
      );
    end if;
/*DBUG    
  exception
    when others
    then raise_application_error
         ( -20000
         , utl_lms.format_message
           ( 'Table: %s; column: %s%s; data type; %s'
           , p_table_name
           , p_column_name
           , case when p_existing_column_name is not null then '(renamed from ' || p_existing_column_name || ')' end
           , l_data_type
           )
         , true
         );
/*DBUG*/
  end;
begin
  add_column(p_column_aud$ins$who, 'AUD$INS$WHO');
  add_column(p_column_aud$ins$when, 'AUD$INS$WHEN');
  add_column(p_column_aud$ins$where, 'AUD$INS$WHERE');
  add_column(p_column_aud$upd$who, 'AUD$UPD$WHO');
  add_column(p_column_aud$upd$when, 'AUD$UPD$WHEN');
  add_column(p_column_aud$upd$where, 'AUD$UPD$WHERE');
end add_columns;

procedure add_trigger
( p_table_name in all_tab_columns.table_name%type
, p_replace in boolean
, p_owner in all_tab_columns.owner%type
)
is
  l_owner_no_qq constant all_tab_columns.owner%type :=
    case
      when p_owner like '"%"'
      then replace(substr(p_owner, 2, length(p_owner) - 2), '""', '"')
      else p_owner
    end;
  l_table_name_no_qq constant all_tab_columns.table_name%type :=
    case
      when p_table_name like '"%"'
      then replace(substr(p_table_name, 2, length(p_table_name) - 2), '""', '"')
      else p_table_name
    end;
  l_table_name_exact constant naturaln :=
    case
      when p_table_name like '"%"'
      then 1
      else 0
    end;
  l_trigger_name_no_qq constant all_triggers.trigger_name%type :=
    utl_lms.format_message('AUD$%s_TRG', l_table_name_no_qq);
  l_trigger_name constant all_triggers.trigger_name%type := 
    case
      when l_table_name_exact = 1
      then utl_lms.format_message('"%s"', l_trigger_name_no_qq)
      else utl_lms.format_message('%s', l_trigger_name_no_qq)
    end;
  l_found pls_integer;
begin
  cfg_install_ddl_pkg.trigger_ddl
  ( p_operation => case when p_replace then 'CREATE OR REPLACE' else 'CREATE' end
  , p_trigger_name => l_trigger_name
  , p_trigger_extra => '
BEFORE INSERT OR UPDATE'
  , p_table_name => p_table_name
  , p_extra => q'<FOR EACH ROW
BEGIN
  IF INSERTING
  THEN
    ORACLE_TOOLS.DATA_AUDITING_PKG.SET_COLUMNS
    ( P_WHO => :NEW.AUD$INS$WHO
    , P_WHEN => :NEW.AUD$INS$WHEN
    , P_WHERE => :NEW.AUD$INS$WHERE
    , P_DO_NOT_SET_WHO => :NEW.AUD$INS$WHO IS NOT NULL
    , P_DO_NOT_SET_WHEN => :NEW.AUD$INS$WHEN IS NOT NULL
    , P_DO_NOT_SET_WHERE => :NEW.AUD$INS$WHERE IS NOT NULL
    );
  ELSE
    ORACLE_TOOLS.DATA_AUDITING_PKG.SET_COLUMNS
    ( P_WHO => :NEW.AUD$UPD$WHO
    , P_WHEN => :NEW.AUD$UPD$WHEN
    , P_WHERE => :NEW.AUD$UPD$WHERE
    , P_DO_NOT_SET_WHO => UPDATING('AUD$UPD$WHO')
    , P_DO_NOT_SET_WHEN => UPDATING('AUD$UPD$WHEN')
    , P_DO_NOT_SET_WHERE => UPDATING('AUD$UPD$WHERE')
    );
  END IF;
END;
>'
  , p_owner => p_owner
  );

  -- disabled an invalid trigger
  begin
    select  1
    into    l_found
    from    all_objects o
            inner join all_triggers t
            on t.owner = o.owner and t.trigger_name = o.object_name
    where   o.owner = nvl(l_owner_no_qq, sys_context('USERENV', 'CURRENT_SCHEMA'))
    and     o.status <> 'VALID'
    and     o.object_type = 'TRIGGER'
    and     ( o.object_name = l_trigger_name_no_qq or
              ( l_table_name_exact = 0 and o.object_name = upper(l_trigger_name_no_qq) )
            )
    ;
    
    cfg_install_ddl_pkg.trigger_ddl
    ( p_operation => 'ALTER'
    , p_trigger_name => l_trigger_name
    , p_table_name => null
    , p_trigger_extra => 'DISABLE'
    , p_owner => p_owner
    );
  exception
    when others
    then null;
  end;
end add_trigger;

procedure set_columns
( p_who in out nocopy varchar2
, p_when in out nocopy timestamp with time zone -- standard
, p_where in out nocopy varchar2
, p_do_not_set_who in boolean
, p_do_not_set_when in boolean
, p_do_not_set_where in boolean
)
is
begin
/*DBUG    
  dbug.enter($$PLSQL_UNIT || '.SET_COLUMNS');
/*DBUG*/    
  if not(p_do_not_set_who) then p_who := oracle_tools.data_session_username; end if;
  if not(p_do_not_set_when) then p_when := oracle_tools.data_timestamp; end if;
  if not(p_do_not_set_where) then p_where := get_call_info; end if;
/*DBUG    
  dbug.print(dbug."output", 'p_who: %s; p_when: %s; p_where: %s', p_who, p_when, p_where);
  dbug.leave;
/*DBUG*/    
exception
  when others
  then 
/*DBUG    
    dbug.leave_on_error;
/*DBUG*/    
    null; /* this call may never raise an error */
end set_columns;

procedure set_columns
( p_who in out nocopy varchar2
, p_when in out nocopy timestamp -- datatype of an old existing colum
, p_where in out nocopy varchar2
, p_do_not_set_who in boolean
, p_do_not_set_when in boolean
, p_do_not_set_where in boolean
)
is
begin
  if not(p_do_not_set_who) then p_who := oracle_tools.data_session_username; end if;
  if not(p_do_not_set_when) then p_when := systimestamp; end if;
  if not(p_do_not_set_where) then p_where := get_call_info; end if;
exception
  when others
  then null; /* this call may never raise an error */
end set_columns;

procedure set_columns
( p_who in out nocopy varchar2
, p_when in out nocopy date -- datatype of an old existing colum
, p_where in out nocopy varchar2
, p_do_not_set_who in boolean
, p_do_not_set_when in boolean
, p_do_not_set_where in boolean
)
is
begin
  if not(p_do_not_set_who) then p_who := oracle_tools.data_session_username; end if;
  if not(p_do_not_set_when) then p_when := sysdate; end if;
  if not(p_do_not_set_where) then p_where := get_call_info; end if;
exception
  when others
  then null; /* this call may never raise an error */
end set_columns;

function get_call_info
return varchar2
is
  subtype t_string is varchar2(1000 char);
  
  l_depth constant positiven := utl_call_stack.dynamic_depth;
  -- skip first index, i.e. this routine
  l_lwb positive := 2;
  l_upb positive := l_depth; 

$if oracle_tools.cfg_pkg.c_apex_installed $then
  l_app_id constant pls_integer := apex_application.g_flow_id;
  l_app_page_id constant pls_integer := apex_application.g_flow_step_id;
  l_tool_call_info t_string :=
    case
      when l_app_id is not null and
           l_app_page_id is not null
      then utl_lms.format_message('APEX app %d page %d', l_app_id, l_app_page_id)
    end;
$else    
  l_tool_call_info t_string := null;
$end

  -- See dbms_application_info.set_module for sizes
  l_module_name varchar2(48 byte);
  l_action_name varchar2(32 byte);

  l_first_call_info t_string := null; -- root call calling this function (leaving out anonymous blocks)
  l_last_call_info t_string := null; -- last call before calling this function
  
  l_unit_qualified_name utl_call_stack.unit_qualified_name;
  l_owner all_objects.owner%type;
  l_object_type all_objects.object_type%type;
  l_object_name all_objects.object_name%type;
  l_line_no pls_integer;  
  
  function construct_call_info
  ( p_unit_qualified_name in utl_call_stack.unit_qualified_name
  , p_owner in all_objects.owner%type
  , p_object_type in all_objects.object_type%type
  , p_object_name in all_objects.object_name%type
  , p_line_no in pls_integer
  )
  return t_string
  is
    l_string t_string := null;
  begin
/*DBUG    
    dbug.enter($$PLSQL_UNIT || '.CONSTRUCT_CALL_INFO (1)');
    dbug.print
    ( dbug."input"
    , 'p_owner: %s; p_object_type: %s; p_object_name: %s; p_line_no: %s'
    , p_owner
    , p_object_type
    , p_object_name
    , p_line_no
    );
/*DBUG*/    
    
    l_string :=
          utl_lms.format_message
          ( '%s %s%s%s'
          , p_object_type
          , p_owner
          , case when p_owner is not null then '.' end
          , p_object_name
          );
          
    if p_line_no is not null
    then
      l_string := l_string || utl_lms.format_message(' line %d', p_line_no);
    end if;
    
    -- construct subprogram (if any)
    for i_idx in 2 .. p_unit_qualified_name.count
    loop
      l_string :=
        l_string ||
        utl_lms.format_message
        ( '%s%s'
        , case i_idx when 2 then ' subprogram ' else '.' end
        , p_unit_qualified_name(i_idx)
        );
    end loop;
     
/*DBUG    
    dbug.print(dbug."output", 'return: %s', l_string);
    dbug.leave;
/*DBUG*/    
     
    return l_string;
  exception
    when value_error
    then
/*DBUG    
      dbug.leave_on_error;
/*DBUG*/    
      return l_string; -- till so far
  end construct_call_info;

  function construct_call_info
  ( p_tool_call_info in t_string
  , p_first_call_info in t_string
  , p_last_call_info in t_string
  )
  return t_string
  is
    l_string t_string := p_last_call_info; -- the most important one
  begin
/*DBUG    
    dbug.enter($$PLSQL_UNIT || '.CONSTRUCT_CALL_INFO (2)');
    dbug.print
    ( dbug."input"
    , 'p_tool_call_info: %s; p_first_call_info: %s; p_last_call_info: %s'
    , p_tool_call_info
    , p_first_call_info
    , p_last_call_info
    );
/*DBUG*/    

    if l_string is null
    then
      -- both p_first_call_info and p_last_call_info are null
      l_string := p_tool_call_info;
    else
      if p_first_call_info <> p_last_call_info -- implies both not null
      then
        l_string := p_first_call_info || ' -->> ' || l_string;
      end if;

      if p_tool_call_info is not null
      then
        l_string := p_tool_call_info || ' | ' || l_string;
      end if;
    end if;
    
/*DBUG    
    dbug.print(dbug."output", 'return: %s', l_string);
    dbug.leave;
/*DBUG*/    
    
    return l_string;
  exception
    when value_error
    then
/*DBUG    
      dbug.leave_on_error;
/*DBUG*/    
      return l_string; -- till so far
  end construct_call_info;
begin
/*DBUG    
  dbug.enter($$PLSQL_UNIT || '.GET_CALL_INFO');
  dbug.print(dbug."info", 'l_depth: %s', l_depth);
/*DBUG*/    

  if l_tool_call_info is null
  then
    dbms_application_info.read_module(module_name => l_module_name, action_name => l_action_name);
    if l_module_name is not null
    then
      l_tool_call_info := 'module ' || l_module_name;
    end if;
    if l_action_name is not null
    then
      l_tool_call_info :=
        case
          when l_tool_call_info is not null
          then l_tool_call_info || ' '
        end || 'action ' || l_action_name;
    end if;
  end if;

  <<try_loop>>
  for i_try in 1..2
  loop
    <<last_call_loop>>
    for i_idx in l_lwb .. l_upb
    loop
      l_unit_qualified_name := utl_call_stack.subprogram(i_idx);
      l_owner := utl_call_stack.owner(i_idx);
      l_object_type := utl_call_stack.unit_type(i_idx);
      l_object_name := l_unit_qualified_name(1);
      l_line_no := utl_call_stack.unit_line(i_idx);

/*DBUG    
      dbug.print
      ( dbug."info"
      , 'i_idx: %s; l_owner: %s; l_object_type: %s; l_object_name: %s; l_line_no: %s'
      , i_idx
      , l_owner
      , l_object_type
      , l_object_name
      , l_line_no
      );
/*DBUG*/    
    
      -- skip calls from:
      -- 1) ORACLE_TOOLS.DATA_AUDITING_PKG subprogram SET_COLUMNS or GET_CALL_INFO
      -- 2) ORACLE_TOOLS.DATA_CALL_INFO
      -- 3) generated auditing triggers
      -- 4) unknown object types
      -- 5) anonymous blocks (stop)
      case
        -- 1)
        when l_owner = $$PLSQL_UNIT_OWNER and
             substr(l_object_type, 1, 7) = 'PACKAGE' and
             l_object_name = 'DATA_AUDITING_PKG' and
             l_unit_qualified_name.count = 2 and
             l_unit_qualified_name(2) in ('SET_COLUMNS', 'GET_CALL_INFO')
        then null;

        -- 2)
        when l_owner = $$PLSQL_UNIT_OWNER and
             substr(l_object_type, 1, 7) = 'FUNCTION' and
             l_object_name = 'DATA_CALL_INFO'
        then null;

        -- 3)
        when l_object_type = 'TRIGGER' and
             substr(l_object_name, 1, 4) = 'AUD$'
        then null;

        -- 4)
        when l_object_type is null or
             l_object_type not in ( 'TRIGGER'
                                  , 'PACKAGE'
                                  , 'PACKAGE BODY'
                                  , 'TYPE'
                                  , 'TYPE BODY'
                                  , 'FUNCTION'
                                  , 'PROCEDURE'
                                  )
        then null;

        -- 5) We will only get anonymous blocks from here on so exit all
        when l_object_type = 'ANONYMOUS BLOCK'
        then exit try_loop;

        when l_last_call_info is null
        then
          PRAGMA INLINE(construct_call_info, 'YES');
          l_last_call_info :=
            construct_call_info
            ( l_unit_qualified_name
            , l_owner
            , l_object_type
            , l_object_name
            , l_line_no
            );
          l_lwb := i_idx + 1;
          exit last_call_loop;
      end case;
    end loop last_call_loop;

    if l_last_call_info is not null
    then
      <<first_call_loop>>
      for i_idx in reverse l_lwb .. l_upb -- now start at the end, i.e. the root (first) call info
      loop
        l_unit_qualified_name := utl_call_stack.subprogram(i_idx);
        l_owner := utl_call_stack.owner(i_idx);
        l_object_type := utl_call_stack.unit_type(i_idx);
        l_object_name := l_unit_qualified_name(1);
        l_line_no := utl_call_stack.unit_line(i_idx);

/*DBUG    
        dbug.print
        ( dbug."info"
        , 'i_idx: %s; l_owner: %s; l_object_type: %s; l_object_name: %s; l_line_no: %s'
        , i_idx
        , l_owner
        , l_object_type
        , l_object_name
        , l_line_no
        );
/*DBUG*/    
    
        -- skip:
        -- 1) unknown object types
        -- 2) anonymous blocks
        case
          -- 1)
          when l_object_type is null or
               l_object_type not in ( 'TRIGGER'
                                    , 'PACKAGE'
                                    , 'PACKAGE BODY'
                                    , 'TYPE'
                                    , 'TYPE BODY'
                                    , 'FUNCTION'
                                    , 'PROCEDURE'
                                    )
          then null;
          
          -- 2)
          when l_object_type = 'ANONYMOUS BLOCK'
          then null;

          when l_first_call_info is null
          then
            PRAGMA INLINE(construct_call_info, 'YES');
            l_first_call_info :=
              construct_call_info
              ( l_unit_qualified_name
              , l_owner
              , l_object_type
              , l_object_name
              , l_line_no
              );
            exit first_call_loop;
        end case;
      end loop last_call_loop;
    end if;
  end loop try_loop;

/*DBUG    
  dbug.leave;
/*DBUG*/    

  PRAGMA INLINE(construct_call_info, 'YES');
  return construct_call_info
         ( l_tool_call_info
         , l_first_call_info
         , l_last_call_info
         );
exception
  when others
  then 
/*DBUG    
    dbug.leave_on_error;
/*DBUG*/    
    return null;
end get_call_info;

procedure add_view
( p_table_name in all_tab_columns.table_name%type -- The table name
, p_prefix in varchar2
, p_suffix in varchar2
, p_replace in boolean
, p_view_text in varchar2
, p_owner in all_tab_columns.owner%type
)
is
  l_table_name_no_qq constant all_tab_columns.table_name%type :=
    case
      when p_table_name like '"%"'
      then replace(substr(p_table_name, 2, length(p_table_name) - 2), '""', '"')
      else p_table_name
    end;
  l_table_name_exact constant naturaln :=
    case
      when p_table_name like '"%"'
      then 1
      else 0
    end;
  l_view_name_no_qq constant all_views.view_name%type :=
    utl_lms.format_message('%s%s%s', p_prefix, l_table_name_no_qq, p_suffix);
  l_view_name constant all_views.view_name%type := 
    case
      when l_table_name_exact = 1
      then utl_lms.format_message('"%s"', l_view_name_no_qq)
      else utl_lms.format_message('%s', l_view_name_no_qq)
    end;
begin
  cfg_install_ddl_pkg.view_ddl
  ( p_operation => case when p_replace then 'CREATE OR REPLACE' else 'CREATE' end
  , p_view_name => l_view_name
  , p_extra => p_view_text
  , p_owner => p_owner
  );
end add_view;

procedure add_view_without_auditing_columns
( p_table_name in all_tab_columns.table_name%type -- The table name
, p_prefix in varchar2 default 'AUD$EXCL$' -- The view prefix
, p_suffix in varchar2 default '_V' -- The view suffix
, p_replace in boolean default false -- Do we create (or replace)?
, p_owner in all_tab_columns.owner%type
)
is
begin
  add_view
  ( p_table_name => p_table_name
  , p_prefix => p_prefix
  , p_suffix => p_suffix
  , p_replace => p_replace
  , p_view_text => utl_lms.format_message( 'AS
SELECT * FROM ORACLE_TOOLS.DATA_SHOW_WITHOUT_AUDITING_COLUMNS(%s)', p_table_name )
  , p_owner => p_owner
  );
end add_view_without_auditing_columns;

procedure add_history_view
( p_table_name in all_tab_columns.table_name%type -- The table name
, p_prefix in varchar2 default 'AUD$HIST$' -- The view prefix
, p_suffix in varchar2 default '_V' -- The view suffix
, p_replace in boolean default false -- Do we create (or replace)?
, p_owner in all_tab_columns.owner%type
)
is
begin
  add_view
  ( p_table_name => p_table_name
  , p_prefix => p_prefix
  , p_suffix => p_suffix
  , p_replace => p_replace
  , p_view_text => utl_lms.format_message( 'AS
SELECT  VERSIONS_STARTTIME
,       VERSIONS_ENDTIME
,       VERSIONS_OPERATION
,       TAB.*
FROM    %s VERSIONS BETWEEN SCN MINVALUE AND MAXVALUE TAB', p_table_name )
  , p_owner => p_owner
  );
end add_history_view;

END;
/
