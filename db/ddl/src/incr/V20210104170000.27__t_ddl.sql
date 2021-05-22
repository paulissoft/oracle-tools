begin
  execute immediate q'[
create type t_ddl authid current_user as object
( ddl#$ integer
, verb$ varchar2(4000 char)
, text t_text_tab
, constructor function t_ddl
  ( self in out nocopy t_ddl
  , p_ddl# in integer
  , p_verb in varchar2
  , p_text in t_text_tab
  )
  return self as result
-- no getter for text because the (possibly large) attribute text will be copied
-- begin of getter(s)
, member function ddl# return integer deterministic
, member function verb return varchar2 deterministic
-- end of getter(s)
, member procedure print
  ( self in t_ddl
  )
, order member function match( p_ddl in t_ddl ) return integer deterministic
, member function compare( p_ddl in t_ddl )
  return integer
  deterministic
, member procedure text_to_compare( self in t_ddl, p_text_tab out nocopy oracle_tools.t_text_tab )
)
not final]';
end;
/
