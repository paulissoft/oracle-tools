CREATE OR REPLACE TYPE BODY "ORACLE_TOOLS"."T_NAMED_OBJECT" AS

overriding final member function object_name
return varchar2
deterministic
is
begin
  return self.object_name$;
end object_name;  

final static procedure create_named_object
( p_object_type in varchar2
, p_object_schema in varchar2
, p_object_name in varchar2
, p_named_object out nocopy t_schema_object
)
is
  l_object_type oracle_tools.pkg_ddl_util.t_metadata_object_type := p_object_type;
begin
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
  dbug.enter('T_NAMED_OBJECT.CREATE_NAMED_OBJECT (1)');
  dbug.print
  ( dbug."input"
  , 'p_object_type: %s; p_object_schema: %s; p_object_name: %s'
  , p_object_type
  , p_object_schema
  , p_object_name
  );
$end

  if l_object_type is null
  then
    select  distinct
            o.object_type
    into    l_object_type
    from    all_objects o
    where   o.owner = p_object_schema
    and     o.object_name = p_object_name
    and     o.object_type not in ('INDEX', 'TRIGGER', 'PACKAGE BODY', 'TYPE BODY', 'MATERIALIZED VIEW') -- only primary objects
    ;

    l_object_type := oracle_tools.t_schema_object.dict2metadata_object_type(l_object_type);
  end if;

  case l_object_type
    when 'SEQUENCE'              then p_named_object := t_sequence_object(p_object_schema, p_object_name);
    when 'TYPE_SPEC'             then p_named_object := t_type_spec_object(p_object_schema, p_object_name);
    when 'CLUSTER'               then p_named_object := t_cluster_object(p_object_schema, p_object_name);
    when 'TABLE'                 then p_named_object := t_table_object(p_object_schema, p_object_name, null);
    when 'FUNCTION'              then p_named_object := t_function_object(p_object_schema, p_object_name);
    when 'PACKAGE_SPEC'          then p_named_object := t_package_spec_object(p_object_schema, p_object_name);
    when 'VIEW'                  then p_named_object := t_view_object(p_object_schema, p_object_name);
    when 'PROCEDURE'             then p_named_object := t_procedure_object(p_object_schema, p_object_name);
    when 'MATERIALIZED_VIEW'     then p_named_object := t_materialized_view_object(p_object_schema, p_object_name);
    when 'MATERIALIZED_VIEW_LOG' then p_named_object := t_materialized_view_log_object(p_object_schema, p_object_name);
    when 'PACKAGE_BODY'          then p_named_object := t_package_body_object(p_object_schema, p_object_name);
    when 'TYPE_BODY'             then p_named_object := t_type_body_object(p_object_schema, p_object_name);
    when 'JAVA_SOURCE'           then p_named_object := t_java_source_object(p_object_schema, p_object_name);
    when 'REFRESH_GROUP'         then p_named_object := t_refresh_group_object(p_object_schema, p_object_name);
    when 'PROCOBJ'               then p_named_object := t_procobj_object(p_object_schema, p_object_name);
    else raise_application_error(-20000, 'Object type "' || l_object_type || '" is not listed here.');
  end case;

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end create_named_object;

final static function create_named_object
( p_object_type in varchar2
, p_object_schema in varchar2
, p_object_name in varchar2
)
return t_named_object
is
  l_named_object t_schema_object;
begin
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
  dbug.enter('T_NAMED_OBJECT.CREATE_NAMED_OBJECT (2)');
$end

  t_named_object.create_named_object
  ( p_object_type => p_object_type
  , p_object_schema => p_object_schema
  , p_object_name => p_object_name
  , p_named_object => l_named_object
  );

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
  dbug.leave;
$end

  return treat(l_named_object as t_named_object);

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end create_named_object;

overriding member procedure chk
( self in t_named_object
, p_schema in varchar2
)
is
begin
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
  dbug.enter('T_NAMED_OBJECT.CHK');
$end

  pkg_ddl_util.chk_schema_object(p_named_object => self, p_schema => p_schema);

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
  dbug.leave;
$end
end chk;  

overriding member function get_creation_date
return date
is
  l_creation_date date := null;
begin
  select  o.created
  into    l_creation_date
  from    all_objects o
  where   o.owner = self.object_schema()
  and     o.object_name = self.object_name()
  and     o.object_type = self.dict_object_type();

  return l_creation_date;
end get_creation_date;

end;
/

