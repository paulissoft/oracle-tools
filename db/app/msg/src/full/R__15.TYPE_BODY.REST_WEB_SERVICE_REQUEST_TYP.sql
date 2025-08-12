CREATE OR REPLACE TYPE BODY "REST_WEB_SERVICE_REQUEST_TYP" AS

final member procedure construct
( self in out nocopy rest_web_service_request_typ
  -- from MSG_TYP
, p_group$ in varchar2
, p_context$ in varchar2
  -- from HTTP_REQUEST_RESPONSE_TYP
, p_cookies in http_cookie_tab_typ -- default null    -- request/response cookies
, p_http_headers in property_tab_typ -- default null  -- request/response headers
, p_body_clob in clob                                 -- empty for GET request (envelope for a SOAP request)
, p_body_blob in blob                                 -- empty for GET request (empty for a SOAP request)
  -- from WEB_SERVICE_REQUEST_TYP
, p_url in varchar2
, p_scheme in varchar2 -- default null -- 'Basic'
, p_proxy_override in varchar2 -- default null
, p_transfer_timeout in number -- default 180
, p_wallet_path in varchar2 -- default null
, p_https_host in varchar2 -- default null
, p_credential_static_id in varchar2 -- default null
, p_token_url in varchar2 -- default null
  -- from REST_WEB_SERVICE_REQUEST_TYP
, p_parms in property_tab_typ default null
, p_binary_response in integer -- default 0
)
is
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.CONSTRUCT');
$end

  (self as web_service_request_typ).construct
  ( p_group$ => p_group$
  , p_context$ => p_context$
  , p_cookies => p_cookies
  , p_http_headers => p_http_headers
  , p_body_clob => p_body_clob
  , p_body_blob => p_body_blob
  , p_url => p_url
  , p_scheme => p_scheme
  , p_proxy_override => p_proxy_override
  , p_transfer_timeout => p_transfer_timeout
  , p_wallet_path => p_wallet_path
  , p_https_host => p_https_host
  , p_credential_static_id => p_credential_static_id
  , p_token_url => p_token_url
  );
  self.parms := p_parms;
  self.binary_response := p_binary_response;

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
$end
end construct;

static procedure construct
( p_http_method in varchar2
  -- from MSG_TYP
, p_group$ in varchar2 default null
, p_context$ in varchar2 default null
  -- from HTTP_REQUEST_RESPONSE_TYP
, p_cookies in http_cookie_tab_typ default null    -- request/response cookies
, p_http_headers in property_tab_typ default null  -- request/response headers
, p_body_clob in clob default null                 -- empty for GET request (envelope for a SOAP request)
, p_body_blob in blob default null                 -- empty for GET request (empty for a SOAP request)
  -- from WEB_SERVICE_REQUEST_TYP
, p_url in varchar2 default null
, p_scheme in varchar2 default null -- 'Basic'
, p_proxy_override in varchar2 default null
, p_transfer_timeout in number default 180
, p_wallet_path in varchar2 default null
, p_https_host in varchar2 default null
, p_credential_static_id in varchar2 default null
, p_token_url in varchar2 default null
  -- from REST_WEB_SERVICE_REQUEST_TYP
, p_parms in property_tab_typ default null
, p_binary_response in integer default 0
, p_rest_web_service_request out nocopy rest_web_service_request_typ -- any of the rest_web_service_<HTTP_METHOD>_request_typ types
)
is
begin
  case upper(p_http_method)
    when 'DELETE'
    then p_rest_web_service_request :=
           new rest_web_service_delete_request_typ
               ( p_group$ => p_group$
               , p_context$ => p_context$
               , p_cookies => p_cookies
               , p_http_headers => p_http_headers
               , p_body_clob => p_body_clob
               , p_body_blob => p_body_blob
               , p_url => p_url
               , p_scheme => p_scheme
               , p_proxy_override => p_proxy_override
               , p_transfer_timeout => p_transfer_timeout
               , p_wallet_path => p_wallet_path
               , p_https_host => p_https_host
               , p_credential_static_id => p_credential_static_id
               , p_token_url => p_token_url
               , p_parms => p_parms
               , p_binary_response => p_binary_response
               );
    when 'GET'
    then p_rest_web_service_request :=
           new rest_web_service_get_request_typ
               ( p_group$ => p_group$
               , p_context$ => p_context$
               , p_cookies => p_cookies
               , p_http_headers => p_http_headers
               , p_url => p_url
               , p_scheme => p_scheme
               , p_proxy_override => p_proxy_override
               , p_transfer_timeout => p_transfer_timeout
               , p_wallet_path => p_wallet_path
               , p_https_host => p_https_host
               , p_credential_static_id => p_credential_static_id
               , p_token_url => p_token_url
               , p_query_parms => p_parms
               , p_binary_response => p_binary_response
               );
    when 'PATCH'
    then p_rest_web_service_request :=
           new rest_web_service_patch_request_typ
               ( p_group$ => p_group$
               , p_context$ => p_context$
               , p_cookies => p_cookies
               , p_http_headers => p_http_headers
               , p_body_clob => p_body_clob
               , p_body_blob => p_body_blob
               , p_url => p_url
               , p_scheme => p_scheme
               , p_proxy_override => p_proxy_override
               , p_transfer_timeout => p_transfer_timeout
               , p_wallet_path => p_wallet_path
               , p_https_host => p_https_host
               , p_credential_static_id => p_credential_static_id
               , p_token_url => p_token_url
               , p_parms => p_parms
               , p_binary_response => p_binary_response
               );
    when 'POST'
    then p_rest_web_service_request :=
           new rest_web_service_post_request_typ
               ( p_group$ => p_group$
               , p_context$ => p_context$
               , p_cookies => p_cookies
               , p_http_headers => p_http_headers
               , p_body_clob => p_body_clob
               , p_body_blob => p_body_blob
               , p_url => p_url
               , p_scheme => p_scheme
               , p_proxy_override => p_proxy_override
               , p_transfer_timeout => p_transfer_timeout
               , p_wallet_path => p_wallet_path
               , p_https_host => p_https_host
               , p_credential_static_id => p_credential_static_id
               , p_token_url => p_token_url
               , p_parms => p_parms
               , p_binary_response => p_binary_response
               );
    when 'PUT'
    then p_rest_web_service_request :=
           new rest_web_service_put_request_typ
               ( p_group$ => p_group$
               , p_context$ => p_context$
               , p_cookies => p_cookies
               , p_http_headers => p_http_headers
               , p_body_clob => p_body_clob
               , p_body_blob => p_body_blob
               , p_url => p_url
               , p_scheme => p_scheme
               , p_proxy_override => p_proxy_override
               , p_transfer_timeout => p_transfer_timeout
               , p_wallet_path => p_wallet_path
               , p_https_host => p_https_host
               , p_credential_static_id => p_credential_static_id
               , p_token_url => p_token_url
               , p_parms => p_parms
               , p_binary_response => p_binary_response
               );
  end case;
end construct;

overriding
final member function must_be_processed
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
final member procedure process$now
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
final member procedure serialize
( self in rest_web_service_request_typ
, p_json_object in out nocopy json_object_t
)
is
  l_json_array json_array_t;
begin
  (self as web_service_request_typ).serialize(p_json_object);
  if self.parms is not null
  then
    web_service_pkg.to_json(self.parms, l_json_array);
    p_json_object.put('PARMS', l_json_array);
  end if;
  p_json_object.put('BINARY_RESPONSE', self.binary_response);
end serialize;

final member function response
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

member function http_method
return varchar2
is
begin
  -- must be overridden by a final function
  raise program_error;
end http_method;

end;
/

