CREATE TYPE "ORACLE_TOOLS"."T_TYPE_ATTRIBUTE_OBJECT" authid current_user under oracle_tools.t_member_object
( /*
  From USER_TYPE_ATTRS:

  Column              Datatype              Description
  ------              --------              -----------
  */
  data_type_name$     varchar2(128 char) -- Datatype of the column/attribute
, data_type_mod$      varchar2(7 char)   -- Datatype modifier of the column/attribute
, data_type_owner$    varchar2(128 char) -- Owner of the datatype of the column
, data_length$        number             -- Length of the column (in bytes)
, data_precision$     number             -- Decimal precision for NUMBER datatype; binary precision for FLOAT datatype, null for all other datatypes
, data_scale$         number             -- Digits to right of decimal point in a number
, character_set_name$ varchar2(44 char)  -- Name of the character set: CHAR_CS or NCHAR_CS

, constructor function t_type_attribute_object
  ( self in out nocopy oracle_tools.t_type_attribute_object
  , p_base_object in oracle_tools.t_named_object
  , p_member# in integer
  , p_member_name in varchar2
  , p_data_type_name in varchar2
  , p_data_type_mod in varchar2
  , p_data_type_owner in varchar2
  , p_data_length in number
  , p_data_precision in number
  , p_data_scale in number
  , p_character_set_name in varchar2
  )
  return self as result
-- begin of getter(s)/setter(s)
, overriding member function object_type return varchar2 deterministic -- return TYPE_ATTRIBUTE
, member function data_type_name return varchar2 deterministic
, member function data_type_mod return varchar2 deterministic
, member function data_type_owner return varchar2 deterministic
, member function data_length return number deterministic
, member function data_precision return number deterministic
, member function data_scale return number deterministic
, member function character_set_name return varchar2 deterministic
, member function char_length return number deterministic
, member function char_used return varchar2 deterministic
-- end of getter(s)/setter(s)
, final member function data_type return varchar2 deterministic
, overriding member function last_ddl_time return date
)
not final;
/

