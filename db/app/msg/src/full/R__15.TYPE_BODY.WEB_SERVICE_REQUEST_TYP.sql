CREATE OR REPLACE TYPE BODY "WEB_SERVICE_REQUEST_TYP" AS

/*
constructor function web_service_request_typ
( self in out nocopy web_service_request_typ
  -- from MSG_TYP
, p_group$ in varchar2 default null -- use default_group() from below
, p_context$ in varchar2 default null -- you may use generate_unique_id() to generate an AQ correlation id
  -- from HTTP_REQUEST_RESPONSE_TYP
, p_cookies in http_cookie_tab_typ default null       -- request/response cookies
, p_http_headers in property_tab_typ default null  -- request/response headers
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
  );
  return;
end;
*/

final member procedure construct
( self in out nocopy web_service_request_typ
, p_group$ in varchar2
, p_context$ in varchar2
, p_cookies in http_cookie_tab_typ
, p_http_headers in property_tab_typ
, p_body_clob in clob
, p_body_blob in blob
  -- from WEB_SERVICE_REQUEST_TYP
, p_url in varchar2
, p_scheme in varchar2
, p_proxy_override in varchar2
, p_transfer_timeout in number
, p_wallet_path in varchar2
, p_https_host in varchar2
, p_credential_static_id in varchar2
, p_token_url in varchar2
)
is
begin
  (self as http_request_response_typ).construct
  ( p_group$ => nvl(p_group$, web_service_request_typ.default_group())
  , p_context$ => p_context$
  , p_cookies => p_cookies
  , p_http_headers => p_http_headers
  , p_body_clob => p_body_clob
  , p_body_blob => p_body_blob  
  );
  self.url := p_url;
  self.scheme := p_scheme;
  self.proxy_override := p_proxy_override;
  self.transfer_timeout := p_transfer_timeout;
  self.wallet_path := p_wallet_path;
  self.https_host := p_https_host;
  self.credential_static_id := p_credential_static_id;
  self.token_url := p_token_url;
end construct;

overriding
member procedure serialize
( self in web_service_request_typ
, p_json_object in out nocopy json_object_t
)
is
begin
  -- every sub type must first start with (self as <super type>).serialize(p_json_object)
  (self as http_request_response_typ).serialize(p_json_object);

  p_json_object.put('URL', self.url);
  p_json_object.put('SCHEME', self.scheme);
  p_json_object.put('PROXY_OVERRIDE', self.proxy_override);
  p_json_object.put('TRANSFER_TIMEOUT', self.transfer_timeout);
  p_json_object.put('WALLET_PATH', self.wallet_path);
  p_json_object.put('HTTPS_HOST', self.https_host);
  p_json_object.put('CREDENTIAL_STATIC_ID', self.credential_static_id);
  p_json_object.put('TOKEN_URL', self.token_url);
end serialize;

static function default_group
return varchar2
is
begin
  return 'WEB_SERVICE_REQUEST';
end default_group;

static function generate_unique_id
return varchar2
is
begin
  return to_char(web_service_request_seq.nextval);
end generate_unique_id;

end;
/

