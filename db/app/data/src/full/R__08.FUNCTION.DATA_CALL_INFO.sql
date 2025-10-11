CREATE OR REPLACE FUNCTION "DATA_CALL_INFO" 
return varchar2
is
  subtype t_string is varchar2(1000 char);
  
  l_depth constant positiven := utl_call_stack.dynamic_depth;
  
$if oracle_tools.cfg_pkg.c_apex_installed $then
  l_app_id constant pls_integer := apex_application.g_flow_id;
  l_app_page_id constant pls_integer := apex_application.g_flow_step_id;
  l_apex_call_info constant t_string :=
    case
      when l_app_id is null
      then null
      when l_app_page_id is null
      then null
      else utl_lms.format_message('APEX app %d page %d', l_app_id, l_app_page_id)
    end;
$else    
  l_apex_call_info constant t_string := null;
$end

  l_first_call_info t_string := null; -- root call calling this function (leaving out anonymous blocks)
  l_last_call_info t_string := null; -- last call before calling this function
  
  l_unit_qualified_name utl_call_stack.unit_qualified_name;
  l_owner all_objects.owner%type;
  l_object_type all_objects.object_type%type;
  l_object_name all_objects.object_name%type;
  l_line_no pls_integer;  
  
  l_first_unit_qualified_name utl_call_stack.unit_qualified_name;
  l_first_owner all_objects.owner%type := null;
  l_first_object_type all_objects.object_type%type := null;
  l_first_object_name all_objects.object_name%type;
  l_first_line_no pls_integer;  
  
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
     
     return l_string;
  exception
    when value_error
    then
      return l_string; -- till so far
  end construct_call_info;

  function construct_call_info
  ( p_apex_call_info in t_string
  , p_first_call_info in t_string
  , p_last_call_info in t_string
  )
  return t_string
  is
    l_string t_string := p_last_call_info; -- the most important one
  begin
    if p_first_call_info <> p_last_call_info -- implies both not null
    then
      l_string := p_first_call_info || ' -->> ' || l_string;
    end if;

    if p_apex_call_info is not null
    then
      l_string := p_apex_call_info || ' | ' || l_string;
    end if;
    
    return l_string;
  exception
    when value_error
    then
      return l_string; -- till so far
  end construct_call_info;
begin
  for i_idx in 2..l_depth -- skip first index, i.e. this routine
  loop
    l_unit_qualified_name := utl_call_stack.subprogram(i_idx);
    l_owner := utl_call_stack.owner(i_idx);
    l_object_type := utl_call_stack.unit_type(i_idx);
    l_object_name := l_unit_qualified_name(1);
    l_line_no := utl_call_stack.unit_line(i_idx);
    
    -- skip calls from:
    -- 1) ORACLE_TOOLS.DATA_AUDITING_PKG subprogram UPD
    -- 2) generated auditing triggers
    case
      -- invoked from package ORACLE_TOOLS.DATA_AUDITING_PKG subprogram UPD
      when l_owner = $$PLSQL_UNIT_OWNER and
           substr(l_object_type, 1, 7) = 'PACKAGE' and
           l_object_name = 'DATA_AUDITING_PKG' and
           l_unit_qualified_name.count = 2 and
           l_unit_qualified_name(2) = 'UPD'
      then continue;

      -- invoked from generated auditing trigger
      when l_object_type = 'TRIGGER' and
           substr(l_object_name, 1, 4) = 'AUD$'
      then continue;

      when l_last_call_info is null
      then
        l_last_call_info :=
          construct_call_info
          ( l_unit_qualified_name
          , l_owner
          , l_object_type
          , l_object_name
          , l_line_no
          );
          
      when l_object_type = 'ANONYMOUS BLOCK'
      then exit;

      else
        -- save for later
        l_first_unit_qualified_name := l_unit_qualified_name;
        l_first_owner := l_owner;
        l_first_object_type := l_object_type;
        l_first_object_name := l_object_name;
        l_first_line_no := l_line_no;
    end case;
  end loop;

  if l_first_object_type is not null -- for an anonymous block the owner is null
  then
    l_first_call_info :=
      construct_call_info
      ( l_first_unit_qualified_name
      , l_first_owner
      , l_first_object_type
      , l_first_object_name
      , l_first_line_no
      );
  end if;

  return construct_call_info
         ( l_apex_call_info
         , l_first_call_info
         , l_last_call_info
         );
exception
  when others
  then return null;
end;
/

