CREATE OR REPLACE TYPE BODY "WEB_SERVICE_REQUEST_TYP" AS

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

overriding member procedure serialize
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

overriding member function repr
( self in web_service_request_typ
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

static function default_group
return varchar2
is
begin
  return 'WEB_SERVICE_REQUEST';
end default_group;

member function default_group
( self in web_service_request_typ
)
return varchar2
is
begin
  return 'WEB_SERVICE_REQUEST'; -- faster not to invoke the static function
end default_group;

static function generate_unique_id
return varchar2
is
begin
  return to_char(web_service_request_seq.nextval);
end generate_unique_id;

end;
/

