create or replace type http_request_response_typ under msg_typ
( /**
  -- HTTP_REQUEST_RESPONSE_TYP
  -- =========================
  -- Common attributes for SOAP/REST request/responses.
  -- However, no sensitive information like username or password is stored.
  -- See also:
  --
  -- - APEX_WEB_SERVICE.MAKE_REQUEST
  -- - APEX_WEB_SERVICE.MAKE_REST_REQUEST
  -- - APEX_WEB_SERVICE.MAKE_REST_REQUEST_B
  **/
  cookies http_cookie_tab_typ       -- request/response cookies
, http_headers http_header_tab_typ  -- request/response headers
, body_vc varchar2(4000 byte)       -- empty for GET request (envelope for a SOAP request)
, body_clob clob                    -- idem
, body_raw raw(2000)                -- empty for GET request (empty for a SOAP request)
, body_blob blob                    -- idem

/**

This super type allows sub types to make a web service call, either synchronous or asynchronous.
When the context$ attribute is not null, the sub type is obliged to enqueue the web service response with that attribute as the correlation id.
This allows for asynchronuous processing but retrieving the result later via a queue.

**/
, constructor function http_request_response_typ
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

, final member procedure construct
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

, overriding
  member procedure serialize
  ( self in http_request_response_typ
  , p_json_object in out nocopy json_object_t
  )

, overriding
  member function has_not_null_lob
  ( self in http_request_response_typ
  )
  return integer

, static function default_group
  return varchar2
/** All sub types share the same request queue, this function. **/  

, static function generate_unique_id
  return varchar2
/** return WEB_SERVICE_REQUEST_SEQ.NEXTVAL **/  

, final member function body_c return clob
/** Get the character body. **/

, final member function envelope return clob
/** Get the SOAP envelope. **/

, final member function body_b return blob
/** Get the binary body. **/
)
not instantiable
not final;
/
