CREATE OR REPLACE TYPE BODY "ORACLE_TOOLS"."T_INDEX_DDL" AS

overriding member procedure migrate
( self in out nocopy oracle_tools.t_index_ddl
, p_source in oracle_tools.t_schema_ddl
, p_target in oracle_tools.t_schema_ddl
)
is
  l_source_index_object oracle_tools.t_index_object := treat(p_source.obj as oracle_tools.t_index_object);
  l_target_index_object oracle_tools.t_index_object := treat(p_target.obj as oracle_tools.t_index_object);
begin
  -- first the standard things
  oracle_tools.t_schema_ddl.migrate
  ( p_source => p_source
  , p_target => p_target
  , p_schema_ddl => self
  );

  -- check if tablespace names are equal
  if l_source_index_object.tablespace_name() != l_target_index_object.tablespace_name() 
  then
    self.add_ddl
    ( p_verb => 'ALTER'
      -- the schema is
    , p_text => 'ALTER INDEX "' ||
                l_target_index_object.object_schema() ||
                '"."' ||
                l_target_index_object.object_name() ||
                '" REBUILD TABLESPACE "' ||
                l_source_index_object.tablespace_name() ||
                '"'
    , p_add_sqlterminator => case when oracle_tools.pkg_ddl_util.c_use_sqlterminator then 1 else 0 end
    );
  end if;

  /*
  --
  -- !!!IMPORTANT!!!
  --
  -- An index rename statement should be the LAST so other statements still can use l_target_index_object.object_name()
  */

  -- check if index names are equal
  if l_source_index_object.object_name() != l_target_index_object.object_name() 
  then
    self.add_ddl
    ( p_verb => 'ALTER'
      -- the schema is
    , p_text => -- GPA 2017-06-27 #147914109 - As a release operator I do not want that index/constraint rename actions fail when the target already exists.
                q'[
declare
  -- ORA-00955: name is already used by an existing object
  e_name_already_used exception;
  pragma exception_init(e_name_already_used, -955);
begin
  execute immediate ']' || 
                'ALTER INDEX "' ||
                l_target_index_object.object_schema() ||
                '"."' ||
                l_target_index_object.object_name() ||
                '" RENAME TO "' ||
                l_source_index_object.object_name() ||
                '"' || q'[';
exception
  when e_name_already_used
  then null;
end;]'
    , p_add_sqlterminator => case when oracle_tools.pkg_ddl_util.c_use_sqlterminator then 1 else 0 end
    );
  end if;
end migrate;

overriding member procedure execute_ddl
( self in oracle_tools.t_index_ddl
)
is
  -- ORA-00955: name is already used by an existing object
  e_name_already_used exception;
  pragma exception_init(e_name_already_used, -955);
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'EXECUTE_DDL');
  dbug.print(dbug."input", 'self:');
  self.print();
$end

  oracle_tools.t_schema_ddl.execute_ddl(p_schema_ddl => self);

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
  dbug.leave;
$end
exception
  when e_name_already_used
  then
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
    dbug.leave;
$end
    null;
end execute_ddl;  

end;
/

