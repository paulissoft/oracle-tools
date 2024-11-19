CREATE OR REPLACE TYPE BODY "ORACLE_TOOLS"."T_TABLE_COLUMN_OBJECT" IS

constructor function t_table_column_object
( self in out nocopy oracle_tools.t_table_column_object
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
, p_nullable in varchar2
, p_default_length in number
, p_data_default in oracle_tools.t_text_tab
, p_char_col_decl_length in number
, p_char_length number
, p_char_used in varchar2
)
return self as result
is
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.CONSTRUCTOR');
  dbug.print
  ( dbug."input"
  , 'p_base_object.id: %s; p_member#: %s; p_member_name: %s'
  , p_base_object.id
  , p_member#
  , p_member_name
  );
$end

  if p_base_object is null
  then
    self.base_object_id$ := null;
  else
    self.base_object_id$ := p_base_object.id;
  end if;
  self.member#$ := p_member#;
  self.member_name$ := p_member_name;
  self.data_type_name$ := p_data_type_name;
  self.data_type_mod$ := p_data_type_mod;
  self.data_type_owner$ := p_data_type_owner;
  self.data_length$ := p_data_length;
  self.data_precision$ := p_data_precision;
  self.data_scale$ := p_data_scale;
  self.character_set_name$ := p_character_set_name;
  self.nullable$ := p_nullable;
  self.default_length$ := p_default_length;
  self.data_default$ := p_data_default;
  self.char_col_decl_length$ := p_char_col_decl_length;
  self.char_length$ := p_char_length;
  self.char_used$ := p_char_used;

  oracle_tools.t_schema_object.set_id(self);
  
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
  dbug.leave;
$end

  return;
end;

-- begin of getter(s)/setter(s)
overriding member function object_type
return varchar2 deterministic
is
begin
  return 'TABLE_COLUMN';
end object_type;

overriding member function column_name
return varchar2 deterministic
is
begin
  return self.member_name();
end column_name;

member function nullable
return varchar2 deterministic
is
begin
  return nullable$;
end nullable;

member function default_length
return number
is
begin
  return default_length$;
end default_length;

member function data_default
return oracle_tools.t_text_tab
is
begin
  return data_default$;
end data_default;

member function char_col_decl_length
return number
is
begin
  return char_col_decl_length$;
end char_col_decl_length;

overriding member function char_length
return number
is
begin
  return char_length$;
end char_length;

overriding member function char_used
return varchar2 deterministic
is
begin
  return char_used$;
end char_used;

overriding member function dict_object_exists
return integer -- 0/1
is
  l_count pls_integer;
  l_column_name constant all_tab_columns.column_name%type := self.member_name$;
  l_base_object_schema constant all_tab_columns.owner%type := self.base_object_schema();
  l_base_object_name constant all_tab_columns.table_name%type := self.base_object_name();
begin
  select  sign(count(*))
  into    l_count
  from    all_tab_columns c
  where   c.owner = l_base_object_schema
  and     c.table_name = l_base_object_name
  and     c.column_name = l_column_name;
  return l_count;
end;

end;
/

