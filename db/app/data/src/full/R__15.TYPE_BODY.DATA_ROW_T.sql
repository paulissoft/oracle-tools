CREATE OR REPLACE TYPE BODY "DATA_ROW_T" AS

final member procedure construct
( self in out nocopy DATA_ROW_T
, p_table_owner in varchar2
, p_table_name in varchar2
, p_dml_operation in varchar2
, p_key in anydata
)
is
begin
  self.table_owner := p_table_owner;
  self.table_name := p_table_name;
  self.dml_operation := p_dml_operation;
  self.key := p_key;
  self.dml_timestamp := systimestamp;
end construct;  

end;
/

