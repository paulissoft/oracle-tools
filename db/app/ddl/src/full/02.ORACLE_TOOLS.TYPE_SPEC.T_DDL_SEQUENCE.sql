CREATE TYPE "ORACLE_TOOLS"."T_DDL_SEQUENCE" authid current_user under oracle_tools.t_ddl
( overriding member procedure text_to_compare
  ( self in oracle_tools.t_ddl_sequence
  , p_text_tab out nocopy oracle_tools.t_text_tab 
  )
)
final;
/

