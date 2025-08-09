create or replace type body http_request_response_typ
is

constructor function http_request_response_typ
( self in out nocopy http_request_response_typ
  -- from MSG_TYP
, p_group$ in varchar2 default null -- use default_group() from below
, p_context$ in varchar2 default null -- you may use generate_unique_id() to generate an AQ correlation id
  -- from HTTP_REQUEST_RESPONSE_TYP
, p_cookies in http_cookie_tab_typ default null
, p_http_headers http_header_tab_typ default null
, p_body_vc in varchar2 default null
, p_body_clob in clob default null
, p_body_raw in raw default null
, p_body_blob in blob default null
)
return self as result
is
begin

  return;
end;

final member procedure construct
( self in out nocopy http_request_response_typ
  -- from MSG_TYP
, p_group$ in varchar2
, p_context$ in varchar2
  -- from HTTP_REQUEST_RESPONSE_TYP
, p_cookies in http_cookie_tab_typ
, p_http_headers http_header_tab_typ
, p_body_vc in varchar2
, p_body_clob in clob
, p_body_raw in raw
, p_body_blob in blob
)
is
begin
  (self as msg_typ).construct(nvl(p_group$, web_service_request_typ.default_group()), p_context$);
  self.cookies := p_cookies;
  self.http_headers := p_http_headers;
  self.body_vc := p_body_vc;
  self.body_clob := p_body_clob;
  self.body_raw := p_body_raw;
  self.body_blob := p_body_blob;
end construct;

overriding
member procedure serialize
( self in http_request_response_typ
, p_json_object in out nocopy json_object_t
)
is
begin
  null;
end serialize;

overriding
member function has_not_null_lob
( self in http_request_response_typ
)
return integer

static function default_group
return varchar2

static function generate_unique_id
return varchar2

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
end boddy_c;

final
member function envelope
return clob
is
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
