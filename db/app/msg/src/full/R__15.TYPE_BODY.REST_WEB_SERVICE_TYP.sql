CREATE OR REPLACE TYPE BODY "REST_WEB_SERVICE_TYP" AS

constructor function rest_web_service_typ
( self in out nocopy rest_web_service_typ
, p_rest_web_service_request in rest_web_service_request_typ
, p_web_service_response in web_service_response_typ
)
return self as result
is
begin
  (self as msg_typ).construct
  ( p_group$ => p_rest_web_service_request.group$
  , p_context$ => p_rest_web_service_request.context$
  );
  self.rest_web_service_request := p_rest_web_service_request;
  self.web_service_response := p_web_service_response;
  return;
end rest_web_service_typ;

overriding
member function must_be_processed
( self in rest_web_service_typ
, p_maybe_later in integer -- True (1) or false (0)
)
return integer -- True (1) or false (0)
is
  l_result integer;
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.MUST_BE_PROCESSED');
  dbug.print(dbug."input", 'p_maybe_later: %s', p_maybe_later);
$end

  l_result :=
    case
      when self.rest_web_service_request is null
      then 0
      when self.web_service_response is not null
      then 0
      else 1
    end;

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.print(dbug."output", 'return: %s', l_result);
  dbug.leave;
$end

  return l_result;
end must_be_processed;

overriding
member procedure process$now
( self in rest_web_service_typ
)
is
  l_msgid raw(16);
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.PROCESS$NOW');
$end

  web_service_pkg.make_rest_request
  ( p_request => self.rest_web_service_request
  , p_username => null
  , p_password => null
  , p_wallet_pwd => null
  , p_response => self.web_service_response
  );

  if self.web_service_response.context$ is not null
  then
    msg_aq_pkg.enqueue
    ( p_msg => self
    , p_correlation => self.web_service_response.context$
    , p_msgid => l_msgid
    );
  end if;

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end process$now;

overriding
member procedure serialize
( self in rest_web_service_typ
, p_json_object in out nocopy json_object_t
)
is
  l_rest_web_service_request json_object_t := json_object_t();
  l_web_service_response json_object_t := json_object_t();
begin
  (self as msg_typ).serialize(p_json_object);
  if self.rest_web_service_request is not null
  then
    self.rest_web_service_request.serialize(l_rest_web_service_request);
    p_json_object.put('REST_WEB_SERVICE_REQUEST', l_rest_web_service_request);
  end if;
  if self.web_service_response is not null
  then
    self.web_service_response.serialize(l_web_service_response);
    p_json_object.put('WEB_SERVICE_RESPONSE', l_web_service_response);
  end if;
end serialize;

overriding
member function has_not_null_lob
( self in rest_web_service_typ
)
return integer
is
begin
  return
    case
      when self.rest_web_service_request.has_not_null_lob() != 0
      then 1
      when self.web_service_response is not null
      then self.web_service_response.has_not_null_lob()
      else 0
    end;
end has_not_null_lob;

end;
/

