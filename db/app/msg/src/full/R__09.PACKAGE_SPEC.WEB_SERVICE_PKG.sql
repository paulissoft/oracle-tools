CREATE OR REPLACE PACKAGE "WEB_SERVICE_PKG" AUTHID DEFINER AS 

/**
A package with some functions and procedures for web services.
**/

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

$if oracle_tools.cfg_pkg.c_apex_installed $then

subtype header_table is apex_web_service.header_table;

$else -- $if oracle_tools.cfg_pkg.c_apex_installed $then

-- from APEX_230200.WWV_FLOW_WEBSERVICES_API

type header is record (
    name       varchar2(256),
    value      varchar2(32767) );

type header_table is table of header index by binary_integer;

$end -- $if oracle_tools.cfg_pkg.c_apex_installed $then

subtype vc_arr2 is sys.dbms_sql.varchar2a;

empty_vc_arr vc_arr2;

g_request_cookies          sys.utl_http.cookie_table;
g_response_cookies         sys.utl_http.cookie_table;

g_headers                  header_table;
g_request_headers          header_table;

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

function data2json
( p_http_header_tab in header_table
)
return clob;
/** Convert a HTTP header table to a JSON array (as a CLOB). **/

function make_rest_request
( p_request in rest_web_service_request_typ
)
return web_service_response_typ;
/** Make a REST request and return the reponse object. **/

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

