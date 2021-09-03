CREATE OR REPLACE PROCEDURE "ORACLE_TOOLS"."P_GENERATE_DDL" 
( pi_source_schema in varchar2 default user
, pi_source_database_link in varchar2 default null
, pi_target_schema in varchar2 default null
, pi_target_database_link in varchar2 default null
, pi_object_type in varchar2 default null
, pi_object_names_include in natural default null
, pi_object_names in varchar2 default null
, pi_skip_repeatables in naturaln default 1
, pi_interface in varchar2 default null
, pi_transform_param_list in varchar2 default oracle_tools.pkg_ddl_util.c_transform_param_list
, po_clob out nocopy clob
)
authid current_user
as
  -- to reduce typos we use constant identifiers
  "pkg_ddl_util v4" constant varchar2(30 char) := 'pkg_ddl_util v4';
  "pkg_ddl_util v5" constant varchar2(30 char) := 'pkg_ddl_util v5';

  -- try the interfaces in this order
  -- the first one which matches pi_interface and which does not return an error, wins
  l_interface_tab constant sys.odcivarchar2list :=
    case
      when pi_interface is null
      then sys.odcivarchar2list("pkg_ddl_util v4", "pkg_ddl_util v5")
      else sys.odcivarchar2list(pi_interface)
    end;

  l_processed boolean := false;
  l_bfile bfile := null;
  l_cursor sys_refcursor := null;
  l_ddl_info_tab dbms_sql.varchar2_table;
  l_text_tab oracle_tools.t_text_tab;

  c_fetch_limit constant pls_integer := 100;

  l_buffer varchar2(32767 char) := null;

  -- dbms_application_info stuff
  l_rindex binary_integer := dbms_application_info.set_session_longops_nohint;
  l_slno   binary_integer := null;
  l_sofar  binary_integer := 0;
  l_op_name constant varchar2(10 char) := 'processed';
  l_units   constant varchar2(10 char) := 'rows';
  l_program constant varchar2(61 char) := $$PLSQL_UNIT; -- no schema because l_program is used in dbms_application_info
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT);
  dbug.print
  ( dbug."input"
  , 'pi_source_schema: %s; pi_source_database_link: %s; pi_target_schema: %s; pi_target_database_link: %s'
  , pi_source_schema
  , pi_source_database_link
  , pi_target_schema
  , pi_target_database_link
  );
  dbug.print
  ( dbug."input"
  , 'pi_object_type: %s; pi_object_names_include: %s; pi_object_names: %s; pi_skip_repeatables: %s; pi_interface: %s'
  , pi_object_type
  , pi_object_names_include
  , pi_object_names
  , pi_skip_repeatables
  , pi_interface
  );
$end

  dbms_lob.createtemporary(po_clob, true);

  <<interface_loop>>
  for i_interface_idx in l_interface_tab.first .. l_interface_tab.last
  loop
    begin
      if l_interface_tab(i_interface_idx) in ("pkg_ddl_util v4", "pkg_ddl_util v5")
      then
        if pi_target_schema is null
        then
          -- enable object valid checks
          oracle_tools.pkg_ddl_util.execute_ddl
          ( oracle_tools.t_text_tab('begin oracle_tools.pkg_ddl_util.do_chk(null, true); end;')
          , pi_source_database_link
          );

          -- full DDL because target schema (and database link) is empty
          open l_cursor for
            select  '-- ddl info: ' ||
                    u.verb() || ';' ||
                    t.obj.object_schema() || ';' ||
                    t.obj.object_type() || ';' ||
                    t.obj.object_name() || ';' ||
                    t.obj.base_object_schema() || ';' ||
                    t.obj.base_object_type() || ';' ||
                    t.obj.base_object_name() || ';' ||
                    t.obj.column_name() || ';' ||
                    t.obj.grantee() || ';' ||
                    t.obj.privilege() || ';' ||
                    t.obj.grantable() || ';' ||
                    u.ddl#() || chr(10) as ddl_info
            ,       u.text
            from    table
                    ( oracle_tools.pkg_ddl_util.display_ddl_schema
                      ( p_schema => pi_source_schema
                      , p_new_schema => null
                      , p_sort_objects_by_deps => case when l_interface_tab(i_interface_idx) = "pkg_ddl_util v4" then 0 else 1 end
                      , p_object_type => pi_object_type
                      , p_object_names => pi_object_names
                      , p_object_names_include => pi_object_names_include
                      , p_network_link => pi_source_database_link
                      , p_grantor_is_schema => 0
                      , p_transform_param_list => pi_transform_param_list
                      )
                    ) t
          ,         table(t.ddl_tab) u
          ;
        else
          -- incremental DDL because target schema is not empty
          open l_cursor for
            select  '-- ddl info: ' ||
                    u.verb() || ';' ||
                    t.obj.object_schema() || ';' ||
                    t.obj.object_type() || ';' ||
                    t.obj.object_name() || ';' ||
                    t.obj.base_object_schema() || ';' ||
                    t.obj.base_object_type() || ';' ||
                    t.obj.base_object_name() || ';' ||
                    t.obj.column_name() || ';' ||
                    t.obj.grantee() || ';' ||
                    t.obj.privilege() || ';' ||
                    t.obj.grantable() || ';' ||
                    u.ddl#() || chr(10) as ddl_info
            ,       u.text
            from    table
                    ( oracle_tools.pkg_ddl_util.display_ddl_schema_diff
                      ( p_object_type => pi_object_type
                      , p_object_names => pi_object_names
                      , p_object_names_include => pi_object_names_include
                      , p_schema_source => pi_source_schema
                      , p_schema_target => pi_target_schema
                      , p_network_link_source => pi_source_database_link
                      , p_network_link_target => pi_target_database_link
                      , p_skip_repeatables => pi_skip_repeatables
                      , p_transform_param_list => pi_transform_param_list
                      )
                    ) t
          ,         table(t.ddl_tab) u
          ;
        end if;
        dbms_lob.trim(po_clob, 0);
        oracle_tools.pkg_str_util.append_text('-- '||l_interface_tab(i_interface_idx), po_clob); -- So Perl script generate_ddl.pl knows how to read the output
        dbms_application_info.set_session_longops(rindex => l_rindex
                                                 ,slno => l_slno
                                                 ,op_name => l_op_name
                                                 ,sofar => l_sofar
                                                 ,totalwork => 0
                                                 ,target_desc => l_program
                                                 ,units => l_units);

        loop
          -- just a simple fetch due to all the temporary clobs
          fetch l_cursor into l_ddl_info_tab(1), l_text_tab;
          exit when l_cursor%notfound;

          -- the text column does not end with an empty newline so we do it here
          oracle_tools.pkg_str_util.append_text(chr(10)||l_ddl_info_tab(1), po_clob);
          oracle_tools.pkg_str_util.text2clob(pi_text_tab => l_text_tab, pio_clob => po_clob, pi_append => true);
          l_sofar := l_sofar + 1;
          dbms_application_info.set_session_longops(rindex => l_rindex
                                                   ,slno => l_slno
                                                   ,op_name => l_op_name
                                                   ,sofar => l_sofar
                                                   ,totalwork => 0
                                                   ,target_desc => l_program
                                                   ,units => l_units);
        end loop;

        close l_cursor;
        -- 100%
        dbms_application_info.set_session_longops(rindex => l_rindex
                                                 ,slno => l_slno
                                                 ,op_name => l_op_name
                                                 ,sofar => l_sofar
                                                 ,totalwork => l_sofar
                                                 ,target_desc => l_program
                                                 ,units => l_units);

      else
        raise_application_error(oracle_tools.pkg_ddl_error.c_could_not_process_interface, 'Could not process interface ' || l_interface_tab(i_interface_idx));
      end if;

      l_processed := true;
      exit interface_loop; -- success, so quit
    exception
      when others
      then
$if oracle_tools.cfg_pkg.c_debugging $then
        dbug.on_error;
$end
        -- when this is the last interface tried we must reraise otherwise we try the next
        if i_interface_idx = l_interface_tab.last
        then
          raise;
        end if;
    end;
  end loop interface_loop;

  if not(l_processed)
  then
    raise_application_error(oracle_tools.pkg_ddl_error.c_could_not_process_interface, 'Could not process interface ' || pi_interface);
  end if;

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
$end  
exception
  when others
  then
$if oracle_tools.cfg_pkg.c_debugging $then
    dbug.leave_on_error;
$end    
    raise_application_error(oracle_tools.pkg_ddl_error.c_reraise_with_backtrace, dbms_utility.format_error_backtrace, true);
end p_generate_ddl;
/

