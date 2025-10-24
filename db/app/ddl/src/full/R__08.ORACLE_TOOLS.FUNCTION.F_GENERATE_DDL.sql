CREATE OR REPLACE FUNCTION "ORACLE_TOOLS"."F_GENERATE_DDL" 
( pi_source_schema in varchar2 default sys_context('USERENV', 'CURRENT_SCHEMA')
, pi_source_database_link in varchar2 default null
, pi_target_schema in varchar2 default null
, pi_target_database_link in varchar2 default null
, pi_object_type in varchar2 default null
, pi_object_names_include in natural default null
, pi_object_names in varchar2 default null
, pi_skip_repeatables in naturaln default 1
, pi_transform_param_list in varchar2 default null
, pi_interface in varchar2 default null
, pi_exclude_objects in clob default null
, pi_include_objects in clob default null
)
return clob
authid current_user
as
  pragma autonomous_transaction; -- may be used inside a query

  l_clob clob := null;
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT);
  dbug.print
  ( dbug."input"
  , 'pi_source_schema: %s; pi_source_database_link: %s; pi_target_schema: %s; pi_target_database_link: %s; pi_object_type: %s'
  , pi_source_schema
  , pi_source_database_link
  , pi_target_schema
  , pi_target_database_link
  , pi_object_type
  );
  dbug.print
  ( dbug."input"
  , 'pi_object_names_include: %s; pi_object_names: %s; pi_skip_repeatables: %s; pi_transform_param_list: %s; pi_interface: %s'
  , pi_object_names_include
  , pi_object_names
  , pi_skip_repeatables
  , pi_transform_param_list
  , pi_interface
  );
  dbug.print
  ( dbug."input"
  , 'pi_exclude_objects length: %s; pi_include_objects length: %s'
  , dbms_lob.getlength(lob_loc => pi_exclude_objects)
  , dbms_lob.getlength(lob_loc => pi_include_objects)
  );
$end

  oracle_tools.p_generate_ddl
  ( pi_source_schema => pi_source_schema
  , pi_source_database_link => pi_source_database_link
  , pi_target_schema => pi_target_schema
  , pi_target_database_link => pi_target_database_link
  , pi_object_type => pi_object_type
  , pi_object_names_include => pi_object_names_include
  , pi_object_names => pi_object_names
  , pi_skip_repeatables => pi_skip_repeatables
  , pi_interface => pi_interface
  , pi_transform_param_list => nvl(pi_transform_param_list, oracle_tools.pkg_ddl_defs.c_transform_param_list)
  , pi_exclude_objects => pi_exclude_objects
  , pi_include_objects => pi_include_objects
  , po_clob => l_clob
  );

  commit; -- see the pragma

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
$end

  return l_clob;

$if oracle_tools.cfg_pkg.c_debugging $then
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end f_generate_ddl;
/

