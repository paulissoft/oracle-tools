CREATE OR REPLACE TYPE BODY "WEB_SERVICE_REQUEST_TYP" AS

constructor function web_service_request_typ
( self in out nocopy web_service_request_typ
, p_url in varchar2
, p_scheme in varchar2 default null -- 'Basic'
, p_proxy_override in varchar2 default null
, p_transfer_timeout in number default 180
, p_wallet_path in varchar2 default null
, p_https_host in varchar2 default null
, p_credential_static_id in varchar2 default null
, p_token_url in varchar2 default null
, p_correlation in varchar2 default null
, p_cookies_clob in clob default null
, p_http_headers_clob in clob default null
)
return self as result
is
begin
  self.construct
  ( p_url => p_url
  , p_scheme => p_scheme
  , p_proxy_override => p_proxy_override
  , p_transfer_timeout => p_transfer_timeout
  , p_wallet_path => p_wallet_path
  , p_https_host => p_https_host
  , p_credential_static_id => p_credential_static_id
  , p_token_url => p_token_url
  , p_correlation => p_correlation
  , p_cookies_clob => p_cookies_clob
  , p_http_headers_clob => p_http_headers_clob
  );
  return;
end web_service_request_typ;

final member procedure construct
( self in out nocopy web_service_request_typ
, p_url in varchar2
, p_scheme in varchar2 default null -- 'Basic'
, p_proxy_override in varchar2 default null
, p_transfer_timeout in number default 180
, p_wallet_path in varchar2 default null
, p_https_host in varchar2 default null
, p_credential_static_id in varchar2 default null
, p_token_url in varchar2 default null
, p_correlation in varchar2 default null
, p_cookies_clob in clob default null
, p_http_headers_clob in clob default null
)
is
begin
  (self as msg_typ).construct(web_service_request_typ.request_queue_name, p_correlation);
  self.url := p_url;
  self.scheme := p_scheme;
  self.proxy_override := p_proxy_override;
  self.transfer_timeout := p_transfer_timeout;
  self.wallet_path := p_wallet_path;
  self.https_host := p_https_host;
  self.credential_static_id := p_credential_static_id;
  self.token_url := p_token_url;
  msg_pkg.data2msg(p_cookies_clob, self.cookies_vc, self.cookies_clob);
  msg_pkg.data2msg(p_http_headers_clob, self.http_headers_vc, self.http_headers_clob);
end construct;

overriding
member procedure serialize
( self in web_service_request_typ
, p_json_object in out nocopy json_object_t
)
is
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
  -- every sub type must first start with (self as <super type>).serialize(p_json_object)
  (self as msg_typ).serialize(p_json_object);

  p_json_object.put('URL', self.url);
  p_json_object.put('SCHEME', self.scheme);
  p_json_object.put('PROXY_OVERRIDE', self.proxy_override);
  p_json_object.put('TRANSFER_TIMEOUT', self.transfer_timeout);
  p_json_object.put('WALLET_PATH', self.wallet_path);
  p_json_object.put('HTTPS_HOST', self.https_host);
  p_json_object.put('CREDENTIAL_STATIC_ID', self.credential_static_id);
  p_json_object.put('CORRELATION', self.correlation());
  p_json_object.put('TOKEN_URL', self.token_url);
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
( self in web_service_request_typ
)
return integer
is
begin
  return
    case
      when self.cookies_clob is not null then 1
      when self.http_headers_clob is not null then 1
      else 0
    end;
end has_not_null_lob;

final member function correlation
return varchar2
is
begin
  return self.context$;
end correlation;

static function request_queue_name
return varchar2
is
begin
  return 'WEB_SERVICE_REQUEST';
end request_queue_name;

static function response_queue_name
return varchar2
is
begin
  return 'WEB_SERVICE_RESPONSE';
end response_queue_name;

static function generate_correlation
return varchar2
is
begin
  return to_char(web_service_request_seq.nextval);
end generate_correlation;

end;
/

