begin
  execute immediate q'[
create type t_ddl_sequence authid current_user under t_ddl
( overriding member procedure text_to_compare
  ( self in t_ddl_sequence
  , p_text_tab out nocopy oracle_tools.t_text_tab 
  )
)
final]';
end;
/
