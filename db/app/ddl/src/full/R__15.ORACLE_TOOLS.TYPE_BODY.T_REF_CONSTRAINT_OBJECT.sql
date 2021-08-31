CREATE OR REPLACE TYPE BODY "ORACLE_TOOLS"."T_REF_CONSTRAINT_OBJECT" AS

constructor function t_ref_constraint_object
( self in out nocopy t_ref_constraint_object
, p_base_object in t_named_object
, p_object_schema in varchar2
, p_object_name in varchar2
, p_constraint_type in varchar2 default null
, p_column_names in varchar2 default null
, p_ref_object in t_named_object default null
)
return self as result
is
begin
  -- must use PKG_SCHEMA_OBJECT.CREATE_REF_CONSTRAINT_OBJECT
  raise_application_error(oracle_tools.pkg_ddl_error.c_not_implemented, 'T_REF_CONSTRAINT_OBJECT.T_REF_CONSTRAINT_OBJECT');
end;

-- begin of getter(s)

overriding member function object_type
return varchar2
deterministic
is
begin
  return 'REF_CONSTRAINT';
end object_type;

member function ref_object_schema
return varchar2
deterministic
is
begin
  return case when self.ref_object$ is not null then self.ref_object$.object_schema() end;
end ref_object_schema;  

final member procedure ref_object_schema
( self in out nocopy t_ref_constraint_object
, p_ref_object_schema in varchar2
)
is
begin
  self.ref_object$.object_schema(p_ref_object_schema);
end ref_object_schema;

member function ref_object_type
return varchar2
deterministic
is
begin
  return case when self.ref_object$ is not null then self.ref_object$.object_type() end;
end ref_object_type;  

member function ref_object_name
return varchar2
deterministic
is
begin
  return case when self.ref_object$ is not null then self.ref_object$.object_name() end;
end ref_object_name;  

-- end of getter(s)

overriding final map member function signature
return varchar2
deterministic
is
begin
  return self.object_schema ||
         ':' ||
         self.object_type ||
         ':' ||
         null || -- constraints may be equal between (remote) schemas even though the name is different
         ':' || 
         self.base_object_schema ||
         ':' ||
         self.base_object_type ||
         ':' ||
         self.base_object_name ||
         ':' ||
         self.constraint_type ||
         ':' ||
         self.column_names ||
         ':' ||
         self.ref_object_schema ||
         ':' ||
         self.ref_object_type ||
         ':' ||
         self.ref_object_name;
end signature;

overriding member procedure chk
( self in t_ref_constraint_object
, p_schema in varchar2
)
is
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
  dbug.enter('T_REF_CONSTRAINT_OBJECT.CHK');
$end

  oracle_tools.pkg_schema_object.chk_schema_object(p_constraint_object => self, p_schema => p_schema);

  if self.ref_object$ is null
  then
    raise_application_error(oracle_tools.pkg_ddl_error.c_invalid_parameters, 'Reference object should not be empty.');
  end if;

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
  dbug.leave;
$end
end chk;

end;
/

