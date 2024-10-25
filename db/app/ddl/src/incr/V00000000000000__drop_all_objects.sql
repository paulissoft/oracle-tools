-- set serveroutput on size unlimited
declare
  l_type_tab sys.odcivarchar2list :=
    sys.odcivarchar2list
    ( -- collections
      'T_ARGUMENT_OBJECT_TAB'
    , 'T_SCHEMA_DDL_TAB'
    , 'T_SCHEMA_OBJECT_TAB'
    , 'T_OBJECT_INFO_TAB'
    , 'T_SORT_OBJECTS_BY_DEPS_TAB'
    , 'T_DDL_TAB'
      -- object types
    , 'T_ARGUMENT_OBJECT'
    , 'T_SCHEMA_DDL'
    , 'T_SCHEMA_OBJECT'
    , 'T_DDL'
    , 'T_OBJECT_INFO_REC'
    , 'T_SORT_OBJECTS_BY_DEPS_REC'
    , 'T_SCHEMA_OBJECT_FILTER'
      -- must be last
    , 'T_TEXT_TAB' 
    );
  l_count pls_integer;
  l_nr_objects_dropped pls_integer;
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
    
    begin
      execute immediate 'drop table all_schema_objects purge';
      l_nr_objects_dropped := l_nr_objects_dropped + 1;
    exception
      when others
      then null;
    end;

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
