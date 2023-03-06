CREATE OR REPLACE PACKAGE "CFG_PKG" AUTHID DEFINER
is

c_debugging constant boolean := $if $$Debugging $then true $else false $end;
  
c_testing constant boolean := $if $$Testing $then true $else false $end;

/**
Package to define some constants that can be used in conditional compiling.
**/

end cfg_pkg;
/

