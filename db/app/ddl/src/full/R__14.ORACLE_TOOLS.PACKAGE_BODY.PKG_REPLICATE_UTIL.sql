CREATE OR REPLACE PACKAGE BODY "ORACLE_TOOLS"."PKG_REPLICATE_UTIL" IS

procedure replicate_table
( p_table_name in varchar2 -- the table name
, p_table_owner in varchar2 -- the table owner
, p_column_list in varchar2 -- the columns separated by a comma
, p_create_or_replace in varchar2 default null -- or CREATE/REPLACE
, p_db_link in varchar2 default null -- database link: the table may reside on a separate database
  -- parameters below only relevant when database link is not null
, p_where_clause in varchar2 default null -- the where clause (without WHERE)
, p_read_only in boolean default true -- is the target read only?
)
is
  l_table_name all_tables.table_name%type;
  l_table_owner all_tables.owner%type;
  l_view_name all_views.view_name%type;
  l_synonym_name all_synonyms.synonym_name%type;
  l_column_list varchar2(4000 byte) := null;
  l_column_tab dbms_sql.varchar2a;
  l_column_name all_tab_columns.column_name%type;
  l_found pls_integer;
  l_table_alias constant varchar2(3 byte) := 'TAB';

  procedure check_existence(p_count_expected in pls_integer)
  is
    l_count_actual pls_integer;
  begin
    select  count(*)
    into    l_count_actual
    from    user_objects o
    where   ( o.object_type = 'SYNONYM' and o.object_name = l_synonym_name )
    or      ( o.object_type = 'VIEW' and o.object_name = l_view_name )
    ;
    if l_count_actual = p_count_expected
    then
      null;
    else
      raise_application_error
      ( -20000
      , utl_lms.format_message
        ( 'Checking existence of synonym "%s" and view "%s". Expected count: %s; actual count: %s'
        , l_synonym_name
        , l_view_name
        , to_char(p_count_expected)
        , to_char(l_count_actual)
        )
      );
    end if;
  end;  

  procedure execute_immediate(p_statement in varchar2)
  is
  begin
    execute immediate p_statement;
  exception
    when others
    then
      raise_application_error(-20000, 'Statement failed: ' || p_statement, true);
  end;  
begin
  case
    when p_db_link is null
    then
      -- 'abc' => 'ABC' and '"abc"' => 'abc'
      l_table_owner := trim('"' from oracle_tools.data_api_pkg.dbms_assert$enquote_name(p_table_owner, 'table owner'));
      l_table_name := trim('"' from oracle_tools.data_api_pkg.dbms_assert$enquote_name(p_table_name, 'table name'));
      l_synonym_name := l_table_name;
      l_view_name := l_table_name || '_V';

      -- check column list
      if p_column_list = '*'
      then
        l_column_list := l_table_alias || '.' || p_column_list;
      else
        oracle_tools.pkg_str_util.split
        ( p_str => p_column_list
        , p_delimiter => ','
        , p_str_tab => l_column_tab
        );

        -- should have count >= 1
        for i_idx in l_column_tab.first .. l_column_tab.last
        loop
          /* '
abc
' => 'ABC' and '"abc"' => 'abc'
          */
          l_column_name := trim(trim(chr(13) from trim(chr(10) from l_column_tab(i_idx))));
          l_column_name := trim('"' from oracle_tools.data_api_pkg.dbms_assert$enquote_name(l_column_name, 'column name'));

          begin
            select  1
            into    l_found
            from    all_tab_columns c
            where   c.owner = l_table_owner
            and     c.table_name = l_table_name
            and     c.column_name = l_column_name;
          exception
            when no_data_found
            then
              raise_application_error
              ( -20000
              , utl_lms.format_message
                ( 'Column "%s"."%s"."%s" not found.'
                , l_table_owner
                , l_table_name
                , l_column_name
                )
              , true
              );
          end;

          l_column_tab(i_idx) := l_table_alias || '.' || '"' || l_column_name || '"';
        end loop;

        l_column_list := oracle_tools.pkg_str_util.join(l_column_tab);
      end if;

      case upper(p_create_or_replace)
        when 'CREATE'
        then
          check_existence(0); -- BOTH SHOULD NOT EXIST
          -- check privileges first before creating the synonym (so we can redo the action)
          execute_immediate('CREATE OR REPLACE VIEW "' || l_view_name || '" AS SELECT ' || l_column_list || ' FROM "' || l_table_owner || '"."' || l_table_name || '"' || ' ' || l_table_alias);
        when 'REPLACE'
        then check_existence(2); -- BOTH MUST EXIST
        else null;
      end case;
      
      execute_immediate('CREATE OR REPLACE SYNONYM "' || l_synonym_name || '" FOR "' || l_table_owner || '"."' || l_table_name || '"');
  end case;

  -- always create a view based on the synonym
  execute_immediate('CREATE OR REPLACE VIEW "' || l_view_name || '" AS SELECT rowid as row_id,' || l_column_list || ' FROM "' || l_synonym_name || '"' || ' ' || l_table_alias);
end replicate_table;

end pkg_replicate_util;
/

