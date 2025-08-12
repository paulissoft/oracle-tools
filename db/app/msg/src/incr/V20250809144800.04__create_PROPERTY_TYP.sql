create or replace type property_typ authid definer as object
( name varchar2(256)
, value varchar2(32767)
/**
PROPERTY_TYP
============
An object type similar to the PL/SQL record APEX_WEB_SERVICE.HEADER.
**/
)
final;
/
