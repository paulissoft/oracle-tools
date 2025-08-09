create or replace type rest_web_service_delete_request_typ under rest_web_service_request_typ
( /**
  -- REST_WEB_SERVICE_DELETE_REQUEST_TYP
  -- ===================================
  **/
  overriding
  final member function http_method return varchar2

)
final;
/
