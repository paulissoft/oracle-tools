CREATE OR REPLACE TYPE BODY "ORACLE_TOOLS"."T_REFRESH_GROUP_DDL" AS

overriding member procedure uninstall
( self in out nocopy t_refresh_group_ddl
, p_target in t_schema_ddl
)
is
begin
  self.add_ddl
  ( p_verb => 'DBMS_REFRESH.DESTROY'
  , p_text => 'BEGIN DBMS_REFRESH.DESTROY(''' || p_target.obj.object_name() || '''); END;'
  , p_add_sqlterminator => case when pkg_ddl_util.c_use_sqlterminator then 1 else 0 end
  );
end uninstall;

end;
/

