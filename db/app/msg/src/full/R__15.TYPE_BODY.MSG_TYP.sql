CREATE OR REPLACE TYPE BODY "MSG_TYP" AS

final
member procedure construct
( self in out nocopy msg_typ
, p_source$ in varchar2
, p_context$ in varchar2
, p_key$ in anydata
)
is
begin
  self.source$ := p_source$;
  self.context$ := p_context$;
  self.key$ := p_key$;
  self.timestamp$ := systimestamp;
end construct;  

member procedure process
( self in msg_typ
, p_msg_just_created in integer default 1 -- True (1) or false (1)
)
is
begin
  if self.wants_to_process(p_msg_just_created) = 1
  then
    case p_msg_just_created
      when 1 then self.process$later;
      when 0 then self.process$now;
    end case;
  end if;
end process;

member function wants_to_process
( self in msg_typ
, p_msg_just_created in integer -- True (1) or false (1)
)
return integer
is
begin
  raise program_error; -- must override this one
end wants_to_process;
  
member procedure process$now
( self in msg_typ
)
is
begin
  raise program_error; -- must override this one
end process$now;

member procedure process$later
( self in msg_typ
)
is
  l_msgid raw(16);
begin
  msg_aq_pkg.enqueue(p_msg => self, p_msgid => l_msgid);
end process$later;

static
function deserialize
( p_obj_type in varchar2
, p_obj in clob
)
return msg_typ
is
  l_cursor sys_refcursor;
  l_msg msg_typ;
begin
  open l_cursor
    for q'[select json_value(:obj, '$' returning ]' || p_obj_type || q'[) from dual]'
    using p_obj;
  fetch l_cursor into l_msg;
  if l_cursor%notfound
  then
    close l_cursor;
    raise no_data_found;
  else
    close l_cursor;
  end if;
  return l_msg;
end deserialize;

final
member function get_type
( self in msg_typ
)
return varchar2
is
begin
  return sys.anydata.getTypeName(sys.anydata.convertObject(self));
end get_type;

final
member function serialize
( self in msg_typ
)
return clob
is
  l_json_object json_object_t := json_object_t();
begin
  serialize(l_json_object);

  return l_json_object.to_clob();
end serialize;

member procedure serialize
( self in msg_typ
, p_json_object in out nocopy json_object_t
)
is
begin
  -- every sub type must first start with (self as <super type>).serialize(p_json_object)
  p_json_object.put('SOURCE$', self.source$);
  p_json_object.put('CONTEXT$', self.context$);
  -- we do not know how to deserialize the key$ since it is anydata
  p_json_object.put('TIMESTAMP$', self.timestamp$);
end serialize;

member function repr
( self in msg_typ
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
( self in msg_typ
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

final
member function lob_attribute_list
( self in msg_typ
)
return varchar2
is
  l_lob_attribute_list varchar2(4000 char) := null;
  l_fq_type constant varchar2(4000 char) := self.get_type();
  l_point constant positiven := instr(l_fq_type, '.'); -- test at the same time it is > 0
  l_owner constant all_type_attrs.owner%type := substr(l_fq_type, 1, l_point - 1);
  l_type_name constant all_type_attrs.type_name%type := substr(l_fq_type, l_point + 1);
begin
  select  listagg(case when a.attr_type_name in ('CLOB', 'BLOB') then a.attr_name end, ',') within group (order by a.attr_name) as lob_attribute_list
  into    l_lob_attribute_list
  from    all_type_attrs a
  where   a.owner = l_owner
  and     a.type_name = l_type_name
  group by
          a.owner
  ,       a.type_name;

  return l_lob_attribute_list;
end lob_attribute_list;

final
member function may_have_non_empty_lob
( self in msg_typ
)
return integer
is
begin
  return case when self.lob_attribute_list() is not null then 1 else 0 end;
end may_have_non_empty_lob;

member function has_non_empty_lob
( self in msg_typ
)
return integer
is
begin
  return 0; -- key$ can not store a LOB
end has_non_empty_lob;

end;
/

