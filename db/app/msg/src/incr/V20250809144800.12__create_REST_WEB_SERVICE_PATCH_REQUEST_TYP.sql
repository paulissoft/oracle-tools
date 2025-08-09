create or replace type rest_web_service_patch_request_typ under rest_web_service_request_typ
( /**
  -- REST_WEB_SERVICE_PATCH_REQUEST_TYP
  -- ==================================
  **/

  overriding
  final member function http_method return varchar2 -- must be overridden by a final function

)
final;
/
