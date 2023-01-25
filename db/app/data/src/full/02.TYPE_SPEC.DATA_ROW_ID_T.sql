CREATE TYPE "DATA_ROW_ID_T" AUTHID DEFINER UNDER DATA_ROW_T (
  final member procedure construct
  ( self in out nocopy data_row_id_t
  , p_table_owner in varchar2
  , p_table_name in varchar2
  , p_dml_operation in varchar2
  , p_id in integer
  )
, final member function id
  return integer
)
not instantiable
not final;
/

