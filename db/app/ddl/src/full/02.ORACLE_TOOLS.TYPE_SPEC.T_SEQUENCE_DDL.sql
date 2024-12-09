CREATE TYPE "ORACLE_TOOLS"."T_SEQUENCE_DDL" authid current_user under oracle_tools.t_schema_ddl
( overriding member procedure add_ddl
  ( self in out nocopy oracle_tools.t_sequence_ddl
  , p_verb in varchar2
  , p_text_tab in oracle_tools.t_text_tab
  )
)
final;
/

