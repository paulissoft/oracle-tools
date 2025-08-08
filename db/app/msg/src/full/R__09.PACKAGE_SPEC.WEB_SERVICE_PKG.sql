CREATE OR REPLACE PACKAGE "WEB_SERVICE_PKG" AUTHID DEFINER AS 

/**
A package with some functions and procedures for web services.
**/

c_prefer_to_use_utl_http constant boolean := false;

subtype vc_arr2 is sys.dbms_sql.varchar2a;

empty_vc_arr vc_arr2;

$if oracle_tools.cfg_pkg.c_apex_installed $then

subtype header_table is apex_web_service.header_table;

$else -- $if oracle_tools.cfg_pkg.c_apex_installed $then

-- from APEX_230200.WWV_FLOW_WEBSERVICES_API

type header is record (
    name       varchar2(256),
    value      varchar2(32767) );

type header_table is table of header index by binary_integer;

$end -- $if oracle_tools.cfg_pkg.c_apex_installed $then

procedure json2data
( p_cookies in json_array_t
, p_cookie_tab out nocopy sys.utl_http.cookie_table
);
/** Convert a JSON array to a HTTP cookie table. **/

procedure data2json
( p_cookie_tab in sys.utl_http.cookie_table
, p_cookies out nocopy json_array_t
);
/** Convert a HTTP cookie table to a JSON array. **/

function data2json
( p_cookie_tab in sys.utl_http.cookie_table
)
return clob;
/** Convert a HTTP cookie table to a JSON array (as a CLOB). **/

procedure json2data
( p_http_headers in json_array_t
, p_http_header_tab out nocopy header_table
);
/** Convert a JSON array to a HTTP header table. **/

procedure data2json
( p_http_header_tab in header_table
, p_http_headers out nocopy json_array_t
);
/** Convert a HTTP header table to a JSON array. **/

procedure data2json
( p_http_headers out nocopy json_array_t
);
/** Convert a HTTP header table to a JSON array but use the request header table set by set_request_headers/remove_request_header/clear_request_headers. */

function data2json
( p_http_header_tab in header_table
)
return clob;
/** Convert a HTTP header table to a JSON array (as a CLOB). **/

function data2json
return clob;
/** Convert a HTTP header table to a JSON array (as a CLOB) but use the request header table set by set_request_headers/remove_request_header/clear_request_headers. **/

procedure set_request_headers
( p_name_01 in varchar2 default null
, p_value_01 in varchar2 default null
, p_name_02 in varchar2 default null
, p_value_02 in varchar2 default null
, p_name_03 in varchar2 default null
, p_value_03 in varchar2 default null
, p_name_04 in varchar2 default null
, p_value_04 in varchar2 default null
, p_name_05 in varchar2 default null
, p_value_05 in varchar2 default null
, p_reset in boolean default true
, p_skip_if_exists in boolean default false
);
/** See apex_web_service.set_request_headers. */

procedure remove_request_header
( p_name in varchar2
);
/** See apex_web_service.remove_request_header. */

procedure clear_request_headers;
/** See apex_web_service.clear_request_headers. */

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
, p_http_method in varchar2 -- The HTTP Method to use, PUT, POST, GET, HEAD or DELETE
, p_username in varchar2 default null -- The username if basic authentication is required for this service
, p_password in varchar2 default null -- The password if basic authentication is required for this service
, p_scheme in varchar2 default 'Basic' -- The authentication scheme, Basic (default), OAUTH_CLIENT_CRED or AWS
, p_proxy_override in varchar2 default null -- The proxy to use for the request
, p_transfer_timeout in number default 180 -- The amount of time in seconds to wait for a response
, p_body in clob default empty_clob() -- The HTTP payload to be sent as clob
, p_body_blob in blob default empty_blob() -- The HTTP payload to be sent as binary blob (ex., posting a file)
, p_parm_name in vc_arr2 default empty_vc_arr -- The name of the parameters to be used in name/value pairs
, p_parm_value in vc_arr2 default empty_vc_arr -- The value of the parameters to be used in name/value pairs
, p_wallet_path in varchar2 default null -- The filesystem path to a wallet if request is https, ex., file:/usr/home/oracle/WALLETS
, p_wallet_pwd in varchar2 default null -- The password to access the wallet
, p_https_host in varchar2 default null -- The host name to be matched against the common name (CN) of the remote server's certificate for an HTTPS request
, p_credential_static_id in varchar2 default null -- The name of the credential store to be used.
, p_token_url in varchar2 default null -- For token-based authentication flows: The URL where to get the token from.
)
return web_service_response_typ;
/** See apex_web_service.make_rest_request. */

subtype http_status_code_t is positive;
subtype http_status_code_nn_t is positiven;
subtype http_status_description_t is varchar2(100 byte) not null;
subtype http_reason_phrase_t is varchar2(4000 byte);

procedure handle_response
( p_response in web_service_response_typ -- The REST request response
, p_http_status_code out nocopy http_status_code_nn_t
, p_http_status_description out nocopy http_status_description_t
, p_http_reason_phrase out nocopy http_reason_phrase_t
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
procedure ut_set_request_headers;

--%test
procedure ut_remove_request_header;

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

