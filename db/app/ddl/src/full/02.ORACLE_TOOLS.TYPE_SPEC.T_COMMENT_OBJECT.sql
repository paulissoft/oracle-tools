CREATE TYPE "ORACLE_TOOLS"."T_COMMENT_OBJECT" authid current_user under oracle_tools.t_dependent_or_granted_object
( column_name$ varchar2(128 byte)
, constructor function t_comment_object
  ( self in out nocopy oracle_tools.t_comment_object
  , p_base_object in oracle_tools.t_named_object
  , p_object_schema in varchar2
  , p_column_name in varchar2
  )
  return self as result
-- begin of getter(s)
, overriding member function object_type return varchar2 deterministic
, overriding member function column_name return varchar2 deterministic
-- end of getter(s)
, overriding member procedure chk
  ( self in oracle_tools.t_comment_object
  , p_schema in varchar2
  )
, overriding member function dict_last_ddl_time return date
)
final;
/

