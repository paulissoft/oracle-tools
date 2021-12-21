begin
  execute immediate q'[
create type oracle_tools.t_schema_ddl authid current_user as object
( obj oracle_tools.t_schema_object
, ddl_tab oracle_tools.t_ddl_tab
, static procedure create_schema_ddl
  ( p_obj in oracle_tools.t_schema_object
  , p_ddl_tab in oracle_tools.t_ddl_tab
  , p_schema_ddl out nocopy oracle_tools.t_schema_ddl
  )
, static function create_schema_ddl
  ( p_obj in oracle_tools.t_schema_object
  , p_ddl_tab in oracle_tools.t_ddl_tab
  )
  return oracle_tools.t_schema_ddl
, member procedure print
  ( self in oracle_tools.t_schema_ddl
  )
, member procedure add_ddl
  ( self in out nocopy oracle_tools.t_schema_ddl
  , p_verb in varchar2
  , p_text in oracle_tools.t_text_tab
  )
, member procedure add_ddl
  ( self in out nocopy oracle_tools.t_schema_ddl
  , p_verb in varchar2
  , p_text in clob
  , p_add_sqlterminator in integer default 0
  )
, order member function match( p_schema_ddl in oracle_tools.t_schema_ddl ) return integer deterministic
, final member procedure install
  ( self in out nocopy oracle_tools.t_schema_ddl
  , p_source in oracle_tools.t_schema_ddl
  )
, static procedure migrate
  ( p_source in oracle_tools.t_schema_ddl
  , p_target in oracle_tools.t_schema_ddl
  , p_schema_ddl in out nocopy oracle_tools.t_schema_ddl
  )
, member procedure migrate
  ( self in out nocopy oracle_tools.t_schema_ddl
  , p_source in oracle_tools.t_schema_ddl
  , p_target in oracle_tools.t_schema_ddl
  )
, member procedure uninstall
  ( self in out nocopy oracle_tools.t_schema_ddl
  , p_target in oracle_tools.t_schema_ddl
  )
-- no getters because the (possibly large) attributes will be copied
, member procedure chk
  ( self in oracle_tools.t_schema_ddl
  , p_schema in varchar2
  )
, static procedure execute_ddl
  ( p_id in varchar2
  , p_text in varchar2
  )
, member procedure execute_ddl
  ( self in oracle_tools.t_schema_ddl
  )
, static procedure execute_ddl(p_schema_ddl in oracle_tools.t_schema_ddl)
)
not final]';
end;
/
