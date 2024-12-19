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

member function nr_objects_to_exclude
return integer
deterministic
is
begin
  return nr_objects_to_exclude$;
end nr_objects_to_exclude;

member function nr_objects
return integer
deterministic
is
begin
  return nvl(cardinality(self.op_object_id_expr_tab$), 0);
end nr_objects;

member function op(p_idx in integer)
return varchar2
deterministic
is
begin
  return substr(op_object_id_expr_tab$(p_idx), 1, 2);
end op;  

member function object_id_expr(p_idx in integer)
return varchar2
deterministic
is
begin
  return substr(op_object_id_expr_tab$(p_idx), 4);
end object_id_expr;

static function ops
return oracle_tools.t_text_tab
deterministic
is
begin
  return oracle_tools.t_text_tab('!~', '!=', ' ~', ' =');
end ops;
  
member function op_order
( p_idx in integer
)
return integer
deterministic
is
begin
  return
    case op(p_idx)
      when '!~' then 1
      when '!=' then 2
      when ' ~' then 3
      when ' =' then 4
    end;
end op_order;  

member function matches_schema_object_details
( self in oracle_tools.t_schema_object_filter
, p_schema_object_id in varchar2
)
return varchar2
deterministic
is
begin
  return oracle_tools.pkg_schema_object_filter.matches_schema_object_details(self, p_schema_object_id);
end matches_schema_object_details;

member procedure chk
( self in oracle_tools.t_schema_object_filter
)
is
begin
  oracle_tools.pkg_schema_object_filter.chk
  ( p_schema_object_filter => self
  );
end chk;

overriding
member procedure serialize
( self in oracle_tools.t_schema_object_filter
, p_json_object in out nocopy json_object_t
)
is
begin
  oracle_tools.pkg_schema_object_filter.serialize(self, p_json_object);
end serialize;

end;
/

