CREATE TYPE "REST_WEB_SERVICE_DELETE_REQUEST_TYP" under rest_web_service_request_typ
(
/**
REST web service DELETE request
===============================
Implement a REST DELETE request.
**/
  constructor function rest_web_service_delete_request_typ
  ( self in out nocopy rest_web_service_delete_request_typ
    -- from MSG_TYP
  , p_group$ in varchar2 default null -- Use WEB_SERVICE_REQUEST_TYP.DEFAULT_GROUP() when null
  , p_context$ in varchar2 default null -- You may use WEB_SERVICE_REQUEST_TYP.GENERATE_UNIQUE_ID() to generate an AQ correlation id
    -- from HTTP_REQUEST_RESPONSE_TYP
  , p_cookies in http_cookie_tab_typ default null
  , p_http_headers in property_tab_typ default null
  , p_body_clob in clob default null
  , p_body_blob in blob default null
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
  , p_binary_response in integer default 0
  )
  return self as result
/** The constructor. **/

, overriding
  final member function http_method return varchar2
/** The HTTP method (DELETE). **/
)
final;
/

