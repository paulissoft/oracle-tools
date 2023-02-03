CREATE OR REPLACE TYPE BODY "DATA_ROW_ID_T" AS

final
member procedure construct
( self in out nocopy data_row_id_t
, p_table_owner in varchar2
, p_table_name in varchar2
, p_dml_operation in varchar2
, p_id in integer
)
is
begin
  (self as data_row_t).construct(p_table_owner, p_table_name, p_dml_operation, anydata.ConvertNumber(p_id));
end construct;  

final
member function id
return integer
is
  l_id number;
begin
  case self.key.getnumber(l_id)
    when DBMS_TYPES.SUCCESS
    then return l_id;
    when DBMS_TYPES.NO_DATA
    then return null;    
  end case;
end id;

overriding
member procedure serialize
( self in data_row_id_t
, p_json_object in out nocopy json_object_t
)
is
begin
  -- every sub type must first start with (self as <super type>).serialize(p_json_object)
  (self as data_row_t).serialize(p_json_object);

  p_json_object.put('ID', self.id());
end serialize;

end;
/

