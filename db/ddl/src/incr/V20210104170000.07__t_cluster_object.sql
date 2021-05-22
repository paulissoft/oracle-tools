begin
  execute immediate q'[
create type t_cluster_object authid current_user under t_named_object
( constructor function t_cluster_object
  ( self in out nocopy t_cluster_object
  , p_object_schema in varchar2
  , p_object_name in varchar2
  )
  return self as result
, overriding member function object_type return varchar2 deterministic
)
final]';
end;
/
