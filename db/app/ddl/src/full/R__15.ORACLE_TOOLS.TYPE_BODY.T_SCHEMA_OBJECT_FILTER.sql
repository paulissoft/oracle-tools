CREATE OR REPLACE TYPE BODY "ORACLE_TOOLS"."T_SCHEMA_OBJECT_FILTER" AS

constructor function t_schema_object_filter
( self in out nocopy oracle_tools.t_schema_object_filter
, p_schema in varchar2 default user
, p_object_type in varchar2 default null
, p_object_names in varchar2 default null
, p_object_names_include in integer default null
, p_grantor_is_schema in integer default 0
, p_exclude_objects in clob default null
, p_include_objects in clob default null
)
return self as result
is
begin
  oracle_tools.pkg_schema_object_filter.construct
  ( p_schema => p_schema
  , p_object_type => p_object_type
  , p_object_names => p_object_names
  , p_object_names_include => p_object_names_include
  , p_grantor_is_schema => p_grantor_is_schema
  , p_exclude_objects => p_exclude_objects
  , p_include_objects => p_include_objects
  , p_schema_object_filter => self
  );

  return; -- essential
end;

member function schema
return varchar2
deterministic
is
begin
  return self.schema$;
end;

member function grantor_is_schema
return integer
deterministic
is
begin
  return self.grantor_is_schema$;
end;

member function matches_schema_object
( self in oracle_tools.t_schema_object_filter
, p_schema_object_id in varchar2
)
return integer
deterministic
is
begin
  return oracle_tools.pkg_schema_object_filter.matches_schema_object(self, p_schema_object_id);
end matches_schema_object;

member function serialize
return clob deterministic
is
begin
  return oracle_tools.pkg_schema_object_filter.serialize(self).to_clob();
end;

member procedure chk
( self in oracle_tools.t_schema_object_filter
)
is
begin
  oracle_tools.pkg_schema_object_filter.chk
  ( p_schema_object_filter => self
  );
end chk;

member procedure print
( self in oracle_tools.t_schema_object_filter
)
is
begin
  oracle_tools.pkg_schema_object_filter.print
  ( p_schema_object_filter => self
  );
end print;

end;
/

