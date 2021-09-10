CREATE OR REPLACE TYPE BODY "ORACLE_TOOLS"."T_PROCOBJ_DDL" AS

overriding member procedure uninstall
( self in out nocopy oracle_tools.t_procobj_ddl
, p_target in oracle_tools.t_schema_ddl
)
is
begin
  -- GPA 2017-01-16 TODO: DBMS_JOBS
  if p_target.obj.dict_object_type() in ('JOB', 'PROGRAM')
  then
    self.add_ddl
    ( p_verb => 'DBMS_SCHEDULER.DROP_' || p_target.obj.dict_object_type()
    , p_text => 'BEGIN DBMS_SCHEDULER.DROP_' || p_target.obj.dict_object_type() || '(''' || p_target.obj.object_name() || '''); END;'
    , p_add_sqlterminator => case when oracle_tools.pkg_ddl_util.c_use_sqlterminator then 1 else 0 end
    );
  else
    raise_application_error
    ( oracle_tools.pkg_ddl_error.c_not_implemented
    , 'Uninstalling ' || p_target.obj.dict_object_type() || ' ' || p_target.obj.fq_object_name() || ' not implemented.'
    );
  end if;
end uninstall;

end;
/

