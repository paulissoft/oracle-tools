CREATE TYPE "REST_WEB_SERVICE_REQUEST_TYP" under web_service_request_typ
( parms property_tab_typ -- Query or body parameters
, use_query_parameters integer -- When 0 (false) put it in the body (not for HTTP method GET) else use query parameters (every HTTP method can use query parameters)
, binary_response integer -- Do we invoke APEX_WEB_SERVICE.MAKE_REST_REQUEST (binary_response = 0) or APEX_WEB_SERVICE.MAKE_REST_REQUEST_B (binary_response = 1)?
/**
REST web service request
========================
This type allows you to make a REST web service call, either synchronous or asynchronous.

The Oracle AQ documentation states this about enqueuing buffered messages: the
queue type for buffered messaging can be ADT, XML, ANYDATA, or RAW. For ADT
types with LOB attributes, only buffered messages with null LOB attributes can
be enqueued.

Since we want to be able to enqueue buffered messages, we must take care of the
LOBs above. There are two variants: a small variant with suffix _vc/_raw or
otherwise the LOB variant with suffix _clob/_blob (meaning we can not use
buffered messages if it has a non null LOB).

**/

, final member procedure construct
  ( self in out nocopy rest_web_service_request_typ
    -- from MSG_TYP
  , p_group$ in varchar2
  , p_context$ in varchar2
    -- from HTTP_REQUEST_RESPONSE_TYP
  , p_cookies in http_cookie_tab_typ -- The static cookies
  , p_http_headers in property_tab_typ -- The static HTTP headers
  , p_body_clob in clob
  , p_body_blob in blob
    -- from WEB_SERVICE_REQUEST_TYP
  , p_url in varchar2
  , p_scheme in varchar2
  , p_proxy_override in varchar2
  , p_transfer_timeout in number
  , p_wallet_path in varchar2
  , p_https_host in varchar2
  , p_credential_static_id in varchar2
  , p_token_url in varchar2
    -- from REST_WEB_SERVICE_REQUEST_TYP
  , p_parms in property_tab_typ
  , p_use_query_parameters in integer
  , p_binary_response in integer
  )
/** The constructor method that can be used to construct sub types (this type is not instantiable). **/

, static procedure construct
  ( p_http_method in varchar2 -- The HTTP method
    -- from MSG_TYP
  , p_group$ in varchar2 default null
  , p_context$ in varchar2 default null
    -- from HTTP_REQUEST_RESPONSE_TYP
  , p_cookies in http_cookie_tab_typ default null    -- The static cookies
  , p_http_headers in property_tab_typ default null  -- The static HTTP headers
  , p_body_clob in clob default null                 -- empty for a GET request (envelope for a SOAP request)
  , p_body_blob in blob default null                 -- empty for a GET request (empty for a SOAP request)
    -- from WEB_SERVICE_REQUEST_TYP
  , p_url in varchar2 default null
  , p_scheme in varchar2 default null -- 'Basic'
  , p_proxy_override in varchar2 default null
  , p_transfer_timeout in number default 180
  , p_wallet_path in varchar2 default null
  , p_https_host in varchar2 default null
  , p_credential_static_id in varchar2 default null
  , p_token_url in varchar2 default null
    -- from REST_WEB_SERVICE_REQUEST_TYP
  , p_parms in property_tab_typ default null
  , p_use_query_parameters in integer default 0
  , p_binary_response in integer default 0
  , p_rest_web_service_request out nocopy rest_web_service_request_typ -- Any of the REST_WEB_SERVICE_<HTTP_METHOD>_REQUEST_TYP types
  )
/** A static method to create a sub type based on the HTTP method. **/

, overriding member function must_be_processed
  ( self in rest_web_service_request_typ
  , p_maybe_later in integer -- True (1) or false (0)
  )
  return integer -- True (1) or false (0)
/** Must this object be processed? **/

, overriding member procedure process$now
  ( self in rest_web_service_request_typ
  )
/**

Steps:
1. Invoke `self.make_rest_request`.
2. Store the output and response cookies and HTTP headers in a `WEB_SERVICE_RESPONSE_TYP`.
3. Enqueue (process) that if the correlation id (attribute context$) is not null.

Now the actual response can be retrieved by response().
**/

, overriding member procedure serialize
  ( self in rest_web_service_request_typ
  , p_json_object in out nocopy json_object_t
  )
/** Serialize to JSON. **/

, overriding member function repr
  ( self in rest_web_service_request_typ
  )
  return clob
/**
Get the pretty printed JSON representation of a message (or one of its sub types).

See WEB_SERVICE_REQUEST_TYP.REPR(). Adds static function http_method().
**/

, static function response
  ( p_context$ in varchar2
  , p_wait in integer default 0 -- The time to wait for a response (default dbms_aq.no_wait).
  )
  return web_service_response_typ
/**
Retrieve the (last) response from the WEB_SERVICE_RESPONSE queue by its correlation id (p_context$).
When this object is processed (by process(), process$later() or ultimately via `process$now`) and the CONTEXT$ is not null,
the response will be put into the WEB_SERVICE_RESPONSE queue.
**/

, final member function response
  ( p_wait in integer default 0 -- The time to wait for a response (default dbms_aq.no_wait).
  )
  return web_service_response_typ
/**
Return `rest_web_service_request_typ.response(this.context$, p_wait)`.
**/

, member function make_rest_request
  return web_service_response_typ
/**

Invoke `web_service_pkg.make_rest_request`.

This is another (synchronous) way to make a REST request.

The other (asynchronous) way is through process() and then response().

**/

, member function http_method return varchar2 -- must be overridden by a final function
/** Return the HTTP method (must be overridden by the sub types). **/
)
not final
not instantiable;
/

