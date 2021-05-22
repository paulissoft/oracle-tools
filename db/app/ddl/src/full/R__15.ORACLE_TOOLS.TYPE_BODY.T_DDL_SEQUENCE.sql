CREATE OR REPLACE TYPE BODY "ORACLE_TOOLS"."T_DDL_SEQUENCE" AS

overriding member procedure text_to_compare( self in t_ddl_sequence, p_text_tab out nocopy oracle_tools.t_text_tab )
is
  l_find_regexp constant varchar2(100) := '( START WITH )(\d+)';
  l_repl_regexp constant varchar2(100) := '\1 1';
begin
  -- a sequence should have just 1 entry
  if cardinality(self.text) = 1
  then
    null;
  else
    raise program_error;
  end if;
  p_text_tab := oracle_tools.t_text_tab(regexp_replace(self.text(1), l_find_regexp, l_repl_regexp));
end text_to_compare;

end;
/

