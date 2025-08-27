CREATE OR REPLACE TYPE BODY "MSG_TYP" AS

final
member procedure construct
( self in out nocopy msg_typ
, p_group$ in varchar2
, p_context$ in varchar2
)
is
begin
  self.group$ := p_group$;
  self.context$ := p_context$;
  self.created$ := oracle_tools.api_time_pkg.timestamp2str(oracle_tools.api_time_pkg.get_timestamp());
end construct;  

member procedure process
( self in msg_typ
, p_maybe_later in integer default 1 -- True (1) or false (0)
)
is
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.PROCESS');
  dbug.print(dbug."input", 'p_maybe_later: %s', p_maybe_later);
$end

  if self.must_be_processed(p_maybe_later) = 1
  then
    case p_maybe_later
      when 1 then self.process$later;
      when 0 then self.process$now;
    end case;
  end if;
  
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
$end
end process;

member function must_be_processed
( self in msg_typ
, p_maybe_later in integer -- True (1) or false (0)
)
return integer
is
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.MUST_BE_PROCESSED');
  dbug.print(dbug."input", 'p_maybe_later: %s', p_maybe_later);
$end

  raise program_error; -- must override this one

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
$end
end must_be_processed;
  
member procedure process$now
( self in msg_typ
)
is
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.PROCESS$NOW');
$end

  raise program_error; -- must override this one

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
$end
end process$now;

member procedure process$later
( self in msg_typ
)
is
  l_msgid raw(16);
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.PROCESS$LATER');
$end

  msg_aq_pkg.enqueue(p_msg => self, p_msgid => l_msgid);

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.print(dbug."info", 'l_msgid enqueued: %s', rawtohex(l_msgid));
  dbug.leave;
$end
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
  p_json_object.put('GROUP$', self.group$);
  p_json_object.put('CONTEXT$', self.context$);
  p_json_object.put('CREATED$', self.created$);
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
member function may_have_not_null_lob
( self in msg_typ
)
return integer
is
begin
  return case when self.lob_attribute_list() is not null then 1 else 0 end;
end may_have_not_null_lob;

member function has_not_null_lob
( self in msg_typ
)
return integer
is
begin
  return 0;
end has_not_null_lob;

member function default_processing_method
( self in msg_typ
)
return varchar2
is
begin
  return msg_constants_pkg.get_default_processing_method;
end default_processing_method;

end;
/

