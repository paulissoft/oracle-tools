CREATE OR REPLACE PACKAGE BODY "WEB_SERVICE_PKG" AS

c_timestamp_format constant varchar2(30) := 'YYYYMMDDHH24MISSXFF';

$if msg_aq_pkg.c_testing $then

c_wait_timeout constant positiven := 30;

$end -- $if msg_aq_pkg.c_testing $then

g_body_clob clob := null;
g_body_blob blob := null;

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

procedure json2data
( p_http_headers in json_array_t
, p_http_header_tab out nocopy apex_web_service.header_table
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
( p_http_header_tab in apex_web_service.header_table
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

function make_rest_request
( p_request in rest_web_service_request_typ
)
return web_service_response_typ
is
  l_parm_names apex_application_global.vc_arr2 := apex_web_service.empty_vc_arr;
  l_parm_values apex_application_global.vc_arr2 := apex_web_service.empty_vc_arr;
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

$if msg_constants_pkg.c_prefer_to_use_utl_http $then

  function simple_request
  return boolean
  is
  begin
$if oracle_tools.cfg_pkg.c_debugging $then
    dbug.print
    ( dbug."info"
    , 'p_request.scheme is null: %s; p_request.proxy_override is null: %s; l_parm_names.count = 0: %s; l_parm_values.count = 0: %s'
    , dbug.cast_to_varchar2(p_request.scheme is null)
    , dbug.cast_to_varchar2(p_request.proxy_override is null)
    , dbug.cast_to_varchar2(l_parm_names.count = 0)
    , dbug.cast_to_varchar2(l_parm_values.count = 0)
    );                          

    dbug.print
    ( dbug."info"
    , 'p_request.wallet_path is null: %s; p_request.https_host is null: %s; p_request.credential_static_id is null: %s; p_request.token_url is null: %s'
    , dbug.cast_to_varchar2(p_request.wallet_path is null)
    , dbug.cast_to_varchar2(p_request.https_host is null)
    , dbug.cast_to_varchar2(p_request.credential_static_id is null)
    , dbug.cast_to_varchar2(p_request.token_url is null)
    );
$end

    return p_request.scheme is null and
           p_request.proxy_override is null and
           l_parm_names.count = 0 and
           l_parm_values.count = 0 and
           p_request.wallet_path is null and
           p_request.https_host is null and
           p_request.credential_static_id is null and
           p_request.token_url is null;
  end simple_request;
  
  procedure utl_http_request
  ( p_body_clob in out nocopy clob -- on input the request body, on output the response body
  , p_body_blob in out nocopy blob -- on input the request body, on output the response body
  , p_request_cookies in sys.utl_http.cookie_table
  , p_request_headers in apex_web_service.header_table
  , p_response_cookies out nocopy sys.utl_http.cookie_table
  , p_response_headers out nocopy apex_web_service.header_table
  , p_status_code out nocopy pls_integer
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
    
    utl_http.set_wallet(null);
    utl_http.set_transfer_timeout(p_request.transfer_timeout);
    utl_http.clear_cookies;
    utl_http.add_cookies(p_request_cookies);

    l_http_request := utl_http.begin_request(p_request.url, p_request.http_method);

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

$end -- $if msg_constants_pkg.c_prefer_to_use_utl_http $then
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.MAKE_REST_REQUEST');
$end

  if l_parms is not null
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
$if msg_constants_pkg.c_prefer_to_use_utl_http $then
  
    when simple_request
    then
$if oracle_tools.cfg_pkg.c_debugging $then
      dbug.print(dbug."info", 'Using UTL_HTTP.BEGIN_REQUEST to issue the REST webservice');
$end

      utl_http_request
      ( p_body_clob => l_body_clob
      , p_body_blob => l_body_blob
      , p_request_cookies => apex_web_service.g_request_cookies
      , p_request_headers => apex_web_service.g_request_headers
      , p_response_cookies => apex_web_service.g_response_cookies
      , p_response_headers => apex_web_service.g_headers
      , p_status_code => apex_web_service.g_status_code
      );
$end -- $if msg_constants_pkg.c_prefer_to_use_utl_http $then
      
    when p_request.binary_response = 0
    then
$if oracle_tools.cfg_pkg.c_debugging $then
      dbug.print(dbug."info", 'Using APEX_WEB_SERVICE.MAKE_REST_REQUEST to issue the REST webservice');
$end

      l_body_clob := apex_web_service.make_rest_request
                     ( p_url => p_request.url
                     , p_http_method => p_request.http_method
                     , p_username => null
                     , p_password => null
                     , p_scheme => p_request.scheme
                     , p_proxy_override => p_request.proxy_override
                     , p_transfer_timeout => p_request.transfer_timeout
                     , p_body => case when l_body_clob is not null then l_body_clob else empty_clob() end
                     , p_body_blob => case when l_body_blob is not null then l_body_blob else empty_blob() end
                     , p_parm_name => l_parm_names
                     , p_parm_value => l_parm_values
                     , p_wallet_path => p_request.wallet_path
                     , p_wallet_pwd => null
                     , p_https_host => p_request.https_host
                     , p_credential_static_id => p_request.credential_static_id
                     , p_token_url => p_request.token_url
                     );
      l_body_blob := null;

    else
$if oracle_tools.cfg_pkg.c_debugging $then
      dbug.print(dbug."info", 'Using APEX_WEB_SERVICE.MAKE_REST_REQUEST_B to issue the REST webservice');
$end

      l_body_blob := apex_web_service.make_rest_request_b
                     ( p_url => p_request.url
                     , p_http_method => p_request.http_method
                     , p_username => null
                     , p_password => null
                     , p_scheme => p_request.scheme
                     , p_proxy_override => p_request.proxy_override
                     , p_transfer_timeout => p_request.transfer_timeout
                     , p_body => case when l_body_clob is not null then l_body_clob else empty_clob() end
                     , p_body_blob => case when l_body_blob is not null then l_body_blob else empty_blob() end
                     , p_parm_name => l_parm_names
                     , p_parm_value => l_parm_values
                     , p_wallet_path => p_request.wallet_path
                     , p_wallet_pwd => null
                     , p_https_host => p_request.https_host
                     , p_credential_static_id => p_request.credential_static_id
                     , p_token_url => p_request.token_url
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
    );

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
$end

  return l_web_service_response;
exception
  when others
  then
$if oracle_tools.cfg_pkg.c_debugging $then
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
           );
end make_rest_request;

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

  -- now the dequeue in reversed order
  for i_idx in reverse l_correlation_tab.first .. l_correlation_tab.last
  loop
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
    -- In bc_dev only when msg_constants_pkg.c_prefer_to_use_utl_http is true, on pato never
  
$if not(msg_constants_pkg.c_prefer_to_use_utl_http) $then
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
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.UT_TEARDOWN');
$end
  if msg_constants_pkg.c_default_processing_method like 'plsql://%'
  then
    msg_aq_pkg.register
    ( p_queue_name => msg_aq_pkg.get_queue_name(web_service_request_typ.default_group())
    , p_subscriber => null
    , p_plsql_callback => replace(msg_constants_pkg.c_default_processing_method, 'plsql://')
    );
  else
    msg_aq_pkg.unregister
    ( p_queue_name => msg_aq_pkg.get_queue_name(web_service_request_typ.default_group())
    , p_subscriber => null
    , p_plsql_callback => '%'
    );
  end if;
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
  -- In bc_dev only when msg_constants_pkg.c_prefer_to_use_utl_http is true, on pato never
  
$if not(msg_constants_pkg.c_prefer_to_use_utl_http) $then
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

