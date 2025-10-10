CREATE OR REPLACE FUNCTION "DATA_CALLER" 
return varchar2
is
  l_depth constant positiven := utl_call_stack.dynamic_depth;
  l_first_call_info varchar2(450 char) := null;
  l_last_call_info varchar2(450 char) := null;
  
  l_unit_qualified_name utl_call_stack.unit_qualified_name;
  l_owner all_objects.owner%type;
  l_object_type all_objects.object_type%type;
  l_object_name all_objects.object_name%type;
  
  l_last_unit_qualified_name utl_call_stack.unit_qualified_name;
  l_last_owner all_objects.owner%type := null;
  l_last_object_type all_objects.object_type%type := null;
  
$if oracle_tools.cfg_pkg.c_apex_installed $then
  l_app_id constant pls_integer := apex_application.g_flow_id;
  l_app_page_id constant pls_integer := apex_application.g_flow_step_id;
  l_apex_call_info constant varchar2(100 char) :=
    case
      when l_app_id is null
      then null
      when l_app_page_id is null
      then null
      else utl_lms.format_message('APEX app %d page %05d', l_app_id, l_app_page_id)
    end;
$end
begin
  for i_idx in 2..l_depth -- skip first index, i.e. this routine
  loop
    l_unit_qualified_name := utl_call_stack.subprogram(i_idx);
    l_owner := utl_call_stack.owner(i_idx);
    l_object_type := utl_call_stack.unit_type(i_idx);
    l_object_name := l_unit_qualified_name(1);

    -- skip calls from ORACLE_TOOLS.DATA_AUDITING_PKG and generated auditing triggers
    case
      -- invoked from package ORACLE_TOOLS.DATA_AUDITING_PKG
      when l_owner = $$PLSQL_UNIT_OWNER and
           substr(l_object_type, 1, 7) = 'PACKAGE' and
           l_object_name = 'DATA_AUDITING_PKG'
      then continue;

      -- invoked from generated auditing trigger
      when l_object_type = 'TRIGGER' and
           substr(l_object_name, 1, 4) = 'AUD$'
      then continue;

      when l_first_call_info is null
      then
        l_first_call_info :=
          utl_lms.format_message
          ( '%s %s%s%s'
          , l_object_type
          , l_owner
          , case when l_owner is not null then '.' end
          , utl_call_stack.concatenate_subprogram(l_unit_qualified_name)
          );
          
      when l_object_type = 'ANONYMOUS BLOCK'
      then exit;

      else
        l_last_unit_qualified_name := l_unit_qualified_name;
        l_last_owner := l_owner;
        l_last_object_type := l_object_type;
    end case;
  end loop;

  if l_last_object_type is not null -- for an anonymous block the owner is null
  then
    l_last_call_info :=
      utl_lms.format_message
      ( '%s %s%s%s'
      , l_last_object_type
      , l_last_owner
      , case when l_last_owner is not null then '.' end
      , utl_call_stack.concatenate_subprogram(l_last_unit_qualified_name)
      );
  end if;

  return
$if oracle_tools.cfg_pkg.c_apex_installed $then
    case
      when l_apex_call_info is not null
      then l_apex_call_info ||
           case
             when l_first_call_info is not null
             then ' | '
           end
    end ||
$end
    case
      when l_first_call_info is not null
      then l_first_call_info ||
           case
             when l_last_call_info is not null
             then ' -->> ' || l_last_call_info
           end
    end;   
end;
/

