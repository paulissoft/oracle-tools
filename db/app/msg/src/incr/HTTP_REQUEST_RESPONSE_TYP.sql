create or replace type http_request_response_typ under msg_typ
( cookies http_cookie_tab_typ  -- request/response cookies
, headers http_header_tab_typ  -- request/response headers
, body_vc varchar2(4000 byte)  -- empty for get request
, body_clob clob               -- idem
, body_raw raw(2000)           -- idem
, body_blob blob               -- idem
)
not instantiable
not final;
/
