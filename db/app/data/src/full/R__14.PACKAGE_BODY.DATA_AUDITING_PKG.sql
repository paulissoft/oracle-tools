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
  )
  is
    l_data_type constant user_tab_columns.data_type%type :=
      case
        when substr(p_column_name, -3) = 'WHO'
        then 'VARCHAR2(128 CHAR)'
        when substr(p_column_name, -4) = 'WHEN'
        then 'TIMESTAMP WITH TIME ZONE'
        when substr(p_column_name, -5) = 'WHERE'
        then 'VARCHAR2(1000 CHAR)'
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
  end;
begin
  add_auditing_colum(p_column_aud$ins$who, 'AUD$INS$WHO');
  add_auditing_colum(p_column_aud$ins$when, 'AUD$INS$WHEN');
  add_auditing_colum(p_column_aud$ins$where, 'AUD$INS$WHERE');
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
    utl_lms.format_message('AUD$%s_TRG', l_table_name_no_qq);
  l_trigger_name constant user_triggers.trigger_name%type := 
    case
      when l_table_name_exact = 1
      then utl_lms.format_message('"%s"', l_trigger_name_no_qq)
      else utl_lms.format_message('%s', l_trigger_name_no_qq)
    end;
  l_found pls_integer;
begin
  cfg_install_ddl_pkg.trigger_ddl
  ( p_operation => 'CREATE'
  , p_trigger_name => l_trigger_name
  , p_trigger_extra => 'BEFORE INSERT OR UPDATE'
  , p_table_name => p_table_name
  , p_extra => 'FOR EACH ROW
BEGIN
  IF INSERTING
  THEN
    ORACLE_TOOLS.DATA_AUDITING_PKG.UPD
    ( P_WHO => :NEW.AUD$INS$WHO
    , P_WHEN => :NEW.AUD$INS$WHEN
    , P_WHERE => :NEW.AUD$INS$WHERE
    );
  ELSE
    ORACLE_TOOLS.DATA_AUDITING_PKG.UPD
    ( P_WHO => :NEW.AUD$UPD$WHO
    , P_WHEN => :NEW.AUD$UPD$WHEN
    , P_WHERE => :NEW.AUD$UPD$WHERE
    );
  END IF;
END;
'
  );

  -- disabled an invalid trigger
  begin
    select  1
    into    l_found
    from    user_objects o
            inner join user_triggers t
            on t.trigger_name = o.object_name
    where   o.status <> 'VALID'
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
    );
  exception
    when others
    then null;
  end;
end add_auditing_trigger;

procedure upd
( p_who out nocopy varchar2
, p_when out nocopy timestamp with time zone -- standard
, p_where out nocopy varchar2
)
is
begin
/*DBUG    
  dbug.enter('UPD');
/*DBUG*/    
  p_who := oracle_tools.data_session_username;
  p_when := oracle_tools.data_timestamp;
  p_where := oracle_tools.data_call_info;
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
end upd;

procedure upd
( p_who out nocopy varchar2
, p_when out nocopy timestamp -- datatype of an old existing colum
, p_where out nocopy varchar2
)
is
begin
  p_who := oracle_tools.data_session_username;
  p_when := systimestamp;
  p_where := oracle_tools.data_call_info;
exception
  when others
  then null; /* this call may never raise an error */
end upd;

procedure upd
( p_who out nocopy varchar2
, p_when out nocopy date -- datatype of an old existing colum
, p_where out nocopy varchar2
)
is
begin
  p_who := oracle_tools.data_session_username;
  p_when := sysdate;
  p_where := oracle_tools.data_call_info;
exception
  when others
  then null; /* this call may never raise an error */
end upd;

END;
/
