CREATE OR REPLACE PACKAGE "WEB_SERVICE_PKG" AUTHID DEFINER AS 

procedure json2data
( p_cookies in json_array_t
, p_cookie_tab out nocopy sys.utl_http.cookie_table
);

procedure data2json
( p_cookie_tab in sys.utl_http.cookie_table
, p_cookies out nocopy json_array_t
);

procedure json2data
( p_http_headers in json_array_t
, p_http_header_tab out nocopy apex_web_service.header_table
);

procedure data2json
( p_http_header_tab in apex_web_service.header_table
, p_http_headers out nocopy json_array_t
);

function make_rest_request
( p_request in rest_web_service_request_typ
)
return web_service_response_typ;

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

$end -- $if msg_aq_pkg.c_testing $then

END WEB_SERVICE_PKG;
/

