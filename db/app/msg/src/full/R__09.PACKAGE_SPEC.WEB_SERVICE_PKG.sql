CREATE OR REPLACE PACKAGE "WEB_SERVICE_PKG" AS 

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

END WEB_SERVICE_PKG;
/

