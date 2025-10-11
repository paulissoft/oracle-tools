CREATE OR REPLACE PACKAGE BODY DATA_AUDITING_PKG IS

procedure add_auditing_columns
( p_table_name in user_tab_columns.table_name%type -- Table name, may be surrounded by double quotes
, p_column_aud$ins$who in user_tab_columns.column_name%type -- When not null this column will be renamed to AUD$INS$WHO
, p_column_aud$ins$when in user_tab_columns.column_name%type -- When not null this column will be renamed to AUD$INS$WHEN
, p_column_aud$ins$where in user_tab_columns.column_name%type -- When not null this column will be renamed to AUD$INS$WHERE
, p_column_aud$upd$who in user_tab_columns.column_name%type -- When not null this column will be renamed to AUD$UPD$WHO
, p_column_aud$upd$when in user_tab_columns.column_name%type -- When not null this column will be renamed to AUD$UPD$WHEN
, p_column_aud$upd$where in user_tab_columns.column_name%type -- When not null this column will be renamed to AUD$UPD$WHERE
)
is
  procedure add_auditing_colum
  ( p_existing_column_name in user_tab_columns.column_name%type
  , p_column_name in user_tab_columns.column_name%type
  , p_data_default in varchar2 default null
  )
  is
    l_data_type constant user_tab_columns.data_type%type :=
      case
        when substr(p_column_name, -4) = 'WHEN'
        then 'TIMESTAMP WITH TIME ZONE'
        else 'VARCHAR2(128 CHAR)'
      end;
  begin
    if p_existing_column_name is not null
    then
      cfg_install_ddl_pkg.column_ddl
      ( p_operation => 'RENAME'
      , p_table_name => p_table_name
      , p_column_name => p_existing_column_name
      , p_extra => 'TO ' || p_column_name
      );
    else
      cfg_install_ddl_pkg.column_ddl
      ( p_operation => 'ADD'
      , p_table_name => p_table_name
      , p_column_name => p_column_name
      , p_extra => l_data_type
      );
    end if;

    if p_data_default is not null
    then
      cfg_install_ddl_pkg.column_ddl
      ( p_operation => 'MODIFY'
      , p_table_name => p_table_name
      , p_column_name => p_column_name
      , p_extra => 'DEFAULT ' || p_data_default
      );
    end if;
  end;
begin
  add_auditing_colum(p_column_aud$ins$who, 'AUD$INS$WHO', 'ORACLE_TOOLS.DATA_SESSION_USERNAME');
  add_auditing_colum(p_column_aud$ins$when, 'AUD$INS$WHEN', 'ORACLE_TOOLS.DATA_TIMESTAMP');
  add_auditing_colum(p_column_aud$ins$where, 'AUD$INS$WHERE', 'ORACLE_TOOLS.DATA_CALL_INFO');
  add_auditing_colum(p_column_aud$upd$who, 'AUD$UPD$WHO');
  add_auditing_colum(p_column_aud$upd$when, 'AUD$UPD$WHEN');
  add_auditing_colum(p_column_aud$upd$where, 'AUD$UPD$WHERE');
end add_auditing_columns;

procedure add_auditing_trigger
( p_table_name in user_tab_columns.table_name%type
)
is
  l_table_name_no_qq constant user_tab_columns.table_name%type :=
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
  l_trigger_name_no_qq constant user_triggers.trigger_name%type :=
    utl_lms.format_message('AUD$%s', l_table_name_no_qq);
  l_trigger_name constant user_triggers.trigger_name%type := 
    case
      when l_table_name_exact = 1
      then utl_lms.format_message('"%s"', l_trigger_name_no_qq)
      else utl_lms.format_message('%s', l_trigger_name_no_qq)
    end;
  l_found pls_integer;
  
  procedure execute_immediate
  ( p_statement in varchar2
  , p_ignore_errors in boolean
  )
  is
  begin
    execute immediate p_statement;
  exception
    when others
    then
      if p_ignore_errors then null; else raise; end if;
  end;
begin
  execute_immediate
  ( utl_lms.format_message
    ( 'CREATE TRIGGER %s
BEFORE UPDATE ON %s
FOR EACH ROW
WHEN (NEW.AUD$UPD$WHO IS NULL OR NEW.AUD$UPD$WHEN IS NULL OR NEW.AUD$UPD$WHERE IS NULL)
DISABLED
BEGIN
  ORACLE_TOOLS.DATA_AUDITING_PKG.UPD
  ( P_AUD$UPD$WHO => :NEW.AUD$UPD$WHO
  , P_AUD$UPD$WHEN => :NEW.AUD$UPD$WHEN
  , P_AUD$UPD$WHERE => :NEW.AUD$UPD$WHERE
  );
END;'
    , l_trigger_name
    , p_table_name
    )
  , true
  );

  begin
    select  1
    into    l_found
    from    user_objects o
            inner join user_triggers t
            on t.trigger_name = o.object_name and t.status = 'DISABLED'
    where   o.status = 'VALID'
    and     o.object_type = 'TRIGGER'
    and     ( o.object_name = l_trigger_name_no_qq or
              ( l_table_name_exact = 0 and o.object_name = upper(l_trigger_name_no_qq) )
            )
    ;
    execute_immediate(utl_lms.format_message('ALTER TRIGGER %s ENABLE', l_trigger_name), false);
  exception
    when others
    then null;
  end;
end add_auditing_trigger;

procedure upd
( p_aud$upd$who in out nocopy varchar2
, p_aud$upd$when in out nocopy timestamp with time zone -- standard
, p_aud$upd$where in out nocopy varchar2
)
is
begin
  if p_aud$upd$who is null then p_aud$upd$who := oracle_tools.data_session_username; end if;
  if p_aud$upd$when is null then p_aud$upd$when := oracle_tools.data_timestamp; end if;
  if p_aud$upd$where is null then p_aud$upd$who := oracle_tools.data_call_info; end if;
end upd;

procedure upd
( p_aud$upd$who in out nocopy varchar2
, p_aud$upd$when in out nocopy timestamp -- datatype of an old existing colum
, p_aud$upd$where in out nocopy varchar2
)
is
begin
  if p_aud$upd$who is null then p_aud$upd$who := oracle_tools.data_session_username; end if;
  if p_aud$upd$when is null then p_aud$upd$when := systimestamp; end if;
  if p_aud$upd$where is null then p_aud$upd$who := oracle_tools.data_call_info; end if;
end upd;

procedure upd
( p_aud$upd$who in out nocopy varchar2
, p_aud$upd$when in out nocopy date -- datatype of an old existing colum
, p_aud$upd$where in out nocopy varchar2
)
is
begin
  if p_aud$upd$who is null then p_aud$upd$who := oracle_tools.data_session_username; end if;
  if p_aud$upd$when is null then p_aud$upd$when := sysdate; end if;
  if p_aud$upd$where is null then p_aud$upd$who := oracle_tools.data_call_info; end if;
end upd;

END;
/
