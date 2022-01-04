CREATE TYPE "ORACLE_TOOLS"."T_TYPE_METHOD_OBJECT" authid current_user under oracle_tools.t_member_object
( /*
  From USER_TYPE_METHODS:

  Used for non-inherited methods only.

  USER_TYPE_METHODS.METHOD_NAME is mapped to MEMBER_NAME.
  USER_TYPE_METHODS.METHOD_NO is mapped to MEMBER#.

  Column              Datatype                 Description
  ------              --------                 -----------
  METHOD_NAME         VARCHAR2(30)          -- Name of the method
  METHOD_NO           NUMBER                -- Method number for distinguishing overloaded methods (not to be used as ID number)

  */
  method_type$        varchar2(6 char)      -- Type of the method:
                                            -- MAP
                                            -- ORDER
                                            -- PUBLIC
, parameters$         integer               -- Number of parameters to the method
, results$            integer               -- Number of results returned by the method
, final$              varchar2(3 char)      -- Indicates whether the method is final (YES) or not (NO)
, instantiable$       varchar2(3 char)      -- Indicates whether the method is instantiable (YES) or not (NO)
, overriding$         varchar2(3 char)      -- Indicates whether the method is overriding a supertype method (YES) or not (NO)
, arguments           oracle_tools.t_argument_object_tab -- List of arguments, if any.

, constructor function t_type_method_object
  ( self in out nocopy oracle_tools.t_type_method_object
  , p_base_object in oracle_tools.t_named_object -- the type specification
  , p_member# in integer -- the METHOD_NO
  , p_member_name in varchar2 -- the METHOD_NAME
  , p_method_type in varchar2
  , p_parameters in integer
  , p_results in integer
  , p_final in varchar2
  , p_instantiable in varchar2
  , p_overriding in varchar2
  , p_arguments in oracle_tools.t_argument_object_tab default null
  )
  return self as result
-- begin of getter(s)/setter(s)
, overriding member function object_type return varchar2 deterministic -- return TYPE_METHOD
, member function method_type return varchar2 deterministic
, member function parameters return integer deterministic
, member function results return integer deterministic
, member function final return varchar2 deterministic
, member function instantiable return varchar2 deterministic
, member function overriding return varchar2 deterministic
-- end of getter(s)/setter(s)
, member function static_or_member return varchar2 deterministic
, overriding final map member function signature return varchar2 deterministic
, overriding member procedure chk( self in oracle_tools.t_type_method_object, p_schema in varchar2 )
)
not final;
/

