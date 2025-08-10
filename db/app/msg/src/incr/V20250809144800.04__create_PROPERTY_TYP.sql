create or replace type property_typ authid definer as object
( -- from wwv_flow_webservices_api.header
  name varchar2(256)
, value varchar2(32767)
)
final;
/
