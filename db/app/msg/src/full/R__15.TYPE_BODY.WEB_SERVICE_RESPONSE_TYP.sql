CREATE OR REPLACE TYPE BODY "WEB_SERVICE_RESPONSE_TYP" AS

constructor function web_service_response_typ
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
, p_sql_code in integer
, p_sql_error_message in varchar2
, p_http_status_code in integer  
, p_http_reason_phrase in varchar2
, p_elapsed_time_ms in integer
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
  , p_sql_code => p_sql_code
  , p_sql_error_message => p_sql_error_message
  , p_http_status_code => p_http_status_code
  , p_http_reason_phrase => p_http_reason_phrase
  , p_elapsed_time_ms => p_elapsed_time_ms
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
, p_sql_code in integer
, p_sql_error_message in varchar2
, p_http_status_code in integer  
, p_http_reason_phrase in varchar2
, p_elapsed_time_ms in integer
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
  self.sql_code := p_sql_code;
  self.sql_error_message := p_sql_error_message;
  self.http_status_code := p_http_status_code;
  self.http_reason_phrase := p_http_reason_phrase;
  self.elapsed_time_ms := p_elapsed_time_ms;
end construct;

overriding member function must_be_processed
( self in web_service_response_typ
, p_maybe_later in integer -- True (1) or false (0)
)
return integer -- True (1) or false (0)
is
  l_result integer;
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.MUST_BE_PROCESSED');
  dbug.print(dbug."input", 'p_maybe_later: %s; self.context$: %s', p_maybe_later, self.context$);
$end

  l_result :=
    case
      when self.context$ is null
      then 0
      else 1
    end;
    
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.print(dbug."output", 'return: %s', l_result);
  dbug.leave;
$end

  return l_result;
end must_be_processed;

overriding member procedure process$later
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
  , p_correlation => self.context$
  , p_msgid => l_msgid
  );

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
$end
end process$later;

overriding member procedure process$now
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

overriding member procedure serialize
( self in web_service_response_typ
, p_json_object in out nocopy json_object_t
)
is
  l_web_service_request json_object_t := json_object_t();
begin
  (self as http_request_response_typ).serialize(p_json_object);
  p_json_object.put('SQL_CODE', self.sql_code);
  p_json_object.put('SQL_ERROR_MESSAGE', self.sql_error_message);
  p_json_object.put('HTTP_STATUS_CODE', self.http_status_code);
  p_json_object.put('HTTP_REASON_PHRASE', self.http_reason_phrase);
  p_json_object.put('ELAPSED_TIME_MS', self.elapsed_time_ms);
end serialize;

overriding member function repr
( self in web_service_response_typ
)
return clob
is
  l_clob clob := (self as http_request_response_typ /* the parent */).repr();
  l_json_object json_object_t := json_object_t(l_clob);
  l_json_functions json_object_t := treat(l_json_object.get('functions') as json_object_t);
begin
  l_json_functions.put('default_group', self.default_group());
  l_json_object.put('functions', l_json_functions);
  
  l_clob := l_json_object.to_clob();

  select  json_serialize(l_clob returning clob pretty)
  into    l_clob
  from    dual;

  return l_clob;  
end repr;

overriding member function default_processing_method
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

member function default_group
( self in web_service_response_typ
)
return varchar2
is
begin
  return 'WEB_SERVICE_RESPONSE'; -- faster not to invoke the static function
end default_group;

final member function http_status_descr
return varchar2
deterministic
is
begin
  return http_request_response_pkg.get_http_status_descr(self.http_status_code);
end http_status_descr;

final member procedure check_http_status_code
( self in web_service_response_typ -- The REST request response
)
is
begin
  web_service_pkg.check_http_status_code(self.http_status_code, self.http_reason_phrase);
end check_http_status_code;

final member function is_ok
return integer -- A numeric boolean (0=false)
is
begin
  self.check_http_status_code();
  return 1;
exception
  when others
  then return 0;
end is_ok;

final member procedure handle_response
( self in web_service_response_typ -- The REST request response
, p_check_http_status_code_ok in integer -- Check that HTTP status code is between 200 and 299
, p_http_status_code out nocopy integer -- The HTTP status code
, p_http_status_description out nocopy varchar2 -- The HTTP status description
, p_http_reason_phrase out nocopy varchar2 -- The HTTP reason phrase
, p_body_clob out nocopy clob -- The HTTP character body
, p_retry_after out nocopy varchar2 -- Retry-After HTTP header
, p_x_ratelimit_limit out nocopy varchar2 -- X-RateLimit-Limit HTTP header
, p_x_ratelimit_remaining out nocopy varchar2 -- X-RateLimit-Remaining HTTP header
, p_x_ratelimit_reset out nocopy varchar2 -- X-RateLimit-Reset HTTP header
)
is
begin
  web_service_pkg.handle_response
  ( p_response => self
  , p_check_http_status_code_ok => p_check_http_status_code_ok != 0
  , p_http_status_code => p_http_status_code
  , p_http_status_description => p_http_status_description
  , p_http_reason_phrase => p_http_reason_phrase
  , p_body_clob => p_body_clob
  , p_retry_after => p_retry_after
  , p_x_ratelimit_limit => p_x_ratelimit_limit
  , p_x_ratelimit_remaining => p_x_ratelimit_remaining
  , p_x_ratelimit_reset => p_x_ratelimit_reset
  );
end handle_response;

final member procedure handle_response
( self in web_service_response_typ -- The REST request response
, p_check_http_status_code_ok in integer -- Check that HTTP status code is between 200 and 299
, p_http_status_code out nocopy integer -- The HTTP status code
, p_http_status_description out nocopy varchar2 -- The HTTP status description
, p_http_reason_phrase out nocopy varchar2 -- The HTTP reason phrase
, p_body_blob out nocopy blob -- The HTTP binary body
, p_retry_after out nocopy varchar2 -- Retry-After HTTP header
, p_x_ratelimit_limit out nocopy varchar2 -- X-RateLimit-Limit HTTP header
, p_x_ratelimit_remaining out nocopy varchar2 -- X-RateLimit-Remaining HTTP header
, p_x_ratelimit_reset out nocopy varchar2 -- X-RateLimit-Reset HTTP header
)
is
begin
  web_service_pkg.handle_response
  ( p_response => self
  , p_check_http_status_code_ok => p_check_http_status_code_ok != 0
  , p_http_status_code => p_http_status_code
  , p_http_status_description => p_http_status_description
  , p_http_reason_phrase => p_http_reason_phrase
  , p_body_blob => p_body_blob
  , p_retry_after => p_retry_after
  , p_x_ratelimit_limit => p_x_ratelimit_limit
  , p_x_ratelimit_remaining => p_x_ratelimit_remaining
  , p_x_ratelimit_reset => p_x_ratelimit_reset
  );
end handle_response;

end;
/

