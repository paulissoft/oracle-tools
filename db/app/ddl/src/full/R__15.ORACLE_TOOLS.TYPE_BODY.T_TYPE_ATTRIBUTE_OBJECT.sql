CREATE OR REPLACE TYPE BODY "ORACLE_TOOLS"."T_TYPE_ATTRIBUTE_OBJECT" IS

constructor function t_type_attribute_object
( self in out nocopy oracle_tools.t_type_attribute_object
, p_base_object in oracle_tools.t_named_object
, p_member# in integer
, p_member_name in varchar2
, p_data_type_name in varchar2
, p_data_type_mod in varchar2
, p_data_type_owner in varchar2
, p_data_length in number
, p_data_precision in number
, p_data_scale in number
, p_character_set_name in varchar2
)
return self as result
is
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.CONSTRUCTOR');
  dbug.print
  ( dbug."input"
  , 'p_base_object.id(): %s; p_member#: %s; p_member_name: %s; p_data_type_name: %s; p_data_type_mod: %s'
  , p_base_object.id()
  , p_member#
  , p_member_name
  , p_data_type_name
  , p_data_type_mod
  );
  dbug.print
  ( dbug."input"
  , 'p_data_type_owner; %s; p_data_length: %s; p_data_precision: %s; p_data_scale: %s; p_character_set_name: %s'
  , p_data_type_owner
  , p_data_length
  , p_data_precision
  , p_data_scale
  , p_character_set_name
  );
$end

  self.base_object_seq$ := case when p_base_object is not null then schema_objects_api.find_by_object_id(p_base_object.id()).seq end;
  self.member#$ := p_member#;
  self.member_name$ := p_member_name;
  self.data_type_name$ := p_data_type_name;
  self.data_type_mod$ := p_data_type_mod;
  self.data_type_owner$ := p_data_type_owner;
  self.data_length$ := p_data_length;
  self.data_precision$ := p_data_precision;
  self.data_scale$ := p_data_scale;
  self.character_set_name$ := p_character_set_name;

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
  dbug.leave;
$end

  return;
end;

-- begin of getter(s)/setter(s)
overriding member function object_type
return varchar2 deterministic
is
  begin return 'TYPE_ATTRIBUTE';
end object_type;

member function data_type_name
return varchar2 deterministic
is
begin
  return data_type_name$;
end data_type_name;

member function data_type_mod
return varchar2 deterministic
is
begin
  return data_type_mod$;
end data_type_mod;

member function data_type_owner
return varchar2 deterministic
is
begin
  return data_type_owner$;
end data_type_owner;

member function data_length
return number
is
begin
  return data_length$;
end data_length;

member function data_precision
return number
is
begin
  return data_precision$;
end data_precision;

member function data_scale
return number
is
begin
  return data_scale$;
end data_scale;

member function character_set_name
return varchar2 deterministic
is
begin
  return character_set_name$;
end character_set_name;

member function char_length
return number
deterministic
is
begin
  return data_length();
end char_length;

member function char_used
return varchar2
deterministic
is
begin
  return null;
end char_used;

-- end of getter(s)/setter(s)

final member function data_type
return varchar2
deterministic
is
begin
  return case
           -- data_type_mod() may be REF or empty
           when self.data_type_mod() is not null
           then self.data_type_mod() || ' '
         end ||
         case
           when self.data_type_owner() is not null
           then '"' || self.data_type_owner() || '"."' || self.data_type_name() || '"' -- object types
           else self.data_type_name()
         end ||
         case
           when self.data_precision() is not null and nvl(self.data_scale(), 0) > 0
           then '(' || self.data_precision() || ',' || self.data_scale() || ')'
           when self.data_precision() is not null and nvl(self.data_scale(), 0) = 0
           then '(' || self.data_precision() || ')'
           when self.data_precision() is null and self.data_scale() is not null
           then '(*,' || self.data_scale() || ')'
           when self.char_length() > 0
           then '(' || self.char_length() || case self.char_used() when 'B' then ' BYTE' when 'C' then ' CHAR' end || ')'
         end;
end data_type;

end;
/

