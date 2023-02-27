CREATE TYPE "REST_WEB_SERVICE_REQUEST_TYP" under web_service_request_typ
( -- Attributes are derived from APEX_WEB_SERVICE.MAKE_REST_REQUEST[_B].
  http_method varchar2(10 byte)
, body_vc varchar2(4000 byte)
, body_clob clob
, body_raw raw(2000)
, body_blob blob
  -- parms_vc/parms_clob: json object with parameter name/value pairs like in apex_web_service.make_rest_request(..., parm_name, parm_value, ...)
, parms_vc varchar2(4000 byte)
, parms_clob clob
, binary_response integer -- do we invoke APEX_WEB_SERVICE.MAKE_REST_REQUEST (binary_response = 0) or APEX_WEB_SERVICE.MAKE_REST_REQUEST_B (binary_response = 1)?
/**

This type allows you to make a REST web service call, either synchronous or asynchronous.

The Oracle AQ documentation states this about enqueuing buffered messages: the
queue type for buffered messaging can be ADT, XML, ANYDATA, or RAW. For ADT
types with LOB attributes, only buffered messages with null LOB attributes can
be enqueued.

Since we want to be able to enqueue buffered messages we must take care of the
LOBs above. There are two variants: a small variant with suffix _vc/_raw or
otherwise the LOB variant with suffix _clob/_blob (meaning we can not use
buffered messages if it has a non null LOB).

**/
, constructor function rest_web_service_request_typ
  ( self in out nocopy rest_web_service_request_typ
    -- from web_service_request_typ
  , p_group$ in varchar2 default null -- use web_service_request_typ.default_group()
  , p_context$ in varchar2 default null -- you may use web_service_request_typ.generate_unique_id() to generate an AQ correlation id
  , p_url in varchar2
  , p_scheme in varchar2 default null -- 'Basic'
  , p_proxy_override in varchar2 default null
  , p_transfer_timeout in number default 180
  , p_wallet_path in varchar2 default null
  , p_https_host in varchar2 default null
  , p_credential_static_id in varchar2 default null
  , p_token_url in varchar2 default null
  , p_cookies_clob in clob default null
  , p_http_headers_clob in clob default null
    -- this type
  , p_http_method in varchar2 default 'GET'
  , p_body_clob in clob default null
  , p_body_blob in blob default null
  , p_parms_clob in clob default null
  , p_binary_response in integer default 0
  )
  return self as result

, constructor function rest_web_service_request_typ
  ( self in out nocopy rest_web_service_request_typ
  )
  return self as result

, final member procedure construct
  ( self in out nocopy rest_web_service_request_typ
    -- from web_service_request_typ
  , p_group$ in varchar2
  , p_context$ in varchar2
  , p_url in varchar2
  , p_scheme in varchar2 default null -- 'Basic'
  , p_proxy_override in varchar2 default null
  , p_transfer_timeout in number default 180
  , p_wallet_path in varchar2 default null
  , p_https_host in varchar2 default null
  , p_credential_static_id in varchar2 default null
  , p_token_url in varchar2 default null
  , p_cookies_clob in clob default null
  , p_http_headers_clob in clob default null
    -- this type
  , p_http_method in varchar2 default 'GET'
  , p_body_clob in clob default null
  , p_body_blob in blob default null
  , p_parms_clob in clob default null
  , p_binary_response in integer default 0
  )

, overriding
  member function must_be_processed
  ( self in rest_web_service_request_typ
  , p_maybe_later in integer -- True (1) or false (0)
  )
  return integer -- True (1) or false (0)

, overriding
  member procedure process$now
  ( self in rest_web_service_request_typ
  )
/**

Invoke the appropiate APEX_WEB_SERVICE.MAKE_REST_REQUEST call,
store the output and response cookies and HTTP headers in a WEB_SERVICE_RESPONSE_TYP and
enqueue (process) that if correlation is not null.

**/
, overriding
  member procedure serialize
  ( self in rest_web_service_request_typ
  , p_json_object in out nocopy json_object_t
  )

, overriding
  member function has_not_null_lob
  ( self in rest_web_service_request_typ
  )
  return integer

, member function response
  return web_service_response_typ
/** Invoke the web service and use the response (body, status, cookies, HTTP headers) to create a response object. **/
)
not final;
/

