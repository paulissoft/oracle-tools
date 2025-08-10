CREATE OR REPLACE TYPE BODY "REST_WEB_SERVICE_PUT_REQUEST_TYP" AS

overriding
final member function http_method
return varchar2
is
begin
  return 'PUT';
end http_method;

end;
/

