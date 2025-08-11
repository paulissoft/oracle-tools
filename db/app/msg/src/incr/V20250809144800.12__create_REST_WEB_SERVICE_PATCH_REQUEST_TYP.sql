create or replace type rest_web_service_patch_request_typ under rest_web_service_request_typ
( /**
  -- REST_WEB_SERVICE_PATCH_REQUEST_TYP
  -- ==================================
  **/

  constructor function rest_web_service_patch_request_typ
  ( self in out nocopy rest_web_service_patch_request_typ
    -- from MSG_TYP
  , p_group$ in varchar2 default null -- use web_service_request_typ.default_group()
  , p_context$ in varchar2 default null -- you may use web_service_request_typ.generate_unique_id() to generate an AQ correlation id
    -- from HTTP_REQUEST_RESPONSE_TYP
  , p_cookies in http_cookie_tab_typ default null       -- request/response cookies
  , p_http_headers in property_tab_typ default null     -- request/response headers
  , p_body_clob in clob default null                    -- empty for GET request (envelope for a SOAP request)
  , p_body_blob in blob default null                    -- empty for GET request (empty for a SOAP request)
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

, overriding
  final member function http_method return varchar2 -- must be overridden by a final function

)
final;
/
