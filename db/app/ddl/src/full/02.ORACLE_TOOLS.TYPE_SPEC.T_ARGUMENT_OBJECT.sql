CREATE TYPE "ORACLE_TOOLS"."T_ARGUMENT_OBJECT" authid current_user is object
( /*
  From USER_ARGUMENTS:

  Please note that these arguments are only used in type methods. Only DATA_LEVEL 0 arguments are stored here.

  USER_ARGUMENTS.POSITION is mapped to ARGUMENT#. 

  Column              Datatype              Description
  ------              --------              -----------
  */
  argument#$          integer            -- This column holds the position of this item in the argument list, or zero for a function return value.
, argument_name$      varchar2(30)	 -- If the argument is a scalar type, then the argument name is the name of the argument.
                                         -- A null argument name is used to denote a function return.
                                         -- ARGUMENT_NAME can refer to any of the following:
                                         -- a) Return type, if ARGUMENT_NAME is null
                                         -- b) The argument that appears in the argument list if ARGUMENT_NAME is not null

, data_type_name$     varchar2(30 char)  -- Datatype of the argument
, in_out$             varchar2(9 char)   -- Direction of the argument: IN, OUT or IN/OUT
, type_owner$         varchar2(30 char)  -- Owner of the type of the argument
, type_name$          varchar2(30 char)  -- Name of the type of the argument.

, constructor function t_argument_object
  ( self in out nocopy t_argument_object
  , p_argument# in integer
  , p_argument_name in varchar2
  , p_data_type_name in varchar2
  , p_in_out in varchar2
  , p_type_owner in varchar2
  , p_type_name in varchar2
  )
  return self as result
-- begin of getter(s)/setter(s)
, member function argument# return integer deterministic
, member function argument_name return varchar2 deterministic
, member function data_type_name return varchar2 deterministic
, member function in_out return varchar2 deterministic
, member function type_owner return varchar2 deterministic
, member function type_name return varchar2 deterministic
-- end of getter(s)/setter(s)
  -- when data_type_name() is REF or OBJECT, it returns type_owner().type_name(), else data_type_name()
, member function data_type return varchar2 deterministic -- when data_type_name() is REF or OBJECT, it returns type_owner().type_name(), else data_type_name()
)
final;
/

