CREATE TYPE "ORACLE_TOOLS"."T_TABLE_DDL" authid current_user under oracle_tools.t_schema_ddl
( overriding member procedure migrate
  ( self in out nocopy oracle_tools.t_table_ddl
  , p_source in oracle_tools.t_schema_ddl
  , p_target in oracle_tools.t_schema_ddl
  )
, overriding member procedure uninstall
  ( self in out nocopy oracle_tools.t_table_ddl
  , p_target in oracle_tools.t_schema_ddl
  )
, overriding member procedure add_ddl
  ( self in out nocopy oracle_tools.t_table_ddl
  , p_verb in varchar2
  , p_text in clob
  , p_add_sqlterminator in integer
  )
)
final;
/

