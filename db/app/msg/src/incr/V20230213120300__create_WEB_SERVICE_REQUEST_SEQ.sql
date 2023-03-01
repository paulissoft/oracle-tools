declare
  -- ORA-00955: name is already used by an existing object
  e_object_already_exists exception;
  pragma exception_init(e_object_already_exists, -955);
begin
  execute immediate 'CREATE SEQUENCE "WEB_SERVICE_REQUEST_SEQ"  MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20 NOORDER  CYCLE  NOKEEP  NOSCALE  GLOBAL';
exception
  when e_object_already_exists
  then null;
end;
/
