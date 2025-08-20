CREATE OR REPLACE PACKAGE "WEB_SERVICE_PKG" AUTHID DEFINER AS 

/**
Invoke web services
===================

A package introduced to provide backwards compability with APEX_WEB_SERVICE, i.e. functions and procedures for web services.

The usual way of invoking a web service via APEX_WEB_SERVICE:

1. set request headers via `APEX_WEB_SERVICE.CLEAR_REQUEST_HEADERS` and `APEX_WEB_SERVICE.SET_REQUEST_HEADERS`
2. clear cookies via `APEX_WEB_SERVICE.CLEAR_REQUEST_COOKIES`
3. invoke `make_rest_request` (or `make_rest_request_b`)

This package allows you to combine steps 1 and 2 and thus just invoke one routine. There is a `make_rest_request` and `make_rest_request_b` function that you can use in a SQL query.

Furthermore, there is `handle_response` for handling the HTTP response, raising by default an exception when the HTTP status code is not 2XX.

The response to the function call `make_rest_request` or `make_rest_request_b`, is an object with all the data from the HTTP response.

See also [APEX_WEB_SERVICE The Definitive Guide](https://blog.cloudnueva.com/apexwebservice-the-definitive-guide).

**/

c_prefer_to_use_utl_http constant boolean := false;

function make_rest_request
( p_request in rest_web_service_request_typ -- The request
, p_username in varchar2 default null -- The username if basic authentication is required for this service
, p_password in varchar2 default null -- The password if basic authentication is required for this service
, p_wallet_pwd in varchar2 default null -- The password to access the wallet
)
return web_service_response_typ;
/** Make a REST request and return the response object. **/

function make_rest_request
( p_url in varchar2 -- The url endpoint of the Web service
, p_http_method in varchar2 default 'GET' -- The HTTP Method to use, PUT, POST, GET, HEAD or DELETE
, p_scheme in varchar2 default 'Basic' -- The authentication scheme, Basic (default), OAUTH_CLIENT_CRED or AWS
, p_cookies in http_cookie_tab_typ default null -- The HTTP cookies
, p_http_headers in property_tab_typ default null -- The HTTP headers
, p_body in clob default null -- The HTTP payload to be sent as clob (but maybe used as query parameters for GET)
, p_body_blob in blob default null -- The HTTP payload to be sent as binary blob (ex., posting a file)
, p_proxy_override in varchar2 default null -- The proxy to use for the request
, p_transfer_timeout in number default 180 -- The amount of time in seconds to wait for a response
, p_wallet_path in varchar2 default null -- The filesystem path to a wallet if request is https, ex., file:/usr/home/oracle/WALLETS
, p_https_host in varchar2 default null -- The host name to be matched against the common name (CN) of the remote server's certificate for an HTTPS request
, p_credential_static_id in varchar2 default null -- The name of the credential store to be used.
, p_token_url in varchar2 default null -- For token-based authentication flows: The URL where to get the token from.
, p_parms in property_tab_typ default null -- The query parameters (GET) or body parameters (not GET and empty body payload)
  -- credential related parameters (not stored in REST_WEB_SERVICE_REQUEST_TYP)
, p_username in varchar2 default null -- The username if basic authentication is required for this service
, p_password in varchar2 default null -- The password if basic authentication is required for this service
, p_wallet_pwd in varchar2 default null -- The password to access the wallet
)
return web_service_response_typ;
/** See APEX_WEB_SERVICE.MAKE_REST_REQUEST. **/

function make_rest_request_b
( p_url in varchar2 -- The url endpoint of the Web service
, p_http_method in varchar2 default 'GET' -- The HTTP Method to use, PUT, POST, GET, HEAD or DELETE
, p_scheme in varchar2 default 'Basic' -- The authentication scheme, Basic (default), OAUTH_CLIENT_CRED or AWS
, p_cookies in http_cookie_tab_typ default null -- The HTTP cookies
, p_http_headers in property_tab_typ default null -- The HTTP headers
, p_body in clob default null -- The HTTP payload to be sent as clob (but maybe used as query parameters for GET)
, p_body_blob in blob default null -- The HTTP payload to be sent as binary blob (ex., posting a file)
, p_proxy_override in varchar2 default null -- The proxy to use for the request
, p_transfer_timeout in number default 180 -- The amount of time in seconds to wait for a response
, p_wallet_path in varchar2 default null -- The filesystem path to a wallet if request is https, ex., file:/usr/home/oracle/WALLETS
, p_https_host in varchar2 default null -- The host name to be matched against the common name (CN) of the remote server's certificate for an HTTPS request
, p_credential_static_id in varchar2 default null -- The name of the credential store to be used.
, p_token_url in varchar2 default null -- For token-based authentication flows: The URL where to get the token from.
, p_parms in property_tab_typ default null -- The query parameters (GET) or body parameters (not GET and empty body payload)
  -- credential related parameters (not stored in REST_WEB_SERVICE_REQUEST_TYP)
, p_username in varchar2 default null -- The username if basic authentication is required for this service
, p_password in varchar2 default null -- The password if basic authentication is required for this service
, p_wallet_pwd in varchar2 default null -- The password to access the wallet
)
return web_service_response_typ;
/** See APEX_WEB_SERVICE.MAKE_REST_REQUEST_B. **/

subtype http_status_code_t is positive;
subtype http_status_description_t is varchar2(100 byte);
subtype http_reason_phrase_t is varchar2(4000 byte);

procedure handle_response
( p_response in web_service_response_typ -- The REST request response
, p_http_status_code out nocopy http_status_code_t -- The HTTP status code
, p_http_status_description out nocopy http_status_description_t -- The HTTP status description
, p_http_reason_phrase out nocopy http_reason_phrase_t -- The HTTP reason phrase
, p_body_clob out nocopy clob -- The HTTP character body
);

procedure handle_response
( p_response in web_service_response_typ -- The REST request response
, p_http_status_code out nocopy http_status_code_t -- The HTTP status code
, p_http_status_description out nocopy http_status_description_t -- The HTTP status description
, p_http_reason_phrase out nocopy http_reason_phrase_t -- The HTTP reason phrase
, p_body_blob out nocopy blob -- The HTTP binary body
);
/**

Handles the REST request response:

- handle X-RateLimit header parameters, i.e. waiting more till the rate limit reset
- raise an exception in the range -20XYZ where XYZ is the HTML status code returned unless X = 2 since that means success
*/

$if msg_aq_pkg.c_testing $then

-- test functions

--%suitepath(MSG)
--%suite

--%beforeeach
--%rollback(manual)
procedure ut_setup;

--%aftereach
--%rollback(manual)
procedure ut_teardown;

--%test
--%rollback(manual)
procedure ut_rest_web_service_get_cb; -- processed by callback

--%test
--%rollback(manual)
procedure ut_rest_web_service_get_job; -- processed by job

--%test
--%rollback(manual)
procedure ut_rest_web_service_post;

--%test
--%rollback(manual)
procedure ut_rest_web_service_get_job_bulk; -- processed by job

$end -- $if msg_aq_pkg.c_testing $then

END WEB_SERVICE_PKG;
/

