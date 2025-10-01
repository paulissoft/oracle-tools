CREATE OR REPLACE PACKAGE BODY "HTTP_REQUEST_RESPONSE_PKG" AS 

c_timestamp_format constant varchar2(30) := 'YYYYMMDDHH24MISSXFF';

procedure to_json
( p_cookie_tab in http_cookie_tab_typ
, p_cookies out nocopy json_array_t
)
is
  l_cookie json_object_t;
begin
  if p_cookie_tab is null or p_cookie_tab.count = 0
  then
    p_cookies := null;
  else
    p_cookies := json_array_t();
    
    for i_idx in p_cookie_tab.first .. p_cookie_tab.last
    loop
      l_cookie := json_object_t();
      
      l_cookie.put('name', p_cookie_tab(i_idx).name);
      l_cookie.put('value', p_cookie_tab(i_idx).value);
      l_cookie.put('domain', p_cookie_tab(i_idx).domain);
      l_cookie.put('expire', to_timestamp(p_cookie_tab(i_idx).expire, c_timestamp_format));
      l_cookie.put('path', p_cookie_tab(i_idx).path);
      l_cookie.put('secure', case p_cookie_tab(i_idx).secure when 0 then false when 1 then true end);
      l_cookie.put('version', p_cookie_tab(i_idx).version);
      l_cookie.put('comment', p_cookie_tab(i_idx).comment);

      p_cookies.append(l_cookie);
    end loop;
  end if;
end to_json;

procedure to_json
( p_http_header_tab in property_tab_typ
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
end to_json;

procedure copy_parameters
( p_parms in property_tab_typ
, p_url_encode in boolean
, p_parameters out nocopy varchar2
)
is
begin
  if p_parms is not null and p_parms.count > 0
  then
    for i_idx in p_parms.first .. p_parms.last
    loop
      if p_parms(i_idx).name is not null and p_parms(i_idx).value is not null
      then
        p_parameters :=
          case
            when i_idx > 1 then p_parameters || '&'
          end ||
          p_parms(i_idx).name ||
          '=' ||
          case
            when p_url_encode
            then utl_url.escape(url => p_parms(i_idx).value, escape_reserved_chars => true)
            else p_parms(i_idx).value
          end;
      end if;
    end loop;
  end if;
end copy_parameters;

function get_cookie_idx
( p_cookies in http_cookie_tab_typ
, p_name in varchar2
, p_ignore_case in boolean
)
return positive
deterministic
is
begin
  if p_cookies is not null and p_cookies.count > 0
  then
    for i_idx in p_cookies.first .. p_cookies.last
    loop
      if p_ignore_case
      then
        if upper(p_cookies(i_idx).name) = upper(p_name)
        then
          return i_idx;
        end if;
      else
        if p_cookies(i_idx).name = p_name
        then
          return i_idx;
        end if;
      end if;
    end loop;
  end if;
  return null;
end get_cookie_idx;

procedure add_cookie
( p_cookie in http_cookie_typ -- The cookie to add
, p_cookies in out nocopy http_cookie_tab_typ -- The cookies
)
is
begin
  if get_cookie_idx(p_cookies => p_cookies, p_name => p_cookie.name) is not null then return; end if;
  if p_cookies is null then p_cookies := http_cookie_tab_typ(); end if;
  p_cookies.extend(1);
  p_cookies(p_cookies.last) := p_cookie;
end add_cookie;

function get_cookie
( p_cookies in http_cookie_tab_typ
, p_name in varchar2
, p_ignore_case in boolean
)
return http_cookie_typ
deterministic
is
  l_idx constant positive :=
    get_cookie_idx
    ( p_cookies => p_cookies
    , p_name => p_name
    , p_ignore_case => p_ignore_case
    );
begin    
  if l_idx is null then raise no_data_found; end if;
  return p_cookies(l_idx);
end get_cookie;

function get_property_idx
( p_properties in property_tab_typ
, p_name in varchar2
, p_ignore_case in boolean
)
return positive
deterministic
is
begin
  if p_properties is not null and p_properties.count > 0
  then
    for i_idx in p_properties.first .. p_properties.last
    loop
      if p_ignore_case
      then
        if upper(p_properties(i_idx).name) = upper(p_name)
        then
          return i_idx;
        end if;
      else
        if p_properties(i_idx).name = p_name
        then
          return i_idx;
        end if;
      end if;
    end loop;
  end if;
  return null;
end get_property_idx;

procedure add_property
( p_property in property_typ -- The property to add
, p_properties in out nocopy property_tab_typ -- The properties (for instance HTTP headers)
)
is
begin
  if get_property_idx(p_properties => p_properties, p_name => p_property.name) is not null then return; end if;
  if p_properties is null then p_properties := property_tab_typ(); end if;
  p_properties.extend(1);
  p_properties(p_properties.last) := p_property;
end add_property;

function get_property
( p_properties in property_tab_typ
, p_name in varchar2
, p_ignore_case in boolean
)
return property_typ
deterministic
is
  l_idx constant positive :=
    get_property_idx
    ( p_properties => p_properties
    , p_name => p_name
    , p_ignore_case => p_ignore_case
    );
begin
  if l_idx is null then raise no_data_found; end if;
  return p_properties(l_idx);
end get_property;

function get_property_value
( p_properties in property_tab_typ -- The properties (for instance HTTP headers)
, p_name in varchar2 -- The property to search for
, p_ignore_case in boolean default true -- Must we ignore case (default YES)?
)
return varchar2 -- the property value if found else null
deterministic
is
  l_idx constant positive :=
    get_property_idx
    ( p_properties => p_properties
    , p_name => p_name
    , p_ignore_case => p_ignore_case
    );
begin
  return case when l_idx is not null then p_properties(l_idx).value end;
end get_property_value;

function get_http_status_descr
( p_http_status_code in positiven -- Should be > 0
)
return varchar2
deterministic
is
begin
  return
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

      else 'Unknown HTTP status code (' || to_char(p_http_status_code) || ')'
    end;
end get_http_status_descr;
  
end http_request_response_pkg;
/

