CREATE OR REPLACE TYPE BODY "WEB_SERVICE_RESPONSE_TYP" AS

constructor function web_service_response_typ
( self in out nocopy web_service_response_typ
, p_group$ in varchar2
, p_context$ in varchar2
, p_web_service_request in web_service_request_typ
, p_http_status_code in integer  
, p_body_clob in clob
, p_body_blob in blob
, p_cookies_clob in clob
, p_http_headers_clob in clob
)
return self as result
is
begin
  self.construct
  ( p_group$ => p_group$
  , p_context$ => p_context$
  , p_web_service_request => p_web_service_request
  , p_http_status_code => p_http_status_code
  , p_body_clob => p_body_clob
  , p_body_blob => p_body_blob
  , p_cookies_clob => p_cookies_clob
  , p_http_headers_clob => p_http_headers_clob
  );
  return;
end web_service_response_typ;

constructor function web_service_response_typ
( self in out nocopy web_service_response_typ
)
return self as result
is
begin
  self.construct
  ( p_group$ => null
  , p_context$ => null
  , p_web_service_request => null
  , p_http_status_code => null
  , p_body_clob => null
  , p_body_blob => null
  , p_cookies_clob => null
  , p_http_headers_clob => null
  );
  return;
end web_service_response_typ;

final member procedure construct
( self in out nocopy web_service_response_typ
, p_group$ in varchar2
, p_context$ in varchar2
, p_web_service_request in web_service_request_typ
, p_http_status_code in integer  
, p_body_clob in clob
, p_body_blob in blob
, p_cookies_clob in clob
, p_http_headers_clob in clob
)
is
begin
  (self as msg_typ).construct(nvl(p_group$, web_service_response_typ.default_group()), p_context$);
  self.web_service_request := p_web_service_request;
  self.http_status_code := p_http_status_code;
  msg_pkg.data2msg(p_body_clob, self.body_vc, self.body_clob);
  msg_pkg.data2msg(p_body_blob, self.body_raw, self.body_blob);
  msg_pkg.data2msg(p_cookies_clob, self.cookies_vc, self.cookies_clob);
  msg_pkg.data2msg(p_http_headers_clob, self.http_headers_vc, self.http_headers_clob);
end construct;

overriding
member function must_be_processed
( self in web_service_response_typ
, p_maybe_later in integer -- True (1) or false (0)
)
return integer -- True (1) or false (0)
is
  l_result integer;
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.MUST_BE_PROCESSED');
  dbug.print(dbug."input", 'p_maybe_later: %s', p_maybe_later);
$end

  l_result :=
    case
      when self.web_service_request is null
      then 0
      when self.web_service_request.context$ is null
      then 0
      else 1
    end;

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.print(dbug."output", 'return: %s', l_result);
  dbug.leave;
$end

  return l_result;
end must_be_processed;

overriding
member procedure process$later
( self in web_service_response_typ
)
is
  l_msgid raw(16);
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.PROCESS$LATER');
$end

  msg_aq_pkg.enqueue
  ( p_msg => self
  , p_correlation => self.web_service_request.context$
  , p_msgid => l_msgid
  );

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
$end
end process$later;

overriding
member procedure process$now
( self in web_service_response_typ
)
is
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.PROCESS$NOW');
$end

  raise program_error;

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end process$now;

overriding
member procedure serialize
( self in web_service_response_typ
, p_json_object in out nocopy json_object_t
)
is
  l_web_service_request json_object_t := json_object_t();
  l_cookies_vc constant json_array_t := 
    case
      when self.cookies_vc is not null
      then json_array_t(self.cookies_vc)
      else null
    end;
  l_cookies_clob constant json_array_t := 
    case
      when self.cookies_clob is not null
      then json_array_t(self.cookies_clob)
      else null
    end;
  l_http_headers_vc constant json_array_t := 
    case
      when self.http_headers_vc is not null
      then json_array_t(self.http_headers_vc)
      else null
    end;
  l_http_headers_clob constant json_array_t := 
    case
      when self.http_headers_clob is not null
      then json_array_t(self.http_headers_clob)
      else null
    end;
begin
  (self as msg_typ).serialize(p_json_object);
  if self.web_service_request is not null
  then
    self.web_service_request.serialize(l_web_service_request);
    p_json_object.put('WEB_SERVICE_REQUEST', l_web_service_request);
  end if;
  p_json_object.put('HTTP_STATUS_CODE', self.http_status_code);
  if self.body_vc is not null
  then
    p_json_object.put('BODY_VC', self.body_vc);
  end if;
  if self.body_clob is not null
  then
    p_json_object.put('BODY_CLOB', self.body_clob);
  end if;
  if self.body_raw is not null
  then
    p_json_object.put('BODY_RAW', self.body_raw);
  end if;
  if self.body_blob is not null
  then
    p_json_object.put('BODY_BLOB', self.body_blob);
  end if;
  if l_cookies_vc is not null
  then
    p_json_object.put('COOKIES_VC', l_cookies_vc);
  end if;
  if l_cookies_clob is not null
  then
    p_json_object.put('COOKIES_CLOB', l_cookies_clob);
  end if;
  if l_http_headers_vc is not null
  then
    p_json_object.put('HTTP_HEADERS_VC', l_http_headers_vc);
  end if;
  if l_http_headers_clob is not null
  then
    p_json_object.put('HTTP_HEADERS_CLOB', l_http_headers_clob);
  end if;
end serialize;

overriding
member function has_not_null_lob
( self in web_service_response_typ
)
return integer
is
begin
  return
    case
      when self.web_service_request is not null and
           self.web_service_request.has_not_null_lob = 1
      then 1
      when self.body_clob is not null
      then 1
      when self.body_blob is not null
      then 1
      when self.cookies_clob is not null
      then 1
      when self.http_headers_clob is not null
      then 1
      else 0
    end;
end has_not_null_lob;

static function default_group
return varchar2
is
begin
  return 'WEB_SERVICE_RESPONSE';
end default_group;

overriding
member function default_processing_method
( self in web_service_response_typ
)
return varchar2
is
begin
  return null;
end default_processing_method;

end;
/

