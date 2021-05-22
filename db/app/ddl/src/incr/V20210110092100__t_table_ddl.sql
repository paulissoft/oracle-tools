begin
  execute immediate q'[
create type t_table_ddl authid current_user under t_schema_ddl
( overriding member procedure migrate
  ( self in out nocopy t_table_ddl
  , p_source in t_schema_ddl
  , p_target in t_schema_ddl
  )
, overriding member procedure uninstall
  ( self in out nocopy t_table_ddl
  , p_target in t_schema_ddl
  )  
, overriding member procedure add_ddl
  ( self in out nocopy t_table_ddl
  , p_verb in varchar2
  , p_text in clob
  , p_add_sqlterminator in integer
  )
)
final]';
end;
/
