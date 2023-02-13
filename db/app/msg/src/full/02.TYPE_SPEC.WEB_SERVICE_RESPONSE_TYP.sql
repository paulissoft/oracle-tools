CREATE TYPE "WEB_SERVICE_RESPONSE_TYP" under msg_typ
( -- The attributes are common for SOAP (APEX_WEB_SERVICE.MAKE_RESPONSE) and REST (APEX_WEB_SERVICE.MAKE_REST_RESPONSE[_B]).
  -- However, no sensitive information like username or password is stored.
  web_service_request web_service_request_typ
, http_status_code integer -- apex_web_service.g_status_code
, body_vc varchar2(4000 byte)
, body_clob clob
, body_raw raw(2000)
, body_blob blob
  -- JSON constructed from apex_web_service.g_response_cookies, a sys.utl_http.cookie_table.
, cookies_vc varchar2(4000 byte)
, cookies_clob clob
  -- JSON constructed from apex_web_service.g_headers, a table of name/value pairs.
, http_headers_vc varchar2(4000 byte)
, http_headers_clob clob
/**

This type stores the response of a web service request.

**/
, constructor function web_service_response_typ
  ( self in out nocopy web_service_response_typ
  , web_service_request in web_service_request_typ
  , p_http_status_code in integer  
  , p_body_clob in clob default null
  , p_body_blob in blob default null
  , p_cookies_clob in clob default null
  , p_http_headers_clob in clob default null
  )
  return self as result

, final member procedure construct
  ( self in out nocopy web_service_response_typ
  , web_service_request in web_service_request_typ
  , p_http_status_code in integer  
  , p_body_clob in clob default null
  , p_body_blob in blob default null
  , p_cookies_clob in clob default null
  , p_http_headers_clob in clob default null
  )

, overriding
  member function must_be_processed
  ( self in web_service_response_typ
  , p_maybe_later in integer -- True (1) or false (0)
  )
  return integer -- True (1) or false (0)
/** Will return 0 if the request correlation is null, meaning it won't get enqueued. **/

, overriding
  member procedure process$later
  ( self in web_service_response_typ
  )
/** Will enqueue but without registering a PL/SQL notification callback. **/

, overriding
  member procedure process$now
  ( self in web_service_response_typ
  )
/** Will just raise an exception since you are supposed to dequeue yourself. **/

, overriding
  member procedure serialize
  ( self in web_service_response_typ
  , p_json_object in out nocopy json_object_t
  )

, overriding
  member function has_not_null_lob
  ( self in web_service_response_typ
  )
  return integer

)
not final;
/

