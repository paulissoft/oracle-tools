CREATE OR REPLACE TYPE BODY "ORACLE_TOOLS"."T_INDEX_OBJECT" AS

constructor function t_index_object
( self in out nocopy t_index_object
, p_base_object in t_named_object
, p_object_schema in varchar2
, p_object_name in varchar2
)
return self as result
is
begin
  -- must use PKG_DDL_UTIL.CREATE_INDEX_OBJECT
  raise_application_error(pkg_ddl_error.c_not_implemented, 'T_INDEX_OBJECT.T_INDEX_OBJECT (1)');
end;

constructor function t_index_object
( self in out nocopy t_index_object
, p_base_object in t_named_object
, p_object_schema in varchar2
, p_object_name in varchar2
, p_tablespace_name in varchar2
)
return self as result
is
begin
  -- must use PKG_DDL_UTIL.CREATE_INDEX_OBJECT
  raise_application_error(pkg_ddl_error.c_not_implemented, 'T_INDEX_OBJECT.T_INDEX_OBJECT (2)');
end;

-- begin of getter(s)
member function tablespace_name 
return varchar2
deterministic
is
begin
  return self.tablespace_name$;
end tablespace_name;

member procedure tablespace_name
( self in out nocopy t_index_object
, p_tablespace_name in varchar2
)
is
begin
  self.tablespace_name$ := p_tablespace_name;
end tablespace_name;

overriding member function object_type
return varchar2
deterministic
is
begin
  return 'INDEX';
end object_type;

overriding member function object_name
return varchar2
deterministic
is
begin
  return self.object_name$;
end object_name;

member function column_names
return varchar2
deterministic
is
begin
  return self.column_names$;
end column_names;

-- end of getter(s)

overriding final map member function signature
return varchar2
deterministic
is
begin
  -- GPA 20170126 This generated SQL statement is totally wrong:
  -- /* SQL statement 7 (ALTER;<owner>;INDEX;ORDER_PK;<owner>;TABLE;ORDERHEADER;;;;;3) */
  -- ALTER INDEX "<owner>"."MAINTENANCE_PK" RENAME TO "ORDER_PK";

  -- select * from all_ind_columns where index_name IN ('MAINTENANCE_PK','ORDER_PK');
  --
  -- INDEX_OWNER  INDEX_NAME  TABLE_OWNER TABLE_NAME  COLUMN_NAME COLUMN_POSITION
  -- -----------        ----------      -----------     ----------      -----------     ---------------
  -- <owner>  MAINTENANCE_PK  <owner> MAINTENANCE SEQ         1
  -- <owner>  ORDER_PK  <owner> ORDERHEADER SEQ         1

  -- GPA 20170126
  -- The problem was that t_schema_object.id ignored base info for an INDEX

  return self.object_schema ||
         ':' ||
         self.object_type ||
         ':' ||
         null || -- indexes may have different names but can be equal between (remote) schemas
         ':' ||
         self.base_object_schema ||
         ':' ||
         self.base_object_type ||
         ':' ||
         self.base_object_name || -- but the table names should be the same
         ':' ||
         self.column_names;
end signature;

static function get_column_names
( p_object_schema in varchar2
, p_object_name in varchar2
)
return varchar2
is
begin
  -- must use PKG_DDL_UTIL.GET_COLUMN_NAMES
  raise_application_error(pkg_ddl_error.c_not_implemented, 'T_INDEX_OBJECT.GET_COLUMN_NAMES');
end get_column_names;

overriding member procedure chk
( self in t_index_object
, p_schema in varchar2
)
is
begin
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
  dbug.enter('T_INDEX_OBJECT.CHK');
$end

  pkg_ddl_util.chk_schema_object(p_dependent_or_granted_object => self, p_schema => p_schema);

  if self.object_name() is null
  then
    raise_application_error(pkg_ddl_error.c_invalid_parameters, 'Object name should not be empty');
  end if;
  if self.column_names() is null
  then
    raise_application_error(pkg_ddl_error.c_invalid_parameters, 'Column names should not be empty');
  end if;

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
  dbug.leave;
$end
end chk;

end;
/

