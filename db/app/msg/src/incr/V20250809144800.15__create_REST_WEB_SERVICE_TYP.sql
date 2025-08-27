create or replace type rest_web_service_typ under msg_typ
( rest_web_service_request rest_web_service_request_typ
, web_service_response web_service_response_typ -- When null, make_rest_request is invoked to fill this.
/**
REST web service
================
This type allows you to make a REST web service call, either synchronous or asynchronous, and store the result in the web_service_response attribute.

**/

, constructor function rest_web_service_typ
  ( self in out nocopy rest_web_service_typ
  , p_rest_web_service_request in rest_web_service_request_typ
  , p_web_service_response in web_service_response_typ default null
  )
  return self as result
/** The constructor method. **/

, overriding
  final member function must_be_processed
  ( self in rest_web_service_typ
  , p_maybe_later in integer -- True (1) or false (0)
  )
  return integer -- True (1) or false (0)
/** Must this object be processed? True if and only if attribute web_service_response is null. **/

, overriding
  final member procedure process$now
  ( self in rest_web_service_typ
  )
/**

When attribute web_service_response is null, invoke the appropiate APEX_WEB_SERVICE.MAKE_REST_REQUEST call,
store the output and response cookies and HTTP headers in this response attribute.
Next, enqueue (process) this object when web_service_response.correlation is not null.

When attribute web_service_response is NOT null, nothing happens (it is assumed to be already processed).

**/

, overriding
  final member procedure serialize
  ( self in rest_web_service_typ
  , p_json_object in out nocopy json_object_t
  )
/** Serialize to JSON. **/

, overriding
  member function has_not_null_lob
  ( self in rest_web_service_typ
  )
  return integer
/** Has this message a not null LOB (BLOB or CLOB)? 0 for No, 1 for Yes. **/  

)
final;
/
