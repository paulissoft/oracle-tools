begin
  execute immediate q'<
CREATE PACKAGE "CFG_202410_PKG" AUTHID DEFINER
is

/**
Package to define some constants that can be used in conditional compiling.
**/

-- https://github.com/paulissoft/oracle-tools/issues/182
c_improve_ddl_generation_performance constant boolean := true;

end cfg_202410_pkg;
>';
exception
  when others
  then
    -- ORA-00955: name is already used by an existing object
    if sqlcode in (-955) then null; else raise; end if;
end;
/

