create or replace type http_request_response_typ under msg_typ
( cookies http_cookie_tab_typ    -- The request/response cookies
, http_headers property_tab_typ  -- The request/response headers
, body_vc varchar2(4000 byte)    -- Is empty for a GET request (envelope for a SOAP request)
, body_clob clob                 -- idem
, body_raw raw(2000)             -- Is empty for a GET request (empty for a SOAP request)
, body_blob blob                 -- idem

/**
HTTP request response
=====================
Common attributes and methods for SOAP/REST requests/responses.
See also:

- `APEX_WEB_SERVICE.MAKE_REQUEST`
- `APEX_WEB_SERVICE.MAKE_REST_REQUEST`
- `APEX_WEB_SERVICE.MAKE_REST_REQUEST_B`
**/

, final member procedure construct
  ( self in out nocopy http_request_response_typ
    -- from MSG_TYP
  , p_group$ in varchar2 -- The group this object belongs to
  , p_context$ in varchar2 -- The context of this object (may be a correlation id when put into AQ)
    -- from HTTP_REQUEST_RESPONSE_TYP
  , p_cookies in http_cookie_tab_typ -- The cookies
  , p_http_headers property_tab_typ -- The HTTP headers
  , p_body_clob in clob -- The character body (will be copied to body_vc when at most 4000 bytes, else to body_clob)
  , p_body_blob in blob -- The binary body (will be copied to body_raw when at most 2000 bytes, else to body_blob)
  )
/** The constructor method that can be used to construct sub types (this type is not instantiable). **/

, overriding member procedure serialize
  ( self in http_request_response_typ
  , p_json_object in out nocopy json_object_t
  )
/** Serialize to a JSON object. **/

, overriding member function has_not_null_lob
  ( self in http_request_response_typ
  )
  return integer -- 0=false, 1=true
/** Does the object have a non-null LOB (body_clob not null or body_blob not null)? **/

, final member function body_c
  return clob
/** Get the character body. **/

, final member function envelope
  return clob
/** Get the SOAP envelope (the character body). **/

, final member function body_b
  return blob
/** Get the binary body. **/

, final member function cookie_idx
  ( p_name in varchar2
  )
  return integer -- null when not found
/** Get the cookie index for this name (case sensitive). **/

, final member function http_header_idx
  ( p_name in varchar2
  )
  return integer -- null when not found
/** Get the HTTP header index for this name (case insensitive). **/  
)
not instantiable
not final;
/

begin
  oracle_tools.cfg_install_pkg.check_object_valid('TYPE', 'HTTP_REQUEST_RESPONSE_TYP');
end;
/
