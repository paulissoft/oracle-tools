CREATE OR REPLACE TYPE BODY "ORACLE_TOOLS"."T_PROCOBJ_OBJECT" AS

constructor function t_procobj_object
( self in out nocopy oracle_tools.t_procobj_object
, p_object_schema in varchar2
, p_object_name in varchar2
)
return self as result
is
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.CONSTRUCTOR');
  dbug.print
  ( dbug."input"
  , 'p_object_schema: %s; p_object_name: %s'
  , p_object_schema
  , p_object_name
  );
$end

  -- default constructor
  self := oracle_tools.t_procobj_object(null, null, p_object_schema, p_object_name, null);

  select  obj.object_type
  into    self.dict_object_type$
  from    all_objects obj
  where   obj.owner = p_object_schema
  and     obj.object_name = p_object_name
  ;

  oracle_tools.t_schema_object.set_id(self);

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
  dbug.leave;
$end

  return;
end;

overriding member function dict_object_type
return varchar2
deterministic
is
begin
  return self.dict_object_type$;
end dict_object_type;

overriding member function object_type
return varchar2
deterministic
is
begin
  return 'PROCOBJ';
end object_type;

overriding member procedure chk
( self in oracle_tools.t_procobj_object
, p_schema in varchar2
)
is
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'CHK');
$end

  oracle_tools.pkg_ddl_util.chk_schema_object(p_named_object => self, p_schema => p_schema);

  if self.dict_object_type() is null
  then
    oracle_tools.pkg_ddl_error.raise_error(oracle_tools.pkg_ddl_error.c_invalid_parameters, 'Dictionary object type should not be null.', self.schema_object_info());
  end if;

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
  dbug.leave;
$end
end chk;

overriding member function dict_object_exists
return integer -- 0/1
is
  l_count pls_integer;
  l_object_schema constant all_objects.owner%type := self.object_schema();
  l_object_name constant all_objects.object_name%type := self.object_name();
begin
  select  sign(count(*))
  into    l_count
  from    all_objects o
  where   o.owner = l_object_schema
  -- here the list from my database
  and     o.object_type in ( null -- to make it easier to (un)comment
--                         , 'CLUSTER'
--                         , 'CONSUMER GROUP'
--                         , 'CONTEXT'
--                         , 'DATABASE LINK'
--                         , 'DESTINATION'
--                         , 'DIRECTORY'
--                         , 'DOMAIN'
--                         , 'EDITION'
                           , 'EVALUATION CONTEXT'
--                         , 'FUNCTION'
--                         , 'INDEX'
--                         , 'INDEX PARTITION'
--                         , 'INDEXTYPE'
--                         , 'JAVA CLASS'
--                         , 'JAVA DATA'
--                         , 'JAVA RESOURCE'
--                         , 'JAVA SOURCE'
                           , 'JOB'
                           , 'JOB CLASS'
--                         , 'LIBRARY'
--                         , 'LOB'
--                         , 'LOB PARTITION'
--                         , 'MATERIALIZED VIEW'
--                         , 'MLE LANGUAGE'
--                         , 'OPERATOR'
--                         , 'PACKAGE'
--                         , 'PACKAGE BODY'
--                         , 'PROCEDURE'
                           , 'PROGRAM'
--                         , 'QUEUE'
--                         , 'RESOURCE PLAN'
                           , 'RULE'
                           , 'RULE SET'
                           , 'SCHEDULE'
                           , 'SCHEDULER GROUP'
--                         , 'SEQUENCE'
--                         , 'SYNONYM'
--                         , 'TABLE'
--                         , 'TABLE PARTITION'
--                         , 'TABLE SUBPARTITION'
--                         , 'TRIGGER'
--                         , 'TYPE'
--                         , 'TYPE BODY'
--                         , 'UNDEFINED'
--                         , 'UNIFIED AUDIT POLICY'
--                         , 'VIEW'
                           , 'WINDOW'
--                         , 'XML SCHEMA'
                           )
  and     o.object_name = l_object_name;
  return l_count;
end;

end;
/

