CREATE TYPE "ORACLE_TOOLS"."T_SEQUENCE_DDL" authid current_user under t_schema_ddl
( overriding member procedure add_ddl
  ( self in out nocopy t_sequence_ddl
  , p_verb in varchar2
  , p_text in t_text_tab
  )
)
final;
/

