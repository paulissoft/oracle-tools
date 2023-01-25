CREATE OR REPLACE TYPE DATA_ROW_T AUTHID CURRENT_USER AS OBJECT (
  table_owner varchar2(128 char)
, table_name varchar2(128 char)
, dml_operation varchar2(1 byte) -- (I)nsert/(U)pdate/(D)elete
, key anydata
, dml_timestamp timestamp
, final member procedure construct
  ( self in out nocopy DATA_ROW_T
  , p_table_owner in varchar2
  , p_table_name in varchar2
  , p_dml_operation in varchar2
  , p_key in anydata
  )
)
not instantiable
not final;
/
