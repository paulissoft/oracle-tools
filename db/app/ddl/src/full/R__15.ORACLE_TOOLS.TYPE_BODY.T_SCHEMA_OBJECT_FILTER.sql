CREATE OR REPLACE TYPE BODY "ORACLE_TOOLS"."T_SCHEMA_OBJECT_FILTER" AS

constructor function t_schema_object_filter
( self in out nocopy oracle_tools.t_schema_object_filter
, p_schema in varchar2 default user
, p_object_type in varchar2 default null
, p_object_names in varchar2 default null
, p_object_names_include in integer default null
, p_grantor_is_schema in integer default 0
)
return self as result
is
  l_item_tab dbms_sql.varchar2a;
  l_part_tab dbms_sql.varchar2a;
begin
  self.schema$ := p_schema;
  self.object_type$ := p_object_type;
  self.object_names$ := replace(replace(replace(replace(p_object_names, chr(9)), chr(13)), chr(10)), chr(32));
  self.object_names_include$ := p_object_names_include;
  self.grantor_is_schema$ := p_grantor_is_schema;

  self.object_name_tab$ := oracle_tools.t_text_tab();
  self.schema_object_info_tab$ := oracle_tools.t_text_tab();

  if self.object_names$ is not null
  then
    oracle_tools.pkg_str_util.split(p_str => self.object_names$, p_delimiter => ',', p_str_tab => l_item_tab);
    if l_item_tab.count > 0
    then
      for i_item_idx in l_item_tab.first .. l_item_tab.last
      loop
        if l_item_tab(i_item_idx) is null
        then
          null;
        elsif instr(l_item_tab(i_item_idx), ':') > 0
        then
          -- a schema object info item (see t_schema_object.schema_object_info())
          self.schema_object_info_tab$.extend(1);
          self.schema_object_info_tab$(self.schema_object_info_tab$.last) := l_item_tab(i_item_idx);
          
          -- add the (base) object name to the object name table
          oracle_tools.pkg_str_util.split(p_str => l_item_tab(i_item_idx), p_delimiter => ':', p_str_tab => l_part_tab);
          if l_part_tab.count >= 3 and l_part_tab(3) is not null
          then
            self.object_name_tab$.extend(1);
            self.object_name_tab$(self.object_name_tab$.last - 1) := l_part_tab(3); -- object name
          end if;
          if l_part_tab.count >= 6 and l_part_tab(6) is not null
          then
            self.object_name_tab$.extend(1);
            self.object_name_tab$(self.object_name_tab$.last) := l_part_tab(6); -- base object name
          end if;
        else
          -- just a simple object name
          self.object_name_tab$.extend(1);
          self.object_name_tab$(self.object_name_tab$.last) := l_item_tab(i_item_idx);
        end if;
      end loop;
    end if;
    
    -- for later
    self.object_names$ := ',' || self.object_names$ || ',';
  end if;

  -- make the tables null if they are empty
  if self.object_name_tab$.count = 0
  then
    self.object_name_tab$ := null;
  end if;

  if self.schema_object_info_tab$.count = 0
  then
    self.schema_object_info_tab$ := null;
  end if;

  return;
end;

member function schema
return varchar2
deterministic
is
begin
  return self.schema$;
end;

member function object_type
return varchar2
deterministic
is
begin
  return self.object_type$;
end;

member function object_names
return varchar2
deterministic
is
begin
  return self.object_names$;
end;

member function object_names_include
return integer
deterministic
is
begin
  return self.object_names_include$;
end;

member function grantor_is_schema
return integer
deterministic
is
begin
  return self.grantor_is_schema$;
end;

member function object_name_tab
return oracle_tools.t_text_tab
deterministic
is
begin
  return self.object_name_tab$;
end;

member function schema_object_info_tab
return oracle_tools.t_text_tab
deterministic
is
begin
  return self.schema_object_info_tab$;
end;

member procedure print
( self in oracle_tools.t_schema_object_filter
)
is
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'PRINT');
  dbug.print
  ( dbug."info"
  , 'schema: %s; object_type: %s; object_names_include: %s; grantor_is_schema: %s; object_names: %s'
  , self.schema()
  , self.object_type()
  , self.object_names_include()
  , self.grantor_is_schema()
  , self.object_names()
  );
  dbug.leave;
$else
  null;
$end
end print;

end;
/

