CREATE OR REPLACE TYPE BODY "DATA_ROW_T" AS

final
member procedure construct
( self in out nocopy data_row_t
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

static
function deserialize
( p_obj_type in varchar2
, p_obj in clob
)
return data_row_t
is
  l_cursor sys_refcursor;
  l_data_row data_row_t;
begin
  open l_cursor
    for q'[select json_value(:obj, '$' returning ]' || p_obj_type || q'[) from dual]'
    using p_obj;
  fetch l_cursor into l_data_row;
  if l_cursor%notfound
  then
    close l_cursor;
    raise no_data_found;
  else
    close l_cursor;
  end if;
  return l_data_row;
end deserialize;

final
member function get_type
( self in data_row_t
)
return varchar2
is
begin
  return sys.anydata.getTypeName(sys.anydata.convertObject(self));
end get_type;

final
member function serialize
( self in data_row_t
)
return clob
is
  l_json_object json_object_t := json_object_t();
begin
  serialize(l_json_object);

  return l_json_object.to_clob();
end serialize;

member procedure serialize
( self in data_row_t
, p_json_object in out nocopy json_object_t
)
is
begin
  -- every sub type must first start with (self as <super type>).serialize(p_json_object)
  p_json_object.put('TABLE_OWNER', self.table_owner);
  p_json_object.put('TABLE_NAME', self.table_name);
  p_json_object.put('DML_OPERATION', self.dml_operation);
  -- we do not know how to deserialize the key since it is anydata
  p_json_object.put('DML_TIMESTAMP', self.dml_timestamp);
end serialize;

member function repr
( self in data_row_t
)
return clob
is
  l_clob clob := serialize();
begin
  select  json_serialize(l_clob returning clob pretty)
  into    l_clob
  from    dual;

  return l_clob;
end repr;

final
member procedure print
( self in data_row_t
)
is
  l_msg constant varchar2(4000 char) := utl_lms.format_message('type: %s; repr: %s', get_type(), dbms_lob.substr(lob_loc => repr(), amount => 2000));
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.print(dbug."info", l_msg);
$else  
  dbms_output.put_line(l_msg);
$end  
end print;

end;
/

