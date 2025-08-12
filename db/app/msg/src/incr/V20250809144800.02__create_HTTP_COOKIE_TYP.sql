create or replace type http_cookie_typ authid definer as object
( name varchar2(256)
, value varchar2(1024)
, domain varchar2(256)
, expire timestamp with time zone
, path varchar2(1024)
, secure number(1, 0) -- numeric boolean: 0=false, 1=true
, version integer
, "COMMENT" varchar2(1024) -- just comment gives PLS-00330: invalid use of type name or subtype name
/**
HTTP_COOKIE_TYP
===============
An object type similar to the PL/SQL record SYS.UTL_HTTP.COOKIE.
**/
)
final;
/
