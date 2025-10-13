CREATE TYPE "PROPERTY_TYP" authid definer as object
( name varchar2(256)
, value varchar2(32767)
/**
PROPERTY
========
An object type similar to the PL/SQL record APEX_WEB_SERVICE.HEADER and used for HTTP headers and HTTP parameters.
**/
, map member function to_string
  return varchar2 -- returns self.name||'='||self.value
/** For comparing properties (needed for "property" member of "properties"). **/
)
final;
/

