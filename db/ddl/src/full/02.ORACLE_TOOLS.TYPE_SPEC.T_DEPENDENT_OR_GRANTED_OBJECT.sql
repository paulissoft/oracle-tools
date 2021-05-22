CREATE TYPE "ORACLE_TOOLS"."T_DEPENDENT_OR_GRANTED_OBJECT" authid current_user under t_schema_object
( base_object$ t_named_object
, overriding member function base_object_schema return varchar2 deterministic
, overriding member function base_object_type return varchar2 deterministic
, overriding member function base_object_name return varchar2 deterministic
, overriding final member procedure base_object_schema
  ( self in out nocopy t_dependent_or_granted_object
  , p_base_object_schema in varchar2
  )
, overriding member procedure chk
  ( self in t_dependent_or_granted_object
  , p_schema in varchar2
  )  
, overriding member function base_dict_object_type return varchar2 deterministic
)
not instantiable
not final;
/

