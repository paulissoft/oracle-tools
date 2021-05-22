begin
  execute immediate q'[
create type t_comment_ddl authid current_user under t_schema_ddl
( overriding member procedure uninstall
  ( self in out nocopy t_comment_ddl
  , p_target in t_schema_ddl
  )
)
final]';
end;
/
