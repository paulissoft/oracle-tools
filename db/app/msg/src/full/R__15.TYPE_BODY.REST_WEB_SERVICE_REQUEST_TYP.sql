CREATE OR REPLACE TYPE BODY "REST_WEB_SERVICE_REQUEST_TYP" AS

constructor function rest_web_service_request_typ
( self in out nocopy rest_web_service_request_typ
  -- from web_service_request_typ
, p_group$ in varchar2
, p_context$ in varchar2
, p_url in varchar2
, p_scheme in varchar2
, p_proxy_override in varchar2
, p_transfer_timeout in number
, p_wallet_path in varchar2
, p_https_host in varchar2
, p_credential_static_id in varchar2
, p_token_url in varchar2
, p_cookies_clob in clob
, p_http_headers_clob in clob
  -- this type
, p_http_method in varchar2
, p_body_clob in clob
, p_body_blob in blob
, p_parms_clob in clob
, p_binary_response in integer
)
return self as result
is
begin
  self.construct
  ( p_group$ => p_group$
  , p_context$ => p_context$
  , p_url => p_url
  , p_scheme => p_scheme
  , p_proxy_override => p_proxy_override
  , p_transfer_timeout => p_transfer_timeout
  , p_wallet_path => p_wallet_path
  , p_https_host => p_https_host
  , p_credential_static_id => p_credential_static_id
  , p_token_url => p_token_url
  , p_cookies_clob => p_cookies_clob
  , p_http_headers_clob => p_http_headers_clob
  , p_http_method => p_http_method
  , p_body_clob => p_body_clob
  , p_body_blob => p_body_blob
  , p_parms_clob => p_parms_clob
  , p_binary_response => p_binary_response
  );
  return;
end rest_web_service_request_typ;

constructor function rest_web_service_request_typ
( self in out nocopy rest_web_service_request_typ
)
return self as result
is
begin
  self.construct
  ( p_group$ => null
  , p_context$ => null
  , p_url => null
  , p_scheme => null
  , p_proxy_override => null
  , p_transfer_timeout => null
  , p_wallet_path => null
  , p_https_host => null
  , p_credential_static_id => null
  , p_token_url => null
  , p_cookies_clob => null
  , p_http_headers_clob => null
  , p_http_method => null
  , p_body_clob => null
  , p_body_blob => null
  , p_parms_clob => null
  , p_binary_response => null
  );
  return;
end rest_web_service_request_typ;

final member procedure construct
( self in out nocopy rest_web_service_request_typ
  -- from web_service_request_typ
, p_group$ in varchar2
, p_context$ in varchar2
, p_url in varchar2
, p_scheme in varchar2
, p_proxy_override in varchar2
, p_transfer_timeout in number
, p_wallet_path in varchar2
, p_https_host in varchar2
, p_credential_static_id in varchar2
, p_token_url in varchar2
, p_cookies_clob in clob
, p_http_headers_clob in clob
  -- this type
, p_http_method in varchar2
, p_body_clob in clob
, p_body_blob in blob
, p_parms_clob in clob
, p_binary_response in integer
)
is
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.CONSTRUCT');
$end

  (self as web_service_request_typ).construct
  ( p_group$ => p_group$
  , p_context$ => p_context$
  , p_url => p_url
  , p_scheme => p_scheme
  , p_proxy_override => p_proxy_override
  , p_transfer_timeout => p_transfer_timeout
  , p_wallet_path => p_wallet_path
  , p_https_host => p_https_host
  , p_credential_static_id => p_credential_static_id
  , p_token_url => p_token_url
  , p_cookies_clob => p_cookies_clob
  , p_http_headers_clob => p_http_headers_clob
  );
  self.http_method := p_http_method;
  msg_pkg.data2msg(p_body_clob, self.body_vc, self.body_clob);
  msg_pkg.data2msg(p_body_blob, self.body_raw, self.body_blob);
  msg_pkg.data2msg(p_parms_clob, self.parms_vc, self.parms_clob);
  self.binary_response := p_binary_response;

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
$end
end construct;

overriding
member function must_be_processed
( self in rest_web_service_request_typ
, p_maybe_later in integer -- True (1) or false (0)
)
return integer -- True (1) or false (0)
is
  l_result constant integer := 1;
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.MUST_BE_PROCESSED');
  dbug.print(dbug."input", 'p_maybe_later: %s', p_maybe_later);
$end

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.print(dbug."output", 'return: %s', l_result);
  dbug.leave;
$end

  return l_result;
end must_be_processed;

overriding
member procedure process$now
( self in rest_web_service_request_typ
)
is
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.PROCESS$NOW');
$end

  self.response().process;

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
$end
end process$now;

overriding
member procedure serialize
( self in rest_web_service_request_typ
, p_json_object in out nocopy json_object_t
)
is
  l_parms_vc constant json_object_t := 
    case
      when self.parms_vc is not null
      then json_object_t(self.parms_vc)
      else null
    end;
  l_parms_clob constant json_object_t := 
    case
      when self.parms_clob is not null
      then json_object_t(self.parms_clob)
      else null
    end;
begin
  (self as web_service_request_typ).serialize(p_json_object);
  p_json_object.put('HTTP_METHOD', self.http_method);
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
  if l_parms_vc is not null
  then
    p_json_object.put('PARMS_VC', l_parms_vc);
  end if;
  if l_parms_clob is not null
  then
    p_json_object.put('PARMS_CLOB', l_parms_clob);
  end if;
  p_json_object.put('BINARY_RESPONSE', self.binary_response);
end serialize;

overriding
member function has_not_null_lob
( self in rest_web_service_request_typ
)
return integer
is
begin
  return
    case
      when (self as web_service_request_typ).has_not_null_lob = 1 then 1
      when self.body_clob is not null then 1
      when self.body_blob is not null then 1
      when self.parms_clob is not null then 1
      else 0
    end;
end has_not_null_lob;

member function response
return web_service_response_typ
is
  l_web_service_response web_service_response_typ;
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.RESPONSE');
$end

  l_web_service_response := web_service_pkg.make_rest_request(self);
  
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
$end

  return l_web_service_response;
end response;

end;
/

