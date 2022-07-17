CREATE OR REPLACE TYPE BODY "ORACLE_TOOLS"."T_OBJECT_GRANT_DDL" AS

overriding member procedure uninstall
( self in out nocopy oracle_tools.t_object_grant_ddl
, p_target in oracle_tools.t_schema_ddl
)
is
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'UNINSTALL');
  dbug.print(dbug."input", 'self:');
  self.print();
  dbug.print(dbug."input", 'p_target:');
  p_target.print();
$end

  -- gpa 2017-03-23 #142308097 The incremental DDL generator incorrectly handles revokes.
  -- Since the grant statement is encapsulated by call oracle_tools.pkg_ddl_util.execute_ddl (see add_ddl below)
  -- we must create the grant ourselves.
  self.add_ddl
  ( p_verb => 'REVOKE'
  , p_text => 'REVOKE ' ||
              p_target.obj.privilege ||
              ' ON "' ||
              p_target.obj.base_object_schema() ||
              '"."' ||
              p_target.obj.base_object_name() ||
              '" FROM "' ||
              p_target.obj.grantee ||
              '"'
  , p_add_sqlterminator => 0 -- the target text should already contain a sqlterminator (or not)
  );

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
  dbug.leave;
$end
end uninstall;

overriding member procedure add_ddl
( self in out nocopy oracle_tools.t_object_grant_ddl
, p_verb in varchar2
, p_text in clob
, p_add_sqlterminator in integer
)
is
  l_pos1 pls_integer;
  l_pos2 pls_integer;
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'ADD_DDL');
  dbug.print(dbug."input", 'self:');
  self.print();
  dbug.print(dbug."input", 'p_verb: %s; p_add_sqlterminator: %s', p_verb, p_add_sqlterminator);
$end

  -- skip whitespace at the end
  l_pos1 := length(p_text);
  l_pos2 := l_pos1;
  while l_pos1 >= 1 and substr(p_text, l_pos1, 1) in (chr(9), chr(10), chr(13), chr(32))
  loop
    l_pos1 := l_pos1 - 1;
  end loop;
  -- l_pos1 >= 1 implies that l_pos1 does not contain whitespace so it is the length in substr()
  if l_pos1 >= 1
  then
    null;
  else
    raise value_error;
  end if;

  -- Oracle 11g has a new feature - support for generalized invocation
  (self as oracle_tools.t_schema_ddl).add_ddl
  ( p_verb => p_verb
  , p_text => case
                when substr(p_text, 1, 2) = '--' /* do not execute comments */
                then substr(p_text, 1, l_pos1)
                else /*q'[
begin
  execute immediate ']' ||
                     */ substr(p_text, 1, l_pos1) /*||
                     q'[';
exception
  when others
  then null;
end;]'*/
              end
  , p_add_sqlterminator => p_add_sqlterminator
  );

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
  dbug.leave;
$end
end add_ddl;

overriding member procedure execute_ddl
( self in oracle_tools.t_object_grant_ddl
)
is
  -- ORA-01917: user or role does not exist
  e_ora_01917 exception;
  pragma exception_init(e_ora_01917, -1917);
  -- ORA-01927: cannot REVOKE privileges you did not grant
  e_ora_01927 exception;
  pragma exception_init(e_ora_01927, -1927);
  -- ORA-02204: ALTER, INDEX and EXECUTE not allowed for views
  e_ora_02204 exception;
  pragma exception_init(e_ora_02204, -2204);
  -- ORA-02224: EXECUTE privilege not allowed for tables
  e_ora_02224 exception;
  pragma exception_init(e_ora_02224, -2224);
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
  when e_ora_01917 or e_ora_01927 or e_ora_02204 or e_ora_02224
  then
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
    dbug.leave;
$end
    null;

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end execute_ddl;

end;
/

