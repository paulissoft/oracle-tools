CREATE OR REPLACE TYPE BODY "ORACLE_TOOLS"."T_SYNONYM_DDL" AS

overriding member procedure uninstall
( self in out nocopy oracle_tools.t_synonym_ddl
, p_target in oracle_tools.t_schema_ddl
)
is
begin
  if p_target.obj.object_schema() = 'PUBLIC'
  then
    self.add_ddl
    ( p_verb => 'DROP'
    , p_text => 'DROP PUBLIC SYNONYM "' || p_target.obj.object_name() || '"'
    , p_add_sqlterminator => case when oracle_tools.pkg_ddl_defs.c_use_sqlterminator then 1 else 0 end
    );
  else
    self.add_ddl
    ( p_verb => 'DROP'
    , p_text => 'DROP ' || p_target.obj.dict_object_type() || ' ' || p_target.obj.fq_object_name()
    , p_add_sqlterminator => case when oracle_tools.pkg_ddl_defs.c_use_sqlterminator then 1 else 0 end
    );
  end if;

end uninstall;

end;
/

