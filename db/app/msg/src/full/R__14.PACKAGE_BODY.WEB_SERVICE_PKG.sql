CREATE OR REPLACE PACKAGE BODY "WEB_SERVICE_PKG" AS

c_timestamp_format constant varchar2(30) := 'YYYYMMDDHH24MISSXFF';

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

$if msg_aq_pkg.c_testing $then

procedure ut_rest_web_service_get
is
  pragma autonomous_transaction;

  l_correlation constant varchar2(128) := web_service_request_typ.generate_unique_id();
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
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.UT_REST_WEB_SERVICE_GET');
$end

  -- See https://terminalcheatsheet.com/guides/curl-rest-api

  -- % curl https://jsonplaceholder.typicode.com/todos/1
  --
  -- {
  --   "userId": 1,
  --   "id": 1,
  --   "title": "delectus aut autem",
  --   "completed": false
  -- }%                                                                                                                                                                                                           
  -- will just get enqueued here
  l_rest_web_service_request :=
    rest_web_service_request_typ
    ( p_context$ => l_correlation
    , p_url => 'https://jsonplaceholder.typicode.com/todos/1'
    , p_http_method => 'GET'
    );

  l_rest_web_service_request.response().print; -- just invoke directly and print
  
  l_rest_web_service_request.process; -- invoke indirectly

  commit;

  -- and dequeued here
  msg_aq_pkg.dequeue
  ( p_queue_name => web_service_response_typ.default_group()
  , p_delivery_mode => null
  , p_visibility => null
  , p_subscriber => null
  , p_dequeue_mode => dbms_aq.remove
    /*
    -- The correlation attribute specifies the correlation identifier of the dequeued message.
    -- The correlation identifier cannot be changed between successive dequeue calls without specifying the FIRST_MESSAGE navigation option.
    */
  , p_navigation => dbms_aq.first_message
  , p_wait => 10 -- dbms_aq.forever
  , p_correlation => l_correlation
  , p_deq_condition => null
  , p_force => true
  , p_msgid => l_msgid
  , p_message_properties => l_message_properties
  , p_msg => l_msg
  );

  l_msg.print();
  
  commit;

  ut.expect(l_msg is of (web_service_response_typ), 'web service response object type').to_be_true();

  l_web_service_response := treat(l_msg as web_service_response_typ);

  msg_pkg.msg2data(l_web_service_response.body_vc, l_web_service_response.body_clob, l_json_act);

  ut.expect(l_json_act, 'json').to_equal(l_json_exp);

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end ut_rest_web_service_get;

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
  , p_delivery_mode => null
  , p_visibility => null
  , p_subscriber => null
  , p_dequeue_mode => dbms_aq.remove
    /*
    -- The correlation attribute specifies the correlation identifier of the dequeued message.
    -- The correlation identifier cannot be changed between successive dequeue calls without specifying the FIRST_MESSAGE navigation option.
    */
  , p_navigation => dbms_aq.first_message
  , p_wait => 10 -- dbms_aq.forever
  , p_correlation => l_correlation
  , p_deq_condition => null
  , p_force => true
  , p_msgid => l_msgid
  , p_message_properties => l_message_properties
  , p_msg => l_msg
  );

  l_msg.print();

  commit;

  ut.expect(l_msg is of (web_service_response_typ), 'web service response object type').to_be_true();

  l_web_service_response := treat(l_msg as web_service_response_typ);

  msg_pkg.msg2data(l_web_service_response.body_vc, l_web_service_response.body_clob, l_json_act);

  ut.expect(l_json_act, 'json').to_equal(l_json_exp);

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

END WEB_SERVICE_PKG;
/

