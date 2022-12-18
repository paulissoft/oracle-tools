CREATE OR REPLACE TYPE BODY "ORACLE_TOOLS"."T_SCHEMA_OBJECT_FILTER" AS

constructor function t_schema_object_filter
( self in out nocopy oracle_tools.t_schema_object_filter
, p_schema in varchar2 default user
, p_object_type in varchar2 default null
, p_object_names in varchar2 default null
, p_object_names_include in integer default null
, p_grantor_is_schema in integer default 0
, p_schema_object_info in clob default null
, p_schema_object_info_include in integer default null
)
return self as result
is
  l_item_tab dbms_sql.varchar2a;
  l_part_tab dbms_sql.varchar2a;
  l_wildcard simple_integer := 0;
begin
  self.schema$ := p_schema;
  self.object_type$ := p_object_type;
  self.object_names$ := replace(replace(replace(replace(p_object_names, chr(9)), chr(13)), chr(10)), chr(32));
  self.object_names_include$ := p_object_names_include;
  self.grantor_is_schema$ := p_grantor_is_schema;
  self.schema_object_info_include$ := p_schema_object_info_include;
  
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
        else
          self.object_name_tab$.extend(1);
          self.object_name_tab$(self.object_name_tab$.last) := l_item_tab(i_item_idx);
        end if;
      end loop;
    end if;
    
    -- for later
    self.object_names$ := ',' || self.object_names$ || ',';
  end if;

  if p_schema_object_info_include is not null
  then
    -- split by LF
    oracle_tools.pkg_str_util.split(p_str => p_schema_object_info, p_delimiter => chr(10), p_str_tab => l_item_tab);
    
    if l_item_tab.count > 0
    then
      for i_item_idx in l_item_tab.first .. l_item_tab.last
      loop
        -- remove TAB and CR
        l_item_tab(i_item_idx) := replace(replace(l_item_tab(i_item_idx), chr(9)), chr(13));
        
        if l_item_tab(i_item_idx) is not null
        then          
          -- O/S wildcards?
          l_wildcard := sign(instr(l_item_tab(i_item_idx), '*')) + sign(instr(l_item_tab(i_item_idx), '?')) * 2;

          -- first character in expression will denote the operator ('=' for equal or '~' for like)
          if l_wildcard = 0
          then
            l_item_tab(i_item_idx) := '=' || l_item_tab(i_item_idx);
          else
            l_item_tab(i_item_idx) := '~' || l_item_tab(i_item_idx);
            -- replace _ by \_
            l_item_tab(i_item_idx) := replace(l_item_tab(i_item_idx), '_', '\_');
            if l_wildcard in (1, 3) -- '*'
            then
              l_item_tab(i_item_idx) := replace(l_item_tab(i_item_idx), '*', '%');
            end if;
            if l_wildcard in (2, 3) -- '?'
            then
              l_item_tab(i_item_idx) := replace(l_item_tab(i_item_idx), '?', '_');
            end if;           
          end if;

          -- a schema object info item (see t_schema_object.schema_object_info())
          self.schema_object_info_tab$.extend(1);
          self.schema_object_info_tab$(self.schema_object_info_tab$.last) := l_item_tab(i_item_idx);
        end if;
      end loop;
    end if;
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

member function schema_object_info_include
return integer
deterministic
is
begin
  return self.schema_object_info_include$;
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
  , 't_schema_object_filter; schema: %s; object_type: %s; object_names_include: %s; grantor_is_schema: %s; object_names: %s'
  , self.schema$
  , self.object_type$
  , self.object_names_include$
  , self.grantor_is_schema$
  , self.object_names$
  );
  dbug.print
  ( dbug."info"
  , 'schema_object_info_include: %s; schema_object_info_tab.count: %s'
  , self.schema_object_info_include$
  , cardinality(self.schema_object_info_tab$)
  );
  if cardinality(self.schema_object_info_tab$) > 0
  then
    for i_idx in self.schema_object_info_tab$.first .. self.schema_object_info_tab$.last
    loop
      dbug.print(dbug."info", 'schema_object_info_tab(%s): %s', self.schema_object_info_tab$(i_idx));      
    end loop;
  end if;
  dbug.leave;
$else
  null;
$end
end print;

member function matches_schema_object
( p_object_types_to_check in oracle_tools.t_text_tab
, p_schema_object_id in varchar2
)
return integer
deterministic
is
  l_part_tab dbms_sql.varchar2a;
  l_metadata_object_type oracle_tools.pkg_ddl_util.t_metadata_object_type := null;
  l_object_name oracle_tools.pkg_ddl_util.t_object_name := null;
  l_metadata_base_object_type oracle_tools.pkg_ddl_util.t_metadata_object_type := null;
  l_base_object_name oracle_tools.pkg_ddl_util.t_object_name := null;
  l_result integer := 0;
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'MATCHES_SCHEMA_OBJECT');
  dbug.print
  ( dbug."input"
  , 'cardinality(p_object_types_to_check): %s; p_schema_object_id: %s'
  , cardinality(p_object_types_to_check)
  , p_schema_object_id
  );
$end    

  oracle_tools.pkg_str_util.split(p_str => p_schema_object_id, p_delimiter => ':', p_str_tab => l_part_tab);
  for i_idx in 2 .. 6
  loop
    if l_part_tab.exists(i_idx)
    then
      case i_idx
        when 2 then l_metadata_object_type := l_part_tab(i_idx); -- object type
        when 3 then l_object_name := l_part_tab(i_idx); -- object name
        when 5 then l_metadata_base_object_type := l_part_tab(i_idx); -- base object type
        when 6 then l_base_object_name := l_part_tab(i_idx); -- base object name
        else null;
      end case;
    end if;
  end loop;

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
  dbug.print
  ( dbug."info"
  , 'l_metadata_object_type: %s; l_object_name: %s; l_metadata_base_object_type: %s; l_base_object_name: %s'
  , l_metadata_object_type
  , l_object_name
  , l_metadata_base_object_type
  , l_base_object_name
  );
$end    

  case
    -- exclude certain (semi-)dependent objects
    when l_metadata_base_object_type is not null and
         l_base_object_name is not null and
         oracle_tools.pkg_ddl_util.is_exclude_name_expr(l_metadata_base_object_type, l_base_object_name) = 1
    then
      l_result := 0;

    -- exclude certain objects
    when l_metadata_object_type is not null and
         l_object_name is not null and
         oracle_tools.pkg_ddl_util.is_exclude_name_expr(l_metadata_object_type, l_object_name) = 1
    then
      l_result := 0;

    when p_object_types_to_check is not null and l_metadata_object_type not member of p_object_types_to_check
    then
      l_result := 1; -- anything is fine

    when self.schema_object_info_include$ is null
    then
      -- old functionality
      if -- filter on object type
         ( self.object_type$ is null or
           self.object_type$ in ( l_metadata_object_type, l_metadata_base_object_type )
         )
         and
         -- filter on object name
         ( self.object_names_include$ is null or
           self.object_names_include$ =
           case -- found?
             when l_object_name is not null and l_object_name member of self.object_name_tab$
             then 1
             when l_base_object_name is not null and l_base_object_name member of self.object_name_tab$
             then 1
             else 0
           end
         )
      then
        l_result := 1;
      else
        l_result := 0;
      end if;

    when self.schema_object_info_include$ is not null
    then
      -- new functionality
      if cardinality(self.schema_object_info_tab$) > 0
      then
        for i_idx in self.schema_object_info_tab$.first .. self.schema_object_info_tab$.last
        loop
          case substr(self.schema_object_info_tab$(i_idx), 1, 1)
            when '=' then l_result := case when p_schema_object_id = substr(self.schema_object_info_tab$(i_idx), 2) then 1 else 0 end;
            when '~' then l_result := case when p_schema_object_id like substr(self.schema_object_info_tab$(i_idx), 2) escape '\' then 1 else 0 end;
          end case;
          exit when l_result != 0;
        end loop;
        
        if self.schema_object_info_include$ = 0 -- p_schema_object_id must NOT be part of schema_object_info_tab$ (list of exclusions)
        then
          -- a) l_result equal 1 means there was a match which means that p_schema_object_id is part of the exclusions so inverse l_result
          -- b) l_result equal 0 means there was no match at all which means that p_schema_object_id is NOT part of the exclusions so inverse l_result
          l_result := 1 - l_result;
        end if;
      end if;

    else
      l_result := 0;
  end case;

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
  dbug.print(dbug."output", 'return: %s', l_result);
  dbug.leave;
$end

  return l_result;
end matches_schema_object;

member function matches_schema_object
( p_object_types_to_check in oracle_tools.t_text_tab
  -- database values
, p_schema_object in oracle_tools.t_schema_object
)
return integer
deterministic
is
begin
  return self.matches_schema_object(p_object_types_to_check, p_schema_object.id());
end matches_schema_object;

end;
/

