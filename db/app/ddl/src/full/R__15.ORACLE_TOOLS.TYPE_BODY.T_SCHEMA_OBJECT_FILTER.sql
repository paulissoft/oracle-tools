CREATE OR REPLACE TYPE BODY "ORACLE_TOOLS"."T_SCHEMA_OBJECT_FILTER" AS

constructor function t_schema_object_filter
( self in out nocopy oracle_tools.t_schema_object_filter
, p_schema in varchar2 default user
, p_object_type in varchar2 default null
, p_object_names in varchar2 default null
, p_object_names_include in integer default null
, p_grantor_is_schema in integer default 0
, p_objects in clob default null
, p_objects_include in integer default null
)
return self as result
is
  l_object_tab dbms_sql.varchar2a;
  l_object_name_tab dbms_sql.varchar2a;
  l_part_tab dbms_sql.varchar2a;
  l_wildcard simple_integer := 0;

  procedure check_object_type
  ( p_object_type in oracle_tools.pkg_ddl_util.t_metadata_object_type
  )
  is
  begin
    if p_object_type is null or
       p_object_type = 'SCHEMA_EXPORT' or
$if not(oracle_tools.pkg_ddl_util.c_get_queue_ddl) $then
       p_object_type in ('AQ_QUEUE', 'AQ_QUEUE_TABLE') or
$end
       p_object_type in ('CONSTRAINT', 'REF_CONSTRAINT') or
       p_object_type member of oracle_tools.pkg_ddl_util.get_md_object_type_tab('SCHEMA')
    then
      null; -- ok
    else
      raise_application_error
      ( oracle_tools.pkg_ddl_error.c_object_type_wrong
      , 'Object type (' || p_object_type || ') is not one of the metadata schema object types.'
      );
    end if;
  end check_object_type;

  procedure check_objects
  ( p_objects in varchar2
  , p_objects_include in oracle_tools.pkg_ddl_util.t_numeric_boolean
  , p_description in varchar2
  )
  is
  begin
    if (p_objects is not null and p_objects_include is null)
    then
      raise_application_error
      ( oracle_tools.pkg_ddl_error.c_objects_wrong
      , 'The ' ||
        p_description ||
        ' include flag (' ||        
        p_objects_include ||
        ') is empty and the ' ||
        p_description ||
        ' list is not empty:' ||
        chr(10) ||
        '"' ||
        p_objects ||
        '"'
      );
    elsif (p_objects is null and p_objects_include is not null)
    then
      raise_application_error
      ( oracle_tools.pkg_ddl_error.c_objects_wrong
      , 'The ' ||
        p_description ||
        ' include flag (' ||        
        p_objects_include ||
        ') is not empty and the ' ||
        p_description ||
        ' list is empty:' ||
        chr(10) ||
        '"' ||
        p_objects ||
        '"'
      );
    end if;
  end check_objects;

  procedure cleanup_object(p_object in out nocopy varchar2)
  is
  begin
    -- remove TAB, CR and LF and then trim spaces
    p_object := trim(replace(replace(replace(p_object, chr(9)), chr(13)), chr(10)));
  end cleanup_object;  

  procedure add_items(p_object_tab in out nocopy dbms_sql.varchar2a)
  is
    l_empty_tab dbms_sql.varchar2a;
  begin
    if p_object_tab.count > 0
    then
      for i_item_idx in p_object_tab.first .. p_object_tab.last
      loop
        cleanup_object(p_object_tab(i_item_idx));

        if p_object_tab(i_item_idx) is not null
        then          
          -- O/S wildcards?
          l_wildcard := sign(instr(p_object_tab(i_item_idx), '*')) + sign(instr(p_object_tab(i_item_idx), '?')) * 2;

          -- first character in expression will denote the operator ('=' for equal or '~' for like)
          if l_wildcard != 0
          then
            -- replace _ by \_
            p_object_tab(i_item_idx) := replace(p_object_tab(i_item_idx), '_', '\_');
            if l_wildcard in (1, 3) -- '*'
            then
              p_object_tab(i_item_idx) := replace(p_object_tab(i_item_idx), '*', '%');
            end if;
            if l_wildcard in (2, 3) -- '?'
            then
              p_object_tab(i_item_idx) := replace(p_object_tab(i_item_idx), '?', '_');
            end if;           
          end if;

          self.objects_tab$.extend(1);
          self.objects_tab$(self.objects_tab$.last) := p_object_tab(i_item_idx);
          self.objects_cmp_tab$.extend(1);
          self.objects_cmp_tab$(self.objects_cmp_tab$.last) := case l_wildcard when 0 then '=' else '~' end;
        end if;
      end loop;
    end if;
    p_object_tab := l_empty_tab;
  end add_items;  
begin
$if oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.CONSTRUCTOR');
  dbug.print
  ( dbug."input"
  , 'p_schema: %s; p_object_type: %s; p_object_names: %s; p_object_names_include: %s; p_grantor_is_schema: %s'
  , p_schema
  , p_object_type
  , p_object_names
  , p_object_names_include
  , p_grantor_is_schema
  );
  dbug.print
  ( dbug."input"
  , 'p_objects: %s; p_objects_include: %s'
  , oracle_tools.pkg_str_util.dbms_lob_substr(p_objects, 100)
  , p_objects_include
  );
$end

  -- old functionality
  oracle_tools.pkg_ddl_util.check_schema(p_schema => p_schema, p_network_link => null);
  check_object_type(p_object_type => p_object_type);
  check_objects(p_objects => p_object_names, p_objects_include => p_object_names_include, p_description => 'object names');
  oracle_tools.pkg_ddl_util.check_numeric_boolean(p_numeric_boolean => p_object_names_include, p_description => 'object names include');
  oracle_tools.pkg_ddl_util.check_numeric_boolean(p_numeric_boolean => p_grantor_is_schema, p_description => 'grantor is schema');
  -- new functionality
  check_objects(p_objects => p_objects, p_objects_include => p_objects_include, p_description => 'objects');
  oracle_tools.pkg_ddl_util.check_numeric_boolean(p_numeric_boolean => p_objects_include, p_description => 'objects include');
    
  self.schema$ := p_schema;
  self.grantor_is_schema$ := p_grantor_is_schema;
  self.objects_include$ := p_objects_include;
  
  self.objects_tab$ := oracle_tools.t_text_tab();
  self.objects_cmp_tab$ := oracle_tools.t_text_tab();

  if p_objects_include is not null
  then
    -- split by LF
    oracle_tools.pkg_str_util.split(p_str => p_objects, p_delimiter => chr(10), p_str_tab => l_object_tab);

    add_items(l_object_tab);
  end if;

  if p_object_names_include is not null
  then
    oracle_tools.pkg_str_util.split
    ( p_str => p_object_names
    , p_delimiter => ','
    , p_str_tab => l_object_name_tab
    );
  elsif p_object_type is not null
  then
    -- one line with any object name: later on this will translate to two lines
    l_object_name_tab(l_object_name_tab.count + 1) := '*';
  end if;
  
  if l_object_name_tab.count > 0
  then
    for i_item_idx in l_object_name_tab.first .. l_object_name_tab.last
    loop
      cleanup_object(l_object_tab(i_item_idx));
      if l_object_name_tab(i_item_idx) is not null
      then
        -- we need to add two objects: one for object and one for base object
        for i_object_idx in 1 .. 2
        loop
          for i_part_idx in 1 .. 10
          loop
            l_part_tab(i_part_idx) :=
              case 
                when i_part_idx = i_object_idx * 3 - 1 -- 2: object type / 5: base object type
                then nvl(p_object_type, '*')
                when i_part_idx = i_object_idx * 3 -- 3: object name / 6: base object name
                then l_object_name_tab(i_item_idx)
                else '*'
              end;
          end loop;
          l_object_tab(l_object_tab.count + 1) := oracle_tools.pkg_str_util.join(p_str_tab => l_part_tab, p_delimiter => ':');
        end loop;
      end if;
    end loop;

    add_items(l_object_tab);
  end if;
  
  -- make the tables null if they are empty
  if self.objects_tab$.count = 0
  then
    self.objects_tab$ := null;
  end if;

  if self.objects_cmp_tab$.count = 0
  then
    self.objects_cmp_tab$ := null;
  end if;

$if oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
  dbug.print
  ( dbug."output"
  , 'schema$: %s; grantor_is_schema$: %s; objects_tab$.count: %s; objects_include$: %s'
  , self.schema$
  , self.grantor_is_schema$
  , cardinality(self.objects_tab$)
  , self.objects_include$
  );
  if cardinality(self.objects_tab$) > 0
  then
    for i_idx in self.objects_tab$.first .. self.objects_tab$.last
    loop
      dbug.print
      ( dbug."output"
      , '[%s] objects_tab$ element: %s; objects_cmp_tab$ element: "%s"'
      , i_idx
      , self.objects_tab$(i_idx)
      , self.objects_cmp_tab$(i_idx)
      );
    end loop;
  end if;

  dbug.leave;
$end

  return; -- essential

$if oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end  
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

member procedure print
( self in oracle_tools.t_schema_object_filter
)
is
begin
$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'PRINT');
  dbug.print
  ( dbug."info"
  , 'schema$: %s; grantor_is_schema$: %s; objects_tab$.count: %s; objects_include$: %s'
  , self.schema$
  , self.grantor_is_schema$
  , cardinality(self.objects_tab$)
  , self.objects_include$
  );
  if cardinality(self.objects_tab$) > 0
  then
    for i_idx in self.objects_tab$.first .. self.objects_tab$.last
    loop
      dbug.print
      ( dbug."info"
      , '[%s] objects_tab$ element: %s; objects_cmp_tab$ element: "%s"'
      , i_idx
      , self.objects_tab$(i_idx)
      , self.objects_cmp_tab$(i_idx)
      );
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
$if oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
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

$if oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
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

    when self.objects_include$ is not null
    then
      -- new functionality
      if cardinality(self.objects_tab$) > 0
      then
        for i_idx in self.objects_tab$.first .. self.objects_tab$.last
        loop
          case self.objects_cmp_tab$(i_idx)
            when '=' then l_result := case when p_schema_object_id = self.objects_tab$(i_idx) then 1 else 0 end;
            when '~' then l_result := case when p_schema_object_id like self.objects_tab$(i_idx) escape '\' then 1 else 0 end;
          end case;
$if oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
          dbug.print(dbug."info", '[%s] %s "%s" %s: %s', i_idx, p_schema_object_id, self.objects_cmp_tab$(i_idx), self.objects_tab$(i_idx), l_result);
$end
          exit when l_result != 0;
        end loop;
        
        if self.objects_include$ = 0 -- p_schema_object_id must NOT be part of objects_tab$ (list of exclusions)
        then
          -- a) l_result equal 1 means there was a match which means that p_schema_object_id is part of the exclusions so inverse l_result
          -- b) l_result equal 0 means there was no match at all which means that p_schema_object_id is NOT part of the exclusions so inverse l_result
          l_result := 1 - l_result;
        end if;
      end if;

    else
      l_result := 1; -- nothing to compare is OK
  end case;

$if oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
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

