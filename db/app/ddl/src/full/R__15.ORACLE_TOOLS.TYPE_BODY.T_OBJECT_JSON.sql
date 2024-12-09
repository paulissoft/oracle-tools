CREATE OR REPLACE TYPE BODY "ORACLE_TOOLS"."T_OBJECT_JSON" AS

static
function deserialize
( p_obj_type in varchar2
, p_obj in clob
)
return oracle_tools.t_object_json
deterministic
is
  l_cursor sys_refcursor;
  l_object_json oracle_tools.t_object_json;
begin
  open l_cursor
    for q'[select json_value(:obj, '$' returning ]' || p_obj_type || q'[) from dual]'
    using p_obj;
  fetch l_cursor into l_object_json;
  if l_cursor%notfound
  then
    close l_cursor;
    raise no_data_found;
  else
    close l_cursor;
  end if;
  return l_object_json;
end deserialize;

final
member function get_type
( self in oracle_tools.t_object_json
)
return varchar2
deterministic
is
begin
  return sys.anydata.getTypeName(sys.anydata.convertObject(self));
end get_type;

final
member function serialize
( self in oracle_tools.t_object_json
)
return clob
deterministic
is
  l_json_object json_object_t := json_object_t();
begin
  serialize(l_json_object);

  return l_json_object.to_clob();
end serialize;

member procedure serialize
( self in oracle_tools.t_object_json
, p_json_object in out nocopy json_object_t
)
is
begin
  -- every sub type must first start with (self as <super type>).serialize(p_json_object)
  null;
end serialize;

order
member function compare
( self in oracle_tools.t_object_json
, p_other_object_json in oracle_tools.t_object_json
)
return integer
deterministic
is
begin
  return dbms_lob.compare(self.serialize(), p_other_object_json.serialize());
end compare;

final
member function repr
( self in oracle_tools.t_object_json
)
return clob
deterministic
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
( self in oracle_tools.t_object_json
)
is
  l_object_json constant varchar2(4000 char) := utl_lms.format_message('type: %s; repr: %s', get_type(), dbms_lob.substr(lob_loc => repr(), amount => 2000));
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.print(dbug."info", l_object_json);
$else  
  dbms_output.put_line(l_object_json);
$end  
end print;

end t_object_json;
/

