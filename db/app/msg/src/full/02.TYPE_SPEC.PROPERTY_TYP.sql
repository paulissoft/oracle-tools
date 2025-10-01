CREATE TYPE "PROPERTY_TYP" authid definer as object
( name varchar2(256)
, value varchar2(32767)
/**
PROPERTY
========
An object type similar to the PL/SQL record APEX_WEB_SERVICE.HEADER and used for HTTP headers and HTTP parameters.
**/
)
final;
/

