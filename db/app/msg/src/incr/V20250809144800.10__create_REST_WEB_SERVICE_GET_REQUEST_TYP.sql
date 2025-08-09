create or replace type rest_web_service_get_request_typ under rest_web_service_request_typ
( /**
  -- REST_WEB_SERVICE_GET_REQUEST_TYP
  -- ================================
  -- parameter name/value pairs like in apex_web_service.make_rest_request(..., parm_name, parm_value, ...)
  **/
  parms http_header_tab_type
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
, constructor function rest_web_service_get_request_typ
  ( self in out nocopy rest_web_service_get_request_typ
    -- from MSG_TYP
  , p_group$ in varchar2 default null -- use web_service_request_typ.default_group()
  , p_context$ in varchar2 default null -- you may use web_service_request_typ.generate_unique_id() to generate an AQ correlation id
    -- from HTTP_REQUEST_REPONSE_TYP
  , p_cookies in http_cookie_tab_typ default null       -- request/response cookies
  , p_http_headers in http_header_tab_typ default null  -- request/response headers
    -- from WEB_SERVICE_REQUEST_TYP
  , p_url in varchar2 default null
  , p_scheme in varchar2 default null -- 'Basic'
  , p_proxy_override in varchar2 default null
  , p_transfer_timeout in number default 180
  , p_wallet_path in varchar2 default null
  , p_https_host in varchar2 default null
  , p_credential_static_id in varchar2 default null
  , p_token_url in varchar2 default null
    -- from REST_WEB_SERVICE_GET_REQUEST_TYP
  , p_query_parms in http_header_tab_type default null -- query parameters
  , p_binary_response in integer default 0
  )
  return self as result

, constructor function rest_web_service_get_request_typ
  ( self in out nocopy rest_web_service_get_request_typ
  )
  return self as result

, final member procedure construct
  ( self in out nocopy rest_web_service_get_request_typ
    -- from MSG_TYP
  , p_group$ in varchar2
  , p_context$ in varchar2
    -- from HTTP_REQUEST_REPONSE_TYP
  , p_cookies in http_cookie_tab_typ -- default null       -- request/response cookies
  , p_http_headers in http_header_tab_typ -- default null  -- request/response headers
    -- from WEB_SERVICE_REQUEST_TYP
  , p_url in varchar2
  , p_scheme in varchar2 -- default null -- 'Basic'
  , p_proxy_override in varchar2 -- default null
  , p_transfer_timeout in number -- default 180
  , p_wallet_path in varchar2 -- default null
  , p_https_host in varchar2 -- default null
  , p_credential_static_id in varchar2 -- default null
  , p_token_url in varchar2 -- default null
    -- from REST_WEB_SERVICE_GET_REQUEST_TYP
  , p_query_parms in http_header_tab_type -- default null -- query parameters
  , p_binary_response in integer -- default 0
  )

, overriding
  final member function http_method return varchar2

, final member function query_parms return http_header_tab_type

)
final;
/
