begin
  execute immediate q'[
create type oracle_tools.t_dependent_or_granted_object authid current_user under oracle_tools.t_schema_object
( base_object_id$ varchar2(500 byte)
  -- begin of constructors
, constructor function t_dependent_or_granted_object
  ( self in out nocopy oracle_tools.t_dependent_or_granted_object
  , network_link$ in varchar2
  , object_schema$ in varchar2
  , base_object_id$ in varchar2
  )
  return self as result
/** Constructor without id since that must be determined by the procedure construct below. **/
, final member procedure construct
  ( self in out nocopy oracle_tools.t_dependent_or_granted_object
  , p_network_link$ in varchar2
  , p_object_schema$ in varchar2
  , p_base_object_id$ in varchar2
  )
/**
This procedure is there since Oracle Object Types do not allow to invoke a
super constructor.  Therefore this procedure can be called instead in a sub
type constructor like this:

(self as oracle_tools.t_dependent_or_granted_object).construct(p_network_link$, p_object_schema$, p_base_object_id$);

This procedure sets id.
**/
, member function base_object_id return varchar2 deterministic
, overriding member function base_object_schema return varchar2 deterministic
, overriding member function base_object_type return varchar2 deterministic
, overriding member function base_object_name return varchar2 deterministic
, overriding final member procedure base_object_schema
  ( self in out nocopy oracle_tools.t_dependent_or_granted_object
  , p_base_object_schema in varchar2
  )
, overriding member procedure chk
  ( self in oracle_tools.t_dependent_or_granted_object
  , p_schema in varchar2
  )
, overriding member function base_dict_object_type return varchar2 deterministic
)
not instantiable
not final]';
end;
/
