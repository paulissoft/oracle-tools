create or replace type rest_web_service_typ under msg_typ
( request rest_web_service_request_typ
/**
REST web service
================
This type allows you to make a REST web service call, either synchronous or asynchronous, and store the result in request queue when rest_web_service_request.context$ is not null.

**/

, constructor function rest_web_service_typ
  ( self in out nocopy rest_web_service_typ
  , p_request in rest_web_service_request_typ
  )
  return self as result
/** The constructor method. **/

, overriding
  member function must_be_processed
  ( self in rest_web_service_typ
  , p_maybe_later in integer -- True (1) or false (0)
  )
  return integer -- True (1) or false (0)
/** Must this object be processed? True if and only if attribute web_service_response is null. **/

, overriding
  member procedure process$now
  ( self in rest_web_service_typ
  )
/**

When attribute web_service_response is null, invoke the appropiate APEX_WEB_SERVICE.MAKE_REST_REQUEST call,
store the output and response cookies and HTTP headers in this response attribute.
Next, enqueue (process) this object when web_service_response.correlation is not null.

When attribute web_service_response is NOT null, nothing happens (it is assumed to be already processed).

**/

, overriding
  member procedure serialize
  ( self in rest_web_service_typ
  , p_json_object in out nocopy json_object_t
  )
/** Serialize to JSON. **/

, member function response
  return web_service_response_typ
/** Use the request context as correlation id to get the response from the web service response queue (BROWSE mode). **/

, overriding
  member function has_not_null_lob
  ( self in rest_web_service_typ
  )
  return integer
/** Has this message a not null LOB (BLOB or CLOB)? 0 for No, 1 for Yes. **/  

)
final;
/
