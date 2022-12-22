CREATE OR REPLACE PACKAGE BODY "ORACLE_TOOLS"."PKG_SCHEMA_OBJECT_FILTER" IS

-- see static function T_SCHEMA_OBJECT.ID
c_nr_parts constant simple_integer := 10;

"OBJECT TYPE" constant simple_integer := 2;
"OBJECT NAME" constant simple_integer := 3;
"BASE OBJECT TYPE" constant simple_integer := 5;
"BASE OBJECT NAME" constant simple_integer := 6;

-- forward declaration
function fill_array(p_element in varchar2)
return dbms_sql.varchar2a;

c_default_empty_part_tab constant dbms_sql.varchar2a := fill_array(null);
c_default_wildcard_part_tab constant dbms_sql.varchar2a:= fill_array('*');

$if oracle_tools.cfg_pkg.c_testing $then

c_schema_object_filter constant t_schema_object_filter := oracle_tools.t_schema_object_filter(null, null, null, null, null, null, null, null);

$end

-- LOCAL

function fill_array(p_element in varchar2)
return dbms_sql.varchar2a
is
  l_part_tab dbms_sql.varchar2a;
begin
  -- create a default array to assign anytime needed
  for i_part_idx in 1 .. c_nr_parts
  loop
    l_part_tab(i_part_idx) := p_element;
  end loop;
  return l_part_tab;
end fill_array;

-- the work horse
function matches_schema_object
( p_schema_object_filter in t_schema_object_filter
, p_schema_object_id in varchar2
, p_match_partial in boolean
, p_metadata_object_type in varchar2
, p_object_name in varchar2
, p_metadata_base_object_type in varchar2
, p_base_object_name in varchar2
)
return integer
deterministic
is
  l_idx simple_integer := 0;
  l_result integer := 0;
begin
$if oracle_tools.pkg_schema_object_filter.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'MATCHES_SCHEMA_OBJECT');
  dbug.print
  ( dbug."input"
  , 'p_schema_object_id: %s; p_match_partial: %s; object: "%s"; base object: "%s"'
  , p_schema_object_id
  , dbug.cast_to_varchar2(p_match_partial)
  , p_metadata_object_type || ':' || p_object_name
  , p_metadata_base_object_type || ':' || p_base_object_name
  );
$end    

  case
    -- exclude certain (semi-)dependent objects
    when p_metadata_base_object_type is not null and
         p_base_object_name is not null and
         oracle_tools.pkg_ddl_util.is_exclude_name_expr(p_metadata_base_object_type, p_base_object_name) = 1
    then
$if oracle_tools.pkg_schema_object_filter.c_debugging $then
       dbug.print(dbug."info", 'case 1');
$end
      l_result := 0;

    -- exclude certain objects
    when p_metadata_object_type is not null and
         p_object_name is not null and
         oracle_tools.pkg_ddl_util.is_exclude_name_expr(p_metadata_object_type, p_object_name) = 1
    then
$if oracle_tools.pkg_schema_object_filter.c_debugging $then
       dbug.print(dbug."info", 'case 2');
$end
      l_result := 0;

    when p_schema_object_filter.objects_include$ is not null
    then
$if oracle_tools.pkg_schema_object_filter.c_debugging $then
       dbug.print(dbug."info", 'case 3');
$end

      /*
      -- When the schema object id is valid we must test the odd numbers else the even.
      -- See also the construct routine.
      */

      l_idx := case when p_match_partial then 2 else 1 end;
      while l_idx <= p_schema_object_filter.objects_tab$.count
      loop
        case p_schema_object_filter.objects_cmp_tab$(l_idx)
          when '=' then l_result := case when p_schema_object_id = p_schema_object_filter.objects_tab$(l_idx) then 1 else 0 end;
          when '~' then l_result := case when p_schema_object_id like p_schema_object_filter.objects_tab$(l_idx) escape '\' then 1 else 0 end;
        end case;
$if oracle_tools.pkg_schema_object_filter.c_debugging $then
        dbug.print
        ( dbug."info"
        , '[%s] %s "%s" %s: %s'
        , l_idx
        , p_schema_object_id
        , p_schema_object_filter.objects_cmp_tab$(l_idx)
        , p_schema_object_filter.objects_tab$(l_idx)
        , l_result
        );
$end
        exit when l_result != 0;

        l_idx := l_idx + 2;        
      end loop;

      if p_schema_object_filter.objects_include$ = 0 -- p_schema_object_id must NOT be part of objects_tab$ (list of exclusions)
      then
        -- a) l_result equal 1 means there was a match which means that p_schema_object_id is part of the exclusions so inverse l_result
        -- b) l_result equal 0 means there was no match at all which means that p_schema_object_id is NOT part of the exclusions so inverse l_result
        l_result := 1 - l_result;
      end if;

    else
$if oracle_tools.pkg_schema_object_filter.c_debugging $then
      dbug.print(dbug."info", 'case 4');
$end
      l_result := 1; -- nothing to compare is OK
  end case;

$if oracle_tools.pkg_schema_object_filter.c_debugging $then
  dbug.print(dbug."output", 'return: %s', l_result);
  dbug.leave;
$end

  return l_result;
end matches_schema_object;

procedure serialize
( p_schema_object_filter in t_schema_object_filter
, p_json_object in out nocopy json_object_t
)
is
  procedure to_json_array(p_attribute in varchar2, p_str_tab in oracle_tools.t_text_tab)
  is
    l_json_array json_array_t;
  begin
    if p_str_tab is not null and p_str_tab.count > 0
    then
      l_json_array := json_array_t();
      for i_idx in p_str_tab.first .. p_str_tab.last
      loop
        l_json_array.append(p_str_tab(i_idx));
      end loop;
      p_json_object.put(p_attribute, l_json_array);
    end if;
  end to_json_array;
begin
  p_json_object.put('SCHEMA$', p_schema_object_filter.schema$);
  p_json_object.put('GRANTOR_IS_SCHEMA$', p_schema_object_filter.grantor_is_schema$);
  to_json_array('OBJECTS_TAB$', p_schema_object_filter.objects_tab$);
  p_json_object.put('OBJECTS_INCLUDE$', p_schema_object_filter.objects_include$);
  to_json_array('OBJECTS_CMP_TAB$', p_schema_object_filter.objects_cmp_tab$);
  p_json_object.put('MATCH_PARTIAL_EQ_COMPLETE$', p_schema_object_filter.match_partial_eq_complete$);
  p_json_object.put('MATCH_COUNT$', p_schema_object_filter.match_count$);
  p_json_object.put('MATCH_COUNT_OK$', p_schema_object_filter.match_count_ok$);
end serialize;

function serialize
( p_schema_object_filter in t_schema_object_filter
)
return json_object_t
is
  l_json_object json_object_t := json_object_t();
begin
  serialize(p_schema_object_filter, l_json_object);
  return l_json_object;
end serialize;

function repr
( p_schema_object_filter in t_schema_object_filter
)
return clob
is
  l_clob clob := serialize(p_schema_object_filter).to_clob();
begin
  select  json_serialize(l_clob returning clob pretty)
  into    l_clob
  from    dual;

  return l_clob;
end repr;

-- GLOBAL

procedure construct
( p_schema in varchar2 default user
, p_object_type in varchar2 default null
, p_object_names in varchar2 default null
, p_object_names_include in integer default null
, p_grantor_is_schema in integer default 0
, p_objects in clob default null
, p_objects_include in integer default null
, p_schema_object_filter in out nocopy t_schema_object_filter
)
is
  l_object_tab dbms_sql.varchar2a;
  l_object_name_tab dbms_sql.varchar2a;
  l_part_tab dbms_sql.varchar2a;

  l_object_names constant oracle_tools.pkg_ddl_util.t_object_names :=
    case
      when p_object_names is not null
      then p_object_names
      -- When p_object_names is null but p_object_type not, this is
      -- the same as matching against any object name with that object type.
      when p_object_type is not null
      then '*'
      else null
    end;

  l_object_names_include constant oracle_tools.pkg_ddl_util.t_numeric_boolean :=
    case
      when p_object_names_include is not null
      then p_object_names_include
      -- When p_object_names_include is null but p_object_type not, that is
      -- similar to matching (inclusive) against any object name.
      when p_object_type is not null
      then 1
      else null
    end;

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

  procedure add_items
  ( p_object_tab in dbms_sql.varchar2a
  )
  is
    l_object varchar2(4000 char);
    l_part1_tab dbms_sql.varchar2a;
    l_part2_tab dbms_sql.varchar2a;

    procedure add_item(p_object in out nocopy varchar2)
    is
      l_wildcard constant simple_integer := sign(instr(p_object, '*')) + sign(instr(p_object, '?')) * 2;
    begin
$if oracle_tools.pkg_schema_object_filter.c_debugging $then
      dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.CONSTRUCT.ADD_ITEMS.ADD_ITEM');
      dbug.print(dbug."input", 'p_object: %s', p_object);
$end

      if l_wildcard != 0
      then
        -- escape SQL wildcards
        p_object := replace(p_object, '_', '\_');
        p_object := replace(p_object, '%', '\%');
        
        if l_wildcard in (1, 3) -- '*'
        then
          p_object := replace(p_object, '*', '%');
        end if;
        if l_wildcard in (2, 3) -- '?'
        then
          p_object := replace(p_object, '?', '_');
        end if;           
      end if;

      -- duplicates allowed: partial versus complete 
      p_schema_object_filter.objects_tab$.extend(1);
      p_schema_object_filter.objects_tab$(p_schema_object_filter.objects_tab$.last) := p_object;
      p_schema_object_filter.objects_cmp_tab$.extend(1);
      p_schema_object_filter.objects_cmp_tab$(p_schema_object_filter.objects_cmp_tab$.last) := case l_wildcard when 0 then '=' else '~' end;

$if oracle_tools.pkg_schema_object_filter.c_debugging $then
      dbug.print
      ( dbug."output"
      , 'p_object: %s; cardinality(p_schema_object_filter.objects_tab$): %s; cardinality(p_schema_object_filter.objects_cmp_tab$): %s'
      , p_object
      , cardinality(p_schema_object_filter.objects_tab$)
      , cardinality(p_schema_object_filter.objects_cmp_tab$)
      );
      dbug.leave;
$end
    end add_item;
  begin
    if p_object_tab.count > 0
    then
      for i_object_idx in p_object_tab.first .. p_object_tab.last
      loop
        l_object := p_object_tab(i_object_idx);

        cleanup_object(l_object);

        if l_object is not null
        then
          -- save this line as an array and check at the same time the number of colons
          oracle_tools.pkg_str_util.split(p_str => l_object, p_delimiter => ':', p_str_tab => l_part1_tab);

          if l_part1_tab.count != c_nr_parts
          then
            oracle_tools.pkg_ddl_error.raise_error
            ( p_error_number => oracle_tools.pkg_ddl_error.c_objects_wrong
            , p_error_message => 'number of parts (' || l_part1_tab.count || ') must be ' || c_nr_parts
            , p_context_info => l_object
            , p_context_label => 'schema object id'
            );            
          end if;

          -- make two lines:
          -- 1) COMPLETE match: with the same info as in l_object but with O/S wildcards replaced and SQL wildcards escaped (odd index)
          -- 2) PARTIAL match: with just OBJECT TYPE, OBJECT NAME, BASE OBJECT TYPE and BASE OBJECT NAME copied (even index) and
          --    empty elements are set to a wildcard so that the cmp entry will be '~' (wildcard)

          -- first line
          add_item(l_object);

          -- second line
          l_part2_tab := c_default_wildcard_part_tab; -- see note 2, force wildcard
          for i_part_idx in 1 .. c_nr_parts
          loop
            case 
              when i_part_idx in("OBJECT TYPE", "OBJECT NAME", "BASE OBJECT TYPE", "BASE OBJECT NAME")
              then l_part2_tab(i_part_idx) := nvl(l_part1_tab(i_part_idx), '*');
              else null;
            end case;
          end loop;

          l_object := oracle_tools.pkg_str_util.join(p_str_tab => l_part2_tab, p_delimiter => ':');
          add_item(l_object);

          -- if the COMPLETE and PARTIAL match entries differ, set p_schema_object_filter.match_partial_eq_complete$ to false (0)
          case
            when p_schema_object_filter.match_partial_eq_complete$ = 0
            then null;
            when p_schema_object_filter.objects_tab$(p_schema_object_filter.objects_tab$.last - 1) =
                 p_schema_object_filter.objects_tab$(p_schema_object_filter.objects_tab$.last) and
                 p_schema_object_filter.objects_cmp_tab$(p_schema_object_filter.objects_cmp_tab$.last - 1) =
                 p_schema_object_filter.objects_cmp_tab$(p_schema_object_filter.objects_cmp_tab$.last)
            then null;
            else p_schema_object_filter.match_partial_eq_complete$ := 0;
          end case;
        end if;
      end loop;
    end if;
  end add_items;  
begin
$if oracle_tools.pkg_schema_object_filter.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.CONSTRUCT');
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
  oracle_tools.pkg_ddl_util.check_numeric_boolean(p_numeric_boolean => p_object_names_include, p_description => 'object names include');
  check_objects(p_objects => p_object_names, p_objects_include => p_object_names_include, p_description => 'object names');
  oracle_tools.pkg_ddl_util.check_numeric_boolean(p_numeric_boolean => p_grantor_is_schema, p_description => 'grantor is schema');
  -- new functionality
  oracle_tools.pkg_ddl_util.check_numeric_boolean(p_numeric_boolean => p_objects_include, p_description => 'objects include');
  check_objects(p_objects => p_objects, p_objects_include => p_objects_include, p_description => 'objects');

  if (p_object_names_include is not null and p_objects_include is not null)
  then
    raise_application_error
    ( oracle_tools.pkg_ddl_error.c_objects_wrong
    , 'Both the object names include flag (' ||        
      p_object_names_include ||
      ') and the objects include flag (' ||
      p_objects_include ||
      ' are not empty: at most one can be specified'
    );
  elsif (p_object_type is not null and p_objects_include is not null)
  then
    raise_application_error
    ( oracle_tools.pkg_ddl_error.c_objects_wrong
    , 'Both the object type (' ||        
      p_object_type ||
      ') and the objects include flag (' ||
      p_objects_include ||
      ' are not empty: at most one can be specified'
    );
  end if;
  
  p_schema_object_filter.schema$ := p_schema;
  p_schema_object_filter.grantor_is_schema$ := p_grantor_is_schema;
  p_schema_object_filter.objects_include$ := nvl(p_objects_include, l_object_names_include);
  p_schema_object_filter.objects_tab$ := oracle_tools.t_text_tab();
  p_schema_object_filter.objects_cmp_tab$ := oracle_tools.t_text_tab();
  p_schema_object_filter.match_partial_eq_complete$ := 1; -- for the time being
  p_schema_object_filter.match_count$ := 0;
  p_schema_object_filter.match_count_ok$ := 0;

  if p_objects_include is not null
  then
    -- new functionality
    -- split by LF
    oracle_tools.pkg_str_util.split(p_str => p_objects, p_delimiter => chr(10), p_str_tab => l_object_tab);

    add_items(l_object_tab);
  else
    -- old functionality
    if l_object_names_include is not null
    then
      oracle_tools.pkg_str_util.split
      ( p_str => l_object_names
      , p_delimiter => ','
      , p_str_tab => l_object_name_tab
      );
    end if;

    if l_object_name_tab.count > 0
    then
      for i_object_name_idx in l_object_name_tab.first .. l_object_name_tab.last
      loop
        cleanup_object(l_object_name_tab(i_object_name_idx));
        if l_object_name_tab(i_object_name_idx) is not null
        then
          if p_object_type member of oracle_tools.pkg_ddl_util.get_md_object_type_tab('DEPENDENT')
          then
            -- Just set OBJECT TYPE and BASE OBJECT NAME
            -- since only the BASE OBJECT will be a NAMED object.
            -- Please note that l_object_name_tab(i_object_name_idx) is a NAMED object (e.g. part of ALL_OBJECTS).
            l_part_tab := c_default_wildcard_part_tab;
            l_part_tab("OBJECT TYPE") := p_object_type;
            l_part_tab("BASE OBJECT NAME") := l_object_name_tab(i_object_name_idx);
            l_object_tab(l_object_tab.count + 1) := oracle_tools.pkg_str_util.join(p_str_tab => l_part_tab, p_delimiter => ':');
          else
            -- We need to add two objects: one for object and one for base object since either may be a NAMED object

            -- object 1
            l_part_tab := c_default_wildcard_part_tab;
            l_part_tab("OBJECT TYPE") := nvl(p_object_type, '*');
            l_part_tab("OBJECT NAME") := l_object_name_tab(i_object_name_idx);
            l_object_tab(l_object_tab.count + 1) := oracle_tools.pkg_str_util.join(p_str_tab => l_part_tab, p_delimiter => ':');
            
            -- object 2
            l_part_tab := c_default_wildcard_part_tab;
            l_part_tab("BASE OBJECT TYPE") := nvl(p_object_type, '*');
            l_part_tab("BASE OBJECT NAME") := l_object_name_tab(i_object_name_idx);
            l_object_tab(l_object_tab.count + 1) := oracle_tools.pkg_str_util.join(p_str_tab => l_part_tab, p_delimiter => ':');
          end if;
        end if;
      end loop;

      add_items(l_object_tab);
    end if;
  end if;

  -- make the tables null if they are empty
  if p_schema_object_filter.objects_tab$.count = 0
  then
    p_schema_object_filter.objects_tab$ := null;
  end if;

  if p_schema_object_filter.objects_cmp_tab$.count = 0
  then
    p_schema_object_filter.objects_cmp_tab$ := null;
  end if;

$if oracle_tools.pkg_schema_object_filter.c_debugging $then
  print(p_schema_object_filter);
$end

  -- sanity checks
  if p_schema_object_filter.objects_include$ is null and
     nvl(cardinality(p_schema_object_filter.objects_tab$), 0) = 0 and
     nvl(cardinality(p_schema_object_filter.objects_cmp_tab$), 0) = 0
  then
    null;
  elsif p_schema_object_filter.objects_include$ is not null and
        cardinality(p_schema_object_filter.objects_tab$) > 0 and
        cardinality(p_schema_object_filter.objects_tab$) = cardinality(p_schema_object_filter.objects_cmp_tab$)
  then
    null;
  else
    raise program_error;
  end if;

$if oracle_tools.pkg_schema_object_filter.c_debugging $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end  
end construct;

procedure print
( p_schema_object_filter in t_schema_object_filter
)
is
begin
-- !!! DO NOT use oracle_tools.pkg_schema_object_filter.c_debugging HERE !!!
$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'PRINT');
  dbug.print
  ( dbug."info"
  , 'schema$: %s; grantor_is_schema$: %s; objects_tab$.count: %s; objects_cmp_tab$.count: %s; objects_include$: %s'
  , p_schema_object_filter.schema$
  , p_schema_object_filter.grantor_is_schema$
  , cardinality(p_schema_object_filter.objects_tab$)
  , cardinality(p_schema_object_filter.objects_cmp_tab$)
  , p_schema_object_filter.objects_include$
  );
  if cardinality(p_schema_object_filter.objects_tab$) > 0
  then
    for i_object_idx in p_schema_object_filter.objects_tab$.first .. p_schema_object_filter.objects_tab$.last
    loop
      dbug.print
      ( dbug."info"
      , '[%s] objects_tab$ element: %s; objects_cmp_tab$ element: "%s"'
      , i_object_idx
      , p_schema_object_filter.objects_tab$(i_object_idx)
      , p_schema_object_filter.objects_cmp_tab$(i_object_idx)
      );
    end loop;
  end if;
  dbug.leave;
$else
  null;
$end
end print;

function matches_schema_object
( p_schema_object_filter in out nocopy t_schema_object_filter
, p_metadata_object_type in varchar2
, p_object_name in varchar2
, p_metadata_base_object_type in varchar2 default null
, p_base_object_name in varchar2 default null
)
return integer
deterministic
is
  l_part_tab dbms_sql.varchar2a;
  l_result pls_integer;
begin
  -- Note SWITCH.
  -- A) When both the base parameters are empty (named search) we need to both lookup
  --    using the OBJECT info in p_schema_object_filter.objects_tab$ and BASE OBJECT info,
  --    hence switch OBJECT and BASE OBJECT. If the result for the switch is then 1
  --    we need to redo a named object match at the end in combine_named_dependent_objects().
  -- B) When at least one of the base parameters is not empty: just one partial match.
  
  for i_try in 1 .. case when p_metadata_base_object_type is null and p_base_object_name is null then 2 else 1 end
  loop
    l_part_tab := c_default_empty_part_tab; -- ':::::::::' like '%:%:%:%:%:%:%:%:%:%'

    if i_try = 1
    then
      l_part_tab("OBJECT TYPE") := p_metadata_object_type;
      l_part_tab("OBJECT NAME") := p_object_name;
      l_part_tab("BASE OBJECT TYPE") := p_metadata_base_object_type;
      l_part_tab("BASE OBJECT NAME") := p_base_object_name;
    else
      -- switch
      l_part_tab("BASE OBJECT TYPE") := p_metadata_object_type;
      l_part_tab("BASE OBJECT NAME") := p_object_name;
    end if;

    l_result := matches_schema_object
                ( p_schema_object_filter => p_schema_object_filter
                , p_schema_object_id => oracle_tools.pkg_str_util.join(p_str_tab => l_part_tab, p_delimiter => ':')
                , p_match_partial => true
                , p_metadata_object_type => p_metadata_object_type
                , p_object_name => p_object_name
                , p_metadata_base_object_type => p_metadata_base_object_type
                , p_base_object_name => p_base_object_name
                );

    p_schema_object_filter.match_count$ := p_schema_object_filter.match_count$ + 1;
    p_schema_object_filter.match_count_ok$ := p_schema_object_filter.match_count_ok$ + l_result;
    
    if l_result = 1 -- stop when found
    then
      -- Since we used onbject (p_metadata_object_type, p_object_name) to match against the base object in the filter entries
      -- we can not be sure that all named objects match the standard criteria so we have to do that again in combine_named_dependent_objects().
      if i_try = 2
      then
        p_schema_object_filter.match_partial_eq_complete$ := 0;
      end if;
      exit;
    end if;
  end loop;
  
  return l_result;
end matches_schema_object;

function matches_schema_object
( p_schema_object_filter in t_schema_object_filter
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
begin
  oracle_tools.pkg_str_util.split(p_str => p_schema_object_id, p_delimiter => ':', p_str_tab => l_part_tab);

  if l_part_tab.count != c_nr_parts
  then
    oracle_tools.pkg_ddl_error.raise_error
    ( p_error_number => oracle_tools.pkg_ddl_error.c_objects_wrong
    , p_error_message => 'number of parts (' || l_part_tab.count || ') must be ' || c_nr_parts
    , p_context_info => p_schema_object_id
    , p_context_label => 'schema object id'
    );            
  end if;

  l_metadata_object_type := l_part_tab("OBJECT TYPE");
  l_object_name := l_part_tab("OBJECT NAME");
  l_metadata_base_object_type := l_part_tab("BASE OBJECT TYPE");
  l_base_object_name := l_part_tab("BASE OBJECT NAME");

  return matches_schema_object
         ( p_schema_object_filter => p_schema_object_filter
         , p_schema_object_id => p_schema_object_id
         , p_match_partial =>
             p_schema_object_id != oracle_tools.t_schema_object.id
                                   ( p_object_schema => l_part_tab(1)
                                   , p_object_type => l_part_tab(2)
                                   , p_object_name => l_part_tab(3)
                                   , p_base_object_schema => l_part_tab(4)
                                   , p_base_object_type => l_part_tab(5)
                                   , p_base_object_name => l_part_tab(6)
                                   , p_column_name => l_part_tab(7)
                                   , p_grantee => l_part_tab(8)
                                   , p_privilege => l_part_tab(9)
                                   , p_grantable => l_part_tab(10)
                                   )
         , p_metadata_object_type => l_metadata_object_type
         , p_object_name => l_object_name
         , p_metadata_base_object_type => l_metadata_base_object_type
         , p_base_object_name => l_base_object_name
         );
end matches_schema_object;

function matches_schema_object
( p_schema_object_filter in t_schema_object_filter
, p_schema_object in oracle_tools.t_schema_object
)
return integer
deterministic
is
begin
  return matches_schema_object
         ( p_schema_object_filter => p_schema_object_filter
         , p_schema_object_id => p_schema_object.id()
         , p_match_partial => false
         , p_metadata_object_type => null -- no need to use oracle_tools.pkg_ddl_util.is_exclude_name_expr() again
         , p_object_name => null -- idem
         , p_metadata_base_object_type => null -- idem
         , p_base_object_name => null -- idem
         );
end matches_schema_object;

procedure combine_named_dependent_objects
( p_schema_object_filter in t_schema_object_filter
, p_named_object_tab in oracle_tools.t_schema_object_tab
, p_dependent_object_tab in oracle_tools.t_schema_object_tab
, p_schema_object_tab out nocopy oracle_tools.t_schema_object_tab
)
is
begin
$if oracle_tools.pkg_schema_object_filter.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.COMBINE_NAMED_DEPENDENT_OBJECTS');
  dbug.print
  ( dbug."input"
  , 'cardinality(p_named_object_tab): %s; cardinality(p_dependent_object_tab): %s'
  , cardinality(p_named_object_tab)
  , cardinality(p_dependent_object_tab)
  );
$end

  if p_schema_object_filter.match_partial_eq_complete$ = 1
  then
    -- We will not filter out any items from p_named_object_tab since the partial match
    -- is equal to the complete match since all complete filter items are equal to
    -- the partial filter items AND never we did switch object and base object.
    -- See note SWITCH above.

    -- Combine and filter based on the map function of oracle_tools.t_schema_object and its subtypes.    
    -- GPA 2017-01-27
    -- For performance reasons do not use DISTINCT since the sets should be unique and distinct already.
    p_schema_object_tab := p_named_object_tab multiset union /*distinct*/ p_dependent_object_tab;
  else
    -- Perform a complete match for the named objects since we may filter out named objects by that.
    
    select  value(obj) as base_object
    bulk collect
    into    p_schema_object_tab
    from    table(p_named_object_tab) obj
    where   oracle_tools.pkg_schema_object_filter.matches_schema_object
            ( p_schema_object_filter => p_schema_object_filter
            , p_schema_object => value(obj)
            ) = 1
    ;

    p_schema_object_tab := p_schema_object_tab multiset union /*distinct*/ p_dependent_object_tab;
  end if;

$if oracle_tools.pkg_schema_object_filter.c_debugging $then
  dbug.print
  ( dbug."output"
  , 'cardinality(p_schema_object_tab): %s'
  , cardinality(p_schema_object_tab)
  );
  dbug.leave;
$end
end combine_named_dependent_objects;

$if oracle_tools.cfg_pkg.c_testing $then

procedure ut_construct
is
  l_schema_object_filter t_schema_object_filter := c_schema_object_filter;
  l_expected json_element_t;
begin
  l_expected := json_element_t.parse('{
  "SCHEMA$" : null,
  "GRANTOR_IS_SCHEMA$" : null,
  "OBJECTS_INCLUDE$" : null,
  "MATCH_PARTIAL_EQ_COMPLETE$" : null,
  "MATCH_COUNT$" : null,
  "MATCH_COUNT_OK$" : null
}');
  
  ut.expect(serialize(l_schema_object_filter), 'empty').to_equal(l_expected);

  for i_try in 1..4
  loop
    case i_try
      when 1
      then
        construct
        ( p_schema_object_filter => l_schema_object_filter
        );
        l_expected := json_element_t.parse('{
  "SCHEMA$" : "ORACLE_TOOLS",
  "GRANTOR_IS_SCHEMA$" : 0,
  "OBJECTS_INCLUDE$" : null,
  "MATCH_PARTIAL_EQ_COMPLETE$" : 1,
  "MATCH_COUNT$" : 0,
  "MATCH_COUNT_OK$" : 0
}');
      when 2
      then
        l_schema_object_filter := oracle_tools.t_schema_object_filter
        ( p_schema => 'SYS'
        , p_object_type => 'PACKAGE_SPEC'
        , p_object_names => 'DBMS_METADATA,DBMS_VERSION'
        , p_object_names_include => 1
        , p_grantor_is_schema => 1
        , p_objects => null
        , p_objects_include => null
        );
        l_expected := json_element_t.parse('{
  "SCHEMA$" : "SYS",
  "GRANTOR_IS_SCHEMA$" : 1,  
  "OBJECTS_TAB$" :
            [
              "%:PACKAGE\\_SPEC:DBMS\\_METADATA:%:%:%:%:%:%:%",
              "%:PACKAGE\\_SPEC:DBMS\\_METADATA:%:%:%:%:%:%:%",
              "%:%:%:%:PACKAGE\\_SPEC:DBMS\\_METADATA:%:%:%:%",
              "%:%:%:%:PACKAGE\\_SPEC:DBMS\\_METADATA:%:%:%:%",
              "%:PACKAGE\\_SPEC:DBMS\\_VERSION:%:%:%:%:%:%:%",
              "%:PACKAGE\\_SPEC:DBMS\\_VERSION:%:%:%:%:%:%:%",
              "%:%:%:%:PACKAGE\\_SPEC:DBMS\\_VERSION:%:%:%:%",
              "%:%:%:%:PACKAGE\\_SPEC:DBMS\\_VERSION:%:%:%:%"
            ],
  "OBJECTS_INCLUDE$" : 1,
  "OBJECTS_CMP_TAB$" :
            [
              "~",
              "~",
              "~",
              "~",
              "~",
              "~",
              "~",
              "~"
            ],
  "MATCH_PARTIAL_EQ_COMPLETE$" : 1,
  "MATCH_COUNT$" : 0,
  "MATCH_COUNT_OK$" : 0
}');
      when 3
      then
        l_schema_object_filter := oracle_tools.t_schema_object_filter
        ( p_schema => 'SYS'
        , p_object_type => 'OBJECT_GRANT'
        , p_object_names => '
DBMS_OUTPUT,
DBMS_SQL
'
        , p_object_names_include => 1
        , p_grantor_is_schema => 1
        , p_objects => null
        , p_objects_include => null
        );
        l_expected := json_element_t.parse('{
  "SCHEMA$" : "SYS",
  "GRANTOR_IS_SCHEMA$" : 1,
  "OBJECTS_TAB$" :
            [
              "%:OBJECT\\_GRANT:%:%:%:DBMS\\_OUTPUT:%:%:%:%",
              "%:OBJECT\\_GRANT:%:%:%:DBMS\\_OUTPUT:%:%:%:%",
              "%:OBJECT\\_GRANT:%:%:%:DBMS\\_SQL:%:%:%:%",
              "%:OBJECT\\_GRANT:%:%:%:DBMS\\_SQL:%:%:%:%"
            ],
  "OBJECTS_INCLUDE$" : 1,
  "OBJECTS_CMP_TAB$" :
            [
              "~",
              "~",
              "~",
              "~"
            ],
  "MATCH_PARTIAL_EQ_COMPLETE$" : 1,
  "MATCH_COUNT$" : 0,
  "MATCH_COUNT_OK$" : 0
}');

      when 4
      then
        l_schema_object_filter := oracle_tools.t_schema_object_filter
        ( p_schema => 'SYS'
        , p_object_type => null
        , p_object_names => '
DBMS_OUTPUT,
DBMS_SQL
'
        , p_object_names_include => 0
        , p_grantor_is_schema => 1
        , p_objects => null
        , p_objects_include => null
        );
        l_expected := json_element_t.parse('{
  "SCHEMA$" : "SYS",
  "GRANTOR_IS_SCHEMA$" : 1,
  "OBJECTS_TAB$" :
            [
              "%:%:DBMS\\_OUTPUT:%:%:%:%:%:%:%",
              "%:%:DBMS\\_OUTPUT:%:%:%:%:%:%:%",
              "%:%:%:%:%:DBMS\\_OUTPUT:%:%:%:%",
              "%:%:%:%:%:DBMS\\_OUTPUT:%:%:%:%",
              "%:%:DBMS\\_SQL:%:%:%:%:%:%:%",
              "%:%:DBMS\\_SQL:%:%:%:%:%:%:%",
              "%:%:%:%:%:DBMS\\_SQL:%:%:%:%",
              "%:%:%:%:%:DBMS\\_SQL:%:%:%:%"
            ],
  "OBJECTS_INCLUDE$" : 0,
  "OBJECTS_CMP_TAB$" :
            [
              "~",
              "~",
              "~",
              "~",
              "~",
              "~",
              "~",
              "~"
            ],
  "MATCH_PARTIAL_EQ_COMPLETE$" : 1,
  "MATCH_COUNT$" : 0,
  "MATCH_COUNT_OK$" : 0
}');

    end case;
    -- ut.expect(repr(l_schema_object_filter), 'test repr ' || i_try).to_equal(l_expected.to_clob());
    ut.expect(serialize(l_schema_object_filter), 'test serialize ' || i_try).to_equal(l_expected);
  end loop;  
end;

procedure ut_matches_schema_object
is
begin
  raise program_error;
end;

$end -- $if oracle_tools.cfg_pkg.c_testing $then

end pkg_schema_object_filter;
/

