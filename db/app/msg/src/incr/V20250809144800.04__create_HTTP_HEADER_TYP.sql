create or replace type http_header_typ authid definer as object
( -- from wwv_flow_webservices_api
  name varchar2(256)
, value varchar2(32767)
)
final;
/
