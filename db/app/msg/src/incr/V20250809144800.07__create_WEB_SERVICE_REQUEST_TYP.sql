create or replace type web_service_request_typ under http_request_response_typ
( -- See APEX_WEB_SERVICE.MAKE_REST_REQUEST for a more detailed description.
  url varchar2(32767)
, scheme varchar2(100)
, proxy_override varchar2(2000)
, transfer_timeout number
, wallet_path varchar2(2000)
, https_host varchar2(2000)
, credential_static_id varchar2(100)
, token_url varchar2(2000)

/**
WEB service request
===================
The attributes are common for SOAP (APEX_WEB_SERVICE.MAKE_REQUEST) and REST (APEX_WEB_SERVICE.MAKE_REST_REQUEST[_B]) requests.
However, no sensitive information like username or password is stored.

This super type allows sub types to make a web service call, either synchronous or asynchronous.
When the context$ attribute is not null, the sub type is obliged to enqueue the web service response with that attribute as the correlation id.
This allows for asynchronous processing and retrieving the result later via the response queue.

**/

, final member procedure construct
  ( self in out nocopy web_service_request_typ
    -- from MSG_TYP
  , p_group$ in varchar2
  , p_context$ in varchar2
    -- from HTTP_REQUEST_RESPONSE_TYP
  , p_cookies in http_cookie_tab_typ
  , p_http_headers in property_tab_typ
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
  )
/** The constructor method that can be used to construct sub types (this type is not instantiable). **/

, overriding
  member procedure serialize
  ( self in web_service_request_typ
  , p_json_object in out nocopy json_object_t
  )
/** Serialize to a JSON object. **/

, static function default_group
  return varchar2
/** All sub types share the same request queue based on the value of this function. **/  

, static function generate_unique_id
  return varchar2
/** Return WEB_SERVICE_REQUEST_SEQ.NEXTVAL **/  
)
not instantiable
not final;
/
