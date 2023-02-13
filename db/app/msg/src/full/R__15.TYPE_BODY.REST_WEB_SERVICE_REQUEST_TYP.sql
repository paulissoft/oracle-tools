CREATE OR REPLACE TYPE BODY "REST_WEB_SERVICE_REQUEST_TYP" AS

constructor function rest_web_service_request_typ
( self in out nocopy rest_web_service_request_typ
  -- from web_service_request_typ
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
  -- this type
, p_http_method in varchar2 default 'GET'
, p_body_clob in clob default null
, p_body_blob in blob default null
, p_parms_clob in clob default null
, p_binary_response in integer default 0
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
  , p_http_method => p_http_method
  , p_body_clob => p_body_clob
  , p_body_blob => p_body_blob
  , p_parms_clob => p_parms_clob
  , p_binary_response => p_binary_response
  );
  return;
end rest_web_service_request_typ;

final member procedure construct
( self in out nocopy rest_web_service_request_typ
  -- from web_service_request_typ
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
  -- this type
, p_http_method in varchar2 default 'GET'
, p_body_clob in clob default null
, p_body_blob in blob default null
, p_parms_clob in clob default null
, p_binary_response in integer default 0
)
is
begin
  (self as web_service_request_typ).construct
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
  self.http_method := p_http_method;
  msg_pkg.data2msg(p_body_clob, self.body_vc, self.body_clob);
  msg_pkg.data2msg(p_body_blob, self.body_raw, self.body_blob);
  msg_pkg.data2msg(p_parms_clob, self.parms_vc, self.parms_clob);
  self.binary_response := p_binary_response;
end construct;

overriding
member function must_be_processed
( self in rest_web_service_request_typ
, p_maybe_later in integer -- True (1) or false (0)
)
return integer -- True (1) or false (0)
is
begin
  return 1;
end must_be_processed;

overriding
member procedure process$now
( self in rest_web_service_request_typ
)
is
  l_parm_names apex_application_global.vc_arr2 := apex_web_service.empty_vc_arr;
  l_parm_values apex_application_global.vc_arr2 := apex_web_service.empty_vc_arr;
  l_parms constant json_object_t := 
    case
      when self.parms_vc is not null
      then json_object_t(self.parms_vc)
      when self.parms_clob is not null
      then json_object_t(self.parms_clob)
      else null
    end;
  l_parms_keys constant json_key_list :=
    case
      when l_parms is not null
      then l_parms.get_keys
      else null
    end;
  l_cookies json_array_t := 
    case
      when self.cookies_vc is not null
      then json_array_t(self.cookies_vc)
      when self.cookies_clob is not null
      then json_array_t(self.cookies_clob)
      else null
    end;
  l_http_headers json_array_t := 
    case
      when self.http_headers_vc is not null
      then json_array_t(self.http_headers_vc)
      when self.http_headers_clob is not null
      then json_array_t(self.http_headers_clob)
      else null
    end;
  l_body_clob clob := null;
  l_body_blob blob := null;
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.PROCESS$NOW');
$end

  if l_parms is not null
  then
    for i_idx in l_parms_keys.first .. l_parms_keys.last
    loop
      l_parm_names(l_parm_names.count+1) := l_parms_keys(i_idx);
      l_parm_values(l_parm_names.count+1) := l_parms.get(l_parms_keys(i_idx)).stringify;
    end loop;
  end if;

  web_service_pkg.json2data(l_cookies, apex_web_service.g_request_cookies);
  web_service_pkg.json2data(l_http_headers, apex_web_service.g_request_headers);

  if self.binary_response = 0
  then
    l_body_clob := apex_web_service.make_rest_request
                   ( p_url => self.url
                   , p_http_method => self.http_method
                   , p_username => null
                   , p_password => null
                   , p_scheme => self.scheme
                   , p_proxy_override => self.proxy_override
                   , p_transfer_timeout => self.transfer_timeout
                   , p_body =>
                       case
                         when self.body_vc is not null
                         then to_clob(self.body_vc)
                         when self.body_clob is not null
                         then self.body_clob
                         else empty_clob()
                       end
                   , p_body_blob =>
                       case
                         when self.body_raw is not null
                         then to_blob(self.body_raw)
                         when self.body_blob is not null
                         then self.body_blob
                         else empty_blob()
                       end
                   , p_parm_name => l_parm_names
                   , p_parm_value => l_parm_values
                   , p_wallet_path => self.wallet_path
                   , p_wallet_pwd => null
                   , p_https_host => self.https_host
                   , p_credential_static_id => self.credential_static_id
                   , p_token_url => self.token_url
                   );
  else
    l_body_blob := apex_web_service.make_rest_request_b
                   ( p_url => self.url
                   , p_http_method => self.http_method
                   , p_username => null
                   , p_password => null
                   , p_scheme => self.scheme
                   , p_proxy_override => self.proxy_override
                   , p_transfer_timeout => self.transfer_timeout
                   , p_body =>
                       case
                         when self.body_vc is not null
                         then to_clob(self.body_vc)
                         when self.body_clob is not null
                         then self.body_clob
                         else empty_clob()
                       end
                   , p_body_blob =>
                       case
                         when self.body_raw is not null
                         then to_blob(self.body_raw)
                         when self.body_blob is not null
                         then self.body_blob
                         else empty_blob()
                       end
                   , p_parm_name => l_parm_names
                   , p_parm_value => l_parm_values
                   , p_wallet_path => self.wallet_path
                   , p_wallet_pwd => null
                   , p_https_host => self.https_host
                   , p_credential_static_id => self.credential_static_id
                   , p_token_url => self.token_url
                   );
  end if;

  web_service_pkg.data2json(apex_web_service.g_response_cookies, l_cookies);
  web_service_pkg.data2json(apex_web_service.g_headers, l_http_headers);

  if self.correlation() is not null
  then
    web_service_response_typ
    ( p_web_service_request => self
    , p_http_status_code => apex_web_service.g_status_code
    , p_body_clob => l_body_clob
    , p_body_blob => l_body_blob
    , p_cookies_clob => case when l_cookies is not null then l_cookies.to_clob() end
    , p_http_headers_clob => case when l_http_headers is not null then l_http_headers.to_clob() end
    ).process;
  end if;
  
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
$end
end;

overriding
member procedure serialize
( self in rest_web_service_request_typ
, p_json_object in out nocopy json_object_t
)
is
  l_body_vc constant json_object_t := 
    case
      when self.body_vc is not null
      then json_object_t(self.body_vc)
      else null
    end;
  l_body_clob constant json_object_t := 
    case
      when self.body_clob is not null
      then json_object_t(self.body_clob)
      else null
    end;
  l_body_raw constant json_object_t := 
    case
      when self.body_raw is not null
      then json_object_t(to_blob(self.body_raw))
      else null
    end;
  l_body_blob constant json_object_t := 
    case
      when self.body_blob is not null
      then json_object_t(self.body_blob)
      else null
    end;
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
  if l_body_vc is not null
  then
    p_json_object.put('BODY_VC', l_body_vc);
  end if;
  if l_body_clob is not null
  then
    p_json_object.put('BODY_CLOB', l_body_clob);
  end if;
  if l_body_raw is not null
  then
    p_json_object.put('BODY_RAW', l_body_raw);
  end if;
  if l_body_blob is not null
  then
    p_json_object.put('BODY_BLOB', l_body_blob);
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

end;
/

