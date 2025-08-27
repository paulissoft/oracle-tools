create or replace type web_service_response_typ authid definer under http_request_response_typ
( sql_code integer -- Will store the result of PL/SQL function SQLCODE
, sql_error_message varchar2(4000 byte) -- Will store the result of PL/SQL function SQLERRM
, http_status_code integer -- May store the result of APEX_WEB_SERVICE.G_STATUS_CODE (or its UTL_HTTP equivalent)
, http_reason_phrase varchar2(4000 byte) -- More details about the HTTP status
, elapsed_time_ms integer -- Elapsed time in milliseconds
/**
WEB service response
====================

This type stores the response of a web service request.

The attributes are common for SOAP (`APEX_WEB_SERVICE.MAKE_REQUEST`) and REST (`APEX_WEB_SERVICE.MAKE_REST_REQUEST[_B]`) responses.

For http_reason_phrase:

-- No real maximum size, see [HTTP Response Status-Line maximum size](https://stackoverflow.com/questions/9513447/http-response-status-line-maximum-size).
-- So we use 4000 byte as a compromise between:
-- a) UTL_HTTP.RESP.REASON_PHRASE (varchar2(256)) and
-- b) APEX_WEB_SERVICE.G_REASON_PHRASE (can store SQLERRM)

**/
, constructor function web_service_response_typ
  ( self in out nocopy web_service_response_typ
    -- from MSG_TYP
  , p_group$ in varchar2 default null                -- Use default_group() from below when null
  , p_context$ in varchar2 default null
    -- from HTTP_REQUEST_RESPONSE_TYP
  , p_cookies in http_cookie_tab_typ default null
  , p_http_headers in property_tab_typ default null
  , p_body_clob in clob default null                 -- empty for a GET request (envelope for a SOAP request)
  , p_body_blob in blob default null                 -- empty for a GET request (empty for a SOAP request)
    -- from WEB_SERVICE_RESPONSE_TYP
  , p_sql_code in integer default null
  , p_sql_error_message in varchar2 default null
  , p_http_status_code in integer default null
  , p_http_reason_phrase in varchar2 default null
  , p_elapsed_time_ms in integer default null
  )
  return self as result
/** The constructor. **/

, final member procedure construct
  ( self in out nocopy web_service_response_typ
    -- from MSG_TYP
  , p_group$ in varchar2
  , p_context$ in varchar2
    -- from HTTP_REQUEST_RESPONSE_TYP
  , p_cookies in http_cookie_tab_typ
  , p_http_headers in property_tab_typ
  , p_body_clob in clob
  , p_body_blob in blob
    -- from WEB_SERVICE_RESPONSE_TYP
  , p_sql_code in integer
  , p_sql_error_message in varchar2
  , p_http_status_code in integer  
  , p_http_reason_phrase in varchar2
  , p_elapsed_time_ms in integer
  )
/**
A construct method that can be used in this type or sub types.
There is no super() constructor syntax but self.construct() is possible.
**/

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
/** Serialize to JSON. */

, overriding
  member function default_processing_method
  ( self in web_service_response_typ
  )
  return varchar2
/** Returns NULL to indicate that a custom routine will dequeue and process the response. **/  

, static function default_group
  return varchar2
/**
All sub types share the same response queue.
You need to dequeue from that queue using the correlation id to get the response (type WEB_SERVICE_RESPONSE_TYP).
**/  

, final member function http_status_descr
  return varchar2
  deterministic
/** Returns the HTTP status code description, e.g. OK for HTTP status code 200. **/

, final member procedure handle_response
  ( self in web_service_response_typ -- The REST request response
  , p_check_http_status_code_ok in integer default 1 -- Check that HTTP status code is between 200 and 299 (0=false)
  , p_http_status_code out nocopy integer -- The HTTP status code
  , p_http_status_description out nocopy varchar2 -- The HTTP status description
  , p_http_reason_phrase out nocopy varchar2 -- The HTTP reason phrase
  , p_body_clob out nocopy clob -- The HTTP character body
  , p_retry_after out nocopy varchar2 -- Retry-After HTTP header
  , p_x_ratelimit_limit out nocopy varchar2 -- X-RateLimit-Limit HTTP header
  , p_x_ratelimit_remaining out nocopy varchar2 -- X-RateLimit-Remaining HTTP header
  , p_x_ratelimit_reset out nocopy varchar2 -- X-RateLimit-Reset HTTP header
  )
/** Get the character body plus other HTTP response info. **/

, final member procedure handle_response
  ( self in web_service_response_typ -- The REST request response
  , p_check_http_status_code_ok in integer default 1 -- Check that HTTP status code is between 200 and 299 (0=false)
  , p_http_status_code out nocopy integer -- The HTTP status code
  , p_http_status_description out nocopy varchar2 -- The HTTP status description
  , p_http_reason_phrase out nocopy varchar2 -- The HTTP reason phrase
  , p_body_blob out nocopy blob -- The HTTP binary body
  , p_retry_after out nocopy varchar2 -- Retry-After HTTP header
  , p_x_ratelimit_limit out nocopy varchar2 -- X-RateLimit-Limit HTTP header
  , p_x_ratelimit_remaining out nocopy varchar2 -- X-RateLimit-Remaining HTTP header
  , p_x_ratelimit_reset out nocopy varchar2 -- X-RateLimit-Reset HTTP header
  )
/** Get the binary body plus other HTTP response info. **/
)
not final;
/
