CREATE OR REPLACE TYPE BODY "MSG_WITH_ID_KEY_TYP" AS

final
member procedure construct
( self in out nocopy msg_with_id_key_typ
, p_source$ in varchar2
, p_context$ in varchar2
, p_id in integer -- sets self.key$ using anydata.ConvertNumber(p_id)
)
is
begin
  (self as msg_typ).construct(p_source$, p_context$, anydata.ConvertNumber(p_id));
end construct;  

final
member function id
return integer
is
  l_id number;
begin
  case self.key$.getnumber(l_id)
    when DBMS_TYPES.SUCCESS
    then return l_id;
    when DBMS_TYPES.NO_DATA
    then return null;    
  end case;
end id;

overriding
member procedure serialize
( self in msg_with_id_key_typ
, p_json_object in out nocopy json_object_t
)
is
begin
  -- every sub type must first start with (self as <super type>).serialize(p_json_object)
  (self as msg_typ).serialize(p_json_object);

  p_json_object.put('ID', self.id());
end serialize;

end;
/

