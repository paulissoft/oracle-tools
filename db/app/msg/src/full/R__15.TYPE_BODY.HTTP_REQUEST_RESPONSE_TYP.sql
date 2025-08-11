create or replace type body http_request_response_typ
is

constructor function http_request_response_typ
( self in out nocopy http_request_response_typ
  -- from MSG_TYP
, p_group$ in varchar2
, p_context$ in varchar2
  -- from HTTP_REQUEST_RESPONSE_TYP
, p_cookies in http_cookie_tab_typ
, p_http_headers property_tab_typ
, p_body_clob in clob
, p_body_blob in blob
)
return self as result
is
begin
  self.construct
  ( p_group$ => p_group$
  , p_context$ => p_context$
  , p_cookies => p_cookies
  , p_http_headers => p_http_headers
  , p_body_clob => p_body_clob
  , p_body_blob => p_body_blob
  );
  return;
end;

final member procedure construct
( self in out nocopy http_request_response_typ
  -- from MSG_TYP
, p_group$ in varchar2
, p_context$ in varchar2
  -- from HTTP_REQUEST_RESPONSE_TYP
, p_cookies in http_cookie_tab_typ
, p_http_headers property_tab_typ
, p_body_clob in clob
, p_body_blob in blob
)
is
begin
  (self as msg_typ).construct(p_group$, p_context$);
  self.cookies := p_cookies;
  self.http_headers := p_http_headers;
  msg_pkg.data2msg(p_body_clob, self.body_vc, self.body_clob);
  msg_pkg.data2msg(p_body_blob, self.body_raw, self.body_blob);
end construct;

overriding
member procedure serialize
( self in http_request_response_typ
, p_json_object in out nocopy json_object_t
)
is
  l_json_array json_array_t;
begin
  (self as msg_typ).serialize(p_json_object);
  if self.cookies is not null
  then
    web_service_pkg.to_json(self.cookies, l_json_array);
    p_json_object.put('COOKIES', l_json_array);
  end if;
  if self.http_headers is not null
  then
    web_service_pkg.to_json(self.http_headers, l_json_array);
    p_json_object.put('HTTP_HEADERS', l_json_array);
  end if;
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
end serialize;

overriding
member function has_not_null_lob
( self in http_request_response_typ
)
return integer
is
begin
  return
    case
      when (self as msg_typ).has_not_null_lob = 1 then 1
      when self.body_clob is not null then 1
      when self.body_blob is not null then 1
      else 0
    end;
end has_not_null_lob;

final
member function body_c
return clob
is
begin
  return
    case
      when self.body_vc is not null
      then to_clob(self.body_vc)
      when self.body_clob is not null
      then self.body_clob
    end;
end body_c;

final
member function envelope
return clob
is
begin
  return self.body_c;
end envelope;  

final
member function body_b
return blob
is
begin
  return
    case
      when self.body_raw is not null
      then to_blob(self.body_raw)
      when self.body_blob is not null
      then self.body_blob
    end;
end body_b;

end;
/
