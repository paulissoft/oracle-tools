CREATE TYPE "ORACLE_TOOLS"."T_OBJECT_GRANT_DDL" authid current_user under t_schema_ddl
( overriding member procedure uninstall
  ( self in out nocopy t_object_grant_ddl
  , p_target in t_schema_ddl
  )
, overriding member procedure add_ddl
  ( self in out nocopy t_object_grant_ddl
  , p_verb in varchar2
  , p_text in clob
  , p_add_sqlterminator in integer
  )
, overriding
  member procedure execute_ddl
  ( self in t_object_grant_ddl
  )
)
final;
/

