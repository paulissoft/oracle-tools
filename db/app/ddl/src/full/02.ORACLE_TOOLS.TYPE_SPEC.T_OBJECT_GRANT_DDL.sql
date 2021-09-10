CREATE TYPE "ORACLE_TOOLS"."T_OBJECT_GRANT_DDL" authid current_user under oracle_tools.t_schema_ddl
( overriding member procedure uninstall
  ( self in out nocopy oracle_tools.t_object_grant_ddl
  , p_target in oracle_tools.t_schema_ddl
  )
, overriding member procedure add_ddl
  ( self in out nocopy oracle_tools.t_object_grant_ddl
  , p_verb in varchar2
  , p_text in clob
  , p_add_sqlterminator in integer
  )
, overriding
  member procedure execute_ddl
  ( self in oracle_tools.t_object_grant_ddl
  )
)
final;
/

