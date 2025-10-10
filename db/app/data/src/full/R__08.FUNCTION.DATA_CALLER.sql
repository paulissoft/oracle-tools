CREATE OR REPLACE FUNCTION "DATA_CALLER" AUTHID DEFINER
( p_size in naturaln default utl_call_stack.dynamic_depth
)
return varchar2
is
  l_call_stack_tab oracle_tools.api_call_stack_pkg.t_call_stack_tab;
begin
  l_call_stack_tab := oracle_tools.api_call_stack_pkg.get_call_stack(-1, p_size); -- get only the last call
  if l_call_stack_tab.last is not null
  then
    return l_call_stack_tab(l_call_stack_tab.last).name;
  else
    return null;
  end if;  
end;
/

