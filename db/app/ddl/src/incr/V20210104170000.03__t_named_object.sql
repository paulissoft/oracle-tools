begin
  execute immediate q'[
create type oracle_tools.t_named_object authid current_user under oracle_tools.t_schema_object
( object_name$ varchar2(128 byte)
  -- begin of constructors
, constructor function t_named_object
  ( self in out nocopy oracle_tools.t_named_object
  , network_link$ in varchar2
  , object_schema$ in varchar2
  , object_name$ in varchar2
  )
  return self as result
/** Constructor without id since that must be determined by the procedure construct below. **/
, final member procedure construct
  ( self in out nocopy oracle_tools.t_named_object
  , p_network_link$ in varchar2
  , p_object_schema$ in varchar2
  , p_object_name$ in varchar2
  )
/**
This procedure is there since Oracle Object Types do not allow to invoke a
super constructor.  Therefore this procedure can be called instead in a sub
type constructor like this:

(self as oracle_tools.t_named_object).construct(p_network_link$, p_object_schema$, p_object_name$);

This procedure sets id.
**/
  -- other methods
, overriding final member function object_name return varchar2 deterministic
, final static procedure create_named_object
  ( p_object_type in varchar2
  , p_object_schema in varchar2
  , p_object_name in varchar2
  , p_named_object out nocopy oracle_tools.t_schema_object
  )
, final static function create_named_object
  ( p_object_type in varchar2
  , p_object_schema in varchar2
  , p_object_name in varchar2
  )
  return oracle_tools.t_named_object
, overriding member procedure chk
  ( self in oracle_tools.t_named_object
  , p_schema in varchar2
  )
)
not instantiable
not final]';
end;
/


