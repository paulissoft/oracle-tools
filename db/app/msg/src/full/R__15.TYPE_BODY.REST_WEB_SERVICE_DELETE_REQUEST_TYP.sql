CREATE OR REPLACE TYPE BODY "REST_WEB_SERVICE_DELETE_REQUEST_TYP" AS

constructor function rest_web_service_delete_request_typ
( self in out nocopy rest_web_service_delete_request_typ
  -- from MSG_TYP
, p_group$ in varchar2 default null -- use web_service_request_typ.default_group()
, p_context$ in varchar2 default null -- you may use web_service_request_typ.generate_unique_id() to generate an AQ correlation id
  -- from HTTP_REQUEST_RESPONSE_TYP
, p_cookies in http_cookie_tab_typ default null       -- request/response cookies
, p_http_headers in property_tab_typ default null     -- request/response headers
, p_body_clob in clob default null                    -- empty for GET request (envelope for a SOAP request)
, p_body_blob in blob default null                    -- empty for GET request (empty for a SOAP request)
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
, p_use_query_parameters in integer default 0
, p_binary_response in integer default 0
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
  , p_url => p_url
  , p_scheme => p_scheme
  , p_proxy_override => p_proxy_override
  , p_transfer_timeout => p_transfer_timeout
  , p_wallet_path => p_wallet_path
  , p_https_host => p_https_host
  , p_credential_static_id => p_credential_static_id
  , p_token_url => p_token_url
  , p_parms => p_parms
  , p_use_query_parameters => p_use_query_parameters
  , p_binary_response => p_binary_response
  );
  return;
end rest_web_service_delete_request_typ;

overriding
final member function http_method
return varchar2
is
begin
  return 'DELETE';
end http_method;

end;
/

