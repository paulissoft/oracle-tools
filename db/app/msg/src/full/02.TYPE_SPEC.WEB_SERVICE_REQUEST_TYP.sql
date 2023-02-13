CREATE TYPE "WEB_SERVICE_REQUEST_TYP" under msg_typ
( -- The attributes are common for SOAP (APEX_WEB_SERVICE.MAKE_REQUEST) and REST (APEX_WEB_SERVICE.MAKE_REST_REQUEST[_B]).
  -- However, no sensitive information like username or password is stored.
  url varchar2(2000 char)
, scheme varchar2(100 char)
, proxy_override varchar2(2000 char)
, transfer_timeout number
, wallet_path varchar2(2000 char)
, https_host varchar2(2000 char)
, credential_static_id varchar2(100 char)
, token_url varchar2(2000 char)
, cookies_vc varchar2(4000 byte)
, cookies_clob clob
, http_headers_vc varchar2(4000 byte)
, http_headers_clob clob
/**

This super type allows sub types to make a web service call, either synchronous or asynchronous.

When the correlation parameter is not null, the sub type is obliged to enqueue the web service response with that correlation number.

The correlation is stored in the attribute context$.

This allows for asynchronuous processing but retrieving the result later via a queue.

**/
, constructor function web_service_request_typ
  ( self in out nocopy web_service_request_typ
  , p_url in varchar2
  , p_scheme in varchar2 default null -- 'Basic'
  , p_proxy_override in varchar2 default null
  , p_transfer_timeout in number default 180
  , p_wallet_path in varchar2 default null
  , p_https_host in varchar2 default null
  , p_credential_static_id in varchar2 default null
  , p_token_url in varchar2 default null
  , p_correlation in varchar2 default null
  , p_cookies_clob in clob default null
  , p_http_headers_clob in clob default null
  )
  return self as result

, final member procedure construct
  ( self in out nocopy web_service_request_typ
  , p_url in varchar2
  , p_scheme in varchar2 default null -- 'Basic'
  , p_proxy_override in varchar2 default null
  , p_transfer_timeout in number default 180
  , p_wallet_path in varchar2 default null
  , p_https_host in varchar2 default null
  , p_credential_static_id in varchar2 default null
  , p_token_url in varchar2 default null
  , p_correlation in varchar2 default null
  , p_cookies_clob in clob default null
  , p_http_headers_clob in clob default null
  )

, overriding
  member procedure serialize
  ( self in web_service_request_typ
  , p_json_object in out nocopy json_object_t
  )

, overriding
  member function has_not_null_lob
  ( self in web_service_request_typ
  )
  return integer

, final member function correlation
  return varchar2
/** The correlation id. **/

, static function request_queue_name
  return varchar2
/** All sub types share the same request queue. **/  

, static function response_queue_name
  return varchar2
/** All sub types share the same response queue. You need to dequeue from that queue usig the correlation id to get the response (type WEB_SERVICE_RESPONSE_TYP). **/  

, static function generate_correlation
  return varchar2
/** return WEB_SERVICE_REQUEST_SEQ.NEXTVAL **/  
)
not final;
/

