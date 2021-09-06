CREATE OR REPLACE PACKAGE "CFG_PKG" AUTHID DEFINER
is

c_debugging constant boolean := $if $$Debugging $then true $else false $end;
  
c_testing constant boolean := $if $$Testing $then true $else false $end;

end cfg_pkg;
/

