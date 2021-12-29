begin
  execute immediate q'[
create type oracle_tools.t_table_object authid current_user under oracle_tools.t_named_object
( tablespace_name$ varchar2(30 char)
, constructor function t_table_object
  ( self in out nocopy oracle_tools.t_table_object
  , p_object_schema in varchar2
  , p_object_name in varchar2
  )
  return self as result
, constructor function t_table_object
  ( self in out nocopy oracle_tools.t_table_object
  , p_object_schema in varchar2
  , p_object_name in varchar2
  , p_tablespace_name in varchar2
  )
  return self as result
, member function tablespace_name return varchar2 deterministic
, member procedure tablespace_name
  ( self in out nocopy oracle_tools.t_table_object
  , p_tablespace_name in varchar2
  )
, overriding member function object_type return varchar2 deterministic
, overriding member procedure chk
  ( self in oracle_tools.t_table_object
  , p_schema in varchar2
  )
)
final]';
end;
/
