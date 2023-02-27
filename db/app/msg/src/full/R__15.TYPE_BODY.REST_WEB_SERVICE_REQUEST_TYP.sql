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
  l_body_clob clob :=
    case
      when self.body_vc is not null
      then to_clob(self.body_vc)
      when self.body_clob is not null
      then self.body_clob
    end;
  l_body_blob blob := 
    case
      when self.body_raw is not null
      then to_blob(self.body_raw)
      when self.body_blob is not null
      then self.body_blob
    end;
  l_web_service_response web_service_response_typ := null;

  function simple_request
  return boolean
  is
  begin
$if oracle_tools.cfg_pkg.c_debugging $then
    dbug.print
    ( dbug."info"
    , 'self.scheme is null: %s; self.proxy_override is null: %s; l_body_clob is not null or l_body_blob is null: %s; l_parm_names.count = 0: %s; l_parm_values.count = 0: %s'
    , dbug.cast_to_varchar2(self.scheme is null)
    , dbug.cast_to_varchar2(self.proxy_override is null)
    , dbug.cast_to_varchar2(l_body_clob is not null or l_body_blob is null)
    , dbug.cast_to_varchar2(l_parm_names.count = 0)
    , dbug.cast_to_varchar2(l_parm_values.count = 0)
    );                          

    dbug.print
    ( dbug."info"
    , 'self.wallet_path: %s; self.https_host is null: %s; self.credential_static_id is null: %s; self.token_url is null: %s; apex_web_service.g_request_cookies.count = 0: %s'
    , dbug.cast_to_varchar2(self.wallet_path is null)
    , dbug.cast_to_varchar2(self.https_host is null)
    , dbug.cast_to_varchar2(self.credential_static_id is null)
    , dbug.cast_to_varchar2(self.token_url is null)
    , dbug.cast_to_varchar2(apex_web_service.g_request_cookies.count = 0)
    );
$end

    return self.scheme is null and
           self.proxy_override is null and
           ( l_body_clob is not null or l_body_blob is null ) and
           l_parm_names.count = 0 and
           l_parm_values.count = 0 and
           self.wallet_path is null and
           self.https_host is null and
           self.credential_static_id is null and
           self.token_url is null and
           apex_web_service.g_request_cookies.count = 0;
  end simple_request;
  
  function clob2blob
  ( p_body_clob in clob
  )
  return blob
  is 
    l_blob        blob;
    l_desc_offset pls_integer := 1;
    l_src_offset  pls_integer := 1;
    l_lang        pls_integer := 0;
    l_warning     pls_integer := 0;  
  begin
    dbms_lob.createtemporary(l_blob, true);
    dbms_lob.converttoblob
    ( l_blob
    , p_body_clob
    , dbms_lob.getlength(p_body_clob)
    , l_desc_offset
    , l_src_offset
    , dbms_lob.default_csid
    , l_lang
    , l_warning
    );
    return l_blob;
  end clob2blob;

  procedure utl_http_request
  ( p_body_clob in out nocopy clob
  , p_body_blob in out nocopy blob
  )
  is
    l_http_request utl_http.req;
    l_http_response utl_http.resp;
    l_offset positiven := 1;
    l_nr_bytes_to_write pls_integer;
    l_raw raw(2000);
    c_max_raw_size constant positiven := 2000;
    l_text varchar2(2000 char);
    c_max_text_size constant positiven := 2000;
    l_header_count pls_integer;
  begin
    if p_body_clob is not null
    then
      p_body_blob := clob2blob(p_body_clob);
      p_body_clob := null;
    else
      p_body_blob := null;
    end if;
    
    apex_web_service.g_headers.delete;
    apex_web_service.g_response_cookies.delete;

    utl_http.set_wallet(null);
    utl_http.set_transfer_timeout(self.transfer_timeout);

    l_http_request := utl_http.begin_request(self.url, self.http_method);

    if apex_web_service.g_request_headers.count > 0
    then
      for i_idx in apex_web_service.g_request_headers.first .. apex_web_service.g_request_headers.last
      loop
        if apex_web_service.g_request_headers(i_idx).name not in ('Content-Length', 'Accept', 'User-Agent')
        then
          utl_http.set_header(l_http_request, apex_web_service.g_request_headers(i_idx).name, apex_web_service.g_request_headers(i_idx).value);
        end if;
      end loop;
    end if;

    utl_http.set_header(l_http_request, 'Accept', '*/*');
    utl_http.set_header(l_http_request, 'User-Agent', 'APEX');

    if p_body_blob is null
    then
      utl_http.set_header(l_http_request, 'Content-Length', 0);
    else
      utl_http.set_header(l_http_request, 'Content-Length', dbms_lob.getlength(p_body_blob));

      l_nr_bytes_to_write := dbms_lob.getlength(p_body_blob);
      
      loop
        exit when l_nr_bytes_to_write <= 0;

        l_raw := dbms_lob.substr(lob_loc => p_body_blob, amount => c_max_raw_size, offset => l_offset);
        
        utl_http.write_raw(l_http_request, l_raw);

        l_nr_bytes_to_write := l_nr_bytes_to_write - c_max_raw_size;
        l_offset := l_offset + c_max_raw_size;
      end loop;
    end if;

    l_http_response := utl_http.get_response(l_http_request);

    apex_web_service.g_status_code := l_http_response.status_code;

    dbms_lob.createtemporary(p_body_clob, true);

    begin
      loop
        utl_http.read_text(l_http_response, l_text, c_max_text_size);
        dbms_lob.writeappend
        ( lob_loc => p_body_clob
        , amount => length(l_text)
        , buffer => l_text
        );   
      end loop;
    exception
      when utl_http.end_of_body 
      then
        /*
        -- If the response body returned by the remote Web server is encoded in chunked transfer encoding format,
        -- the trailer headers that are returned at the end of the response body will be added to the response,
        -- and the response header count will be updated. You can retrieve the additional headers
        -- after the end of the response body is reached and before you end the response.
        */
        l_header_count := utl_http.get_header_count(l_http_response);
        for i_header_idx in 1..l_header_count
        loop
          utl_http.get_header
          ( r => l_http_response
          , n => i_header_idx
          , name => apex_web_service.g_headers(i_header_idx).name
          , value => apex_web_service.g_headers(i_header_idx).value
          );
        end loop;

        utl_http.end_response(l_http_response);
    end;

    if p_body_blob is not null
    then
      dbms_lob.freetemporary(p_body_blob);
      p_body_blob := null;
    end if;

    utl_http.get_cookies(cookies => apex_web_service.g_response_cookies);
  end utl_http_request;
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.RESPONSE');
$end

  if l_parms is not null
  then
    for i_idx in l_parms_keys.first .. l_parms_keys.last
    loop
      l_parm_names(l_parm_names.count+1) := l_parms_keys(i_idx);
      l_parm_values(l_parm_values.count+1) := l_parms.get(l_parms_keys(i_idx)).stringify;
    end loop;
  end if;

  web_service_pkg.json2data(l_cookies, apex_web_service.g_request_cookies);
  web_service_pkg.json2data(l_http_headers, apex_web_service.g_request_headers);

  if self.binary_response = 0
  then
    -- Prefer utl_http over apex_web_service since it is more performant.
    -- But only for simple calls.

    if simple_request
    then
$if oracle_tools.cfg_pkg.c_debugging $then
      dbug.print(dbug."info", 'Using UTL_HTTP.BEGIN_REQUEST to issue the REST webservice');
$end

      utl_http_request(l_body_clob, l_body_blob);
    else
    
$if oracle_tools.cfg_pkg.c_debugging $then
      dbug.print(dbug."info", 'Using APEX_WEB_SERVICE.MAKE_REST_REQUEST to issue the REST webservice');
$end

      l_body_clob := apex_web_service.make_rest_request
                     ( p_url => self.url
                     , p_http_method => self.http_method
                     , p_username => null
                     , p_password => null
                     , p_scheme => self.scheme
                     , p_proxy_override => self.proxy_override
                     , p_transfer_timeout => self.transfer_timeout
                     , p_body => case when l_body_clob is not null then l_body_clob else empty_clob() end
                     , p_body_blob => case when l_body_blob is not null then l_body_blob else empty_blob() end
                     , p_parm_name => l_parm_names
                     , p_parm_value => l_parm_values
                     , p_wallet_path => self.wallet_path
                     , p_wallet_pwd => null
                     , p_https_host => self.https_host
                     , p_credential_static_id => self.credential_static_id
                     , p_token_url => self.token_url
                     );
    end if;                    
  else
$if oracle_tools.cfg_pkg.c_debugging $then
    dbug.print(dbug."info", 'Using APEX_WEB_SERVICE.MAKE_REST_REQUEST_B to issue the REST webservice');
$end

    l_body_blob := apex_web_service.make_rest_request_b
                   ( p_url => self.url
                   , p_http_method => self.http_method
                   , p_username => null
                   , p_password => null
                   , p_scheme => self.scheme
                   , p_proxy_override => self.proxy_override
                   , p_transfer_timeout => self.transfer_timeout
                   , p_body => case when l_body_clob is not null then l_body_clob else empty_clob() end
                   , p_body_blob => case when l_body_blob is not null then l_body_blob else empty_blob() end
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

  l_web_service_response :=
    web_service_response_typ
    ( p_web_service_request => self
    , p_http_status_code => apex_web_service.g_status_code
    , p_body_clob => l_body_clob
    , p_body_blob => l_body_blob
    , p_cookies_clob => case when l_cookies is not null then l_cookies.to_clob() end
    , p_http_headers_clob => case when l_http_headers is not null then l_http_headers.to_clob() end
    );

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
$end

  return l_web_service_response;
end response;

end;
/

