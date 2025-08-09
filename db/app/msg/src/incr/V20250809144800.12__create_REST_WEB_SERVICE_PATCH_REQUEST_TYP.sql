create or replace type rest_web_service_patch_request_typ under rest_web_service_request_typ
( /**
  -- REST_WEB_SERVICE_PATCH_REQUEST_TYP
  -- ==================================
  -- parameter name/value pairs like in apex_web_service.make_rest_request(..., parm_name, parm_value, ...)
  **/

  overriding
  final member function http_method return varchar2 -- must be overridden by a final function

)
final;
/
