CREATE OR REPLACE TYPE BODY "ORACLE_TOOLS"."T_NAMED_OBJECT" AS

overriding final member function object_name
return varchar2
deterministic
is
begin
  return self.object_name$;
end object_name;

overriding member function object_type
return varchar2
deterministic
is
begin
  raise_application_error(-20000, 'This type (T_NAMED_OBJECT) should not be instantiated.');
end object_type;

final static procedure create_named_object
( p_object_type in varchar2
, p_object_schema in varchar2
, p_object_name in varchar2
, p_named_object out nocopy oracle_tools.t_schema_object
)
is
  l_object_type oracle_tools.pkg_ddl_util.t_metadata_object_type := p_object_type;
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'CREATE_NAMED_OBJECT (1)');
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
    begin
      select  distinct
              o.object_type
      into    l_object_type
      from    all_objects o
      where   o.owner = p_object_schema
      and     o.object_name = p_object_name
      and     o.object_type not in ( 'INDEX'
                                   , 'TRIGGER'
                                   , 'PACKAGE BODY'
                                   , 'TYPE BODY'
                                   , 'MATERIALIZED VIEW'
                                   , 'TABLE PARTITION'
                                   , 'TABLE SUBPARTITION'
                                   ); -- only primary objects
    exception
      when no_data_found
      then oracle_tools.pkg_ddl_error.raise_error
           ( p_error_number => oracle_tools.pkg_ddl_error.c_object_type_wrong
           , p_error_message => 'Object type not found for this object.'
           , p_context_info => p_object_schema || '.' || p_object_name
           , p_context_label => 'object owner and name'
           );
      when too_many_rows
      then oracle_tools.pkg_ddl_error.raise_error
           ( p_error_number => oracle_tools.pkg_ddl_error.c_object_type_wrong
           , p_error_message => 'Too many object types found for this object.'
           , p_context_info => p_object_schema || '.' || p_object_name
           , p_context_label => 'object owner and name'
           );
    end;
    l_object_type := oracle_tools.t_schema_object.dict2metadata_object_type(l_object_type);
  end if;

  case l_object_type
    when 'SEQUENCE'              then p_named_object := oracle_tools.t_sequence_object(p_object_schema, p_object_name);
    when 'TYPE_SPEC'             then p_named_object := oracle_tools.t_type_spec_object(p_object_schema, p_object_name);
    when 'CLUSTER'               then p_named_object := oracle_tools.t_cluster_object(p_object_schema, p_object_name);
    when 'TABLE'                 then p_named_object := oracle_tools.t_table_object(p_object_schema, p_object_name);
    when 'FUNCTION'              then p_named_object := oracle_tools.t_function_object(p_object_schema, p_object_name);
    when 'PACKAGE_SPEC'          then p_named_object := oracle_tools.t_package_spec_object(p_object_schema, p_object_name);
    when 'VIEW'                  then p_named_object := oracle_tools.t_view_object(p_object_schema, p_object_name);
    when 'PROCEDURE'             then p_named_object := oracle_tools.t_procedure_object(p_object_schema, p_object_name);
    when 'MATERIALIZED_VIEW'     then p_named_object := oracle_tools.t_materialized_view_object(p_object_schema, p_object_name);
    when 'MATERIALIZED_VIEW_LOG' then p_named_object := oracle_tools.t_materialized_view_log_object(p_object_schema, p_object_name);
    when 'PACKAGE_BODY'          then p_named_object := oracle_tools.t_package_body_object(p_object_schema, p_object_name);
    when 'TYPE_BODY'             then p_named_object := oracle_tools.t_type_body_object(p_object_schema, p_object_name);
    when 'JAVA_SOURCE'           then p_named_object := oracle_tools.t_java_source_object(p_object_schema, p_object_name);
    when 'REFRESH_GROUP'         then p_named_object := oracle_tools.t_refresh_group_object(p_object_schema, p_object_name);
    when 'PROCOBJ'               then p_named_object := oracle_tools.t_procobj_object(p_object_schema, p_object_name);
    else -- GJP 2023-01-06 An error occurred for object with object type/schema/name: POST_TABLE_ACTION//
         oracle_tools.pkg_ddl_error.raise_error
         ( oracle_tools.pkg_ddl_error.c_object_type_wrong -- oracle_tools.pkg_ddl_error.c_invalid_parameters
         , 'Object type "' || l_object_type || '" is not listed here.'
         , utl_lms.format_message
           ( '%s/%s/%s'
           , p_object_type
           , p_object_schema
           , p_object_name
           )
         , 'object type/schema/name'
         );
  end case;

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
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
return oracle_tools.t_named_object
is
  l_named_object oracle_tools.t_schema_object;
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'CREATE_NAMED_OBJECT (2)');
$end

  oracle_tools.t_named_object.create_named_object
  ( p_object_type => p_object_type
  , p_object_schema => p_object_schema
  , p_object_name => p_object_name
  , p_named_object => l_named_object
  );

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
  dbug.leave;
$end

  return treat(l_named_object as oracle_tools.t_named_object);

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end create_named_object;

overriding member procedure chk
( self in oracle_tools.t_named_object
, p_schema in varchar2
)
is
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'CHK');
$end

  oracle_tools.pkg_ddl_util.chk_schema_object(p_named_object => self, p_schema => p_schema);

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
  dbug.leave;
$end
end chk;

end;
/

