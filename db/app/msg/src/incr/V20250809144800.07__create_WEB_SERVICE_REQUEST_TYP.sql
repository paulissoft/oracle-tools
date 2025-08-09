create or replace type web_service_request_typ under http_request_response_typ
( /**
  -- WEB_SERVICE_REQUEST_TYP
  -- =======================
  -- The attributes are common for SOAP (APEX_WEB_SERVICE.MAKE_REQUEST) and REST (APEX_WEB_SERVICE.MAKE_REST_REQUEST[_B]).
  -- However, no sensitive information like username or password is stored.
  **/
  url varchar2(32767)
, scheme varchar2(100)
, proxy_override varchar2(2000)
, transfer_timeout number
, wallet_path varchar2(2000)
, https_host varchar2(2000)
, credential_static_id varchar2(100)
, token_url varchar2(2000)

/**

This super type allows sub types to make a web service call, either synchronous or asynchronous.
When the context$ attribute is not null, the sub type is obliged to enqueue the web service response with that attribute as the correlation id.
This allows for asynchronuous processing but retrieving the result later via a queue.

**/
, constructor function web_service_request_typ
  ( self in out nocopy web_service_request_typ
    -- from MSG_TYP
  , p_group$ in varchar2 default null -- use default_group() from below
  , p_context$ in varchar2 default null -- you may use generate_unique_id() to generate an AQ correlation id
    -- from HTTP_REQUEST_RESPONSE_TYP
  , p_cookies in http_cookie_tab_typ default null       -- request/response cookies
  , p_http_headers in http_header_tab_typ default null  -- request/response headers
  , p_body_vc in varchar2 default null                  -- empty for GET request (envelope for a SOAP request)
  , p_body_clob in clob default null                    -- idem
  , p_body_raw in raw default null                      -- empty for GET request (empty for a SOAP request)
  , p_body_blob in blob default null                    -- idem
    -- from WEB_SERVICE_REQUEST_TYP
  , p_url in varchar2 default null
  , p_scheme in varchar2 default null -- 'Basic'
  , p_proxy_override in varchar2 default null
  , p_transfer_timeout in number default 180
  , p_wallet_path in varchar2 default null
  , p_https_host in varchar2 default null
  , p_credential_static_id in varchar2 default null
  , p_token_url in varchar2 default null
  )
  return self as result

, final member procedure construct
  ( self in out nocopy web_service_request_typ
    -- from MSG_TYP
  , p_group$ in varchar2
  , p_context$ in varchar2
    -- from HTTP_REQUEST_RESPONSE_TYP
  , p_cookies in http_cookie_tab_typ       -- request/response cookies
  , p_http_headers in http_header_tab_typ  -- request/response headers
  , p_body_vc in varchar2                  -- empty for GET request (envelope for a SOAP request)
  , p_body_clob in clob                    -- idem
  , p_body_raw in raw                      -- empty for GET request (empty for a SOAP request)
  , p_body_blob in blob                    -- idem
    -- from WEB_SERVICE_REQUEST_TYP  
  , p_url in varchar2
  , p_scheme in varchar2
  , p_proxy_override in varchar2
  , p_transfer_timeout in number
  , p_wallet_path in varchar2
  , p_https_host in varchar2
  , p_credential_static_id in varchar2
  , p_token_url in varchar2
  )

, overriding
  member procedure serialize
  ( self in web_service_request_typ
  , p_json_object in out nocopy json_object_t
  )

, static function default_group
  return varchar2
/** All sub types share the same request queue, this function. **/  

, static function generate_unique_id
  return varchar2
/** return WEB_SERVICE_REQUEST_SEQ.NEXTVAL **/  
)
not instantiable
not final;
/
