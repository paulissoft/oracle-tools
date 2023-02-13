CREATE OR REPLACE PACKAGE BODY "WEB_SERVICE_PKG" AS

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
      
      p_cookie_tab(p_cookie_tab.count+1).name := l_cookie.get_string('name');
      p_cookie_tab(p_cookie_tab.count+0).value := l_cookie.get_string('value');
      p_cookie_tab(p_cookie_tab.count+0).domain := l_cookie.get_string('domain');
      p_cookie_tab(p_cookie_tab.count+0).expire := to_timestamp(l_cookie.get_string('expire'), 'YYYYMMDDHH24MISSXFF');
      p_cookie_tab(p_cookie_tab.count+0).path := l_cookie.get_string('path');
      p_cookie_tab(p_cookie_tab.count+0).secure := l_cookie.get_boolean('secure');
      p_cookie_tab(p_cookie_tab.count+0).version := l_cookie.get_number('version');
      p_cookie_tab(p_cookie_tab.count+0).comment := l_cookie.get_string('comment');
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
      l_cookie.put('expire', to_timestamp(p_cookie_tab(i_idx).expire, 'YYYYMMDDHH24MISSXFF'));
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
begin
  if p_http_headers is not null
  then
    for i_idx in 0 .. p_http_headers.get_size - 1 -- 0 based
    loop
      /*
      type header is record (
        name       varchar2(256),
        value      varchar2(32767) );

      type header_table is table of header index by binary_integer;
      */
      
      l_http_header := treat(p_http_headers.get(i_idx) as json_object_t);
      
      p_http_header_tab(p_http_header_tab.count+1).name := l_http_header.get_string('name');
      p_http_header_tab(p_http_header_tab.count+0).value := l_http_header.get_string('value');
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
      
      l_http_header.put('name', p_http_header_tab(i_idx).name);
      l_http_header.put('value', p_http_header_tab(i_idx).value);

      p_http_headers.append(l_http_header);
    end loop;
  end if;
end data2json;

END WEB_SERVICE_PKG;
/

