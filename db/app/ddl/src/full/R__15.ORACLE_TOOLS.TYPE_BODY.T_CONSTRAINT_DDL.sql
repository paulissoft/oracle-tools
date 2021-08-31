CREATE OR REPLACE TYPE BODY "ORACLE_TOOLS"."T_CONSTRAINT_DDL" AS

overriding member procedure migrate
( self in out nocopy t_constraint_ddl
, p_source in t_schema_ddl
, p_target in t_schema_ddl
)
is
begin
  -- first the standard things
  t_schema_ddl.migrate
  ( p_source => p_source
  , p_target => p_target
  , p_schema_ddl => self
  );

  -- check if constraint names are equal
  if self.obj.object_name() != p_target.obj.object_name() 
  then
    self.add_ddl
    ( p_verb => 'ALTER'
      -- the schema is
    , p_text => -- GPA 2017-06-27 #147914109 - As a release operator I do not want that index/constraint rename actions fail when the target already exists.
                q'[
declare
  -- ORA-02264: name already used by an existing constraint
  e_constraint_name_already_used exception;
  pragma exception_init(e_constraint_name_already_used, -02264);
begin
  execute immediate ']' || 
                'ALTER TABLE "' ||
                self.obj.base_object_schema() ||
                '"."' ||
                self.obj.base_object_name() ||
                '" RENAME CONSTRAINT "' ||
                p_target.obj.object_name() ||
                '" TO "' ||
                self.obj.object_name() ||
                '"' || q'[';
exception
  when e_constraint_name_already_used
  then null;
end;]'
    , p_add_sqlterminator => case when oracle_tools.pkg_ddl_util.c_use_sqlterminator then 1 else 0 end
    );
  end if;
end migrate;

overriding member procedure uninstall
( self in out nocopy t_constraint_ddl
, p_target in t_schema_ddl
)
is
$if oracle_tools.pkg_ddl_util.c_#138707615_2 $then
  l_constraint_object t_constraint_object := treat(p_target.obj as t_constraint_object);
$end  
begin
  -- ALTER TABLE cust_table DROP CONSTRAINT fk_cust_table_ref;
  self.add_ddl
  ( p_verb => 'ALTER'
  , p_text => 'ALTER ' ||
              p_target.obj.base_object_type() ||
              ' "' ||
              p_target.obj.base_object_schema() ||
              '"."' ||
              p_target.obj.base_object_name() ||
              '"' ||
$if oracle_tools.pkg_ddl_util.c_#138707615_2 $then
              -- When a primary/unique constraint is dropped, the associated index may be dropped too.
              -- In that case the DROP INDEX may fail.
              --
              -- Simple solution: KEEP the INDEX
              --

              case l_constraint_object.constraint_type()
                when 'P' -- primary key
                then ' DROP PRIMARY KEY KEEP INDEX'
                when 'U' -- unique key
                then ' DROP UNIQUE (' || l_constraint_object.column_names() || ') KEEP INDEX'
                else ' DROP CONSTRAINT ' || p_target.obj.object_name()
              end
$else
              ' DROP CONSTRAINT ' || p_target.obj.object_name()
$end
  , p_add_sqlterminator => case when oracle_tools.pkg_ddl_util.c_use_sqlterminator then 1 else 0 end
  );
end uninstall;

overriding member procedure add_ddl
( self in out nocopy t_constraint_ddl
, p_verb in varchar2
, p_text in clob
, p_add_sqlterminator in integer
)
is
$if oracle_tools.pkg_ddl_util.c_#138707615_2 $then
  l_ddl_text clob;
$end  
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
  dbug.enter('T_CONSTRAINT_DDL.ADD_DDL');
  dbug.print(dbug."input", 'self:');
  self.print();
  dbug.print(dbug."input", 'p_verb: %s; p_add_sqlterminator: %s', p_verb, p_add_sqlterminator);
$end

$if oracle_tools.pkg_ddl_util.c_#138707615_2 $then

  -- Primary/unique constraints with USING INDEX syntax may fail.
  --
  -- a) This may fail when the index is already there:
  --
  -- ALTER TABLE "<owner>"."WORKORDERTYPE" ADD CONSTRAINT "WORKORDERTYPE_PK" PRIMARY KEY ("SEQ")
  -- USING INDEX (CREATE UNIQUE INDEX "<owner>"."WORKORDERTYPE1_PK" ON "<owner>"."WORKORDERTYPE" ("SEQ") 
  -- PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  -- TABLESPACE "YSSINDEX" )  ENABLE;
  --
  -- b) This may fail when the index is not there:
  --
  -- ALTER TABLE "<owner>"."WORKORDERTYPE" ADD CONSTRAINT "WORKORDERTYPE_PK" PRIMARY KEY ("SEQ")
  -- USING INDEX "<owner>"."WORKORDERTYPE1_PK" ENABLE;
  --
  -- Simple solution: remove the USING INDEX syntax. Oracle will use or create an index.
  --
  -- ALTER TABLE "<owner>"."WORKORDERTYPE" ADD CONSTRAINT "WORKORDERTYPE_PK" PRIMARY KEY ("SEQ") ENABLE;
  --
  l_ddl_text := regexp_replace
                ( p_text
                , '(.*\S)\s+USING INDEX\s+.*(ENABLE|DISABLE)'
                , '\1 \2'
                , 1
                , 1
                , 'n' -- a dot may represent a newline
                );

  -- Oracle 11g has a new feature - support for generalized invocation
  (self as oracle_tools.t_schema_ddl).add_ddl
  ( p_verb => p_verb
  , p_text => l_ddl_text
  , p_add_sqlterminator => p_add_sqlterminator
  );

$else

  -- Oracle 11g has a new feature - support for generalized invocation
  (self as oracle_tools.t_schema_ddl).add_ddl
  ( p_verb => p_verb
  , p_text => p_text
  , p_add_sqlterminator => p_add_sqlterminator
  );

$end


$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
  dbug.leave;
$end
end add_ddl;

overriding member procedure execute_ddl
( self in t_constraint_ddl
)
is
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
  dbug.enter('T_CONSTRAINT_DDL.EXECUTE_DDL');
  dbug.print(dbug."input", 'self:');
  self.print();
$end

  t_schema_ddl.execute_ddl(p_schema_ddl => self);

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
  dbug.leave;
$end
end execute_ddl;  

end;
/

