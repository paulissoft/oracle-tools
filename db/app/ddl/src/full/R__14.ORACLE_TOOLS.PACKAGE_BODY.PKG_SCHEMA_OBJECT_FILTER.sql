CREATE OR REPLACE PACKAGE BODY "ORACLE_TOOLS"."PKG_SCHEMA_OBJECT_FILTER" IS

-- see static function T_SCHEMA_OBJECT.ID
c_nr_parts constant simple_integer := 10;

"OBJECT TYPE" constant simple_integer := 2;
"OBJECT NAME" constant simple_integer := 3;
"BASE OBJECT TYPE" constant simple_integer := 5;
"BASE OBJECT NAME" constant simple_integer := 6;

-- steps in get_schema_objects
"queue tables" constant varchar2(30 char) := 'queue tables';
"materialized views" constant varchar2(30 char) := 'materialized views';
"tables" constant varchar2(30 char) := 'tables';
"base objects" constant varchar2(30 char) := 'base objects';
"dependent objects" constant varchar2(30 char) := 'dependent objects';
"public synonyms and comments" constant varchar2(30 char) := 'public synonyms and comments';
"constraints" constant varchar2(30 char) := 'constraints';
"private synonyms and triggers" constant varchar2(30 char) := 'private synonyms and triggers';
"indexes" constant varchar2(30 char) := 'indexes';
"all objects" constant varchar2(30 char) := 'all objects';

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

procedure cleanup_object(p_object in out nocopy varchar2)
is
begin
  -- remove TAB, CR and LF and then trim spaces
  p_object := trim(replace(replace(replace(p_object, chr(9)), chr(13)), chr(10)));
end cleanup_object;  

-- the two work horses
function matches_schema_object_partial
( p_schema_object_filter in t_schema_object_filter
, p_switch in boolean
, p_metadata_object_type in varchar2
, p_object_name in varchar2
, p_metadata_base_object_type in varchar2
, p_base_object_name in varchar2
)
return integer
deterministic
is
  l_result integer := 0;
  l_schema_object_id oracle_tools.pkg_ddl_util.t_object;
  l_idx simple_integer := 0;
  l_count constant pls_integer := (cardinality(p_schema_object_filter.objects_tab$) / 3); -- number of complete items
begin
$if oracle_tools.pkg_schema_object_filter.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'MATCHES_SCHEMA_OBJECT_PARTIAL');
  dbug.print
  ( dbug."input"
  , 'switch: %s; object: "%s"; base object: "%s"'
  , dbug.cast_to_varchar2(p_switch)
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

/*
|   >ORACLE_TOOLS.PKG_SCHEMA_OBJECT_FILTER.MATCHES_SCHEMA_OBJECT
|   |   input: p_schema_object_id: :PACKAGE_SPEC:PKG_DDL_ERROR:::::::; p_match_partial: TRUE; object: "PACKAGE_SPEC:PKG_DDL_ERROR"; base object: ":"
|   |   >ORACLE_TOOLS.PKG_DDL_UTIL.IS_EXCLUDE_NAME_EXPR
|   |   |   input: p_object_type: PACKAGE_SPEC; p_object_name: PKG_DDL_ERROR
|   |   |   output: return: 0
|   |   <ORACLE_TOOLS.PKG_DDL_UTIL.IS_EXCLUDE_NAME_EXPR
|   |   info: case 3
|   |   info: [2] :PACKAGE_SPEC:PKG_DDL_ERROR::::::: "~" %:OBJECT\_GRANT:%:%:%:PKG\_DDL\_ERROR:%:%:%:%: 0
|   |   output: return: 0
|   <ORACLE_TOOLS.PKG_SCHEMA_OBJECT_FILTER.MATCHES_SCHEMA_OBJECT
|   >ORACLE_TOOLS.PKG_SCHEMA_OBJECT_FILTER.MATCHES_SCHEMA_OBJECT
|   |   input: p_schema_object_id: :::::PKG_DDL_ERROR::::; p_match_partial: TRUE; object: ":"; base object: ":PKG_DDL_ERROR"
|   |   info: case 3
|   |   info: [2] :::::PKG_DDL_ERROR:::: "~" %:OBJECT\_GRANT:%:%:%:PKG\_DDL\_ERROR:%:%:%:%: 0
|   |   output: return: 0
|   <ORACLE_TOOLS.PKG_SCHEMA_OBJECT_FILTER.MATCHES_SCHEMA_OBJECT
*/

      <<search_loop>>
      for i_complete_idx in 1 .. l_count
      loop
        <<what_loop>>
        for i_what_idx in case when p_switch then /* GJP 2 */ 2 else 1 end .. 2 -- ignore object on SWITCH
        loop
          l_idx := l_count + 2 * (i_complete_idx-1) + i_what_idx;
          
          l_schema_object_id := 
            case i_what_idx
              when 1 then p_metadata_object_type || ':' || p_object_name
              when 2 then p_metadata_base_object_type || ':' || p_base_object_name
            end;

          -- GJP 2022-12-23 We should be able to skip this item when both parts of schema object id are empty
          /*
          if l_schema_object_id = ':'
          then
$if oracle_tools.pkg_schema_object_filter.c_debugging $then
            dbug.print(dbug."info", '[%s] skipping schema object id "%s"', l_idx, l_schema_object_id);
$end
            continue;
          end if;
          */

          l_result := case
                        when l_schema_object_id like p_schema_object_filter.objects_tab$(l_idx) escape '\'
                        then i_complete_idx -- the index where we found a match
                        else 0
                      end;

$if oracle_tools.pkg_schema_object_filter.c_debugging $then
          dbug.print
          ( dbug."info"
          , '[%s] "%s" "~" "%s": %s'
          , l_idx
          , l_schema_object_id
          , p_schema_object_filter.objects_tab$(l_idx)
          , l_result
          );
$end

          exit what_loop when l_result = 0; -- if any of the named and other object is not found the result for this index is 0 (false)

          -- GJP 2022-12-23 Dependent objects can quit the loop when the result was okay
          /*
          if i_what_idx = 1 and
             p_metadata_object_type member of oracle_tools.pkg_ddl_util.get_md_object_type_tab('DEPENDENT')
          then
$if oracle_tools.pkg_schema_object_filter.c_debugging $then
            dbug.print(dbug."info", '[%s] matching dependent schema object id "%s" need not test its base fields', l_idx, l_schema_object_id);
$end         
            exit what_loop;
          end if;
          */
        end loop what_loop;
        
        exit search_loop when l_result != 0;
      end loop search_loop;

$if oracle_tools.pkg_schema_object_filter.c_debugging $then
      dbug.print(dbug."info", 'object found at index (0 = not found): %s', l_result);
$end

      l_result := sign(l_result); -- we only return 0 or 1
      
      if p_schema_object_filter.objects_include$ = 0 -- schema object id must NOT be part of objects_tab$ (list of exclusions)
      then
        -- a) l_result = 1 means there was a match which means that schema object id is part of the exclusions so inverse l_result
        -- b) l_result = 0 means there was no match at all which means that schema object id is NOT part of the exclusions so inverse l_result
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
end matches_schema_object_partial;

function matches_schema_object_complete
( p_schema_object_filter in t_schema_object_filter
, p_schema_object_id in varchar2
)
return integer
deterministic
is
  l_result integer := 0;
  l_count constant pls_integer := cardinality(p_schema_object_filter.objects_tab$) / 3; -- number of complete items
begin
$if oracle_tools.pkg_schema_object_filter.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'MATCHES_SCHEMA_OBJECT_COMPLETE');
  dbug.print(dbug."input", 'p_schema_object_id: %s', p_schema_object_id);
$end    

  case
    when p_schema_object_filter.objects_include$ is not null
    then
$if oracle_tools.pkg_schema_object_filter.c_debugging $then
       dbug.print(dbug."info", 'case 1');
$end

      for i_idx in 1..l_count
      loop
        l_result := 
          case
            when ( p_schema_object_filter.objects_cmp_tab$(i_idx) = '=' and p_schema_object_id = p_schema_object_filter.objects_tab$(i_idx) ) or
                 ( p_schema_object_filter.objects_cmp_tab$(i_idx) = '~' and p_schema_object_id like p_schema_object_filter.objects_tab$(i_idx) escape '\' )
            then i_idx -- the index where we found a match
            else 0
          end;

$if oracle_tools.pkg_schema_object_filter.c_debugging $then
        dbug.print
        ( dbug."info"
        , '[%s] "%s" "%s" "%s": %s'
        , i_idx
        , p_schema_object_id
        , p_schema_object_filter.objects_cmp_tab$(i_idx)
        , p_schema_object_filter.objects_tab$(i_idx)
        , l_result
        );
$end
        exit when l_result != 0;
      end loop;

      l_result := sign(l_result); -- we only return 0 or 1

      if p_schema_object_filter.objects_include$ = 0 -- p_schema_object_id must NOT be part of objects_tab$ (list of exclusions)
      then
        -- a) l_result = 1 means there was a match which means that p_schema_object_id is part of the exclusions so inverse l_result
        -- b) l_result = 0 means there was no match at all which means that p_schema_object_id is NOT part of the exclusions so inverse l_result
        l_result := 1 - l_result;
      end if;

    else
$if oracle_tools.pkg_schema_object_filter.c_debugging $then
      dbug.print(dbug."info", 'case 2');
$end
      l_result := 1; -- nothing to compare is OK
  end case;

$if oracle_tools.pkg_schema_object_filter.c_debugging $then
  dbug.print(dbug."output", 'return: %s', l_result);
  dbug.leave;
$end

  return l_result;
end matches_schema_object_complete;

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
      for i_idx in 1 .. p_str_tab.count -- show all items
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

$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then

procedure check_duplicates(p_schema_object_tab in oracle_tools.t_schema_object_tab, p_step in varchar2)
is
  l_object_tab t_object_natural_tab;
begin
  dbug.print(dbug."info", 'checking duplicates after retrieving ' || p_step);
  if p_schema_object_tab.count > 0
  then
    for i_idx in p_schema_object_tab.first .. p_schema_object_tab.last
    loop
      p_schema_object_tab(i_idx).print();
      if l_object_tab.exists(p_schema_object_tab(i_idx).signature())
      then
        raise_application_error(oracle_tools.pkg_ddl_error.c_duplicate_item, 'The signature of the object is a duplicate: ' || p_schema_object_tab(i_idx).signature());
      else
        l_object_tab(p_schema_object_tab(i_idx).signature()) := 0;
      end if;
    end loop;
  end if;
end check_duplicates;

$end            

procedure process_schema_object
( p_step in varchar2
, p_object_schema in varchar2
, p_object_type in varchar2
, p_object_name in varchar2 default null
, p_base_object_schema in varchar2 default null
, p_base_object_type in varchar2 default null
, p_base_object_name in varchar2 default null
, p_column_name in varchar2 default null
, p_grantee in varchar2 default null
, p_privilege in varchar2 default null
, p_grantable in varchar2 default null
, p_tablespace_name in varchar2 default null
, p_schema_object_filter in out nocopy oracle_tools.t_schema_object_filter
, p_schema_object_tab in out nocopy oracle_tools.t_schema_object_tab
)
is
  l_schema_object oracle_tools.t_schema_object := null;
begin

  case p_step
    when "queue tables"
    then
$if oracle_tools.pkg_ddl_util.c_get_queue_ddl $then
      oracle_tools.t_named_object.create_named_object
      ( p_object_type => p_object_type
      , p_object_schema => p_object_schema
      , p_object_name => p_object_name
      , p_named_object => l_schema_object
      );
$else
      /* ORA-00904: "KU$"."SCHEMA_OBJ"."TYPE": invalid identifier */
      null; 
$end

    when "materialized views"
    then
      l_schema_object := oracle_tools.t_materialized_view_object(p_object_schema, p_object_name);

    when "tables"
    then
      l_schema_object := oracle_tools.t_table_object(p_object_schema, p_object_name, p_tablespace_name);

    when "base objects"
    then
    oracle_tools.t_named_object.create_named_object
      ( p_object_type => r.object_type
      , p_object_schema => r.owner
      , p_object_name => r.object_name
      , p_named_object => l_named_object_tab(l_named_object_tab.last)
      );
  end case;

  if l_schema_object is not null and p_schema_object_filter.matches_schema_object(l_schema_object) = 0
  then      
    l_schema_object := null;
  end if;

  if l_schema_object is not null
  then
    p_schema_object_tab.extend(1);
    p_schema_object_tab(p_schema_object_tab.last) := l_schema_object;
  end if;
end process_schema_object;

-- GLOBAL

procedure construct
( p_schema in varchar2
, p_object_type in varchar2
, p_object_names in varchar2
, p_object_names_include in integer
, p_grantor_is_schema in integer
, p_exclude_objects in clob
, p_include_objects in clob
, p_schema_object_filter in out nocopy t_schema_object_filter
)
is
  l_object_tab dbms_sql.varchar2a;
  l_object_name_tab dbms_sql.varchar2a;
  l_object varchar2(4000 char);
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
  ( p_object_names in varchar2
  , p_object_names_include in oracle_tools.pkg_ddl_util.t_numeric_boolean
  , p_description in varchar2
  )
  is
  begin
    if (p_object_names is not null and p_object_names_include is null)
    then
      raise_application_error
      ( oracle_tools.pkg_ddl_error.c_objects_wrong
      , 'The ' ||
        p_description ||
        ' include flag (' ||        
        p_object_names_include ||
        ') is empty and the ' ||
        p_description ||
        ' list is NOT empty:' ||
        chr(10) ||
        '"' ||
        p_object_names ||
        '"'
      );
    elsif (p_object_names is null and p_object_names_include is not null)
    then
      raise_application_error
      ( oracle_tools.pkg_ddl_error.c_objects_wrong
      , 'The ' ||
        p_description ||
        ' include flag (' ||        
        p_object_names_include ||
        ') is NOT empty and the ' ||
        p_description ||
        ' list is empty:' ||
        chr(10) ||
        '"' ||
        p_object_names ||
        '"'
      );
    end if;
  end check_objects;

  procedure add_complete_items
  ( p_object_tab in dbms_sql.varchar2a
  )
  is
    procedure add_complete_item(p_object in out nocopy varchar2)
    is
      l_wildcard constant simple_integer := sign(instr(p_object, '*')) + sign(instr(p_object, '?')) * 2;
    begin
$if oracle_tools.pkg_schema_object_filter.c_debugging $then
      dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.CONSTRUCT.ADD_COMPLETE_ITEMS.ADD_COMPLETE_ITEM');
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

      -- no duplicates allowed
      if not(p_object member of p_schema_object_filter.objects_tab$)
      then
        p_schema_object_filter.objects_tab$.extend(1);
        p_schema_object_filter.objects_tab$(p_schema_object_filter.objects_tab$.last) := p_object;
        p_schema_object_filter.objects_cmp_tab$.extend(1);
        p_schema_object_filter.objects_cmp_tab$(p_schema_object_filter.objects_cmp_tab$.last) := case l_wildcard when 0 then '=' else '~' end;
      end if;
      
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
    end add_complete_item;
  begin
    if p_object_tab.count > 0
    then
      for i_object_idx in p_object_tab.first .. p_object_tab.last
      loop
        l_object := p_object_tab(i_object_idx);

        cleanup_object(l_object);

        if l_object is not null
        then
          -- add a line for a COMPLETE match: with the same info as in l_object but with O/S wildcards replaced and SQL wildcards escaped (odd index)
          add_complete_item(l_object);
        end if;
      end loop;
    end if;
  end add_complete_items;

  procedure add_partial_items
  is
    l_count constant pls_integer := cardinality(p_schema_object_filter.objects_tab$); -- only complete items for now
  begin
    -- now we need to add lines for partial matches, one for matching the named object and one for the other
    if l_count > 0
    then
      for i_object_idx in 1 .. l_count
      loop
        l_object := p_schema_object_filter.objects_tab$(i_object_idx);

        if p_schema_object_filter.objects_cmp_tab$(i_object_idx) != '~'
        then
          -- no escaping done yet on the whole line so escape SQL wildcards now because partial matches work with like escape
          l_object := replace(l_object, '_', '\_');
          l_object := replace(l_object, '%', '\%');
        end if;
          
        -- save this line as an array and check at the same time the number of colons
        oracle_tools.pkg_str_util.split(p_str => l_object, p_delimiter => ':', p_str_tab => l_part_tab);

        if l_part_tab.count != c_nr_parts
        then
          oracle_tools.pkg_ddl_error.raise_error
          ( p_error_number => oracle_tools.pkg_ddl_error.c_objects_wrong
          , p_error_message => 'number of parts (' || l_part_tab.count || ') must be ' || c_nr_parts
          , p_context_info => l_object
          , p_context_label => 'schema object id'
          );            
        end if;

        for i_idx in 1..2
        loop
          p_schema_object_filter.objects_tab$.extend(1);
          p_schema_object_filter.objects_tab$(p_schema_object_filter.objects_tab$.last) :=
            case i_idx
              when 1 then l_part_tab("OBJECT TYPE") || ':' || l_part_tab("OBJECT NAME")
              when 2 then l_part_tab("BASE OBJECT TYPE") || ':' || l_part_tab("BASE OBJECT NAME")
            end;
          p_schema_object_filter.objects_cmp_tab$.extend(1);
          p_schema_object_filter.objects_cmp_tab$(p_schema_object_filter.objects_cmp_tab$.last) := null;
        end loop;
      end loop;
    end if;
  end add_partial_items;  
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
  , 'p_exclude_objects length: %s; p_include_objects length: %s'
  , dbms_lob.getlength(p_exclude_objects)
  , dbms_lob.getlength(p_include_objects)
  );
$end

  -- old functionality
  oracle_tools.pkg_ddl_util.check_schema(p_schema => p_schema, p_network_link => null);
  check_object_type(p_object_type => p_object_type);
  oracle_tools.pkg_ddl_util.check_numeric_boolean(p_numeric_boolean => p_object_names_include, p_description => 'object names include');
  check_objects(p_object_names => p_object_names, p_object_names_include => p_object_names_include, p_description => 'object names');
  oracle_tools.pkg_ddl_util.check_numeric_boolean(p_numeric_boolean => p_grantor_is_schema, p_description => 'grantor is schema');

  p_schema_object_filter.schema$ := p_schema;
  p_schema_object_filter.grantor_is_schema$ := p_grantor_is_schema;
  p_schema_object_filter.objects_tab$ := oracle_tools.t_text_tab();
  p_schema_object_filter.objects_cmp_tab$ := oracle_tools.t_text_tab();
  p_schema_object_filter.match_count$ := 0;
  p_schema_object_filter.match_count_ok$ := 0;

  if p_exclude_objects is not null
  then
    -- new functionality
    -- split by LF
    oracle_tools.pkg_str_util.split(p_str => p_include_objects, p_delimiter => chr(10), p_str_tab => l_object_tab);

    p_schema_object_filter.match_partial_eq_complete$ := 0; -- always re-evaluate named objects in combine_named_other_objects()
    add_complete_items(l_object_tab);
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
            -- GJP 2022-12-23
            --/*
            l_part_tab("BASE OBJECT TYPE") := null; -- this is supposed to be named object hence base fields empty
            l_part_tab("BASE OBJECT NAME") := null; -- idem
            --*/
            l_object_tab(l_object_tab.count + 1) := oracle_tools.pkg_str_util.join(p_str_tab => l_part_tab, p_delimiter => ':');

            -- GJP 2022-12-23 This does not seem to be necessary.
            --/*
            -- object 2
            l_part_tab := c_default_wildcard_part_tab;
            l_part_tab("BASE OBJECT TYPE") := nvl(p_object_type, '*');
            l_part_tab("BASE OBJECT NAME") := l_object_name_tab(i_object_name_idx);
            l_object_tab(l_object_tab.count + 1) := oracle_tools.pkg_str_util.join(p_str_tab => l_part_tab, p_delimiter => ':');
            --*/
          end if;
        end if;
      end loop;

      add_complete_items(l_object_tab);
    end if;
  end if;

  add_partial_items;

  -- make the tables null if they are empty
  if p_schema_object_filter.objects_tab$.count = 0
  then
    p_schema_object_filter.objects_tab$ := null;
    p_schema_object_filter.objects_cmp_tab$ := null;
    p_schema_object_filter.objects_include$ := null;
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
  l_line_tab dbms_sql.varchar2a;
begin
-- !!! DO NOT use oracle_tools.pkg_schema_object_filter.c_debugging HERE !!!
$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'PRINT');

  oracle_tools.pkg_str_util.split
  ( p_str => repr(p_schema_object_filter)
  , p_delimiter => chr(10)
  , p_str_tab => l_line_tab
  );

  if l_line_tab.count > 0
  then
    for i_idx in l_line_tab.first .. l_line_tab.last
    loop
      dbug.print(dbug."info", '[%s] %s', i_idx, l_line_tab(i_idx));
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
, p_metadata_base_object_type in varchar2
, p_base_object_name in varchar2
)
return integer
deterministic
is
  l_result pls_integer;
begin
  -- Note SWITCH.
  -- A) When both the base parameters are empty (named search) we need to both lookup
  --    using the OBJECT info in p_schema_object_filter.objects_tab$ and BASE OBJECT info,
  --    hence switch. If the result for the switch is then 1
  --    we need to redo a named object match at the end in combine_named_other_objects().
  -- B) When at least one of the base parameters is not empty: just one partial match.
  
  for i_try in 1 .. case when p_metadata_base_object_type is null and p_base_object_name is null then 2 else 1 end
  loop
    l_result := matches_schema_object_partial
                ( p_schema_object_filter => p_schema_object_filter
                , p_switch => (i_try = 2)
                , p_metadata_object_type => case i_try when 1 then p_metadata_object_type else p_metadata_base_object_type end
                , p_object_name => case i_try when 1 then p_object_name else p_base_object_name end
                , p_metadata_base_object_type => case i_try when 1 then p_metadata_base_object_type else p_metadata_object_type end
                , p_base_object_name => case i_try when 1 then p_base_object_name else p_object_name end
                );

    p_schema_object_filter.match_count$ := p_schema_object_filter.match_count$ + 1;
    p_schema_object_filter.match_count_ok$ := p_schema_object_filter.match_count_ok$ + l_result;
    
    if l_result = 1 -- stop when found
    then
      -- Since we used onbject (p_metadata_object_type, p_object_name) to match against the base object in the filter entries
      -- we can not be sure that all named objects match the standard criteria so we have to do that again in combine_named_other_objects().
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

  return
    case
      when p_schema_object_id = oracle_tools.t_schema_object.id
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
      then
        -- complete match
        matches_schema_object_complete
        ( p_schema_object_filter => p_schema_object_filter
        , p_schema_object_id => p_schema_object_id
        )
      else
        -- partial match
        matches_schema_object_partial
        ( p_schema_object_filter => p_schema_object_filter
        , p_switch => false
        , p_metadata_object_type => l_part_tab("OBJECT TYPE")
        , p_object_name => l_part_tab("OBJECT NAME")
        , p_metadata_base_object_type => l_part_tab("BASE OBJECT TYPE")
        , p_base_object_name => l_part_tab("BASE OBJECT NAME")
        )
    end;
end matches_schema_object;

function matches_schema_object
( p_schema_object_filter in t_schema_object_filter
, p_schema_object in oracle_tools.t_schema_object
)
return integer
deterministic
is
begin
  return matches_schema_object_complete
         ( p_schema_object_filter => p_schema_object_filter
         , p_schema_object_id => p_schema_object.id()
         );
end matches_schema_object;

procedure combine_named_other_objects
( p_schema_object_filter in t_schema_object_filter
, p_named_object_tab in oracle_tools.t_schema_object_tab
, p_other_object_tab in oracle_tools.t_schema_object_tab
, p_schema_object_tab out nocopy oracle_tools.t_schema_object_tab
)
is
begin
$if oracle_tools.pkg_schema_object_filter.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.COMBINE_NAMED_OTHER_OBJECTS');
  dbug.print
  ( dbug."input"
  , 'cardinality(p_named_object_tab): %s; cardinality(p_other_object_tab): %s'
  , cardinality(p_named_object_tab)
  , cardinality(p_other_object_tab)
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
    p_schema_object_tab := p_named_object_tab multiset union /*distinct*/ p_other_object_tab;
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

    p_schema_object_tab := p_schema_object_tab multiset union /*distinct*/ p_other_object_tab;
  end if;

$if oracle_tools.pkg_schema_object_filter.c_debugging $then
  dbug.print
  ( dbug."output"
  , 'cardinality(p_schema_object_tab): %s'
  , cardinality(p_schema_object_tab)
  );
  dbug.leave;
$end
end combine_named_other_objects;

procedure get_schema_objects
( p_schema_object_filter in out nocopy oracle_tools.t_schema_object_filter
, p_schema_object_tab out nocopy oracle_tools.t_schema_object_tab
)
is
  l_schema constant t_schema_nn := p_schema_object_filter.schema();
  l_grantor_is_schema constant t_numeric_boolean := p_schema_object_filter.grantor_is_schema();
  
  type t_excluded_tables_tab is table of boolean index by all_tables.table_name%type;

  l_excluded_tables_tab t_excluded_tables_tab;

  l_schema_object_tab oracle_tools.t_schema_object_tab := oracle_tools.t_schema_object_tab();
  l_step varchar2(30 char);

  l_refcursor sys_refcursor;

  -- steps:
  -- 1. queue tables
  -- 2. materialized views
  -- 3. tables
  -- 4. base objects
  -- 5. dependent objects
  -- 6. public synonyms and comments
  -- 7. constraints
  -- 8. private synonyms and triggers
  -- 9. indexes
  -- 10. all objects

  l_longops_rec t_longops_rec :=
    longops_init
    ( p_target_desc => 'procedure ' || 'GET_SCHEMA_OBJECTS'
    , p_totalwork => 10
    , p_op_name => 'what'
    , p_units => 'steps'
    );

  procedure cleanup
  is
  begin
    if l_refcursor%isopen
    then
      close l_refcursor;
    end if;
    longops_done(l_longops_rec);
  end cleanup;
begin
$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
  dbug.enter(g_package_prefix || 'GET_SCHEMA_OBJECTS');
  p_schema_object_filter.print();
$end

  l_step := "queue tables";

  -- queue table
  for r in
  ( select  q.owner
    ,       q.queue_table
    from    all_queue_tables q
    where   q.owner = l_schema
  )
  loop
    l_excluded_tables_tab(r.queue_table) := true;
    process_schema_object
    ( p_step => l_step
    , p_object_type => 'AQ_QUEUE_TABLE'
    , p_object_schema => r.owner
    , p_object_name => r.queue_table
    , p_schema_object_filter => l_schema_object_filter
    , p_schema_object_tab => l_schema_object_tab
    );
  end loop;

  longops_show(l_longops_rec);

$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
  check_duplicates(l_named_object_tab, 'queue tables');
$end

  l_step := "materialized views";

  -- no MATERIALIZED VIEW tables unless PREBUILT
  for r in
  ( select  m.owner
    ,       m.mview_name
    ,       m.build_mode
    from    all_mviews m
    where   m.owner = l_schema
  )
  loop
    if r.build_mode != 'PREBUILT'
    then
      l_excluded_tables_tab(r.mview_name) := true;
    end if;
    -- this is a special case since we need to exclude first
    process_schema_object
    ( p_step => l_step
    , p_object_type => 'MATERIALIZED_VIEW'
    , p_object_schema => r.owner
    , p_object_name => r.mview_name
    , p_schema_object_filter => l_schema_object_filter
    , p_schema_object_tab => l_schema_object_tab
    );
  end loop;

  longops_show(l_longops_rec);

$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
  check_duplicates(l_named_object_tab, 'materialized views');
$end

  l_step := "tables";

  for r in
  ( select  t.owner
    ,       t.table_name
    ,       t.tablespace_name
    ,       'TABLE' as object_type
    from    all_tables t
    where   t.owner = l_schema
    and     t.nested = 'NO' -- Exclude nested tables, their DDL is part of their parent table.
    and     ( t.iot_type is null or t.iot_type = 'IOT' ) -- Only the IOT table itself, not an overflow or mapping
            -- GPA 2017-06-28 #147916863 - As a release operator I do not want comments without table or column.
    and     substr(t.table_name, 1, 5) not in (/*'APEX$', */'MLOG$', 'RUPD$') 
    union -- not union all because since Oracle 12, temporary tables are also shown in all_tables
    -- temporary tables
    select  t.owner
    ,       t.object_name as table_name
    ,       null as tablespace_name
    ,       t.object_type
    from    all_objects t
    where   t.owner = l_schema
    and     t.object_type = 'TABLE'
    and     t.temporary = 'Y'
$if oracle_tools.pkg_ddl_util.c_exclude_system_objects $then
    and     t.generated = 'N' -- GPA 2016-12-19 #136334705
$end      
            -- GPA 2017-06-28 #147916863 - As a release operator I do not want comments without table or column.
    and     substr(t.object_name, 1, 5) not in (/*'APEX$', */'MLOG$', 'RUPD$') 
  )
  loop
    if r.object_type <> 'TABLE'
    then
      raise program_error;
    end if;

    if not(l_excluded_tables_tab.exists(r.table_name))
    then
      process_schema_object
      ( p_step => l_step
      , p_object_type => r.object_type
      , p_object_schema => r.owner
      , p_object_name => r.table_name
      , p_tablespace_name => r.tablespace_name
      , p_schema_object_filter => l_schema_object_filter
      , p_schema_object_tab => l_schema_object_tab
      );
    end if; 
  end loop;

  longops_show(l_longops_rec);

$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
  check_duplicates(l_named_object_tab, 'tables');
$end

  l_step := "base objects";

  for r in
  ( /*
    -- Just the base objects, i.e. no constraints, comments, grant nor public synonyms to base objects.
    */
    select  o.owner
    ,       o.object_type
    ,       o.object_name
    from    ( select  o.owner
                      -- use scalar subquery cache
              ,       (select oracle_tools.t_schema_object.dict2metadata_object_type(o.object_type) from dual) as object_type
              ,       o.object_name
              from    all_objects o
              where   o.owner = l_schema
              and     o.object_type not in ('QUEUE', 'MATERIALIZED VIEW', 'TABLE', 'TRIGGER', 'INDEX', 'SYNONYM')
$if oracle_tools.pkg_ddl_util.c_exclude_system_objects $then
              and     o.generated = 'N' -- GPA 2016-12-19 #136334705
$end                
                      -- OWNER         OBJECT_NAME                      SUBOBJECT_NAME
                      -- =====         ===========                      ==============
                      -- ORACLE_TOOLS  oracle_tools.t_table_column_ddl  $VSN_1
              and     o.subobject_name is null
                      -- GPA 2017-06-28 #147916863 - As a release operator I do not want comments without table or column.
              and     not( o.object_type = 'SEQUENCE' and substr(o.object_name, 1, 5) = 'ISEQ$' )
            ) o
    where   o.object_type member of g_schema_md_object_type_tab
            -- use scalar subquery cache
    and     (select oracle_tools.pkg_ddl_util.is_dependent_object_type(p_object_type => o.object_type) from dual) = 0
  )
  loop
    process_schema_object
    ( p_step => l_step
    , p_object_type => r.object_type
    , p_object_schema => r.owner
    , p_object_name => r.object_name
    , p_schema_object_filter => l_schema_object_filter
    , p_schema_object_tab => l_schema_object_tab
    );
  end loop;

  longops_show(l_longops_rec);

$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
  check_duplicates(l_named_object_tab, 'base objects');
  if l_named_object_tab.count > 0
  then
    for i_named_idx in l_named_object_tab.first .. l_named_object_tab.last
    loop
      dbug.print(dbug."info", 'l_named_object_tab(%s).id(): %s', i_named_idx, l_named_object_tab(i_named_idx).id());
    end loop;
  end if;
$end

  for r in
  ( -- before Oracle 12 there was no type column in all_tab_privs
    with prv as -- use this clause to speed up the query for <owner>
    ( -- several grantors may have executed the same grant statement
      select  p.table_schema
      ,       p.table_name
      ,       p.grantee
      ,       p.privilege
      ,       max(p.grantable) as grantable -- YES comes after NO
      from    all_tab_privs p
      where   p.table_schema = l_schema
      and     ( l_grantor_is_schema = 0 or p.grantor = l_schema )
      group by
              p.table_schema
      ,       p.table_name
      ,       p.grantee
      ,       p.privilege
    )
    -- grants for all our objects
    select  obj.obj as base_object
    ,       null as object_schema
    ,       p.grantee
    ,       p.privilege
    ,       p.grantable
    from    ( select  obj.object_type() as object_type
              ,       obj.object_schema() as object_schema
              ,       obj.object_name() as object_name
              ,       value(obj) as obj
              from    table(l_named_object_tab) obj
            ) obj
            inner join prv p
            on p.table_schema = obj.object_schema and p.table_name = obj.object_name
    where   obj.object_type not like '%BODY'
    and     obj.object_type not in ('MATERIALIZED_VIEW') -- grants are on underlying tables
  )
  loop
    if p_schema_object_filter.matches_schema_object
       ( p_metadata_object_type => 'OBJECT_GRANT'
       , p_object_name => null
       , p_metadata_base_object_type => r.base_object.object_type
       , p_base_object_name => r.base_object.object_name
       ) = 1
    then
      l_schema_object_tab.extend(1);
      l_schema_object_tab(l_schema_object_tab.last) :=
        oracle_tools.t_object_grant_object
        ( p_base_object => treat(r.base_object as oracle_tools.t_named_object)
        , p_object_schema => r.object_schema
        , p_grantee => r.grantee
        , p_privilege => r.privilege
        , p_grantable => r.grantable
        );
    end if;
  end loop;

  longops_show(l_longops_rec);

$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
  check_duplicates(l_schema_object_tab, 'dependent objects');
$end

  for r in
  ( select  t.*
    from    ( -- public synonyms for all our objects
              select  value(obj)     as base_object
              ,       s.owner        as object_schema
              ,       'SYNONYM'      as object_type
              ,       s.synonym_name as object_name
              ,       null           as column_name
              from    table(l_named_object_tab) obj
                      inner join all_synonyms s
                      on s.table_owner = obj.object_schema() and s.table_name = obj.object_name()
              where   obj.object_type() not like '%BODY'
              and     obj.object_type() <> 'MATERIALIZED_VIEW'
              and     s.owner = 'PUBLIC'
              union all
              -- table/view comments
              select  value(obj)     as base_object
              ,       null           as object_schema
              ,       'COMMENT'      as object_type
              ,       null           as object_name
              ,       null           as column_name
              from    table(l_named_object_tab) obj
                      inner join all_tab_comments t
                      on t.owner = obj.object_schema() and t.table_type = obj.object_type() and t.table_name = obj.object_name()
              where   obj.object_type() in ('TABLE', 'VIEW')
              and     t.comments is not null
              union all
              -- materialized view comments
              select  value(obj)     as base_object
              ,       null           as object_schema
              ,       'COMMENT'      as object_type
              ,       null           as object_name
              ,       null           as column_name
              from    table(l_named_object_tab) obj
                      inner join all_mview_comments m
                      on m.owner = obj.object_schema() and m.mview_name = obj.object_name()
              where   obj.object_type() = 'MATERIALIZED_VIEW'
              and     m.comments is not null
              union all
              -- column comments
              select  value(obj)     as base_object
              ,       null           as object_schema
              ,       'COMMENT'      as object_type
              ,       null           as object_name
              ,       c.column_name  as column_name
              from    table(l_named_object_tab) obj
                      inner join all_col_comments c
                      on c.owner = obj.object_schema() and c.table_name = obj.object_name()
              where   obj.object_type() in ('TABLE', 'VIEW', 'MATERIALIZED_VIEW')
              and     c.comments is not null
            ) t
  )
  loop
    if p_schema_object_filter.matches_schema_object
       ( p_metadata_object_type => r.object_type
       , p_object_name => r.object_name
       , p_metadata_base_object_type => r.base_object.object_type()
       , p_base_object_name => r.base_object.object_name()
       ) = 1
    then
      l_schema_object_tab.extend(1);
      case r.object_type
        when 'SYNONYM'
        then
          l_schema_object_tab(l_schema_object_tab.last) :=
            oracle_tools.t_synonym_object
            ( p_base_object => treat(r.base_object as oracle_tools.t_named_object)
            , p_object_schema => r.object_schema
            , p_object_name => r.object_name
            );
        when 'COMMENT'
        then
          l_schema_object_tab(l_schema_object_tab.last) :=
            oracle_tools.t_comment_object
            ( p_base_object => treat(r.base_object as oracle_tools.t_named_object)
            , p_object_schema => r.object_schema
            , p_column_name => r.column_name
            );
      end case;
    end if;
  end loop;

  longops_show(l_longops_rec);

$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
  check_duplicates(l_schema_object_tab, 'public synonyms and comments');
$end

  for r in
  ( -- constraints for objects in the same schema
    select  t.*
    from    ( select  value(obj) as base_object
              ,       c.owner as object_schema
              ,       case when c.constraint_type = 'R' then 'REF_CONSTRAINT' else 'CONSTRAINT' end as object_type
              ,       c.constraint_name as object_name
              ,       c.constraint_type
              ,       c.search_condition
$if oracle_tools.pkg_ddl_util.c_exclude_not_null_constraints and oracle_tools.pkg_ddl_util.c_#138707615_1 $then
              ,       case c.constraint_type
                        when 'C'
                        then ( select  cc.column_name
                               from    all_cons_columns cc
                               where   cc.owner = c.owner
                               and     cc.table_name = c.table_name
                               and     cc.constraint_name = c.constraint_name
                               and     rownum = 1
                             )
                        else null
                      end as any_column_name
$end                          
              from    table(l_named_object_tab) obj
                      inner join all_constraints c /* this is where we are interested in */
                      on c.owner = obj.object_schema() and c.table_name = obj.object_name()
              where   obj.object_type() in ('TABLE', 'VIEW')
                      /* Type of constraint definition:
                         C (check constraint on a table)
                         P (primary key)
                         U (unique key)
                         R (referential integrity)
                         V (with check option, on a view)
                         O (with read only, on a view)
                      */
              and     c.constraint_type in ('C', 'P', 'U', 'R')
$if oracle_tools.pkg_ddl_util.c_exclude_system_constraints $then
              and     c.generated = 'USER NAME'
$end
$if oracle_tools.pkg_ddl_util.c_exclude_not_null_constraints and not(oracle_tools.pkg_ddl_util.c_#138707615_1) $then
                      -- exclude system generated not null constraints
              and     ( c.constraint_name not like 'SYS\_C%' escape '\' or
                        c.constraint_type <> 'C' or
                        -- column is the only column in the check constraint and must be nullable
                        ( 1, 'Y' ) in
                        ( select  count(cc.column_name)
                          ,       max(tc.nullable)
                          from    all_cons_columns cc
                                  inner join all_tab_columns tc
                                  on tc.owner = cc.owner and tc.table_name = cc.table_name and tc.column_name = cc.column_name
                          where   cc.owner = c.owner
                          and     cc.table_name = c.table_name
                          and     cc.constraint_name = c.constraint_name
                        )
                      )
$end
            ) t
  )
  loop
    if p_schema_object_filter.matches_schema_object
       ( p_metadata_object_type => r.object_type
       , p_object_name => r.object_name
       , p_metadata_base_object_type => r.base_object.object_type()
       , p_base_object_name => r.base_object.object_name()
       ) = 0
    then
      continue;
    end if;

$if oracle_tools.pkg_ddl_util.c_exclude_not_null_constraints and oracle_tools.pkg_ddl_util.c_#138707615_1 $then
    -- We do NOT want a NOT NULL constraint, named or not.
    -- Since search_condition is a LONG we must use PL/SQL to filter
    if r.search_condition is not null and
       r.any_column_name is not null and
       r.search_condition = '"' || r.any_column_name || '" IS NOT NULL'
    then
      -- This is a not null constraint.
      -- Since search_condition has only one column, any column name is THE column name.
$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
      dbug.print
      ( dbug."info"
      , 'ignoring not null constraint: owner: %s; table: %s; constraint: %s; search_condition: %s'
      , r.object_schema
      , r.base_object.object_name()
      , r.object_name
      , r.search_condition
      );
$end
      continue;
    end if;
$end -- $if oracle_tools.pkg_ddl_util.c_exclude_not_null_constraints and oracle_tools.pkg_ddl_util.c_#138707615_1 $then

    l_schema_object_tab.extend(1);
    case r.object_type
      when 'REF_CONSTRAINT'
      then
        l_schema_object_tab(l_schema_object_tab.last) :=
          oracle_tools.t_ref_constraint_object
          ( p_base_object => treat(r.base_object as oracle_tools.t_named_object)
          , p_object_schema => r.object_schema
          , p_object_name => r.object_name
          , p_constraint_type => r.constraint_type
          , p_column_names => null
          );

      when 'CONSTRAINT'
      then
        l_schema_object_tab(l_schema_object_tab.last) :=
          oracle_tools.t_constraint_object
          ( p_base_object => treat(r.base_object as oracle_tools.t_named_object)
          , p_object_schema => r.object_schema
          , p_object_name => r.object_name
          , p_constraint_type => r.constraint_type
          , p_search_condition => r.search_condition
          );
    end case;
  end loop;

  longops_show(l_longops_rec);

$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
  check_duplicates(l_schema_object_tab, 'constraints');
$end

  for r in
  ( select  t.*
    from    ( -- private synonyms for this schema which may point to another schema
              select  s.owner as object_schema
              ,       'SYNONYM' as object_type
              ,       s.synonym_name as object_name
              ,       obj.owner as base_object_schema
                      -- use scalar subquery cache
              ,       (select oracle_tools.t_schema_object.dict2metadata_object_type(obj.object_type) from dual) as base_object_type
              ,       obj.object_name as base_object_name
              ,       null as column_name
              from    all_synonyms s
                      inner join all_objects obj
                      on obj.owner = s.table_owner and obj.object_name = s.table_name
              where   obj.object_type not like '%BODY'
              and     obj.object_type <> 'MATERIALIZED VIEW'
              and     s.owner = l_schema
              -- no need to check on s.generated since we are interested in synonyms, not objects
              union all
              -- triggers for this schema which may point to another schema
              select  t.owner as object_schema
              ,       'TRIGGER' as object_type
              ,       t.trigger_name as object_name
/* GJP 20170106 see oracle_tools.t_schema_object.chk()
              -- when the trigger is based on an object in another schema, no base info
              ,       case when t.owner = t.table_owner then t.table_owner end as base_object_schema
              ,       case when t.owner = t.table_owner then t.base_object_type end as base_object_type
              ,       case when t.owner = t.table_owner then t.table_name end as base_object_name
*/
              ,       t.table_owner as base_object_schema
                      -- use scalar subquery cache
              ,       (select oracle_tools.t_schema_object.dict2metadata_object_type(t.base_object_type) from dual) as base_object_type
              ,       t.table_name as base_object_name
              ,       null as column_name
              from    all_triggers t
              where   t.owner = l_schema
              and     t.base_object_type in ('TABLE', 'VIEW')
            ) t
  )
  loop
    if p_schema_object_filter.matches_schema_object
       ( p_metadata_object_type => r.object_type
       , p_object_name => r.object_name
       , p_metadata_base_object_type => null -- GJP 2022-12-23 r.base_object_type
       , p_base_object_name => null -- GJP 2022-12-23 r.base_object_name
       ) = 1
    then
      l_schema_object_tab.extend(1);
      oracle_tools.t_schema_object.create_schema_object
      ( p_object_schema => r.object_schema
      , p_object_type => r.object_type
      , p_object_name => r.object_name
      , p_base_object_schema => r.base_object_schema
      , p_base_object_type => r.base_object_type
      , p_base_object_name => r.base_object_name
      , p_column_name => r.column_name
      , p_schema_object => l_schema_object_tab(l_schema_object_tab.last)
      );
    end if;
  end loop;

  longops_show(l_longops_rec);

$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
  check_duplicates(l_schema_object_tab, 'private synonyms and triggers');
$end

  for r in
  ( -- indexes
    select  i.owner as object_schema
    ,       i.index_name as object_name
/* GJP 20170106 see oracle_tools.t_schema_object.chk()
    -- when the index is based on an object in another schema, no base info
    ,       case when i.owner = i.table_owner then i.table_owner end as base_object_schema
    ,       case when i.owner = i.table_owner then i.table_type end as base_object_type
    ,       case when i.owner = i.table_owner then i.table_name end as base_object_name
*/
    ,       i.table_owner as base_object_schema
            -- use scalar subquery cache
    ,       (select oracle_tools.t_schema_object.dict2metadata_object_type(i.table_type) from dual) as base_object_type
    ,       i.table_name as base_object_name
    ,       i.tablespace_name
    from    all_indexes i
    where   i.owner = l_schema
            -- GPA 2017-06-28 #147916863 - As a release operator I do not want comments without table or column.
    and     not(/*substr(i.index_name, 1, 5) = 'APEX$' or */substr(i.index_name, 1, 7) = 'I_MLOG$')
            -- GJP 2022-08-22
            -- When constraint_index = 'YES' the index is created as part of the constraint DDL,
            -- so it will not be listed as a separate DDL statement.
    and     not(i.constraint_index = 'YES')
$if oracle_tools.pkg_ddl_util.c_exclude_system_indexes $then
    and     i.generated = 'N'
$end      
  )
  loop
    if p_schema_object_filter.matches_schema_object
       ( p_metadata_object_type => 'INDEX'
       , p_object_name => r.object_name
       , p_metadata_base_object_type => null -- GJP 2022-12-23 r.base_object_type
       , p_base_object_name => null -- GJP 2022-12-23 r.base_object_name
       ) = 1
    then
      l_schema_object_tab.extend(1);
      l_schema_object_tab(l_schema_object_tab.last) :=
        oracle_tools.t_index_object
        ( p_base_object =>
            oracle_tools.t_named_object.create_named_object
            ( p_object_schema => r.base_object_schema
            , p_object_type => r.base_object_type
            , p_object_name => r.base_object_name
            )
        , p_object_schema => r.object_schema
        , p_object_name => r.object_name
        , p_tablespace_name => r.tablespace_name
        );
    end if;
  end loop;

  longops_show(l_longops_rec);

$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
  check_duplicates(l_schema_object_tab, 'indexes');
$end

  p_schema_object_filter.combine_named_other_objects
  ( p_named_object_tab => l_named_object_tab
  , p_other_object_tab => l_schema_object_tab
  , p_schema_object_tab => p_schema_object_tab
  );

  longops_show(l_longops_rec);

$if oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
  check_duplicates(p_schema_object_tab, 'all objects');
$end

  cleanup;

$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
  dbug.print(dbug."output", 'cardinality(p_schema_object_tab): %s', cardinality(p_schema_object_tab));
  dbug.leave;
$end

exception
  when no_data_needed
  then
    cleanup;
$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
    dbug.leave_on_error;
$end
  
  when others
  then
    cleanup;
$if oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
    dbug.leave_on_error;
$end
    raise;
end get_schema_objects;

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
        , p_exclude_objects => null
        , p_include_objects => null
        );
        l_expected := json_element_t.parse('{
  "SCHEMA$" : "SYS",
  "GRANTOR_IS_SCHEMA$" : 1,  
  "OBJECTS_TAB$" :
            [
              "%:PACKAGE\\_SPEC:DBMS\\_METADATA:%:::%:%:%:%",
              "%:PACKAGE\\_SPEC:DBMS\\_VERSION:%:::%:%:%:%",
              "PACKAGE\\_SPEC:DBMS\\_METADATA",
              ":",
              "PACKAGE\\_SPEC:DBMS\\_VERSION",
              ":"
            ],
  "OBJECTS_INCLUDE$" : 1,
  "OBJECTS_CMP_TAB$" :
            [
              "~",
              "~",
              null,
              null,
              null,
              null
            ],
  "MATCH_PARTIAL_EQ_COMPLETE$" : 1,
  "MATCH_COUNT$" : 0,
  "MATCH_COUNT_OK$" : 0
}');

      when 3
      then
        -- duplicate objects are ignored
        l_schema_object_filter := oracle_tools.t_schema_object_filter
        ( p_schema => 'SYS'
        , p_object_type => 'OBJECT_GRANT'
        , p_object_names => '
DBMS_OUTPUT,
DBMS_OUTPUT,
DBMS_SQL,
DBMS_SQL
'
        , p_object_names_include => 1
        , p_grantor_is_schema => 1
        , p_exclude_objects => null
        , p_include_objects => null
        );
        l_expected := json_element_t.parse('{
  "SCHEMA$" : "SYS",
  "GRANTOR_IS_SCHEMA$" : 1,
  "OBJECTS_TAB$" :
            [
              "%:OBJECT\\_GRANT:%:%:%:DBMS\\_OUTPUT:%:%:%:%",
              "%:OBJECT\\_GRANT:%:%:%:DBMS\\_SQL:%:%:%:%",
              "OBJECT\\_GRANT:%",
              "%:DBMS\\_OUTPUT",
              "OBJECT\\_GRANT:%",
              "%:DBMS\\_SQL"
            ],
  "OBJECTS_INCLUDE$" : 1,
  "OBJECTS_CMP_TAB$" :
            [
              "~",
              "~",
              null,
              null,
              null,
              null
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
        , p_exclude_objects => null
        , p_include_objects => null
        );
        l_expected := json_element_t.parse('{
  "SCHEMA$" : "SYS",
  "GRANTOR_IS_SCHEMA$" : 1,
  "OBJECTS_TAB$" :
            [
              "%:%:DBMS\\_OUTPUT:%:::%:%:%:%",
              "%:%:DBMS\\_SQL:%:::%:%:%:%",
              "%:DBMS\\_OUTPUT",
              ":",
              "%:DBMS\\_SQL",
              ":"
            ],
  "OBJECTS_INCLUDE$" : 0,
  "OBJECTS_CMP_TAB$" :
            [
              "~",
              "~",
              null,
              null,
              null,
              null
            ],
  "MATCH_PARTIAL_EQ_COMPLETE$" : 1,
  "MATCH_COUNT$" : 0,
  "MATCH_COUNT_OK$" : 0
}');

    end case;
    -- GJP 2022-12-23 Only uncomment the next line when you have JSON differences
    -- ut.expect(repr(l_schema_object_filter), 'test repr ' || i_try).to_equal(l_expected.to_clob()); 
    ut.expect(serialize(l_schema_object_filter), 'test serialize ' || i_try).to_equal(l_expected);
  end loop;  
end;

procedure ut_matches_schema_object
is
  l_id oracle_tools.pkg_ddl_util.t_object;
  l_cnt pls_integer;
  l_max_objects constant pls_integer := 1;
  l_object_names constant varchar2(4000 char) := 'PKG_SCHEMA_OBJECT_FILTER,PKG_DDL_UTIL';
  l_objects constant clob :=
    to_clob
    ('
ORACLE_TOOLS:CONSTRAINT:SYS_C0032420:ORACLE_TOOLS:TABLE:DEMO_CONSTRAINT_LOOKUP::::
ORACLE_TOOLS:FUNCTION:F_GENERATE_DDL:::::::
ORACLE_TOOLS:INDEX:EBA_INTRACK_VERSION_PK:ORACLE_TOOLS::EBA_INTRACK_VERSION::::
:OBJECT_GRANT::ORACLE_TOOLS::V_MY_SCHEMA_OBJECT_INFO::PUBLIC:SELECT:NO
ORACLE_TOOLS:PACKAGE_BODY:XUTL_XLSB:::::::
ORACLE_TOOLS:PACKAGE_SPEC:XUTL_XLSB:::::::
ORACLE_TOOLS:PROCEDURE:P_GENERATE_DDL:::::::
:PROCOBJ:UI_RESET_PWD_JOB:::::::
ORACLE_TOOLS:REF_CONSTRAINT:EBA_INTRACK_VERS_PROD_FK:ORACLE_TOOLS:TABLE:EBA_INTRACK_VERSION::::
ORACLE_TOOLS:SEQUENCE:EBA_INTRACK_SEQ:::::::
ORACLE_TOOLS:SYNONYM:DBUG_TRIGGER:::::::
ORACLE_TOOLS:TABLE:schema_version_tools_ui:::::::
ORACLE_TOOLS:TRIGGER:UI_APEX_MESSAGES_TRG:::::::
ORACLE_TOOLS:TYPE_BODY:T_VIEW_OBJECT:::::::
ORACLE_TOOLS:TYPE_SPEC:T_VIEW_OBJECT:::::::
ORACLE_TOOLS:VIEW:V_MY_SCHEMA_OBJECT_INFO:::::::
'   );
  l_schema_object_filter oracle_tools.t_schema_object_filter;
  l_object_tab dbms_sql.varchar2a;
  l_part_tab dbms_sql.varchar2a;
begin
  <<try_loop>>
  for i_try in 1..4
  loop
    case i_try
      when 1
      then
        oracle_tools.pkg_str_util.split(p_str => l_objects, p_delimiter => chr(10), p_str_tab => l_object_tab);

        l_schema_object_filter :=
          oracle_tools.t_schema_object_filter
          ( p_exclude_objects => null
          , p_include_objects => l_objects
          );
          
      else
        oracle_tools.pkg_str_util.split(p_str => l_object_names, p_delimiter => ',', p_str_tab => l_object_tab);

        l_schema_object_filter :=
          oracle_tools.t_schema_object_filter
          ( p_object_type => case i_try when 2 then 'OBJECT_GRANT' when 3 then 'PACKAGE_BODY' when 4 then null end
          , p_object_names => l_object_names
          , p_object_names_include => 1
          );
    end case;

    for i_idx in l_object_tab.first .. l_object_tab.last
    loop
      cleanup_object(l_object_tab(i_idx));

      if l_object_tab(i_idx) is not null
      then
        -- complete match but only for i_try 1
        if i_try = 1
        then
          ut.expect
          ( l_schema_object_filter.matches_schema_object(l_object_tab(i_idx))
          , utl_lms.format_message
            ( 'try: %s; object index: %s; complete match for object "%s"'
            , to_char(i_try)
            , to_char(i_idx)
            , l_object_tab(i_idx)
            )
          ).to_equal(1);
        end if;

        -- partial match now

        case 
          when i_try = 1
          then
            oracle_tools.pkg_str_util.split(p_str => l_object_tab(i_idx), p_delimiter => ':', p_str_tab => l_part_tab);
          when i_try in (2, 3)
          then
            l_part_tab("OBJECT TYPE") := 'PACKAGE_SPEC';
            l_part_tab("OBJECT NAME") := l_object_tab(i_idx);
            l_part_tab("BASE OBJECT TYPE") := null;
            l_part_tab("BASE OBJECT NAME") := null;
            
          when i_try = 4
          then
            l_part_tab("OBJECT TYPE") := 'PACKAGE_BODY';
            l_part_tab("OBJECT NAME") := l_object_tab(i_idx);
            l_part_tab("BASE OBJECT TYPE") := null;
            l_part_tab("BASE OBJECT NAME") := null;
        end case;    

        ut.expect
        ( l_schema_object_filter.matches_schema_object
          ( p_metadata_object_type => l_part_tab("OBJECT TYPE")
          , p_object_name => l_part_tab("OBJECT NAME")
          , p_metadata_base_object_type => l_part_tab("BASE OBJECT TYPE")
          , p_base_object_name => l_part_tab("BASE OBJECT NAME")
          )
        , utl_lms.format_message
          ( 'try: %s; object index: %s; partial match for object "%s"'
          , to_char(i_try)
          , to_char(i_idx)
          , l_object_tab(i_idx)
          )
        ).to_equal
          ( case i_try
              when 1 then case when l_object_tab(i_idx) = 'ORACLE_TOOLS:TABLE:schema_version_tools_ui:::::::' then 0 else 1 end
              when 2 then 1
              when 3 then 0
              when 4 then 1
            end
          );
      end if;
    end loop;
  end loop try_loop;

  return;

  -- get all
  for r in
  ( with src as
    ( select  a.id() as id
      from    table
              ( oracle_tools.pkg_ddl_util.get_schema_object
                ( oracle_tools.t_schema_object_filter
                  ( p_object_names => 'PKG_*'
                  , p_object_names_include => 1
                  )
                )
              ) a -- all
      order by
              id
    )
    select  src.*
    from    src
    where   rownum <= l_max_objects
  )
  loop
    -- get the current one
    select  max(o.id()) as id
    ,       count(*) as cnt
    into    l_id
    ,       l_cnt
    from    table
            ( oracle_tools.pkg_ddl_util.get_schema_object
              ( oracle_tools.t_schema_object_filter
                ( p_exclude_objects => null
                , p_include_objects => r.id
                )
              )
            ) o -- one
    ;
    ut.expect(l_cnt, r.id).to_equal(1);
    ut.expect(l_id, r.id).to_equal(r.id);
  end loop;
end;

procedure ut_compatible_le_oracle_11g
is
  l_max_length_object_name pls_integer;
  l_max_length_package_name pls_integer;
  l_max_length_argument_name pls_integer;  
begin
  select  max(length(object_name))
  ,       max(length(package_name))
  ,       max(length(argument_name))
  into    l_max_length_object_name
  ,       l_max_length_package_name
  ,       l_max_length_argument_name
  from    user_arguments;

  ut.expect(l_max_length_object_name, 'max_length_object_name').to_be_less_or_equal(30);
  ut.expect(l_max_length_package_name, 'max_length_package_name').to_be_less_or_equal(30);
  ut.expect(l_max_length_argument_name, 'max_length_argument_name').to_be_less_or_equal(30);
end ut_compatible_le_oracle_11g;

$end -- $if oracle_tools.cfg_pkg.c_testing $then

end pkg_schema_object_filter;
/

