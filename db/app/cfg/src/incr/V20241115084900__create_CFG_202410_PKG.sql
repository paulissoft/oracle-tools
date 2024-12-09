CREATE PACKAGE "CFG_202410_PKG" AUTHID DEFINER
is

/**
Package to define some constants that can be used in conditional compiling.
**/

-- https://github.com/paulissoft/oracle-tools/issues/182
c_improve_ddl_generation_performance constant boolean := true;

end cfg_202410_pkg;
/

