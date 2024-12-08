-- set serveroutput on size unlimited
declare
  l_type_tab sys.odcivarchar2list :=
    sys.odcivarchar2list
    ( -- collections
      'T_ARGUMENT_OBJECT_TAB'
    , 'T_SCHEMA_DDL_TAB'
    , 'T_SCHEMA_OBJECT_TAB'
    , 'T_OBJECT_INFO_TAB'
    , 'T_DDL_TAB'
    , 'T_DISPLAY_DDL_SQL_TAB'
      -- object types
    , 'T_ARGUMENT_OBJECT'
    , 'T_SCHEMA_DDL'
    , 'T_SCHEMA_OBJECT'
    , 'T_DDL'
    , 'T_OBJECT_INFO_REC'
    , 'T_SCHEMA_OBJECT_FILTER'
    , 'T_SCHEMA_DDL_PARAMS'
    , 'T_SCHEMA_OBJECT_PARAMS'
    , 'T_OBJECT_JSON'
    , 'T_DISPLAY_DDL_SQL'
      -- must be last
    , 'T_TEXT_TAB' 
    );
  l_table_tab sys.odcivarchar2list :=
    sys.odcivarchar2list
    ( 'SCHEMA_OBJECT_FILTERS'
    , 'SCHEMA_OBJECTS'
    , 'SCHEMA_OBJECT_FILTER_RESULTS'
    , 'GENERATE_DDL_CONFIGURATIONS'
    , 'GENERATE_DDL_PARAMETERS' -- obsolete
    , 'GENERATE_DDL_SESSIONS'
    , 'GENERATE_DDL_SESSION_SCHEMA_OBJECTS'
    , 'GENERATE_DDL_SESSION_SCHEMA_DDLS' -- obsolete
    , 'GENERATED_DDLS'
    , 'GENERATED_DDL_STATEMENTS'
    , 'GENERATE_DDL_SESSION_SCHEMA_DDL_CHUNKS' -- obsolete
    , 'GENERATED_DDL_STATEMENT_CHUNKS'
    , 'GENERATE_DDL_SESSION_SCHEMA_DDL_BATCHES' -- obsolete
    , 'GENERATE_DDL_SESSION_BATCHES'
    );
  l_view_tab sys.odcivarchar2list :=
    sys.odcivarchar2list
    ( 'V_ALL_SCHEMA_OBJECTS' -- obsolete
    , 'V_DEPENDENT_OR_GRANTED_OBJECT_TYPES'
    , 'V_DISPLAY_DDL_SCHEMA'
    , 'V_MY_COMMENTS_DICT' -- obsolete
    , 'V_MY_CONSTRAINTS_DICT' -- obsolete
    , 'V_MY_GENERATE_DDL_SESSIONS'
    , 'V_MY_GENERATE_DDL_SESSION_SCHEMA_DDL_BATCHES' -- obsolete
    , 'V_MY_GENERATE_DDL_SESSION_BATCHES'
    , 'V_MY_GENERATE_DDL_SESSION_BATCHES_NO_SCHEMA_EXPORT' -- obsolete
    , 'V_MY_GENERATE_DDL_SESSION_BATCH_PARAMETERS'
    , 'V_MY_NAMED_SCHEMA_OBJECTS'
    , 'V_MY_OBJECT_GRANTS_DICT' -- obsolete
    , 'V_MY_SCHEMA_OBJECTS'
    , 'V_MY_SCHEMA_OBJECTS_NO_DDL_YET'
    , 'V_MY_SCHEMA_DDLS'
    , 'V_MY_SCHEMA_DDL_INFO'
    , 'V_MY_SCHEMA_OBJECT_FILTER'
    , 'V_MY_SCHEMA_OBJECT_FILTER_RESULTS'
    , 'V_MY_SCHEMA_OBJECT_INFO'
    , 'V_SCHEMA_OBJECTS'
    );
  l_sequence_tab sys.odcivarchar2list :=
    sys.odcivarchar2list
    ( 'SCHEMA_OBJECT_FILTERS$SEQ'
    );
  l_function_tab sys.odcivarchar2list :=
    sys.odcivarchar2list
    ( 'MATCHES_SCHEMA_OBJECT_FNC'
    );
  l_count pls_integer;
  l_nr_objects_dropped pls_integer;

  -- ORA-00942: table or view does not exist
  e_table_or_view_does_not_exist exception;
  pragma exception_init(e_table_or_view_does_not_exist, -942);
begin
  select  count(*)
  into    l_count
  from    "schema_version_tools_ddl";

  if l_count <> 0
  then
    raise_application_error(-20000, 'Please clean up Flyway cache by: delete from "schema_version_tools_ddl"');
  end if;

  <<while_objects_dropped_loop>>
  loop
    l_nr_objects_dropped := 0;
    
    for i_idx in reverse l_table_tab.first .. l_table_tab.last -- in reverse order to mimimize cascade constraints
    loop
      begin
        execute immediate 'drop table ' || l_table_tab(i_idx) || ' cascade constraints purge';
        l_nr_objects_dropped := l_nr_objects_dropped + 1;
      exception
        when e_table_or_view_does_not_exist
        then null;
        when others
        then raise; -- null;
      end;
    end loop;
    
    for i_idx in l_view_tab.first .. l_view_tab.last
    loop
      begin
        execute immediate 'drop view ' || l_view_tab(i_idx);
        l_nr_objects_dropped := l_nr_objects_dropped + 1;
      exception
        when others
        then null;
      end;
    end loop;
    
    for i_idx in l_sequence_tab.first .. l_sequence_tab.last
    loop
      begin
        execute immediate 'drop sequence ' || l_sequence_tab(i_idx);
        l_nr_objects_dropped := l_nr_objects_dropped + 1;
      exception
        when others
        then null;
      end;
    end loop;

    for i_idx in l_function_tab.first .. l_function_tab.last
    loop
      begin
        execute immediate 'drop function ' || l_function_tab(i_idx);
        l_nr_objects_dropped := l_nr_objects_dropped + 1;
      exception
        when others
        then null;
      end;
    end loop;

    for i_idx in l_type_tab.first .. l_type_tab.last
    loop
      for r in
      ( select  'drop type ' || type_name || ' force' as cmd
        from    user_types
        connect by
                supertype_name = prior type_name
        start with
                type_name = l_type_tab(i_idx)
        order by
                level desc
      )
      loop
        begin
          -- dbms_output.put_line(r.cmd);
          execute immediate r.cmd;
          l_nr_objects_dropped := l_nr_objects_dropped + 1;
        exception
          when others
          then
            -- dbms_output.put_line(sqlerrm);
            null;
        end;
      end loop;
    end loop;
    exit when l_nr_objects_dropped = 0;
  end loop while_objects_dropped_loop;
end;
/
