create or replace type rest_web_service_put_request_typ under web_service_request_typ
( /**
  -- REST_WEB_SERVICE_PUT_REQUEST_TYP
  -- ================================
  **/

  overriding
  final member function http_method return varchar2

)
final;
/
