-- GPA 20170323 #142311911 The incremental DDL generator should not show differences for sequences with just another start with value.
begin
  execute immediate q'[
create type oracle_tools.t_sequence_ddl authid current_user under oracle_tools.t_schema_ddl
( overriding member procedure add_ddl
  ( self in out nocopy oracle_tools.t_sequence_ddl
  , p_verb in varchar2
  , p_text in oracle_tools.t_text_tab
  )
)
final]';
end;
/
