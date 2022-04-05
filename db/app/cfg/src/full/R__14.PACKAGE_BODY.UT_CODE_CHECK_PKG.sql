CREATE OR REPLACE PACKAGE BODY "UT_CODE_CHECK_PKG" IS

subtype t_var is varchar2(4 char);

procedure ut_assign(p_str out nocopy varchar2)
is
begin
  p_str := "abcd";
end;

procedure ut_reference(p_str in varchar2)
is
begin
  if p_str is null
  then
    null;
  end if;
end;

procedure ut_var_not_used
is
  l_var t_var;
begin
  null;
end ut_var_not_used;

procedure ut_var_assign_declaration
is
  l_var t_var := "abcd";
begin
  null;
end ut_var_assign_declaration;

procedure ut_var_assign_direct
is
  l_var t_var;
begin
  l_var := "abcd";
end ut_var_assign_direct;

procedure ut_var_assign_indirect
is
  l_var t_var;
begin
  ut_assign(l_var);
end ut_var_assign_indirect;

procedure ut_var_assign_after_reference
is
  l_var t_var;
begin
  if l_var is null
  then
    l_var := "abcd";
  end if;
end ut_var_assign_after_reference;

-- Output parameters should be assigned a value
-- Unused procedure and function parameters
procedure ut_output_parameters_not_set(p_i in varchar2, p_io in out varchar2, p_o out varchar2)
is
begin
  null;
end;

-- Functions should not have output parameters
-- Unused procedure and function parameters
function ut_function_output_parameters(p_i in varchar2, p_io in out varchar2, p_o out varchar2)
return varchar2
is
begin
  return null;
end;

-- Identifiers shadowing another identifier
procedure ut_variables_out_of_scope
is
  i_idx integer;
begin
  for i_idx in 1..2
  loop
    null;
  end loop;

  declare
    i_idx integer;
  begin
    null;
  end;
end;

end ut_code_check_pkg;
/

