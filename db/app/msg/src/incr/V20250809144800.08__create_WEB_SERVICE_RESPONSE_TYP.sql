create or replace type web_service_response_typ under http_request_reponse_typ
( -- The attributes are common for SOAP (APEX_WEB_SERVICE.MAKE_RESPONSE) and REST (APEX_WEB_SERVICE.MAKE_REST_RESPONSE[_B]).
  -- However, no sensitive information like username or password is stored.
  web_service_request web_service_request_typ
, sql_code integer -- sqlcode
, sql_error_message varchar2(4000 byte) -- sqlerrm
, http_status_code integer -- apex_web_service.g_status_code
, http_reason_phrase varchar2(4000 byte)
  -- No real maximum size, see https://stackoverflow.com/questions/9513447/http-response-status-line-maximum-size.
  -- So we use 4000 byte as a compromise between
  -- a) utl_http.resp.reason_phrase (varchar2(256)) and
  -- b) apex_web_service.g_reason_phrase (can store sqlerrm)
/**

This type stores the response of a web service request.

**/
, constructor function web_service_response_typ
  ( self in out nocopy web_service_response_typ
    -- from MSG_TYP
  , p_group$ in varchar2 default null -- use default_group() from below
  , p_context$ in varchar2 default null
    -- from HTTP_REQUEST_REPONSE_TYP
  , p_cookies in http_cookie_tab_typ default null       -- request/response cookies
  , p_http_headers in http_header_tab_typ default null  -- request/response headers
  , p_body_vc in varchar2 default null                  -- empty for GET request (envelope for a SOAP request)
  , p_body_clob in clob default null                    -- idem
  , p_body_raw in raw default null                      -- empty for GET request (empty for a SOAP request)
  , p_body_blob in blob default null                    -- idem
    -- from WEB_SERVICE_RESPONSE_TYP
  , p_web_service_request in web_service_request_typ
  , p_sql_code in integer
  , p_sql_error_message in varchar2
  , p_http_status_code in integer  
  , p_http_reason_phrase in varchar2 default null
  )
  return self as result

, constructor function web_service_response_typ
  ( self in out nocopy web_service_response_typ
  )
  return self as result

, final member procedure construct
  ( self in out nocopy web_service_response_typ
    -- from MSG_TYP
  , p_group$ in varchar2
  , p_context$ in varchar2
    -- from HTTP_REQUEST_REPONSE_TYP
  , p_cookies in http_cookie_tab_typ default null       -- request/response cookies
  , p_http_headers in http_header_tab_typ default null  -- request/response headers
  , p_body_vc in varchar2 default null                  -- empty for GET request (envelope for a SOAP request)
  , p_body_clob in clob default null                    -- idem
  , p_body_raw in raw default null                      -- empty for GET request (empty for a SOAP request)
  , p_body_blob in blob default null                    -- idem
    -- from WEB_SERVICE_RESPONSE_TYP
  , p_web_service_request in web_service_request_typ
  , p_sql_code in integer
  , p_sql_error_message in varchar2
  , p_http_status_code in integer  
  , p_http_reason_phrase in varchar2
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
  member function default_processing_method
  ( self in web_service_response_typ
  )
  return varchar2
/** Returns NULL to indicate that a custom routine will dequeue and process the response. **/  

, static function default_group
  return varchar2
/** All sub types share the same response queue. You need to dequeue from that queue using the correlation id to get the response (type WEB_SERVICE_RESPONSE_TYP). **/  

)
not final;
/
