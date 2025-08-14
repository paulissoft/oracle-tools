CREATE OR REPLACE TYPE BODY "WEB_SERVICE_RESPONSE_TYP" AS

constructor function web_service_response_typ
( self in out nocopy web_service_response_typ
  -- from MSG_TYP
, p_group$ in varchar2 default null                -- use default_group() from below
, p_context$ in varchar2 default null
  -- from HTTP_REQUEST_RESPONSE_TYP
, p_cookies in http_cookie_tab_typ default null    -- request/response cookies
, p_http_headers in property_tab_typ default null  -- request/response headers
, p_body_clob in clob default null                 -- empty for GET request (envelope for a SOAP request)
, p_body_blob in blob default null                 -- empty for GET request (empty for a SOAP request)
  -- from WEB_SERVICE_RESPONSE_TYP
, p_web_service_request in web_service_request_typ
, p_sql_code in integer
, p_sql_error_message in varchar2
, p_http_status_code in integer  
, p_http_reason_phrase in varchar2 default null
)
return self as result
is
begin
  self.construct
  ( p_group$ => p_group$
  , p_context$ => p_context$
  , p_cookies => p_cookies
  , p_http_headers => p_http_headers
  , p_body_clob => p_body_clob
  , p_body_blob => p_body_blob
  , p_web_service_request => p_web_service_request
  , p_sql_code => p_sql_code
  , p_sql_error_message => p_sql_error_message
  , p_http_status_code => p_http_status_code
  , p_http_reason_phrase => p_http_reason_phrase
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
  , p_cookies => null
  , p_http_headers => null
  , p_body_clob => null
  , p_body_blob => null
  , p_web_service_request => null
  , p_sql_code => null
  , p_sql_error_message => null
  , p_http_status_code => null
  , p_http_reason_phrase => null
  );
  return;
end web_service_response_typ;

final member procedure construct
( self in out nocopy web_service_response_typ
  -- from MSG_TYP
, p_group$ in varchar2
, p_context$ in varchar2
  -- from HTTP_REQUEST_RESPONSE_TYP
, p_cookies in http_cookie_tab_typ
, p_http_headers in property_tab_typ
, p_body_clob in clob
, p_body_blob in blob
  -- from WEB_SERVICE_RESPONSE_TYP
, p_web_service_request in web_service_request_typ
, p_sql_code in integer
, p_sql_error_message in varchar2
, p_http_status_code in integer  
, p_http_reason_phrase in varchar2
)
is
begin
  (self as http_request_response_typ).construct
  ( p_group$ => nvl(p_group$, web_service_response_typ.default_group())
  , p_context$ => p_context$
  , p_cookies => p_cookies
  , p_http_headers => p_http_headers
  , p_body_clob => p_body_clob
  , p_body_blob => p_body_blob  
  );
  self.web_service_request := p_web_service_request;
  self.sql_code := p_sql_code;
  self.sql_error_message := p_sql_error_message;
  self.http_status_code := p_http_status_code;
  self.http_reason_phrase := p_http_reason_phrase;
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
begin
  (self as http_request_response_typ).serialize(p_json_object);
  if self.web_service_request is not null
  then
    self.web_service_request.serialize(l_web_service_request);
    p_json_object.put('WEB_SERVICE_REQUEST', l_web_service_request);
  end if;
  p_json_object.put('SQL_CODE', self.sql_code);
  p_json_object.put('SQL_ERROR_MESSAGE', self.sql_error_message);
  p_json_object.put('HTTP_STATUS_CODE', self.http_status_code);
  p_json_object.put('HTTP_REASON_PHRASE', self.http_reason_phrase);
end serialize;

overriding
member function default_processing_method
( self in web_service_response_typ
)
return varchar2
is
begin
  return null;
end default_processing_method;

static function default_group
return varchar2
is
begin
  return 'WEB_SERVICE_RESPONSE';
end default_group;

final member function http_status_descr
return varchar2
deterministic
is
begin
  return http_request_response_pkg.get_http_status_descr(self.http_status_code);
end http_status_descr;

end;
/

