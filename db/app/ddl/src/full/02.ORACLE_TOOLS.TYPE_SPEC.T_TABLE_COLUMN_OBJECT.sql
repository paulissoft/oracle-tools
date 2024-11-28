CREATE TYPE "ORACLE_TOOLS"."T_TABLE_COLUMN_OBJECT" authid current_user under oracle_tools.t_type_attribute_object
( /*
  From USER_TAB_COLUMNS (see also T_TYPE_ATTRIBUTE_OBJECT):

  Column                Datatype              Description
  ------                --------              -----------
  */
  nullable$             varchar2(1 char)   -- Specifies whether a column allows NULLs.
                                           -- Value is N if there is a NOT NULL constraint on the column or if the column is part of a PRIMARY KEY.
                                           -- The constraint should be in an ENABLE VALIDATE state.
, default_length$       number             -- Length of default value for the column.
                                           -- This starts at the default expression after DEFAULT plus whitespace till the next token.
, data_default$         oracle_tools.t_text_tab         -- Default value for the column
, char_col_decl_length$ number             -- Length
, char_length$          number             -- Displays the length of the column in characters. This value only applies to the following datatypes:
                                           -- CHAR
                                           -- VARCHAR2
                                           -- NCHAR
                                           -- NVARCHAR
, char_used$            varchar2(1 char)   -- B | C.
                                           -- B indicates that the column uses BYTE length semantics.
                                           -- C indicates that the column uses CHAR length semantics.
                                           -- NULL indicates the datatype is not any of the following:
                                           -- CHAR
                                           -- VARCHAR2
                                           -- NCHAR
                                           -- NVARCHAR2
, constructor function t_table_column_object
  ( self in out nocopy oracle_tools.t_table_column_object
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
  , p_nullable in varchar2
  , p_default_length in number
  , p_data_default in oracle_tools.t_text_tab
  , p_char_col_decl_length in number
  , p_char_length number
  , p_char_used in varchar2
  )
  return self as result
-- begin of getter(s)/setter(s)
, overriding member function object_type return varchar2 deterministic -- return TABLE_COLUMN
, overriding member function column_name return varchar2 deterministic
, member function nullable return varchar2 deterministic
, member function default_length return number deterministic
, member function data_default return oracle_tools.t_text_tab deterministic
, member function char_col_decl_length return number deterministic
, overriding member function char_length return number deterministic
, overriding member function char_used return varchar2 deterministic
-- end of getter(s)/setter(s)
, overriding member function last_ddl_time return date
)
final;
/

