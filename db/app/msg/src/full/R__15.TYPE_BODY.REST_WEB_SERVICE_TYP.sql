CREATE OR REPLACE TYPE BODY "REST_WEB_SERVICE_TYP" AS

constructor function rest_web_service_typ
( self in out nocopy rest_web_service_typ
, p_request in rest_web_service_request_typ
)
return self as result
is
begin
  (self as msg_typ).construct
  ( p_group$ => p_request.group$
  , p_context$ => p_request.context$
  );
  self.request := p_request;
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
      when self.request is null
      then 0
      when self.request.context$ is null
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
  l_response web_service_response_typ;
  l_msgid raw(16);
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.PROCESS$NOW');
$end

  web_service_pkg.make_rest_request
  ( p_request => self.request
  , p_username => null
  , p_password => null
  , p_wallet_pwd => null
  , p_response => l_response
  );

  if l_response.context$ is not null
  then
    msg_aq_pkg.enqueue
    ( p_msg => l_response
    , p_correlation => l_response.context$
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
  l_json_request json_object_t := json_object_t();
  l_response constant web_service_response_typ := self.response();
  l_json_response json_object_t := json_object_t();
begin
  (self as msg_typ).serialize(p_json_object);
  if self.request is not null
  then
    self.request.serialize(l_json_request);
    p_json_object.put('REQUEST', l_json_request);
  end if;
  if l_response is not null
  then
    l_response.serialize(l_json_response);
    p_json_object.put('RESPONSE', l_json_response);
  end if;
end serialize;

member function response
return web_service_response_typ
is
begin
  
end response;

overriding
member function has_not_null_lob
( self in rest_web_service_typ
)
return integer
is
begin
  return self.request.has_not_null_lob();
end has_not_null_lob;

end;
/

