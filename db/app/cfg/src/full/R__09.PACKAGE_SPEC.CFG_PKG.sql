CREATE OR REPLACE PACKAGE "CFG_PKG" AUTHID DEFINER
is

c_debugging constant boolean := $if $$Debugging $then true $else false $end;
  
c_testing constant boolean := $if $$Testing $then true $else false $end;

-- It must be possible to install PATO in a database without APEX installed.
c_apex_installed constant boolean := $if $$APEX $then true $else false $end;

c_start_stop_msg_framework constant boolean := true; -- it may be irritating when compiling blocks due to processes running so you can set it to false

/**
Package to define some constants that can be used in conditional compiling.
**/

end cfg_pkg;
/

