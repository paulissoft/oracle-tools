CREATE OR REPLACE PACKAGE BODY "WEB_SERVICE_PKG" AS

c_timestamp_format constant varchar2(30) := 'YYYYMMDDHH24MISSXFF';

$if msg_aq_pkg.c_testing $then

c_wait_timeout constant positiven := 60;

$end -- $if msg_aq_pkg.c_testing $then

g_body_clob clob := null;
g_body_blob blob := null;

$if not(oracle_tools.cfg_pkg.c_apex_installed) $then

g_request_cookies          sys.utl_http.cookie_table;
g_response_cookies         sys.utl_http.cookie_table;

g_headers                  header_table;
g_request_headers          header_table;

g_status_code              http_status_code_t;
g_reason_phrase            http_reason_phrase_t;

$end

-- LOCAL

$if web_service_pkg.c_prefer_to_use_utl_http $then

function simple_request
( p_request in rest_web_service_request_typ
)
return boolean
is
  l_simple_request constant boolean :=
    p_request.proxy_override is null and
    p_request.https_host is null and
    p_request.credential_static_id is null and
    p_request.token_url is null;
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.print
  ( dbug."info"
  , 'simple request: %s (p_request.proxy_override is null: %s; p_request.https_host is null: %s; p_request.credential_static_id is null: %s; p_request.token_url is null: %s)'
  , dbug.cast_to_varchar2(l_simple_request)
  , dbug.cast_to_varchar2(p_request.proxy_override is null)
  , dbug.cast_to_varchar2(p_request.https_host is null)
  , dbug.cast_to_varchar2(p_request.credential_static_id is null)
  , dbug.cast_to_varchar2(p_request.token_url is null)
  );
$end

  return l_simple_request;
end simple_request;

procedure utl_http_request
( p_request in rest_web_service_request_typ
, p_body_clob in out nocopy clob -- on input the request body, on output the response body
, p_body_blob in out nocopy blob -- on input the request body, on output the response body
, p_parm_names in vc_arr2
, p_parm_values in vc_arr2
, p_username in varchar2
, p_password in varchar2
, p_scheme in varchar2
, p_wallet_path in varchar2
, p_wallet_pwd in varchar2
, p_request_cookies in sys.utl_http.cookie_table
, p_request_headers in header_table
, p_response_cookies out nocopy sys.utl_http.cookie_table
, p_response_headers out nocopy header_table
, p_status_code out nocopy http_status_code_t
, p_reason_phrase out nocopy http_reason_phrase_t
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
  -- for dbms_lob.converttoblob
  l_dest_offset integer := 1;
  l_src_offset integer := 1;
  l_lang number := dbms_lob.default_lang_ctx;
  l_warning integer;
begin
  if p_body_clob is null or dbms_lob.getlength(p_body_clob) = 0
  then
    copy_parameters
    ( p_parm_names => p_parm_names
    , p_parm_values => p_parm_values
    , p_url_encode => true
    , p_body_clob => p_body_clob
    );
  end if;
  
  if p_body_clob is not null
  then
    dbms_lob.trim(g_body_blob, 0);
    dbms_lob.converttoblob
    ( /*dest_lob => */g_body_blob
    , /*src_lob => */p_body_clob
    , /*amount => */dbms_lob.getlength(p_body_clob)
    , /*dest_offset => */l_dest_offset
    , /*src_offset => */l_src_offset
    , /*blob_csid => */dbms_lob.default_csid
    , /*lang_context => */l_lang
    , /*warning => */l_warning
    );
    p_body_clob := null;
    p_body_blob := g_body_blob;
  end if;
  -- request body is in p_body_blob, if any

  utl_http.set_wallet(p_wallet_path, p_wallet_pwd);
  utl_http.set_transfer_timeout(p_request.transfer_timeout);
  utl_http.clear_cookies;
  utl_http.add_cookies(p_request_cookies);

  l_http_request := utl_http.begin_request(p_request.url, p_request.http_method);

  if p_username is not null
  then
    utl_http.set_authentication
    ( r => l_http_request
    , username => p_username
    , password => p_password
    , scheme => nvl(p_scheme, 'Basic')
    );
  end if;

  if p_request_headers.count > 0
  then
    for i_idx in p_request_headers.first .. p_request_headers.last
    loop
      if p_request_headers(i_idx).name not in ('Content-Length'/*, 'Accept', 'User-Agent'*/)
      then
        utl_http.set_header(l_http_request, p_request_headers(i_idx).name, p_request_headers(i_idx).value);
      end if;
    end loop;
  end if;

  -- utl_http.set_header(l_http_request, 'Accept', '*/*');
  -- utl_http.set_header(l_http_request, 'User-Agent', 'APEX');

  l_nr_bytes_to_write := case when p_body_blob is null then 0 else dbms_lob.getlength(p_body_blob) end;
  utl_http.set_header(l_http_request, 'Content-Length', l_nr_bytes_to_write);

  while l_nr_bytes_to_write > 0
  loop
    l_raw := dbms_lob.substr(lob_loc => p_body_blob, amount => c_max_raw_size, offset => l_offset);
    utl_http.write_raw(l_http_request, l_raw);
    l_nr_bytes_to_write := l_nr_bytes_to_write - c_max_raw_size; -- may be too much if l_raw is not fully filled but that does not hurt
    l_offset := l_offset + c_max_raw_size;
  end loop;

  l_http_response := utl_http.get_response(l_http_request);

  p_status_code := l_http_response.status_code;
  p_reason_phrase := l_http_response.reason_phrase;

  begin
    if p_request.binary_response = 0
    then
      -- read text
      dbms_lob.trim(g_body_clob, 0);
      loop
        utl_http.read_text(l_http_response, l_text, c_max_text_size);
        dbms_lob.writeappend
        ( lob_loc => g_body_clob
        , amount => length(l_text)
        , buffer => l_text
        );   
      end loop;
    else
      -- read binary
      dbms_lob.trim(g_body_blob, 0);
      loop
        utl_http.read_raw(l_http_response, l_raw, c_max_raw_size);
        dbms_lob.writeappend
        ( lob_loc => g_body_blob
        , amount => utl_raw.length(l_raw)
        , buffer => l_raw
        );   
      end loop;
    end if;
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
        , name => p_response_headers(i_header_idx).name
        , value => p_response_headers(i_header_idx).value
        );
      end loop;

      utl_http.get_cookies(cookies => p_response_cookies);

      utl_http.end_response(l_http_response);
  end;

  if p_request.binary_response = 0
  then
    -- read text
    p_body_clob := g_body_clob;
    p_body_blob := null;
  else
    -- read binary
    p_body_clob := null;
    p_body_blob := g_body_blob;
  end if;
end utl_http_request;

$end -- $if web_service_pkg.c_prefer_to_use_utl_http $then

function get_hdr_array_idx
( p_header_name in varchar2
, p_request_headers in header_table
, p_skip_if_exists in boolean default false
)
return pls_integer -- returns null only when p_skip_if_exists and the header was found
is
  c_lower_header_name constant varchar2(32767) := lower(p_header_name);    
begin
  if p_request_headers.count > 0
  then
    for j in p_request_headers.first .. p_request_headers.last
    loop
      if lower(p_request_headers(j).name) = c_lower_header_name
      then
        return case when not p_skip_if_exists then j else null end;
      end if;
    end loop;
  end if;
  return nvl(p_request_headers.last, 0) + 1;
end get_hdr_array_idx;        

procedure set_request_headers
( p_name_01 in varchar2 default null
, p_value_01 in varchar2 default null
, p_name_02 in varchar2 default null
, p_value_02 in varchar2 default null
, p_name_03 in varchar2 default null
, p_value_03 in varchar2 default null
, p_name_04 in varchar2 default null
, p_value_04 in varchar2 default null
, p_name_05 in varchar2 default null
, p_value_05 in varchar2 default null
, p_reset in boolean default true
, p_skip_if_exists in boolean default false
, p_request_headers in out nocopy header_table
)
is
  procedure do_set_header
  ( p_name  in varchar2
  , p_value in varchar2
  )
  is
    l_array_idx pls_integer;
  begin
    if p_name is null then return; end if;

    pragma inline(get_hdr_array_idx, 'YES');
    l_array_idx := get_hdr_array_idx(p_name, p_request_headers, p_skip_if_exists);

    if l_array_idx is not null
    then
      p_request_headers(l_array_idx).name := p_name;
      p_request_headers(l_array_idx).value := p_value;
    end if;
  end do_set_header;
begin
  if p_reset
  then
    p_request_headers.delete;
  end if;

  do_set_header( p_name_01, p_value_01 );
  do_set_header( p_name_02, p_value_02 );
  do_set_header( p_name_03, p_value_03 );
  do_set_header( p_name_04, p_value_04 );
  do_set_header( p_name_05, p_value_05 );
end set_request_headers;

procedure remove_request_header
( p_name in varchar2
, p_request_headers in out nocopy header_table
)
is
  l_array_idx pls_integer;
begin
  if p_name is null then return; end if;

  pragma inline(get_hdr_array_idx, 'YES');
  l_array_idx := get_hdr_array_idx(p_name, p_request_headers);
  
  if l_array_idx between p_request_headers.first and p_request_headers.last
  then
    if l_array_idx < p_request_headers.last
    then
      p_request_headers(l_array_idx) := p_request_headers(p_request_headers.last);
    end if;
      
    p_request_headers.delete(p_request_headers.last);
  end if;
end remove_request_header;

procedure clear_request_headers
( p_request_headers in out nocopy header_table )
is
begin
  p_request_headers.delete;
end clear_request_headers;

procedure handle_response
( p_response in web_service_response_typ -- The REST request response
, p_http_status_code out nocopy http_status_code_t
, p_http_status_description out nocopy http_status_description_t
, p_http_reason_phrase out nocopy http_reason_phrase_t
, p_body_clob out nocopy clob
, p_body_blob out nocopy blob
)
is
$if oracle_tools.cfg_pkg.c_debugging $then
  l_clob clob;
$end
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.HANDLE_RESPONSE');
$end

  p_http_status_code := p_response.http_status_code;
  if p_http_status_code is null
  then
    raise value_error;
  end if;
  
  -- From https://www.oxitsolutions.co.uk/blog/http-status-code-cheat-sheet-infographic
  p_http_status_description :=
    case p_http_status_code
      -- 1XX - Information

      when 100 then 'Continue'
      when 101 then 'Switching Protocols'
      when 102 then 'Processing'
      when 103 then 'Early Hints'

      -- 2XX - Success

      when 200 then 'OK'
      when 201 then 'Created'
      when 202 then 'Accepted'
      when 203 then 'Non-authoritative Information'
      when 205 then 'Reset Content'
      when 206 then 'Partial Content'
      when 207 then 'Multi-status (WebDAV)'
      when 208 then 'Already Reported (WebDAV)'
      when 226 then 'IM Used (HTTP Delta Encoding)'

      -- 3XX - Redirection

      when 300 then 'Multiple Choices'
      when 301 then 'Moved Permanently'
      when 302 then 'Found'
      when 303 then 'See Other'
      when 304 then 'Not Modified'
      when 304 then 'Use Proxy'
      when 306 then 'Unused'
      when 307 then 'Temporary Redirect'
      when 308 then 'Permanent Redirect'

      -- 4XX - Client Error

      when 400 then 'Bad Request'
      when 401 then 'Unauthorised'
      when 402 then 'Payment Required'
      when 403 then 'Forbidden'
      when 404 then 'Not Found'
      when 405 then 'Method Not Allowed'
      when 406 then 'Not Acceptable'
      when 407 then 'Proxy Authentication Required'
      when 408 then 'Request Timeout'
      when 409 then 'Conflict'
      when 410 then 'Gone'
      when 411 then 'Length Required'
      when 412 then 'Precondition Failed'
      when 413 then 'Payload Too Large'
      when 414 then 'URI Too Large'
      when 415 then 'Unsupported Media Type'
      when 416 then 'Range Not Satisfiable'
      when 417 then 'Exception Failed'
      when 418 then 'I’m a Teapot'
      when 421 then 'Misdirected Request'
      when 422 then 'Unpossessable Entity (WebDAV)'
      when 423 then 'Locked (WebDAV)'
      when 424 then 'Failed '
      when 425 then 'Too Early'
      when 426 then 'Upgrade Required'
      when 428 then 'Precondition Required'
      when 429 then 'Too Many Requests'
      when 431 then 'Request Header Fields too Large'
      when 451 then 'Unavailable for Legal Reasons'
      when 499 then 'Client Closed Request'

      -- 5XX - Server Error Responses

      when 500 then 'Internal Server Error'
      when 501 then 'Not Implemented'
      when 502 then 'Bad Gateway'
      when 503 then 'Service Unavailable'
      when 504 then 'Gateway Timeout'
      when 505 then 'HTTP Version Not Supported'
      when 507 then 'Insufficient Storage (WebDAV)'
      when 508 then 'Loop Detected (WebDAV)'
      when 510 then 'Not Extended'
      when 511 then 'Network Authentication Required'
      when 599 then 'Network Connection Timeout Error'

      else 'Unknown HTTP status code ' || to_char(p_http_status_code)
    end;

  p_http_reason_phrase := p_response.http_reason_phrase;

  p_body_clob :=
    case
      when p_response.body_vc is not null
      then to_clob(p_response.body_vc)
      when p_response.body_clob is not null
      then p_response.body_clob
    end;
    
  p_body_blob := 
    case
      when p_response.body_raw is not null
      then to_blob(p_response.body_raw)
      when p_response.body_blob is not null
      then p_response.body_blob
    end;

  if not(p_http_status_code between 200 and 299)
  then
    raise_application_error
    ( -20000 + -1 * p_http_status_code
    , utl_lms.format_message('HTTP status description: %s; HTTP reason phrase: %s', p_http_status_description, p_http_reason_phrase)
    );
  end if;

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.print
  ( dbug."output"
  , 'p_http_status_code: %s; p_http_status_description: %s; p_http_reason_phrase: %s'
  , p_http_status_code
  , p_http_status_description
  , p_http_reason_phrase
  );
  dbug.leave;
exception
  when others
  then
    l_clob :=
      case
        when p_response.cookies_vc is not null
        then to_clob(p_response.cookies_vc)
        else p_response.cookies_clob
      end;
    dbug.print
    ( dbug."error"
    , 'cookies: %s'
    , dbms_lob.substr(lob_loc => l_clob, amount => 2000)
    );
    l_clob :=
      case
        when p_response.http_headers_vc is not null
        then to_clob(p_response.http_headers_vc)
        else p_response.http_headers_clob
      end;
    dbug.print
    ( dbug."error"
    , 'HTTP headers: %s'
    , dbms_lob.substr(lob_loc => l_clob, amount => 2000)
    );
    dbug.leave_on_error;
    raise;
$end
end handle_response;

-- PUBLIC

procedure json2data
( p_cookies in json_array_t
, p_cookie_tab out nocopy sys.utl_http.cookie_table
)
is
  l_cookie json_object_t;
begin
  if p_cookies is not null
  then
    for i_idx in 0 .. p_cookies.get_size - 1 -- 0 based
    loop
      /*
      -- A PL/SQL record type that represents a HTTP cookie
      TYPE cookie IS RECORD (
        name     VARCHAR2(4096),  -- Cookie name
        value    VARCHAR2(4096),  -- Cookie value
        domain   VARCHAR2(256),   -- Domain for which the cookie applies
        expire   TIMESTAMP WITH TIME ZONE,  -- When should the cookie expire ?
        path     VARCHAR2(1024),  -- Virtual path for which the cookie applies
        secure   BOOLEAN,         -- Should the cookie be transferred by HTTPS only
        version  PLS_INTEGER,     -- Cookie specification version
        comment  VARCHAR2(1024)   -- Comments about this cookie
      );
      -- A PL/SQL table of cookies
      TYPE cookie_table IS TABLE OF cookie INDEX BY BINARY_INTEGER;
      */
      
      l_cookie := treat(p_cookies.get(i_idx) as json_object_t);
      
      p_cookie_tab(i_idx + 1).name := l_cookie.get_string('name');
      p_cookie_tab(i_idx + 1).value := l_cookie.get_string('value');
      p_cookie_tab(i_idx + 1).domain := l_cookie.get_string('domain');
      p_cookie_tab(i_idx + 1).expire := to_timestamp(l_cookie.get_string('expire'), c_timestamp_format);
      p_cookie_tab(i_idx + 1).path := l_cookie.get_string('path');
      p_cookie_tab(i_idx + 1).secure := l_cookie.get_boolean('secure');
      p_cookie_tab(i_idx + 1).version := l_cookie.get_number('version');
      p_cookie_tab(i_idx + 1).comment := l_cookie.get_string('comment');
    end loop;
  end if;  
end json2data;

procedure data2json
( p_cookie_tab in sys.utl_http.cookie_table
, p_cookies out nocopy json_array_t
)
is
  l_cookie json_object_t;
begin
  if p_cookie_tab.count = 0
  then
    p_cookies := null;
  else
    p_cookies := json_array_t();
    
    for i_idx in p_cookie_tab.first .. p_cookie_tab.last
    loop
      l_cookie := json_object_t();
      
      /*
      -- A PL/SQL record type that represents a HTTP cookie
      TYPE cookie IS RECORD (
        name     VARCHAR2(4096),  -- Cookie name
        value    VARCHAR2(4096),  -- Cookie value
        domain   VARCHAR2(256),   -- Domain for which the cookie applies
        expire   TIMESTAMP WITH TIME ZONE,  -- When should the cookie expire ?
        path     VARCHAR2(1024),  -- Virtual path for which the cookie applies
        secure   BOOLEAN,         -- Should the cookie be transferred by HTTPS only
        version  PLS_INTEGER,     -- Cookie specification version
        comment  VARCHAR2(1024)   -- Comments about this cookie
      );
      -- A PL/SQL table of cookies
      TYPE cookie_table IS TABLE OF cookie INDEX BY BINARY_INTEGER;
      */
      
      l_cookie.put('name', p_cookie_tab(i_idx).name);
      l_cookie.put('value', p_cookie_tab(i_idx).value);
      l_cookie.put('domain', p_cookie_tab(i_idx).domain);
      l_cookie.put('expire', to_timestamp(p_cookie_tab(i_idx).expire, c_timestamp_format));
      l_cookie.put('path', p_cookie_tab(i_idx).path);
      l_cookie.put('secure', p_cookie_tab(i_idx).secure);
      l_cookie.put('version', p_cookie_tab(i_idx).version);
      l_cookie.put('comment', p_cookie_tab(i_idx).comment);

      p_cookies.append(l_cookie);
    end loop;
  end if;
end data2json;

function data2json
( p_cookie_tab in sys.utl_http.cookie_table
)
return clob
is
  l_cookies json_array_t;
begin
  data2json(p_cookie_tab, l_cookies);
  return case when l_cookies is not null then l_cookies.to_clob end;
end data2json;

procedure json2data
( p_http_headers in json_array_t
, p_http_header_tab out nocopy header_table
)
is
  l_http_header json_object_t;
  l_http_header_keys json_key_list;
begin
  if p_http_headers is not null
  then
    for i_header_idx in 0 .. p_http_headers.get_size - 1 -- 0 based
    loop
      /*
      type header is record (
        name       varchar2(256),
        value      varchar2(32767) );

      type header_table is table of header index by binary_integer;
      */
      
      l_http_header := treat(p_http_headers.get(i_header_idx) as json_object_t);
      l_http_header_keys := l_http_header.get_keys();
      
      if l_http_header_keys.count = 0
      then
        continue;
      end if;
      
      for i_key_idx in l_http_header_keys.first .. l_http_header_keys.last
      loop
        p_http_header_tab(p_http_header_tab.count+1).name := l_http_header_keys(i_key_idx);
        p_http_header_tab(p_http_header_tab.count+0).value := l_http_header.get_string(l_http_header_keys(i_key_idx));
      end loop;
    end loop;
  end if;
end json2data;

procedure data2json
( p_http_header_tab in header_table
, p_http_headers out nocopy json_array_t
)
is
  l_http_header json_object_t;
begin
  if p_http_header_tab.count = 0
  then
    p_http_headers := null;
  else
    p_http_headers := json_array_t();
    
    for i_idx in p_http_header_tab.first .. p_http_header_tab.last
    loop
      l_http_header := json_object_t();
      
      /*
      type header is record (
        name       varchar2(256),
        value      varchar2(32767) );

      type header_table is table of header index by binary_integer;
      */
      
      l_http_header.put(p_http_header_tab(i_idx).name, p_http_header_tab(i_idx).value);

      p_http_headers.append(l_http_header);
    end loop;
  end if;
end data2json;

procedure data2json
( p_http_headers out nocopy json_array_t
)
is
begin
  data2json
  ( p_http_header_tab => $if oracle_tools.cfg_pkg.c_apex_installed $then apex_web_service.g_request_headers $else g_request_headers $end
  , p_http_headers => p_http_headers
  );
end data2json;

function data2json
( p_http_header_tab in header_table
)
return clob
is
  l_http_headers json_array_t;
begin
  data2json(p_http_header_tab, l_http_headers);
  return case when l_http_headers is not null then l_http_headers.to_clob end;
end data2json;

function data2json
return clob
is
begin
  return data2json(p_http_header_tab => $if oracle_tools.cfg_pkg.c_apex_installed $then apex_web_service.g_request_headers $else g_request_headers $end);
end data2json;

procedure set_request_headers
( p_name_01 in varchar2
, p_value_01 in varchar2
, p_name_02 in varchar2
, p_value_02 in varchar2
, p_name_03 in varchar2
, p_value_03 in varchar2
, p_name_04 in varchar2
, p_value_04 in varchar2
, p_name_05 in varchar2
, p_value_05 in varchar2
, p_reset in boolean
, p_skip_if_exists in boolean
)
is
begin
  set_request_headers
  ( p_name_01 => p_name_01
  , p_value_01 => p_value_01
  , p_name_02 => p_name_02
  , p_value_02 => p_value_02
  , p_name_03 => p_name_03
  , p_value_03 => p_value_03
  , p_name_04 => p_name_04
  , p_value_04 => p_value_04
  , p_name_05 => p_name_05
  , p_value_05 => p_value_05
  , p_reset => p_reset
  , p_skip_if_exists => p_skip_if_exists
  , p_request_headers => $if oracle_tools.cfg_pkg.c_apex_installed $then apex_web_service.g_request_headers $else g_request_headers $end
  );
end set_request_headers;

procedure remove_request_header
( p_name in varchar2
)
is
begin
  remove_request_header
  ( p_name => p_name
  , p_request_headers => $if oracle_tools.cfg_pkg.c_apex_installed $then apex_web_service.g_request_headers $else g_request_headers $end
  );
end remove_request_header;

procedure clear_request_headers
is
begin
  clear_request_headers
  ( p_request_headers => $if oracle_tools.cfg_pkg.c_apex_installed $then apex_web_service.g_request_headers $else g_request_headers $end
  );
end clear_request_headers;

procedure copy_parameters
( p_parm_names in vc_arr2
, p_parm_values in vc_arr2
, p_url_encode in boolean
, p_body_clob out nocopy clob
)
is
  function url_encode2
  ( p_str in varchar2
  )
  return varchar2
  as
    x varchar2(32767);
  begin
    x := replace(p_str, '%', '%25');
    x := replace(x,     '+', '%2B');
    x := replace(x,     ' ', '+'  );
    x := replace(x,     '.', '%2E');
    x := replace(x,     '*', '%2A');
    x := replace(x,     '?', '%3F');
    x := replace(x,     '\', '%5C');
    x := replace(x,     '/', '%2F');
    x := replace(x,     '>', '%3E');
    x := replace(x,     '<', '%3C');
    x := replace(x,     '{', '%7B');
    x := replace(x,     '}', '%7D');
    x := replace(x,     '~', '%7E');
    x := replace(x,     '[', '%5B');
    x := replace(x,     ']', '%5D');
    x := replace(x,     '`', '%60');
    x := replace(x,     ';', '%3B');
    x := replace(x,     '?', '%3F');
    x := replace(x,     '@', '%40');
    x := replace(x,     '&', '%26');
    x := replace(x,     '#', '%23');
    x := replace(x,     '|', '%7C');
    x := replace(x,     '^', '%5E');
    x := replace(x,     ':', '%3A');
    x := replace(x,     '=', '%3D');
    x := replace(x,     '$', '%24');
    return x;
  end url_encode2;
begin
  if p_parm_names.count > 0
  then
    for i_idx in p_parm_names.first .. p_parm_names.last
    loop
      p_body_clob :=
        case
          when i_idx > 1 then p_body_clob || '&'
        end ||
        p_parm_names(i_idx) ||
        '=' ||
        case
          when p_url_encode
          then url_encode2(p_parm_values(i_idx))
          else p_parm_values(i_idx)
        end;
    end loop;
  end if;
end copy_parameters;

procedure copy_parameters
( p_name_01 in varchar2
, p_value_01 in varchar2
, p_name_02 in varchar2
, p_value_02 in varchar2
, p_name_03 in varchar2
, p_value_03 in varchar2
, p_name_04 in varchar2
, p_value_04 in varchar2
, p_name_05 in varchar2
, p_value_05 in varchar2
, p_url_encode in boolean
, p_body_clob out nocopy clob
)
is
  l_parm_names vc_arr2;
  l_parm_values vc_arr2;

  procedure do_set_parameter
  ( p_name  in varchar2
  , p_value in varchar2
  )
  is
  begin
    if p_name is null then return; end if;

    l_parm_names(l_parm_names.count+1) := p_name;
    l_parm_values(l_parm_values.count+1) := p_value;
  end do_set_parameter;
begin
  do_set_parameter( p_name_01, p_value_01 );
  do_set_parameter( p_name_02, p_value_02 );
  do_set_parameter( p_name_03, p_value_03 );
  do_set_parameter( p_name_04, p_value_04 );
  do_set_parameter( p_name_05, p_value_05 );

  copy_parameters
  ( p_parm_names => l_parm_names 
  , p_parm_values => l_parm_values 
  , p_url_encode => p_url_encode 
  , p_body_clob => p_body_clob
  );
end copy_parameters;

$if oracle_tools.cfg_pkg.c_apex_installed $then

function make_rest_request
( p_request in rest_web_service_request_typ
, p_username in varchar2
, p_password in varchar2
, p_wallet_pwd in varchar2
)
return web_service_response_typ
is
  l_parm_names vc_arr2 := empty_vc_arr;
  l_parm_values vc_arr2 := empty_vc_arr;
  l_parms constant json_object_t := 
    case
      when p_request.parms_vc is not null
      then json_object_t(p_request.parms_vc)
      when p_request.parms_clob is not null
      then json_object_t(p_request.parms_clob)
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
      when p_request.cookies_vc is not null
      then json_array_t(p_request.cookies_vc)
      when p_request.cookies_clob is not null
      then json_array_t(p_request.cookies_clob)
      else null
    end;
  l_http_headers json_array_t := 
    case
      when p_request.http_headers_vc is not null
      then json_array_t(p_request.http_headers_vc)
      when p_request.http_headers_clob is not null
      then json_array_t(p_request.http_headers_clob)
      else null
    end;
  l_body_clob clob :=
    case
      when p_request.body_vc is not null
      then to_clob(p_request.body_vc)
      when p_request.body_clob is not null
      then p_request.body_clob
    end;
  l_body_blob blob := 
    case
      when p_request.body_raw is not null
      then to_blob(p_request.body_raw)
      when p_request.body_blob is not null
      then p_request.body_blob
    end;
  l_web_service_response web_service_response_typ := null;
$if oracle_tools.cfg_pkg.c_debugging $then
  l_start constant number := dbms_utility.get_time;
$end  
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.MAKE_REST_REQUEST');
$end

  if l_parms is not null and l_parms_keys.count > 0
  then
    for i_idx in l_parms_keys.first .. l_parms_keys.last
    loop
      l_parm_names(l_parm_names.count+1) := l_parms_keys(i_idx);
      l_parm_values(l_parm_values.count+1) := l_parms.get(l_parms_keys(i_idx)).stringify;
    end loop;
  end if;

  pragma inline (json2data, 'YES');
  json2data(l_cookies, apex_web_service.g_request_cookies);
  pragma inline (json2data, 'YES');
  json2data(l_http_headers, apex_web_service.g_request_headers);

  -- Do we prefer utl_http over apex_web_service since it is more performant?
  -- But only for simple calls.
  case
$if web_service_pkg.c_prefer_to_use_utl_http $then
  
    when simple_request(p_request)
    then
$if oracle_tools.cfg_pkg.c_debugging $then
      dbug.print(dbug."info", 'Using UTL_HTTP.BEGIN_REQUEST to issue the REST webservice');
$end

      utl_http_request
      ( p_request => p_request
      , p_body_clob => l_body_clob
      , p_body_blob => l_body_blob
      , p_parm_names => l_parm_names
      , p_parm_values => l_parm_values
      , p_username => p_username
      , p_password => p_password
      , p_scheme => p_request.scheme
      , p_wallet_path => p_request.wallet_path
      , p_wallet_pwd => p_wallet_pwd
      , p_request_cookies => apex_web_service.g_request_cookies
      , p_request_headers => apex_web_service.g_request_headers
      , p_response_cookies => apex_web_service.g_response_cookies
      , p_response_headers => apex_web_service.g_headers
      , p_status_code => apex_web_service.g_status_code
      , p_reason_phrase => apex_web_service.g_reason_phrase
      );
$end -- $if web_service_pkg.c_prefer_to_use_utl_http $then
      
    when p_request.binary_response = 0
    then
$if oracle_tools.cfg_pkg.c_debugging $then
      dbug.print(dbug."info", 'Using APEX_WEB_SERVICE.MAKE_REST_REQUEST to issue the REST webservice');
$end

      l_body_clob := apex_web_service.make_rest_request
                     ( p_url => p_request.url
                     , p_http_method => p_request.http_method
                     , p_username => p_username
                     , p_password => p_password
                     , p_scheme => p_request.scheme
/*APEX*/             , p_proxy_override => p_request.proxy_override
                     , p_transfer_timeout => p_request.transfer_timeout
                     , p_body => case when l_body_clob is not null then l_body_clob else empty_clob() end
                     , p_body_blob => case when l_body_blob is not null then l_body_blob else empty_blob() end
                     , p_parm_name => l_parm_names
                     , p_parm_value => l_parm_values
                     , p_wallet_path => p_request.wallet_path
                     , p_wallet_pwd => p_wallet_pwd
/*APEX*/             , p_https_host => p_request.https_host
/*APEX*/             , p_credential_static_id => p_request.credential_static_id
/*APEX*/             , p_token_url => p_request.token_url
                     );
      l_body_blob := null;

    else
$if oracle_tools.cfg_pkg.c_debugging $then
      dbug.print(dbug."info", 'Using APEX_WEB_SERVICE.MAKE_REST_REQUEST_B to issue the REST webservice');
$end

      l_body_blob := apex_web_service.make_rest_request_b
                     ( p_url => p_request.url
                     , p_http_method => p_request.http_method
                     , p_username => p_username
                     , p_password => p_username
                     , p_scheme => p_request.scheme
/*APEX*/             , p_proxy_override => p_request.proxy_override
                     , p_transfer_timeout => p_request.transfer_timeout
                     , p_body => case when l_body_clob is not null then l_body_clob else empty_clob() end
                     , p_body_blob => case when l_body_blob is not null then l_body_blob else empty_blob() end
                     , p_parm_name => l_parm_names
                     , p_parm_value => l_parm_values
                     , p_wallet_path => p_request.wallet_path
                     , p_wallet_pwd => null
/*APEX*/             , p_https_host => p_request.https_host
/*APEX*/             , p_credential_static_id => p_request.credential_static_id
/*APEX*/             , p_token_url => p_request.token_url
                     );
      l_body_clob := null;
  end case;

  pragma inline (data2json, 'YES');
  data2json(apex_web_service.g_response_cookies, l_cookies);
  pragma inline (data2json, 'YES');
  data2json(apex_web_service.g_headers, l_http_headers);

  l_web_service_response :=
    web_service_response_typ
    ( p_web_service_request => p_request
    , p_sql_code => sqlcode -- 0
    , p_sql_error_message => sqlerrm -- null
    , p_http_status_code => apex_web_service.g_status_code
    , p_body_clob => l_body_clob
    , p_body_blob => l_body_blob
    , p_cookies_clob => case when l_cookies is not null then l_cookies.to_clob() end
    , p_http_headers_clob => case when l_http_headers is not null then l_http_headers.to_clob() end
    , p_http_reason_phrase => substrb(apex_web_service.g_reason_phrase, 1, 4000)
    );

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.print(dbug."info", 'REST webservice issued in %s milliseconds', (dbms_utility.get_time - l_start) * 10);
  dbug.leave;
$end

  return l_web_service_response;
exception
  when others
  then
$if oracle_tools.cfg_pkg.c_debugging $then
    dbug.print(dbug."info", 'REST webservice issued in %s milliseconds', (dbms_utility.get_time - l_start) * 10);
    dbug.leave_on_error;
$end

    return web_service_response_typ
           ( p_web_service_request => p_request
           , p_sql_code => sqlcode
           , p_sql_error_message => sqlerrm
           , p_http_status_code => null
           , p_body_clob => null
           , p_body_blob => null
           , p_cookies_clob => null
           , p_http_headers_clob => null
           , p_http_reason_phrase => null
           );
end make_rest_request;

$else -- $if oracle_tools.cfg_pkg.c_apex_installed $then

function make_rest_request
( p_request in rest_web_service_request_typ
, p_username in varchar2
, p_password in varchar2
, p_wallet_pwd in varchar2
)
return web_service_response_typ
is
  l_parm_names vc_arr2 := empty_vc_arr;
  l_parm_values vc_arr2 := empty_vc_arr;
  l_parms constant json_object_t := 
    case
      when p_request.parms_vc is not null
      then json_object_t(p_request.parms_vc)
      when p_request.parms_clob is not null
      then json_object_t(p_request.parms_clob)
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
      when p_request.cookies_vc is not null
      then json_array_t(p_request.cookies_vc)
      when p_request.cookies_clob is not null
      then json_array_t(p_request.cookies_clob)
      else null
    end;
  l_http_headers json_array_t := 
    case
      when p_request.http_headers_vc is not null
      then json_array_t(p_request.http_headers_vc)
      when p_request.http_headers_clob is not null
      then json_array_t(p_request.http_headers_clob)
      else null
    end;
  l_body_clob clob :=
    case
      when p_request.body_vc is not null
      then to_clob(p_request.body_vc)
      when p_request.body_clob is not null
      then p_request.body_clob
    end;
  l_body_blob blob := 
    case
      when p_request.body_raw is not null
      then to_blob(p_request.body_raw)
      when p_request.body_blob is not null
      then p_request.body_blob
    end;
  l_web_service_response web_service_response_typ := null;
$if oracle_tools.cfg_pkg.c_debugging $then
  l_start constant number := dbms_utility.get_time;
$end  
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.MAKE_REST_REQUEST');
$end

$if web_service_pkg.c_prefer_to_use_utl_http $then

  if l_parms is not null and l_parms_keys.count > 0
  then
    for i_idx in l_parms_keys.first .. l_parms_keys.last
    loop
      l_parm_names(l_parm_names.count+1) := l_parms_keys(i_idx);
      l_parm_values(l_parm_values.count+1) := l_parms.get(l_parms_keys(i_idx)).stringify;
    end loop;
  end if;

  pragma inline (json2data, 'YES');
  json2data(l_cookies, g_request_cookies);
  pragma inline (json2data, 'YES');
  json2data(l_http_headers, g_request_headers);
  
  if simple_request(p_request)
  then
$if oracle_tools.cfg_pkg.c_debugging $then
    dbug.print(dbug."info", 'Using UTL_HTTP.BEGIN_REQUEST to issue the REST webservice');
$end

    if l_body_clob is null or dbms_lob.getlength(l_body_clob) = 0
    then
      copy_parameters
      ( p_parm_names => l_parm_names
      , p_parm_values => l_parm_values
      , p_url_encode => true
      , p_body_clob => l_body_clob
      );
    end if;

    utl_http_request
    ( p_request => p_request
    , p_body_clob => l_body_clob
    , p_body_blob => l_body_blob
    , p_parm_names => l_parm_names
    , p_parm_values => l_parm_values
    , p_username => p_username
    , p_password => p_password
    , p_scheme => p_request.scheme
    , p_wallet_path => p_request.wallet_path
    , p_wallet_pwd => p_wallet_pwd
    , p_request_cookies => g_request_cookies
    , p_request_headers => g_request_headers
    , p_response_cookies => g_response_cookies
    , p_response_headers => g_headers
    , p_status_code => g_status_code
    , p_reason_phrase => g_reason_phrase
    );
  else
    raise_application_error(-20000, 'The request is not simple enough and should be executed by APEX_WEB_SERVICE but APEX is not installed.');
  end if;

$else -- $if web_service_pkg.c_prefer_to_use_utl_http $then

  raise_application_error(-20000, 'APEX is not installed.');

$end -- $if web_service_pkg.c_prefer_to_use_utl_http $then

  pragma inline (data2json, 'YES');
  data2json(g_response_cookies, l_cookies);
  pragma inline (data2json, 'YES');
  data2json(g_headers, l_http_headers);

  l_web_service_response :=
    web_service_response_typ
    ( p_web_service_request => p_request
    , p_sql_code => sqlcode -- 0
    , p_sql_error_message => sqlerrm -- null
    , p_http_status_code => g_status_code
    , p_body_clob => l_body_clob
    , p_body_blob => l_body_blob
    , p_cookies_clob => case when l_cookies is not null then l_cookies.to_clob() end
    , p_http_headers_clob => case when l_http_headers is not null then l_http_headers.to_clob() end
    , p_http_reason_phrase => g_reason_phrase
    );

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.print(dbug."info", 'REST webservice issued in %s milliseconds', (dbms_utility.get_time - l_start) * 10);
  dbug.leave;
$end

  return l_web_service_response;
exception
  when others
  then
$if oracle_tools.cfg_pkg.c_debugging $then
    dbug.print(dbug."info", 'REST webservice issued in %s milliseconds', (dbms_utility.get_time - l_start) * 10);
    dbug.leave_on_error;
$end

    return web_service_response_typ
           ( p_web_service_request => p_request
           , p_sql_code => sqlcode
           , p_sql_error_message => sqlerrm
           , p_http_status_code => null
           , p_body_clob => null
           , p_body_blob => null
           , p_cookies_clob => null
           , p_http_headers_clob => null
           , p_http_reason_phrase => null
           );
end make_rest_request;

$end -- $if oracle_tools.cfg_pkg.c_apex_installed $then

function make_rest_request
( p_url in varchar2
, p_http_method in varchar2
, p_username in varchar2
, p_password in varchar2
, p_scheme in varchar2
, p_proxy_override in varchar2
, p_transfer_timeout in number
, p_body in clob
, p_body_blob in blob
, p_parm_name in vc_arr2
, p_parm_value in vc_arr2
, p_wallet_path in varchar2
, p_wallet_pwd in varchar2
, p_https_host in varchar2
, p_credential_static_id in varchar2
, p_token_url in varchar2
)
return web_service_response_typ
is
  l_rest_web_service_request rest_web_service_request_typ;
  l_web_service_response web_service_response_typ;
  l_parms json_object_t := json_object_t();
begin
  if p_parm_name.count > 0
  then
    for i_idx in p_parm_name.first .. p_parm_name.last
    loop
      l_parms.put(key => p_parm_name(i_idx), val => p_parm_value(i_idx));
    end loop;
  end if;

  l_rest_web_service_request :=
    new rest_web_service_request_typ
        ( p_context$ => null
        , p_url => p_url
        , p_scheme => p_scheme
        , p_proxy_override => p_proxy_override
        , p_transfer_timeout => p_transfer_timeout
        , p_wallet_path => p_wallet_path
        , p_https_host => p_https_host
        , p_credential_static_id => p_credential_static_id
        , p_token_url => p_token_url
        , p_cookies_clob => web_service_pkg.data2json($if oracle_tools.cfg_pkg.c_apex_installed $then apex_web_service.g_request_cookies $else g_request_cookies $end)
        , p_http_headers_clob => web_service_pkg.data2json($if oracle_tools.cfg_pkg.c_apex_installed $then apex_web_service.g_request_headers $else g_request_headers $end)        
        , p_http_method => p_http_method
        , p_body_clob => p_body
        , p_body_blob => p_body_blob
        , p_parms_clob => l_parms.stringify
        , p_binary_response => 0        
        );
  l_web_service_response :=
    web_service_pkg.make_rest_request
    ( p_request => l_rest_web_service_request
    , p_username => p_username
    , p_password => p_password
    , p_wallet_pwd => p_wallet_pwd
    );
    
  return l_web_service_response;
end make_rest_request;

procedure handle_response
( p_response in web_service_response_typ -- The REST request response
, p_http_status_code out nocopy http_status_code_t -- The HTTP status code
, p_http_status_description out nocopy http_status_description_t -- The HTTP status description
, p_http_reason_phrase out nocopy http_reason_phrase_t -- The HTTP reason phrase
, p_body_clob out nocopy clob -- The HTTP character body
)
is
  l_body_blob blob;
begin
  handle_response
  ( p_response => p_response
  , p_http_status_code => p_http_status_code
  , p_http_status_description => p_http_status_description
  , p_http_reason_phrase => p_http_reason_phrase
  , p_body_clob => p_body_clob
  , p_body_blob => l_body_blob
  );
end handle_response;

procedure handle_response
( p_response in web_service_response_typ -- The REST request response
, p_http_status_code out nocopy http_status_code_t -- The HTTP status code
, p_http_status_description out nocopy http_status_description_t -- The HTTP status description
, p_http_reason_phrase out nocopy http_reason_phrase_t -- The HTTP reason phrase
, p_body_blob out nocopy blob -- The HTTP binary body
)
is
  l_body_clob clob;
begin
  handle_response
  ( p_response => p_response
  , p_http_status_code => p_http_status_code
  , p_http_status_description => p_http_status_description
  , p_http_reason_phrase => p_http_reason_phrase
  , p_body_clob => l_body_clob
  , p_body_blob => p_body_blob
  );
end handle_response;

$if msg_aq_pkg.c_testing $then

-- PRIVATE

procedure ut_rest_web_service_get_bulk
( p_count in positiven
, p_stop_dequeue_before_enqueue in boolean
)
is
  pragma autonomous_transaction;

  l_correlation_tab sys.odcivarchar2list := sys.odcivarchar2list();
  l_msgid raw(16) := null;
  l_message_properties dbms_aq.message_properties_t;
  l_msg msg_typ;
  l_rest_web_service_request rest_web_service_request_typ;
  l_web_service_response web_service_response_typ;
  l_json_act json_element_t;
  l_json_exp constant json_object_t := json_object_t('{
  "userId": 1,
  "id": 1,
  "title": "delectus aut autem",
  "completed": false
}');
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.UT_REST_WEB_SERVICE_GET_BULK');
  dbug.print
  ( dbug."input"
  , 'p_count: %s; p_stop_dequeue_before_enqueue: %s'
  , p_count
  , dbug.cast_to_varchar2(p_stop_dequeue_before_enqueue)
  );
$end

  -- stop queue for dequeue only
  if p_stop_dequeue_before_enqueue
  then
    msg_aq_pkg.stop_queue(p_queue_name => 'WEB_SERVICE_REQUEST', p_enqueue => false, p_dequeue => true);
  end if;
  
  -- See https://terminalcheatsheet.com/guides/curl-rest-api

  -- % curl https://jsonplaceholder.typicode.com/todos/1
  --
  -- {
  --   "userId": 1,
  --   "id": 1,
  --   "title": "delectus aut autem",
  --   "completed": false
  -- }%

  for i_idx in 1..p_count
  loop
$if oracle_tools.cfg_pkg.c_debugging $then
    dbug.print(dbug."info", 'i_idx: %s', i_idx);
$end

    l_correlation_tab.extend(1);
    l_correlation_tab(l_correlation_tab.last) := web_service_request_typ.generate_unique_id();

    -- will just get enqueued here
    l_rest_web_service_request :=
      rest_web_service_request_typ
      ( p_context$ => l_correlation_tab(l_correlation_tab.last)
      , p_url => 'https://jsonplaceholder.typicode.com/todos/1'
      , p_http_method => 'GET'
      );

    l_rest_web_service_request.response().print; -- just invoke directly and print

    l_rest_web_service_request.process; -- invoke indirectly

    commit;

    if mod(i_idx, 10) = 0
    then
      dbms_session.sleep(1);
    end if;
  end loop;

  -- restart queue for enqueue and dequeue
  if p_stop_dequeue_before_enqueue
  then
    msg_aq_pkg.start_queue(p_queue_name => 'WEB_SERVICE_REQUEST', p_enqueue => true, p_dequeue => true);
  end if;

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.print
  ( dbug."info"
  , 'l_correlation_tab.first: %s; l_correlation_tab.last: %s'
  , l_correlation_tab.first
  , l_correlation_tab.last
  );
$end

  -- now the dequeue in reversed order (l_correlation_tab.count > 0 since p_count > 0)
  for i_idx in reverse l_correlation_tab.first .. l_correlation_tab.last
  loop
$if oracle_tools.cfg_pkg.c_debugging $then
    dbug.print(dbug."info", 'dequeueing l_correlation_tab(%s): %s', i_idx, l_correlation_tab(i_idx));
$end

    l_msgid := null;
    msg_aq_pkg.dequeue
    ( p_queue_name => web_service_response_typ.default_group()
    , p_delivery_mode => dbms_aq.persistent_or_buffered
    , p_visibility => dbms_aq.immediate
    , p_subscriber => null
    , p_dequeue_mode => dbms_aq.remove
      /*
      -- The correlation attribute specifies the correlation identifier of the dequeued message.
      -- The correlation identifier cannot be changed between successive dequeue calls without specifying the FIRST_MESSAGE navigation option.
      */
    , p_navigation => dbms_aq.first_message
    , p_wait => c_wait_timeout
    , p_correlation => l_correlation_tab(i_idx)
    , p_deq_condition => null
    , p_force => true
    , p_msgid => l_msgid
    , p_message_properties => l_message_properties
    , p_msg => l_msg
    );

$if msg_pkg.c_debugging >= 1 $then
    l_msg.print();
$end    
  
    commit;

    ut.expect(l_msg is of (web_service_response_typ), 'web service response object type').to_be_true();

    l_web_service_response := treat(l_msg as web_service_response_typ);

    -- ORA-29273: HTTP request failed?
    -- In bc_dev only when web_service_pkg.c_prefer_to_use_utl_http is true, on pato never
  
$if not(web_service_pkg.c_prefer_to_use_utl_http) $then
    ut.expect(l_web_service_response.sql_code, 'sql code').to_equal(0);
$end  

    if l_web_service_response.sql_code = 0
    then
      msg_pkg.msg2data(l_web_service_response.body_vc, l_web_service_response.body_clob, l_json_act);

      ut.expect(l_json_act, 'json').to_equal(l_json_exp);
    else
      ut.expect(l_web_service_response.sql_code, 'sql code').to_equal(-29273);  
      ut.expect(l_web_service_response.sql_error_message, 'sql error message').to_equal('ORA-29273: HTTP request failed');  
    end if;

    if mod(i_idx, 10) = 0
    then
      dbms_session.sleep(1);
    end if;
  end loop;

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end ut_rest_web_service_get_bulk;

procedure ut_rest_web_service_get
is
begin
  ut_rest_web_service_get_bulk(1, true);
end ut_rest_web_service_get;

-- PUBLIC

procedure ut_setup
is
  pragma autonomous_transaction;

  l_queue_name constant user_queues.name%type := msg_aq_pkg.get_queue_name(web_service_request_typ.default_group());
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.UT_SETUP');
$end
  for i_try in 1..2
  loop
    begin
      msg_aq_pkg.register
      ( p_queue_name => l_queue_name
      , p_subscriber => null
      , p_plsql_callback => $$PLSQL_UNIT_OWNER || '.' || 'MSG_NOTIFICATION_PRC'
      );
      exit;
    exception
      when msg_aq_pkg.e_queue_does_not_exist or msg_aq_pkg.e_fq_queue_does_not_exist
      then
$if oracle_tools.cfg_pkg.c_debugging $then
        dbug.on_error;
$end
        if i_try != 2
        then
          msg_aq_pkg.create_queue
          ( p_queue_name => l_queue_name
          , p_comment => 'Queue for table ' || replace(l_queue_name, '$', '.')
          );
        else
          raise;
        end if;      
    end;
  end loop;
  commit;
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
$end
end ut_setup;
  
procedure ut_teardown
is
  pragma autonomous_transaction;

  l_request_queue_name constant user_queues.name%type := msg_aq_pkg.get_queue_name(web_service_request_typ.default_group());
  l_response_queue_name constant user_queues.name%type := msg_aq_pkg.get_queue_name(web_service_response_typ.default_group());
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.UT_TEARDOWN');
$end
  if msg_constants_pkg.get_default_processing_method like 'plsql://%'
  then
    msg_aq_pkg.register
    ( p_queue_name => l_request_queue_name
    , p_subscriber => null
    , p_plsql_callback => replace(msg_constants_pkg.get_default_processing_method, 'plsql://')
    );
  else
    msg_aq_pkg.unregister
    ( p_queue_name => l_request_queue_name
    , p_subscriber => null
    , p_plsql_callback => '%'
    );
  end if;

  -- empty the response queue
  begin
    msg_aq_pkg.empty_queue
    ( p_queue_name => l_response_queue_name
    , p_dequeue_and_process => false
    );
  exception
    when msg_aq_pkg.e_queue_does_not_exist
    then null;
  end;

  commit;
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
$end
end ut_teardown;

procedure ut_set_request_headers
is
  l_request_headers header_table;

  procedure check_headers
  is
    l_name_exp varchar2(100);
    l_value_exp varchar2(100);
  begin
    for i_idx in l_request_headers.first .. l_request_headers.last
    loop
      l_name_exp := case i_idx when 1 then 'Content-Type' when 2 then 'Accept' when 3 then 'User-Agent' when 4 then 'Authorization' end;
      ut.expect(l_request_headers(i_idx).name, 'l_request_headers('||i_idx||').name').to_equal(l_name_exp);

      l_value_exp := case i_idx when 1 then 'application/json' when 2 then '*/*' when 3 then 'APEX' when 4 then 'Basic abacadabra' end;
      ut.expect(l_request_headers(i_idx).value, 'l_request_headers('||i_idx||').value').to_equal(l_value_exp);
    end loop;
  end check_headers;
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.UT_SET_REQUEST_HEADERS');
$end

  set_request_headers
  ( p_name_01 => 'Content-Type'
  , p_value_01 => 'application/json'
  , p_name_02 => 'Accept'
  , p_value_02 => '*/*'
  , p_name_03 => 'User-Agent'
  , p_value_03 => 'APEX'
  , p_request_headers => l_request_headers
  );

  ut.expect(l_request_headers.first, 'l_request_headers.first').to_equal(1);
  ut.expect(l_request_headers.last, 'l_request_headers.last').to_equal(3);

  check_headers;
  
  set_request_headers
  ( p_name_04 => 'Authorization'
  , p_value_04 => 'Basic abacadabra'
  , p_reset => false
  , p_skip_if_exists => true -- keep indices 1, 2 and 3
  , p_request_headers => l_request_headers
  );

  ut.expect(l_request_headers.first, 'l_request_headers.first').to_equal(1);
  ut.expect(l_request_headers.last, 'l_request_headers.last').to_equal(4);

  check_headers;

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end ut_set_request_headers;

procedure ut_remove_request_header
is
  l_request_headers header_table;

  procedure check_headers
  is
    l_name_exp varchar2(100);
    l_value_exp varchar2(100);
  begin
    if l_request_headers.first is null then return; end if;

    -- check_headers is invoked when index 2 has been removed, then (original) index 3 and then 1
    for i_idx in l_request_headers.first .. l_request_headers.last
    loop
      l_name_exp := case i_idx when 1 then 'Content-Type' when 2 then 'User-Agent' end;
      ut.expect(l_request_headers(i_idx).name, 'l_request_headers('||i_idx||').name').to_equal(l_name_exp);

      l_value_exp := case i_idx when 1 then 'application/json' when 2 then 'APEX' end;
      ut.expect(l_request_headers(i_idx).value, 'l_request_headers('||i_idx||').value').to_equal(l_value_exp);
    end loop;
  end check_headers;
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.UT_SET_REQUEST_HEADERS');
$end

  set_request_headers
  ( p_name_01 => 'Content-Type'
  , p_value_01 => 'application/json'
  , p_name_02 => 'Accept'
  , p_value_02 => '*/*'
  , p_name_03 => 'User-Agent'
  , p_value_03 => 'APEX'
  , p_request_headers => l_request_headers
  );

  ut.expect(l_request_headers.first, 'l_request_headers.first').to_equal(1);
  ut.expect(l_request_headers.last, 'l_request_headers.last').to_equal(3);
  
  remove_request_header('abcadabra', l_request_headers); -- non-existent
  
  ut.expect(l_request_headers.first, 'l_request_headers.first').to_equal(1);
  ut.expect(l_request_headers.last, 'l_request_headers.last').to_equal(3);
  
  remove_request_header(null, l_request_headers); -- non-existent
  
  ut.expect(l_request_headers.first, 'l_request_headers.first').to_equal(1);
  ut.expect(l_request_headers.last, 'l_request_headers.last').to_equal(3);
  
  remove_request_header('accept', l_request_headers); -- test lower case as well

  -- only 2 left
  ut.expect(l_request_headers.last, 'l_request_headers.last').to_equal(2);
  check_headers; 

  remove_request_header('USER-AGENT', l_request_headers); -- test upper case as well

  -- only 1 left
  ut.expect(l_request_headers.last, 'l_request_headers.last').to_equal(1);
  check_headers; 

  remove_request_header('Content-Type', l_request_headers); -- exact match

  -- none left
  ut.expect(l_request_headers.count, 'l_request_headers.last').to_equal(0);
  check_headers; 

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end ut_remove_request_header;

procedure ut_rest_web_service_get_cb
is
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.UT_REST_WEB_SERVICE_GET_CB');
$end

  -- ut_setup issues the register
  ut_rest_web_service_get;

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end ut_rest_web_service_get_cb;

procedure ut_rest_web_service_get_job
is
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.UT_REST_WEB_SERVICE_GET_JOB');
$end

  msg_aq_pkg.unregister
  ( p_queue_name => msg_aq_pkg.get_queue_name(web_service_request_typ.default_group())
  , p_subscriber => null
  , p_plsql_callback => '%'
  );
  ut_rest_web_service_get;

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end ut_rest_web_service_get_job;

procedure ut_rest_web_service_post
is
  pragma autonomous_transaction;

  l_correlation constant varchar2(128) := web_service_request_typ.generate_unique_id();
  l_msgid raw(16) := null;
  l_body_vc constant varchar2(4000 char) := '{"title":"foo","body":"bar","userId":123}';
  l_message_properties dbms_aq.message_properties_t;
  l_msg msg_typ;
  l_rest_web_service_request rest_web_service_request_typ;
  l_web_service_response web_service_response_typ;
  l_json_act json_element_t;
  l_json_exp constant json_object_t := json_object_t('{
  "title": "foo",
  "body": "bar",
  "userId": 123,
  "id": 101
}');
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.UT_REST_WEB_SERVICE_POST');
$end

  -- See https://terminalcheatsheet.com/guides/curl-rest-api

  -- will just get enqueued here
  l_rest_web_service_request :=
    rest_web_service_request_typ
    ( p_context$ => l_correlation
    , p_url => 'https://jsonplaceholder.typicode.com/posts'
    , p_http_method => 'POST'
    , p_body_clob => to_clob(l_body_vc)
    , p_http_headers_clob => to_clob('[{"Content-Type":"application/json"}]')
    );
    
  l_rest_web_service_request.response().print; -- just invoke directly and print
  
  l_rest_web_service_request.process; -- invoke indirectly

  commit;

  -- and dequeued here
  msg_aq_pkg.dequeue
  ( p_queue_name => web_service_response_typ.default_group()
  , p_delivery_mode => dbms_aq.persistent_or_buffered
  , p_visibility => dbms_aq.immediate
  , p_subscriber => null
  , p_dequeue_mode => dbms_aq.remove
    /*
    -- The correlation attribute specifies the correlation identifier of the dequeued message.
    -- The correlation identifier cannot be changed between successive dequeue calls without specifying the FIRST_MESSAGE navigation option.
    */
  , p_navigation => dbms_aq.first_message
  , p_wait => c_wait_timeout
  , p_correlation => l_correlation
  , p_deq_condition => null
  , p_force => true
  , p_msgid => l_msgid
  , p_message_properties => l_message_properties
  , p_msg => l_msg
  );

$if msg_pkg.c_debugging >= 1 $then
  l_msg.print();
$end  

  commit;

  ut.expect(l_msg is of (web_service_response_typ), 'web service response object type').to_be_true();

  l_web_service_response := treat(l_msg as web_service_response_typ);

  -- ORA-29273: HTTP request failed?
  -- In bc_dev only when web_service_pkg.c_prefer_to_use_utl_http is true, on pato never
  
$if not(web_service_pkg.c_prefer_to_use_utl_http) $then
  ut.expect(l_web_service_response.sql_code, 'sql code').to_equal(0);
$end  

  if l_web_service_response.sql_code = 0
  then
    msg_pkg.msg2data(l_web_service_response.body_vc, l_web_service_response.body_clob, l_json_act);

    ut.expect(l_json_act, 'json').to_equal(l_json_exp);
  else
    ut.expect(l_web_service_response.sql_code, 'sql code').to_equal(-29273);  
    ut.expect(l_web_service_response.sql_error_message, 'sql error message').to_equal('ORA-29273: HTTP request failed');  
  end if;

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end ut_rest_web_service_post;

procedure ut_rest_web_service_get_job_bulk
is
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.UT_REST_WEB_SERVICE_GET_JOB_BULK');
$end

  msg_aq_pkg.unregister
  ( p_queue_name => msg_aq_pkg.get_queue_name(web_service_request_typ.default_group())
  , p_subscriber => null
  , p_plsql_callback => '%'
  );
  ut_rest_web_service_get_bulk(100, false);

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end ut_rest_web_service_get_job_bulk;

$end -- $if msg_aq_pkg.c_testing $then

begin
  dbms_lob.createtemporary(g_body_clob, true);
  dbms_lob.createtemporary(g_body_blob, true);
end web_service_pkg;
/

