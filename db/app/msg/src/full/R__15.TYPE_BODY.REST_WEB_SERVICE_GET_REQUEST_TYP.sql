CREATE OR REPLACE TYPE BODY "REST_WEB_SERVICE_GET_REQUEST_TYP" AS

constructor function rest_web_service_get_request_typ
( self in out nocopy rest_web_service_get_request_typ
  -- from MSG_TYP
, p_group$ in varchar2
, p_context$ in varchar2
  -- from HTTP_REQUEST_RESPONSE_TYP
, p_cookies in http_cookie_tab_typ
, p_http_headers in property_tab_typ
  -- from WEB_SERVICE_REQUEST_TYP
, p_url in varchar2
, p_scheme in varchar2
, p_proxy_override in varchar2
, p_transfer_timeout in number
, p_wallet_path in varchar2
, p_https_host in varchar2
, p_credential_static_id in varchar2
, p_token_url in varchar2
  -- from REST_WEB_SERVICE_GET_REQUEST_TYP
, p_parms in property_tab_typ
, p_binary_response in integer
)
return self as result
is
begin
  self.construct
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
  , p_parms => p_parms
  , p_binary_response => p_binary_response
  );
  return;
end;

final member procedure construct
( self in out nocopy rest_web_service_get_request_typ
  -- from MSG_TYP
, p_group$ in varchar2
, p_context$ in varchar2
  -- from HTTP_REQUEST_RESPONSE_TYP
, p_cookies in http_cookie_tab_typ
, p_http_headers in property_tab_typ
  -- from WEB_SERVICE_REQUEST_TYP
, p_url in varchar2
, p_scheme in varchar2
, p_proxy_override in varchar2
, p_transfer_timeout in number
, p_wallet_path in varchar2
, p_https_host in varchar2
, p_credential_static_id in varchar2
, p_token_url in varchar2
  -- from REST_WEB_SERVICE_GET_REQUEST_TYP
, p_parms in property_tab_typ
, p_binary_response in integer
)
is
begin
  (self as rest_web_service_request_typ).construct
  ( p_group$ => p_group$
  , p_context$ => p_context$
  , p_cookies => p_cookies
  , p_http_headers => p_http_headers
  , p_body_clob => null
  , p_body_blob => null
  , p_url => p_url
  , p_scheme => p_scheme
  , p_proxy_override => p_proxy_override
  , p_transfer_timeout => p_transfer_timeout
  , p_wallet_path => p_wallet_path
  , p_https_host => p_https_host
  , p_credential_static_id => p_credential_static_id
  , p_token_url => p_token_url
  , p_parms => p_parms
  , p_use_query_parameters => 1
  , p_binary_response => p_binary_response
  );
end;

overriding
final member function http_method
return varchar2
is
begin
  return 'GET';
end http_method;

final member function query_parms
return property_tab_typ
is
begin
  return self.parms;
end;

end;
/

