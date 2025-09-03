CREATE OR REPLACE PACKAGE BODY "WEB_SERVICE_PKG" AS

subtype vc_arr2 is sys.dbms_sql.varchar2a;

empty_vc_arr vc_arr2;

$if oracle_tools.cfg_pkg.c_apex_installed $then

subtype header_table is apex_web_service.header_table;

$else -- $if oracle_tools.cfg_pkg.c_apex_installed $then

-- from APEX_230200.WWV_FLOW_WEBSERVICES_API

type header is record (
    name       varchar2(256),
    value      varchar2(32767) );

type header_table is table of header index by binary_integer;

$end -- $if oracle_tools.cfg_pkg.c_apex_installed $then

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

$end -- $if not(oracle_tools.cfg_pkg.c_apex_installed) $then

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

$end -- $if web_service_pkg.c_prefer_to_use_utl_http $then

$if web_service_pkg.c_prefer_to_use_utl_http $then

procedure utl_http_request
( p_request in rest_web_service_request_typ
, p_url in varchar2
, p_body_blob in blob
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
begin
  utl_http.set_wallet(p_wallet_path, p_wallet_pwd);
  utl_http.set_transfer_timeout(p_request.transfer_timeout);
  utl_http.clear_cookies;
  utl_http.add_cookies(p_request_cookies);

  l_http_request := utl_http.begin_request(p_url, p_request.http_method);

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
      if upper(p_request_headers(i_idx).name) not in (upper('Content-Length')/*, 'Accept', 'User-Agent'*/)
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
end utl_http_request;

procedure utl_http_request
( p_request in rest_web_service_request_typ
, p_url in varchar2
, p_body_clob in out nocopy clob -- on input the request body, on output the response body
, p_body_blob in out nocopy blob -- on input the request body, on output the response body
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
  -- for dbms_lob.converttoblob
  l_dest_offset integer := 1;
  l_src_offset integer := 1;
  l_lang number := dbms_lob.default_lang_ctx;
  l_warning integer;
begin
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

  utl_http_request
  ( p_request => p_request
  , p_url => p_url
  , p_body_blob => p_body_blob
  , p_username => p_username
  , p_password => p_password
  , p_scheme => p_scheme
  , p_wallet_path => p_wallet_path
  , p_wallet_pwd => p_wallet_pwd
  , p_request_cookies => p_request_cookies
  , p_request_headers => p_request_headers
  , p_response_cookies => p_response_cookies
  , p_response_headers => p_response_headers
  , p_status_code => p_status_code
  , p_reason_phrase => p_reason_phrase
  );

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

procedure check_http_status_code
( p_http_status_code in http_status_code_t
, p_http_reason_phrase in http_reason_phrase_t
)
is
begin
  if p_http_status_code is null
  then
    raise value_error;
  elsif not(p_http_status_code between 200 and 299)
  then
    -- p_http_status_code is not null
    raise_application_error
    ( -20000 + -1 * p_http_status_code
    , utl_lms.format_message
      ( 'HTTP status description: %s; HTTP reason phrase: %s'
      , http_request_response_pkg.get_http_status_descr(p_http_status_code)
      , p_http_reason_phrase
      )
    );
  end if;
end check_http_status_code;

procedure handle_response
( p_response in web_service_response_typ -- The REST request response
, p_check_http_status_code_ok in boolean -- Check that HTTP status code is between 200 and 299
, p_http_status_code out nocopy http_status_code_t
, p_http_status_description out nocopy http_status_description_t
, p_http_reason_phrase out nocopy http_reason_phrase_t
, p_body_clob out nocopy clob
, p_body_blob out nocopy blob
, p_retry_after out nocopy varchar2 -- Retry-After HTTP header
, p_x_ratelimit_limit out nocopy varchar2 -- X-RateLimit-Limit HTTP header
, p_x_ratelimit_remaining out nocopy varchar2 -- X-RateLimit-Remaining HTTP header
, p_x_ratelimit_reset out nocopy varchar2 -- X-RateLimit-Reset HTTP header
)
is
$if oracle_tools.cfg_pkg.c_debugging $then
  l_clob clob;
$end
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.HANDLE_RESPONSE');
  dbug.print
  ( dbug."input"
  , 'p_check_http_status_code_ok: %s'
  , p_check_http_status_code_ok
  );
$end

  p_http_status_code := p_response.http_status_code;
  
  -- From https://www.oxitsolutions.co.uk/blog/http-status-code-cheat-sheet-infographic
  p_http_status_description :=
    case
      when p_http_status_code is not null
      then http_request_response_pkg.get_http_status_descr(p_http_status_code)
    end;
  p_http_reason_phrase := p_response.http_reason_phrase;

  p_body_clob := p_response.body_c();    
  p_body_blob := p_response.body_b();

  p_retry_after := http_request_response_pkg.get_property(p_response.http_headers, 'Retry-After');
  p_x_ratelimit_limit := http_request_response_pkg.get_property(p_response.http_headers, 'X-RateLimit-Limit');
  p_x_ratelimit_remaining := http_request_response_pkg.get_property(p_response.http_headers, 'X-RateLimit-Remaining');
  p_x_ratelimit_reset := http_request_response_pkg.get_property(p_response.http_headers, 'X-RateLimit-Reset');

  if p_check_http_status_code_ok
  then
    check_http_status_code
    ( p_http_status_code => p_http_status_code
    , p_http_reason_phrase => p_http_reason_phrase
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
  dbug.print
  ( dbug."output"
  , 'p_retry_after: %s; p_x_ratelimit_limit: %s; p_x_ratelimit_remaining: %s; p_x_ratelimit_reset: %s'
  , p_retry_after
  , p_x_ratelimit_limit
  , p_x_ratelimit_remaining
  , p_x_ratelimit_reset
  );
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end handle_response;

procedure convert_to_cookie_table
( p_cookie_in_tab in http_cookie_tab_typ
, p_cookie_out_tab out nocopy sys.utl_http.cookie_table
)
is
begin
  if p_cookie_in_tab is not null and p_cookie_in_tab.count > 0
  then
    for i_idx in p_cookie_in_tab.first .. p_cookie_in_tab.last
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
      if p_cookie_in_tab(i_idx).name is not null and p_cookie_in_tab(i_idx).value is not null
      then
        p_cookie_out_tab(p_cookie_out_tab.count+1).name := p_cookie_in_tab(i_idx).name;
        p_cookie_out_tab(p_cookie_out_tab.count+0).value := p_cookie_in_tab(i_idx).value;
        p_cookie_out_tab(p_cookie_out_tab.count+0).domain := p_cookie_in_tab(i_idx).domain;
        p_cookie_out_tab(p_cookie_out_tab.count+0).expire := p_cookie_in_tab(i_idx).expire;
        p_cookie_out_tab(p_cookie_out_tab.count+0).path := p_cookie_in_tab(i_idx).path;
        p_cookie_out_tab(p_cookie_out_tab.count+0).secure := p_cookie_in_tab(i_idx).secure = 1;
        p_cookie_out_tab(p_cookie_out_tab.count+0).version := p_cookie_in_tab(i_idx).version;
        p_cookie_out_tab(p_cookie_out_tab.count+0).comment := p_cookie_in_tab(i_idx).comment;
      end if;
    end loop;
  end if;  
end convert_to_cookie_table;

procedure convert_from_cookie_table
( p_cookie_in_tab in sys.utl_http.cookie_table
, p_cookie_out_tab out nocopy http_cookie_tab_typ
)
is
begin
  if p_cookie_in_tab.count = 0
  then
    p_cookie_out_tab := null;
  else
    p_cookie_out_tab := http_cookie_tab_typ();
    for i_idx in p_cookie_in_tab.first .. p_cookie_in_tab.last
    loop
      if p_cookie_in_tab(i_idx).name is not null and p_cookie_in_tab(i_idx).value is not null
      then
        p_cookie_out_tab.extend(1);
        p_cookie_out_tab(p_cookie_out_tab.last) :=
          http_cookie_typ
          ( p_cookie_in_tab(i_idx).name
          , p_cookie_in_tab(i_idx).value
          , p_cookie_in_tab(i_idx).domain
          , p_cookie_in_tab(i_idx).expire
          , p_cookie_in_tab(i_idx).path
          , case p_cookie_in_tab(i_idx).secure when true then 1 when false then 0 else null end
          , p_cookie_in_tab(i_idx).version
          , p_cookie_in_tab(i_idx).comment
          );
      end if;
    end loop;
  end if;  
end convert_from_cookie_table;

procedure convert_to_header_table
( p_http_header_in_tab in property_tab_typ
, p_http_header_out_tab out nocopy header_table
)
is
begin
  if p_http_header_in_tab is not null and p_http_header_in_tab.count > 0
  then
    for i_idx in p_http_header_in_tab.first .. p_http_header_in_tab.last
    loop
      if p_http_header_in_tab(i_idx).name is not null and p_http_header_in_tab(i_idx).value is not null
      then
        p_http_header_out_tab(p_http_header_out_tab.count+1).name := p_http_header_in_tab(i_idx).name;
        p_http_header_out_tab(p_http_header_out_tab.count+0).value := p_http_header_in_tab(i_idx).value;
      end if;
    end loop;
  end if;  
end convert_to_header_table;

procedure convert_from_header_table
( p_http_header_in_tab in header_table
, p_http_header_out_tab out nocopy property_tab_typ
)
is
begin
  if p_http_header_in_tab.count = 0
  then
    p_http_header_out_tab := null;
  else
    p_http_header_out_tab := property_tab_typ();
    for i_idx in p_http_header_in_tab.first .. p_http_header_in_tab.last
    loop
      if p_http_header_in_tab(i_idx).name is not null and p_http_header_in_tab(i_idx).value is not null
      then
        p_http_header_out_tab.extend(1);
        p_http_header_out_tab(p_http_header_out_tab.last) :=
          property_typ
          ( p_http_header_in_tab(i_idx).name
          , p_http_header_in_tab(i_idx).value
          );
      end if;
    end loop;
  end if;  
end convert_from_header_table;

procedure convert_to_parms_tables
( p_parms in property_tab_typ
, p_parm_names out nocopy vc_arr2
, p_parm_values out nocopy vc_arr2
)
is
begin
  p_parm_names := empty_vc_arr;
  p_parm_values := empty_vc_arr;

  if p_parms is not null and p_parms.count > 0
  then
    for i_idx in p_parms.first .. p_parms.last
    loop
      if p_parms(i_idx).name is not null and p_parms(i_idx).value is not null
      then
        p_parm_names(p_parm_names.count+1) := p_parms(i_idx).name;
        p_parm_values(p_parm_values.count+1) := p_parms(i_idx).value;
      end if;
    end loop;
  end if;
end convert_to_parms_tables;

-- PUBLIC

procedure make_rest_request
( p_request in rest_web_service_request_typ -- The request
, p_username in varchar2 default null -- The username if basic authentication is required for this service
, p_password in varchar2 default null -- The password if basic authentication is required for this service
, p_wallet_pwd in varchar2 default null -- The password to access the wallet
, p_response out nocopy web_service_response_typ -- The response
)
is
/*
  l_parm_names vc_arr2 := empty_vc_arr;
  l_parm_values vc_arr2 := empty_vc_arr;
*/  
  l_url_encode boolean := (p_request.use_query_parameters != 0);
  l_idx positive;
  l_url varchar2(32767 byte) := p_request.url;
  l_parameters varchar2(32767 byte);
  l_body_clob clob := p_request.body_c();
  l_body_blob blob := p_request.body_b();
  l_start constant number := dbms_utility.get_time;
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.MAKE_REST_REQUEST');
  dbug.print(dbug."input", 'p_request.context$: %s', p_request.context$);
$end

/*
  pragma inline (convert_to_parms_tables, 'YES');
  convert_to_parms_tables(p_request.parms, l_parm_names, l_parm_values);
*/

  if not l_url_encode -- put them in the body
  then
    -- Content-Type=application/x-www-form-urlencoded?
    l_idx := http_request_response_pkg.get_property_idx(p_request.http_headers, 'Content-Type');
    if l_idx is not null and p_request.http_headers(l_idx).value like 'application/x-www-form-urlencoded%'
    then
      l_url_encode := true;
    end if;
  end if;
  
  http_request_response_pkg.copy_parameters
  ( p_parms => p_request.parms
  , p_url_encode => l_url_encode
  , p_parameters => l_parameters
  );

  -- Use parameters as GET query parameters or put them into an empty body (non-GET)
  if l_parameters is not null
  then  
    if p_request.use_query_parameters != 0
    then
      l_url := l_url || '?' || l_parameters;
    elsif p_request.http_method() != 'GET' and
          (l_body_clob is null or dbms_lob.getlength(l_body_clob) = 0) and
          (l_body_blob is null or dbms_lob.getlength(l_body_blob) = 0)
    then
      -- put parameters in empty character body since there is room and binary body is not used
      l_body_clob := to_clob(l_parameters);
    else
      raise program_error; -- nowhere to put them (without getting in the way of something else)
    end if;
  end if;

$if oracle_tools.cfg_pkg.c_apex_installed $then  
  pragma inline (convert_to_cookie_table, 'YES');
  convert_to_cookie_table(p_request.cookies, apex_web_service.g_request_cookies);
  pragma inline (convert_to_header_table, 'YES');
  convert_to_header_table(p_request.http_headers, apex_web_service.g_request_headers);
$else
  pragma inline (convert_to_cookie_table, 'YES');
  convert_to_cookie_table(p_request.cookies, g_request_cookies);
  pragma inline (convert_to_header_table, 'YES');
  convert_to_header_table(p_request.http_headers, g_request_headers);
$end

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
      , p_url => l_url
      , p_body_clob => l_body_clob
      , p_body_blob => l_body_blob
      , p_username => p_username
      , p_password => p_password
      , p_scheme => p_request.scheme
      , p_wallet_path => p_request.wallet_path
      , p_wallet_pwd => p_wallet_pwd
$if oracle_tools.cfg_pkg.c_apex_installed $then      
      , p_request_cookies => apex_web_service.g_request_cookies
      , p_request_headers => apex_web_service.g_request_headers
      , p_response_cookies => apex_web_service.g_response_cookies
      , p_response_headers => apex_web_service.g_headers
$else
      , p_request_cookies => g_request_cookies
      , p_request_headers => g_request_headers
      , p_response_cookies => g_response_cookies
      , p_response_headers => g_headers
$end
      , p_status_code => apex_web_service.g_status_code
      , p_reason_phrase => apex_web_service.g_reason_phrase
      );
$end -- $if web_service_pkg.c_prefer_to_use_utl_http $then

$if oracle_tools.cfg_pkg.c_apex_installed $then

    when p_request.binary_response = 0
    then
$if oracle_tools.cfg_pkg.c_debugging $then
      dbug.print(dbug."info", 'Using APEX_WEB_SERVICE.MAKE_REST_REQUEST to issue the REST webservice');
$end

      l_body_clob := apex_web_service.make_rest_request
                     ( p_url => l_url
                     , p_http_method => p_request.http_method
                     , p_username => p_username
                     , p_password => p_password
                     , p_scheme => p_request.scheme
/*APEX*/             , p_proxy_override => p_request.proxy_override
                     , p_transfer_timeout => p_request.transfer_timeout
                     , p_body => case when l_body_clob is not null then l_body_clob else empty_clob() end
                     , p_body_blob => case when l_body_blob is not null then l_body_blob else empty_blob() end
/*                     
                     , p_parm_name => l_parm_names
                     , p_parm_value => l_parm_values
*/                     
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
                     ( p_url => l_url
                     , p_http_method => p_request.http_method
                     , p_username => p_username
                     , p_password => p_username
                     , p_scheme => p_request.scheme
/*APEX*/             , p_proxy_override => p_request.proxy_override
                     , p_transfer_timeout => p_request.transfer_timeout
                     , p_body => case when l_body_clob is not null then l_body_clob else empty_clob() end
                     , p_body_blob => case when l_body_blob is not null then l_body_blob else empty_blob() end
/*                     
                     , p_parm_name => l_parm_names
                     , p_parm_value => l_parm_values
*/                     
                     , p_wallet_path => p_request.wallet_path
                     , p_wallet_pwd => null
/*APEX*/             , p_https_host => p_request.https_host
/*APEX*/             , p_credential_static_id => p_request.credential_static_id
/*APEX*/             , p_token_url => p_request.token_url
                     );
      l_body_clob := null;

$else -- $if oracle_tools.cfg_pkg.c_apex_installed $then

    when false
    then
      null;
      
    else
      raise_application_error(-20000, 'APEX is not installed.');

$end -- $if oracle_tools.cfg_pkg.c_apex_installed $then
  end case;

  p_response :=
    web_service_response_typ
    ( p_group$ => null
    , p_context$ => p_request.context$
    , p_cookies => null
    , p_http_headers => null
    , p_body_clob => l_body_clob
    , p_body_blob => l_body_blob
    , p_sql_code => sqlcode -- 0
    , p_sql_error_message => sqlerrm -- null
    , p_http_status_code => apex_web_service.g_status_code
    , p_http_reason_phrase => substrb(apex_web_service.g_reason_phrase, 1, 4000)
    );

$if oracle_tools.cfg_pkg.c_apex_installed $then
  pragma inline (convert_from_cookie_table, 'YES');
  convert_from_cookie_table(apex_web_service.g_response_cookies, p_response.cookies);
  pragma inline (convert_from_header_table, 'YES');
  convert_from_header_table(apex_web_service.g_headers, p_response.http_headers);
$else
  pragma inline (convert_from_cookie_table, 'YES');
  convert_from_cookie_table(g_response_cookies, p_response.cookies);
  pragma inline (convert_from_header_table, 'YES');
  convert_from_header_table(g_headers, p_response.http_headers);
$end

  p_response.elapsed_time_ms := (dbms_utility.get_time - l_start) * 10;

$if oracle_tools.cfg_pkg.c_debugging $then  
  dbug.print(dbug."info", 'REST webservice issued in %s milliseconds', p_response.elapsed_time_ms);
  dbug.print(dbug."output", 'p_response.context$: %s', p_response.context$);
  dbug.leave;
$end
exception
  when others
  then
    p_response :=
      web_service_response_typ
      ( p_group$ => null
      , p_context$ => p_request.context$
      , p_cookies => null
      , p_http_headers => null
      , p_body_clob => null
      , p_body_blob => null
      , p_sql_code => sqlcode
      , p_sql_error_message => sqlerrm
      , p_http_status_code => null
      , p_http_reason_phrase => null
      );

    p_response.elapsed_time_ms := (dbms_utility.get_time - l_start) * 10;
    
$if oracle_tools.cfg_pkg.c_debugging $then
    dbug.print(dbug."info", 'REST webservice issued in %s milliseconds', p_response.elapsed_time_ms);
    dbug.print(dbug."output", 'p_response.context$: %s', p_response.context$);
    dbug.leave_on_error;
$end
end make_rest_request;

function make_rest_request
( p_request in rest_web_service_request_typ
, p_username in varchar2
, p_password in varchar2
, p_wallet_pwd in varchar2
)
return web_service_response_typ
is
  l_web_service_response web_service_response_typ;
begin
  make_rest_request
  ( p_request => p_request
  , p_username => p_username
  , p_password => p_password
  , p_wallet_pwd => p_wallet_pwd
  , p_response => l_web_service_response
  );
  return l_web_service_response;
end make_rest_request;

function make_rest_request
( p_url in varchar2
, p_http_method in varchar2
, p_scheme in varchar2
, p_cookies in http_cookie_tab_typ
, p_http_headers in property_tab_typ
, p_body in clob
, p_body_blob in blob
, p_proxy_override in varchar2
, p_transfer_timeout in number
, p_wallet_path in varchar2
, p_https_host in varchar2
, p_credential_static_id in varchar2
, p_token_url in varchar2
, p_parms in property_tab_typ
, p_username in varchar2
, p_password in varchar2
, p_wallet_pwd in varchar2
)
return web_service_response_typ
is
  l_rest_web_service_request rest_web_service_request_typ;
  l_web_service_response web_service_response_typ;
begin
  rest_web_service_request_typ.construct
  ( p_http_method => p_http_method
  , p_cookies => p_cookies
  , p_http_headers => p_http_headers
  , p_body_clob => p_body
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
  , p_binary_response => 0
  , p_rest_web_service_request => l_rest_web_service_request
  );
  
  l_web_service_response :=
    make_rest_request
    ( p_request => l_rest_web_service_request
    , p_username => p_username
    , p_password => p_password
    , p_wallet_pwd => p_wallet_pwd
    );
    
  return l_web_service_response;
end make_rest_request;

function make_rest_request_b
( p_url in varchar2
, p_http_method in varchar2
, p_scheme in varchar2
, p_cookies in http_cookie_tab_typ
, p_http_headers in property_tab_typ
, p_body in clob
, p_body_blob in blob
, p_proxy_override in varchar2
, p_transfer_timeout in number
, p_wallet_path in varchar2
, p_https_host in varchar2
, p_credential_static_id in varchar2
, p_token_url in varchar2
, p_parms in property_tab_typ
, p_username in varchar2
, p_password in varchar2
, p_wallet_pwd in varchar2
)
return web_service_response_typ
is
  l_rest_web_service_request rest_web_service_request_typ;
  l_web_service_response web_service_response_typ;
begin
  rest_web_service_request_typ.construct
  ( p_http_method => p_http_method
  , p_cookies => p_cookies
  , p_http_headers => p_http_headers
  , p_body_clob => p_body
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
  , p_binary_response => 1
  , p_rest_web_service_request => l_rest_web_service_request
  );
  
  l_web_service_response :=
    make_rest_request
    ( p_request => l_rest_web_service_request
    , p_username => p_username
    , p_password => p_password
    , p_wallet_pwd => p_wallet_pwd
    );
    
  return l_web_service_response;
end make_rest_request_b;

procedure handle_response
( p_response in web_service_response_typ -- The REST request response
, p_check_http_status_code_ok in boolean -- Check that HTTP status code is between 200 and 299
, p_http_status_code out nocopy http_status_code_t -- The HTTP status code
, p_http_status_description out nocopy http_status_description_t -- The HTTP status description
, p_http_reason_phrase out nocopy http_reason_phrase_t -- The HTTP reason phrase
, p_body_clob out nocopy clob -- The HTTP character body
, p_retry_after out nocopy varchar2 -- Retry-After HTTP header
, p_x_ratelimit_limit out nocopy varchar2 -- X-RateLimit-Limit HTTP header
, p_x_ratelimit_remaining out nocopy varchar2 -- X-RateLimit-Remaining HTTP header
, p_x_ratelimit_reset out nocopy varchar2 -- X-RateLimit-Reset HTTP header
)
is
  l_body_blob_dummy blob;
begin
  handle_response
  ( p_response => p_response
  , p_check_http_status_code_ok => p_check_http_status_code_ok
  , p_http_status_code => p_http_status_code
  , p_http_status_description => p_http_status_description
  , p_http_reason_phrase => p_http_reason_phrase
  , p_body_clob => p_body_clob
  , p_body_blob => l_body_blob_dummy
  , p_retry_after => p_retry_after
  , p_x_ratelimit_limit => p_x_ratelimit_limit
  , p_x_ratelimit_remaining => p_x_ratelimit_remaining
  , p_x_ratelimit_reset => p_x_ratelimit_reset
  );
end handle_response;

procedure handle_response
( p_response in web_service_response_typ -- The REST request response
, p_check_http_status_code_ok in boolean -- Check that HTTP status code is between 200 and 299
, p_http_status_code out nocopy http_status_code_t -- The HTTP status code
, p_http_status_description out nocopy http_status_description_t -- The HTTP status description
, p_http_reason_phrase out nocopy http_reason_phrase_t -- The HTTP reason phrase
, p_body_blob out nocopy blob -- The HTTP binary body
, p_retry_after out nocopy varchar2 -- Retry-After HTTP header
, p_x_ratelimit_limit out nocopy varchar2 -- X-RateLimit-Limit HTTP header
, p_x_ratelimit_remaining out nocopy varchar2 -- X-RateLimit-Remaining HTTP header
, p_x_ratelimit_reset out nocopy varchar2 -- X-RateLimit-Reset HTTP header
)
is
  l_body_clob_dummy clob;
begin
  handle_response
  ( p_response => p_response
  , p_check_http_status_code_ok => p_check_http_status_code_ok
  , p_http_status_code => p_http_status_code
  , p_http_status_description => p_http_status_description
  , p_http_reason_phrase => p_http_reason_phrase
  , p_body_clob => l_body_clob_dummy
  , p_body_blob => p_body_blob
  , p_retry_after => p_retry_after
  , p_x_ratelimit_limit => p_x_ratelimit_limit
  , p_x_ratelimit_remaining => p_x_ratelimit_remaining
  , p_x_ratelimit_reset => p_x_ratelimit_reset
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
    rest_web_service_request_typ.construct
    ( p_context$ => l_correlation_tab(l_correlation_tab.last)
    , p_url => 'https://jsonplaceholder.typicode.com/todos/1'
    , p_http_method => 'GET'
    , p_rest_web_service_request => l_rest_web_service_request
    );

    l_rest_web_service_request.process; -- invoke now

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

  l_plsql_callback varchar2(100 byte) := replace(msg_constants_pkg.get_default_processing_method, 'plsql://' || $$PLSQL_UNIT_OWNER || '.');
  l_queue_name constant user_queues.name%type := msg_aq_pkg.get_queue_name(web_service_request_typ.default_group());
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.UT_SETUP');
$end

  begin
    select  owner || '.' || object_name
    into    l_plsql_callback
    from    all_objects o
    where   o.owner = user
    and     o.object_type = 'PROCEDURE'
    and     object_name = l_plsql_callback;
  exception
    when no_data_found
    then
      raise_application_error(-20000, 'Could not find PROCEDURE "' || l_plsql_callback || '"', true);
  end;

  for i_try in 1..2
  loop
$if oracle_tools.cfg_pkg.c_debugging $then
    dbug.print(dbug."info", 'try %s to register callback %s for queue %s', i_try, l_plsql_callback, l_queue_name);
$end
    begin
      msg_aq_pkg.register
      ( p_queue_name => l_queue_name
      , p_subscriber => null
      , p_plsql_callback => l_plsql_callback
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
$if oracle_tools.cfg_pkg.c_debugging $then
          dbug.print(dbug."info", 'create queue', l_queue_name);
$end
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

  l_request_queue_name constant user_queues.name%type :=
    msg_aq_pkg.get_queue_name(web_service_request_typ.default_group());
  l_response_queue_name constant user_queues.name%type :=
    msg_aq_pkg.get_queue_name(web_service_response_typ.default_group());
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

  rest_web_service_request_typ.construct
  ( p_http_method => 'POST'
  , p_context$ => l_correlation
  , p_url => 'https://jsonplaceholder.typicode.com/posts'
  , p_body_clob => to_clob(l_body_vc)
  , p_http_headers => property_tab_typ(property_typ('Content-Type', 'application/json'))
  , p_rest_web_service_request => l_rest_web_service_request
  );

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

$end -- $if msg_aq_pkg.c_testing $then

begin
  dbms_lob.createtemporary(g_body_clob, true);
  dbms_lob.createtemporary(g_body_blob, true);
end web_service_pkg;
/

