CREATE OR REPLACE TYPE BODY "ORACLE_TOOLS"."T_OBJECT_GRANT_OBJECT" AS

constructor function t_object_grant_object
( self in out nocopy oracle_tools.t_object_grant_object
, p_base_object in oracle_tools.t_named_object
, p_object_schema in varchar2
, p_grantee in varchar2
, p_privilege in varchar2
, p_grantable in varchar2
)
return self as result
is
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_defs.c_debugging >= 3 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.CONSTRUCTOR');
  p_base_object.print();
  dbug.print
  ( dbug."input"
  , 'p_object_schema: %s; p_grantee: %s; p_privilege: %s; p_grantable: %s'
  , p_object_schema
  , p_grantee
  , p_privilege
  , p_grantable
  );
$end

  if p_base_object is null
  then
    self.base_object_id$ := null;
  else
    self.base_object_id$ := p_base_object.id;
  end if;
  self.network_link$ := null;
  self.object_schema$ := p_object_schema;
  self.grantee$ := p_grantee;
  self.privilege$ := p_privilege;
  self.grantable$ := p_grantable;

  oracle_tools.t_schema_object.normalize(self);

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_defs.c_debugging >= 3 $then
  dbug.leave;
$end

  return;
end;

-- begin of getter(s)

overriding member function object_type
return varchar2
deterministic
is
begin
  return 'OBJECT_GRANT';
end object_type;

overriding member function grantee
return varchar2
deterministic
is
begin
  return self.grantee$;
end grantee;

overriding member function privilege
return varchar2
deterministic
is
begin
  return self.privilege$;
end privilege;

overriding member function grantable
return varchar2
deterministic
is
begin
  return self.grantable$;
end grantable;

-- end of getter(s)

overriding member procedure chk
( self in oracle_tools.t_object_grant_object
, p_schema in varchar2
)
is
$if oracle_tools.pkg_ddl_defs.c_#140920801 $then
  pragma autonomous_transaction;

  -- Capture invalid objects before releasing to next enviroment.
  l_statement varchar2(4000 char) := null;
  l_error_message varchar2(2000 char);
$end
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_defs.c_debugging >= 3 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'CHK');
$end

  oracle_tools.pkg_ddl_util.chk_schema_object(p_dependent_or_granted_object => self, p_schema => p_schema);

  l_error_message := 
    case
      when self.object_schema() is not null then 'Object schema should be empty.'
      when self.object_name() is not null then 'Object name should be empty.'
      when self.column_name() is not null then 'Column name should be null.'
      when self.grantee() is null then 'Grantee should not be null.'
      when self.privilege() is null then 'Privilege should not be null.'
      when self.grantable() is null then 'Grantable should not be null.'
      else null
    end;

  if l_error_message is not null
  then
    oracle_tools.pkg_ddl_error.raise_error(oracle_tools.pkg_ddl_error.c_invalid_parameters, l_error_message, self.schema_object_info());
  end if;

$if oracle_tools.pkg_ddl_defs.c_#140920801 $then

  -- Capture invalid objects before releasing to next enviroment.
  -- This is implemented by re-granting the grant statement when the grantor is equal to the logged in user.

  if oracle_tools.pkg_ddl_util.do_chk(self.object_type()) and self.network_link() is null
  then
    begin
      select  'GRANT ' ||
              grt.privilege ||
              ' ON "' ||
              grt.table_schema ||
              '"."' ||
              grt.table_name ||
              '" TO "' ||
              grt.grantee ||
              '"' ||
              case when grt.grantable = 'YES' then ' WITH GRANT OPTION' end as stmt
      into    l_statement
      from    all_tab_privs grt
$if dbms_db_version.version < 12 $then
              inner join all_objects obj
              on obj.owner = grt.table_schema and obj.object_name = grt.table_name
$end
      where   grt.table_schema = self.base_object_schema()
$if dbms_db_version.version < 12 $then
      and     obj.object_type = self.base_dict_object_type()
      and     obj.object_type not in ('MATERIALIZED VIEW', 'TYPE BODY', 'PACKAGE BODY')
$else
      and     grt.type = self.base_dict_object_type()
      and     grt.type not in ('MATERIALIZED VIEW', 'TYPE BODY', 'PACKAGE BODY')
$end
      and     grt.table_name = self.base_object_name()
      and     grt.grantee = self.grantee()
      and     grt.privilege = self.privilege()
      and     grt.grantable = self.grantable()
      and     grt.grantor = sys_context('USERENV', 'CURRENT_SCHEMA') /* we can always grant our own objects */
      ;

      execute immediate l_statement;
    exception
      when no_data_found
      then
        null;
    end;
  end if;

$end

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_defs.c_debugging >= 3 $then
  dbug.leave;
$end
end chk;

overriding member function dict_last_ddl_time
return date
is
  l_owner constant all_objects.owner%type := self.base_object_schema();
  l_object_name constant all_objects.object_name%type := self.base_object_name();
  l_last_ddl_time all_objects.last_ddl_time%type;
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_defs.c_debugging >= 3 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'LAST_DDL_TIME');
  dbug.print
  ( dbug."input"
  , 'l_owner: %s; l_object_name: %s'
  , l_owner
  , l_object_name
  );
$end

  -- self.base_dict_object_type() is null, so check all objects matching base object schema/base object name
  select  max(o.last_ddl_time)
  into    l_last_ddl_time
  from    all_objects o
  where   o.owner = l_owner
  and     o.object_name = l_object_name;

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_defs.c_debugging >= 3 $then
  dbug.print(dbug."output", 'return: %s', l_last_ddl_time);
  dbug.leave;
$end

  return l_last_ddl_time;
end dict_last_ddl_time;

end;
/

