CREATE OR REPLACE PACKAGE BODY "ORACLE_TOOLS"."PKG_SCHEMA_OBJECT_FILTER" IS

subtype t_module is varchar2(100);
subtype t_object is oracle_tools.pkg_ddl_util.t_object;
subtype t_object_names is oracle_tools.pkg_ddl_util.t_object_names;
subtype t_numeric_boolean is oracle_tools.pkg_ddl_util.t_numeric_boolean;
subtype t_metadata_object_type is oracle_tools.pkg_ddl_util.t_metadata_object_type;
subtype t_schema_nn is oracle_tools.pkg_ddl_util.t_schema_nn;
subtype t_schema is oracle_tools.pkg_ddl_util.t_schema;

-- see static function T_SCHEMA_OBJECT.ID
c_nr_parts constant simple_integer := 10;

"OBJECT SCHEMA" constant simple_integer := 1;
"OBJECT TYPE" constant simple_integer := 2;
"OBJECT NAME" constant simple_integer := 3;
"BASE OBJECT TYPE" constant simple_integer := 5;
"BASE OBJECT NAME" constant simple_integer := 6;

-- steps in get_schema_objects
"named objects" constant varchar2(30 char) := 'base objects';
"object grants" constant varchar2(30 char) := 'object grants';
"public synonyms and comments" constant varchar2(30 char) := 'public synonyms and comments';
"constraints" constant varchar2(30 char) := 'constraints';
"private synonyms and triggers" constant varchar2(30 char) := 'private synonyms and triggers';
"indexes" constant varchar2(30 char) := 'indexes';

c_steps constant sys.odcivarchar2list :=
  sys.odcivarchar2list
  ( "named objects"                 -- no base object
  , "object grants"                 -- base object (named)
  , "public synonyms and comments"  -- base object (named)
  , "constraints"                   -- base object (named)
  , "private synonyms and triggers" -- base object (NOT named)
  , "indexes"                       -- base object (NOT named)
  );

-- forward declaration
function fill_array(p_element in varchar2)
return dbms_sql.varchar2a;

c_default_empty_part_tab constant dbms_sql.varchar2a := fill_array(null);
c_default_wildcard_part_tab constant dbms_sql.varchar2a:= fill_array('*');

g_default_match_perc_threshold integer := 50;

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

function matches_schema_object
( p_object_type in varchar2
, p_object_name in varchar2
, p_base_object_type in varchar2 default null
, p_base_object_name in varchar2 default null
, p_schema_object_filter in t_schema_object_filter default null
, p_schema_object_id in varchar2 default null
)
return integer
deterministic
is
  l_result simple_integer := 0;

  function search(p_lwb in naturaln, p_upb in naturaln)
  return natural
  is
    l_cmp simple_integer := -1;
  begin
    for i_idx in p_lwb .. p_upb
    loop      
      l_cmp := 
        case substr(p_schema_object_filter.object_cmp_tab$(i_idx), -1)
          when '~'
          then
            case
              when p_schema_object_id like p_schema_object_filter.object_tab$(i_idx) escape '\'
              then 0 -- found
              else 1 -- try further
            end

          when '='
          then
            case
              when p_schema_object_id = p_schema_object_filter.object_tab$(i_idx)
              then 0 -- found
              when p_schema_object_id > p_schema_object_filter.object_tab$(i_idx)
              then 1 -- try further: p_schema_object_filter.object_tab$(i_idx+1) > p_schema_object_filter.object_tab$(i_idx)
              else -1 -- will never find it since ordered (first object_cmp_tab$ !?~, then object_cmp_tab$ !?= and in ascending object_tab$ order)
            end
        end;

$if oracle_tools.pkg_schema_object_filter.c_debugging $then
      dbug.print
      ( dbug."info"
      , '[%s] compare "%s" "%s" "%s": %s'
      , i_idx
      , p_schema_object_id
      , p_schema_object_filter.object_cmp_tab$(i_idx)
      , p_schema_object_filter.object_tab$(i_idx)
      , l_cmp
      );
$end

      case l_cmp
        when 0  then return 1; -- found: stop
        when -1 then return 0; -- will never find
        else null;
      end case;
    end loop search_loop;

    return case when p_lwb <= p_upb then 0 else null end;
  end search;
begin
$if oracle_tools.pkg_schema_object_filter.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'MATCHES_SCHEMA_OBJECT');
  dbug.print
  ( dbug."input"
  , 'object: "%s"; base object: "%s"; p_schema_object_id: %s'
  , p_object_type || ':' || p_object_name
  , p_base_object_type || ':' || p_base_object_name
  , p_schema_object_id
  );
  dbug.print
  ( dbug."input"
  , 'cardinality(p_schema_object_filter.object_tab$): %s; p_schema_object_filter.nr_excluded_objects$: %s'
  , case when p_schema_object_filter is not null then cardinality(p_schema_object_filter.object_tab$) end
  , case when p_schema_object_filter is not null then p_schema_object_filter.nr_excluded_objects$ end
  );
$end    

  case
    -- exclude certain (semi-)dependent objects
    when p_base_object_type is not null and
         p_base_object_name is not null and
         oracle_tools.pkg_ddl_util.is_exclude_name_expr(p_base_object_type, p_base_object_name) = 1
    then
$if oracle_tools.pkg_schema_object_filter.c_debugging $then
       dbug.print(dbug."info", 'case 1');
$end
      l_result := 0;

    -- exclude certain named objects
    when p_object_type is not null and
         p_object_name is not null and
         oracle_tools.pkg_ddl_util.is_exclude_name_expr(p_object_type, p_object_name) = 1
    then
$if oracle_tools.pkg_schema_object_filter.c_debugging $then
       dbug.print(dbug."info", 'case 2');
$end
      l_result := 0;

    when p_schema_object_filter is null or
         p_schema_object_id is null or
         cardinality(p_schema_object_filter.object_tab$) = 0
    then
      l_result := 1;

    when search(1, p_schema_object_filter.nr_excluded_objects$) = 1
    then
      -- any exclusion match; return 0
      l_result := 0;

    else
      -- check for inclusion match
      l_result := nvl
                  ( search
                    ( p_schema_object_filter.nr_excluded_objects$ + 1
                    , nvl(cardinality(p_schema_object_filter.object_tab$), 0)
                    )
                  , 1 -- when there are no inclusions at all: OK
                  );
  end case;  

$if oracle_tools.pkg_schema_object_filter.c_debugging $then
  dbug.print(dbug."output", 'return: %s', l_result);
  dbug.leave;
$end

  return l_result;

$if oracle_tools.pkg_schema_object_filter.c_debugging $then
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
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
  to_json_array('OBJECT_TAB$', p_schema_object_filter.object_tab$);
  to_json_array('OBJECT_CMP_TAB$', p_schema_object_filter.object_cmp_tab$);
  p_json_object.put('NR_EXCLUDED_OBJECTS$', p_schema_object_filter.nr_excluded_objects$);
  p_json_object.put('MATCH_COUNT$', p_schema_object_filter.match_count$);
  p_json_object.put('MATCH_COUNT_OK$', p_schema_object_filter.match_count_ok$);
  p_json_object.put('MATCH_PERC_THRESHOLD$', p_schema_object_filter. match_perc_threshold$);
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

$if oracle_tools.pkg_schema_object_filter.c_debugging $then

procedure check_duplicates(p_schema_object_tab in oracle_tools.t_schema_object_tab, p_step in varchar2)
is
  type t_object_natural_tab is table of natural /* >= 0 */ index by t_object;

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

-- GLOBAL

function get_named_objects
( p_schema in varchar2
)
return oracle_tools.t_schema_object_tab
pipelined
is
  type t_excluded_tables_tab is table of boolean index by all_tables.table_name%type;

  l_excluded_tables_tab t_excluded_tables_tab;

  l_schema_md_object_type_tab constant oracle_tools.t_text_tab :=
    oracle_tools.pkg_ddl_util.get_md_object_type_tab('SCHEMA');
begin
$if oracle_tools.pkg_schema_object_filter.c_tracing $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'GET_NAMED_OBJECTS');
$if oracle_tools.pkg_schema_object_filter.c_debugging $then
  dbug.print(dbug."input", 'p_schema: %s', p_schema);
$end  
$end

  for i_idx in 1 .. 4
  loop
$if oracle_tools.pkg_schema_object_filter.c_debugging $then
    dbug.print(dbug."info", 'i_idx: %s', i_idx);
$end

    case i_idx
      when 1
      then
        -- queue tables
        for r in
        ( select  q.owner as object_schema
          ,       'AQ_QUEUE_TABLE' as object_type
          ,       q.queue_table as object_name
          from    all_queue_tables q
          where   q.owner = p_schema
        )
        loop
          l_excluded_tables_tab(r.object_name) := true;

$if oracle_tools.pkg_schema_object_filter.c_debugging $then
          dbug.print(dbug."info", 'excluding queue table: %s', r.object_name);
$end

$if oracle_tools.pkg_ddl_util.c_get_queue_ddl $then

          continue when matches_schema_object(p_object_type => r.object_type, p_object_name => r.object_name) = 0;

          pipe row ( oracle_tools.t_named_object.create_named_object
                     ( p_object_schema => r.object_schema
                     , p_object_type => r.object_type
                     , p_object_name => r.object_name
                     )
                   );
$else
          /* ORA-00904: "KU$"."SCHEMA_OBJ"."TYPE": invalid identifier */
          null; 
$end
        end loop;

      when 2
      then
        -- no MATERIALIZED VIEW tables unless PREBUILT
        for r in
        ( select  m.owner as object_schema
          ,       'MATERIALIZED_VIEW' as object_type
          ,       m.mview_name as object_name
          ,       m.build_mode
          from    all_mviews m
          where   m.owner = p_schema
        )
        loop
          if r.build_mode != 'PREBUILT'
          then
            l_excluded_tables_tab(r.object_name) := true;

$if oracle_tools.pkg_schema_object_filter.c_debugging $then
            dbug.print(dbug."info", 'excluding materialized view table: %s', r.object_name);
$end
          end if;

          continue when matches_schema_object(p_object_type => r.object_type, p_object_name => r.object_name) = 0;

          -- this is a special case since we need to exclude first
          pipe row (oracle_tools.t_materialized_view_object(r.object_schema, r.object_name));
        end loop;

      when 3
      then
        -- tables
        for r in
        ( select  t.owner as object_schema
          ,       t.table_name as object_name
          ,       t.tablespace_name
          ,       'TABLE' as object_type
          from    all_tables t
          where   t.owner = p_schema
          and     t.nested = 'NO' -- Exclude nested tables, their DDL is part of their parent table.
          and     ( t.iot_type is null or t.iot_type = 'IOT' ) -- Only the IOT table itself, not an overflow or mapping
                  -- GPA 2017-06-28 #147916863 - As a release operator I do not want comments without table or column.
          and     substr(t.table_name, 1, 5) not in (/*'APEX$', */'MLOG$', 'RUPD$') 
          union -- not union all because since Oracle 12, temporary tables are also shown in all_tables
          -- temporary tables
          select  t.owner as object_schema
          ,       t.object_name
          ,       null as tablespace_name
          ,       t.object_type
          from    all_objects t
          where   t.owner = p_schema
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

          if not(l_excluded_tables_tab.exists(r.object_name))
          then
            continue when matches_schema_object(p_object_type => r.object_type, p_object_name => r.object_name) = 0;

            pipe row (oracle_tools.t_table_object(r.object_schema, r.object_name, r.tablespace_name));

$if oracle_tools.pkg_schema_object_filter.c_debugging $then
          else  
            dbug.print(dbug."info", 'not checking since table was excluded: %s', r.object_name);
$end
          end if; 
        end loop;

      when 4
      then
        for r in
        ( /*
          -- Just the base objects, i.e. no constraints, comments, grant nor public synonyms to base objects.
          */
          with obj as
          ( select  obj.owner
            ,       obj.object_type
            ,       obj.object_name
            ,       obj.status
            ,       obj.generated
            ,       obj.temporary
            ,       obj.subobject_name
                    -- use scalar subqueries for a (possible) better performance
            ,       ( select substr(oracle_tools.t_schema_object.dict2metadata_object_type(obj.object_type), 1, 23) from dual ) as md_object_type
--            ,       ( select oracle_tools.t_schema_object.is_a_repeatable(obj.object_type) from dual ) as is_a_repeatable
--            ,       ( select oracle_tools.pkg_ddl_util.is_exclude_name_expr(oracle_tools.t_schema_object.dict2metadata_object_type(obj.object_type), obj.object_name) from dual ) as is_exclude_name_expr
            ,       ( select oracle_tools.pkg_ddl_util.is_dependent_object_type(obj.object_type) from dual ) as is_dependent_object_type
            from    all_objects obj
          )
          select  o.owner as object_schema
          ,       o.md_object_type as object_type
          ,       o.object_name
          from    obj o
          where   o.owner = p_schema
          and     o.object_type not in ('QUEUE', 'MATERIALIZED VIEW', 'TABLE', 'TRIGGER', 'INDEX', 'SYNONYM')
          and     not( o.object_type = 'SEQUENCE' and substr(o.object_name, 1, 5) = 'ISEQ$' )
          and     o.md_object_type member of l_schema_md_object_type_tab
$if oracle_tools.pkg_ddl_util.c_exclude_system_objects $then
          and     o.generated = 'N' -- GPA 2016-12-19 #136334705
$end                
                  -- OWNER         OBJECT_NAME                      SUBOBJECT_NAME
                  -- =====         ===========                      ==============
                  -- ORACLE_TOOLS  oracle_tools.t_table_column_ddl  $VSN_1
          and     o.subobject_name is null
                  -- GPA 2017-06-28 #147916863 - As a release operator I do not want comments without table or column.
          and     o.is_dependent_object_type = 0
        )
        loop
          continue when matches_schema_object(p_object_type => r.object_type, p_object_name => r.object_name) = 0;

          pipe row ( oracle_tools.t_named_object.create_named_object
                     ( p_object_schema => r.object_schema
                     , p_object_type => r.object_type
                     , p_object_name => r.object_name
                     )
                   );
        end loop;        
    end case;
  end loop;

$if oracle_tools.pkg_schema_object_filter.c_tracing $then
  dbug.leave;
$end

  return; -- essential

$if oracle_tools.pkg_schema_object_filter.c_tracing $then
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end get_named_objects;

procedure default_match_perc_threshold
( p_match_perc_threshold in integer
)
is
begin
  g_default_match_perc_threshold := p_match_perc_threshold;
end default_match_perc_threshold;

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
  l_dependent_md_object_type_tab constant oracle_tools.t_text_tab :=
    oracle_tools.pkg_ddl_util.get_md_object_type_tab('DEPENDENT');

  l_exclude_object_tab dbms_sql.varchar2a;
  l_include_object_tab dbms_sql.varchar2a;
  l_object_name_tab dbms_sql.varchar2a;
  l_case simple_integer := 0;

  cursor c_objects
  ( b_object_tab in sys.odcivarchar2list
  , b_prefix in varchar2
  )
  is
    with src1 as
    ( select  unique
              trim(replace(replace(replace(t.column_value, chr(9)), chr(13)), chr(10))) as id
      from    table(b_object_tab) t
    ), src2 as
    ( select  sign(instr(t.id, '*')) + sign(instr(t.id, '?')) * 2 as wildcard
      ,       t.id
      from    src1 t
      where   t.id is not null
    )
    select  case t.wildcard
              when 0
              then t.id
              when 1
              then replace(replace(replace(t.id, '_', '\_'), '%', '\%'), '*', '%')
              when 2
              then replace(replace(replace(t.id, '_', '\_'), '%', '\%'), '?', '_')
              when 3
              then replace(replace(replace(replace(t.id, '_', '\_'), '%', '\%'), '*', '%'), '?', '_')
            end as id
    ,       b_prefix ||
            case t.wildcard
              when 0
              then '='
              else '~'
            end as cmp
    from    src2 t
    order by
            sign(t.wildcard) desc -- first wildcards
    ,       id asc -- next by ascending id
    ;

  procedure check_object_type
  ( p_object_type in t_metadata_object_type
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
  , p_object_names_include in t_numeric_boolean
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

  procedure add_item
  ( p_object_tab in out nocopy dbms_sql.varchar2a
  , p_id in varchar2
  )
  is
  begin
$if oracle_tools.pkg_schema_object_filter.c_debugging $then
    dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.CONSTRUCT.ADD_ITEM (1)');
    dbug.print
    ( dbug."input"
    , 'p_object_tab.count: %s; p_id : %s'
    , p_object_tab.count
    , p_id
    );
$end

    if instr(p_id, ':', 1, 9) > 0 and instr(p_id, ':', 1, 10) = 0
    then
      p_object_tab(p_object_tab.count + 1) := p_id;
    else
      oracle_tools.pkg_ddl_error.raise_error
      ( p_error_number => oracle_tools.pkg_ddl_error.c_objects_wrong
      , p_error_message => 'number of parts must be ' || c_nr_parts
      , p_context_info => p_id
      , p_context_label => 'schema object id'
      );
    end if;

$if oracle_tools.pkg_schema_object_filter.c_debugging $then
    dbug.print
    ( dbug."output"
    , 'p_object_tab.count: %s'
    , p_object_tab.count
    );
    dbug.leave;
$end
  end add_item;

  procedure add_item
  ( p_id in varchar2
  , p_cmp in varchar2
  )
  is
  begin
$if oracle_tools.pkg_schema_object_filter.c_debugging $then
    dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.CONSTRUCT.ADD_ITEM (2)');
    dbug.print
    ( dbug."input"
    , 'p_schema_object_filter.object_tab$.count: %s; p_id : %s; p_cmp: %s'
    , p_schema_object_filter.object_tab$.count
    , p_id
    , p_cmp
    );
$end

    if instr(p_id, ':', 1, 9) > 0 and instr(p_id, ':', 1, 10) = 0
    then
      p_schema_object_filter.object_tab$.extend(1);
      p_schema_object_filter.object_tab$(p_schema_object_filter.object_tab$.last) := p_id;
      p_schema_object_filter.object_cmp_tab$.extend(1);
      p_schema_object_filter.object_cmp_tab$(p_schema_object_filter.object_cmp_tab$.last) := p_cmp;
    else
      oracle_tools.pkg_ddl_error.raise_error
      ( p_error_number => oracle_tools.pkg_ddl_error.c_objects_wrong
      , p_error_message => 'number of parts must be ' || c_nr_parts
      , p_context_info => p_id
      , p_context_label => 'schema object id'
      );
    end if;

$if oracle_tools.pkg_schema_object_filter.c_debugging $then
    dbug.print
    ( dbug."output"
    , 'p_schema_object_filter.object_tab$.count: %s'
    , p_schema_object_filter.object_tab$.count
    );
    dbug.leave;
$end
  end add_item;

  procedure add_item
  ( p_case in positiven
  , p_base_object in boolean default false
  , p_object_schema in varchar2 default '*'
  , p_object_type in varchar2 default '*'
  , p_object_name in varchar2 default '*'
  , p_base_object_type in varchar2 default '*'
  , p_base_object_name in varchar2 default '*'
  )
  is
    l_object varchar2(4000 char);

    function must_skip_object
    ( p_object in varchar2
    )
    return boolean
    is
      l_part_tab dbms_sql.varchar2a;
      l_result boolean := false;
    begin
$if oracle_tools.pkg_schema_object_filter.c_debugging $then
      dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.CONSTRUCT.ADD_ITEM (3).MUST_SKIP_OBJECT');
      dbug.print(dbug."input", 'p_object: %s', p_object);
$end
      if p_base_object
      then
        oracle_tools.pkg_str_util.split(p_str => p_object, p_delimiter => ':', p_str_tab => l_part_tab);
        if nvl(l_part_tab("BASE OBJECT TYPE"), '*') = '*' and
           nvl(l_part_tab("BASE OBJECT NAME"), '*') = '*' and
           -- one exception since an INDEX can only depend on a TABLE, see NOTE dependent or granted objects below
           not(p_object_type = 'INDEX' and p_base_object_type = 'TABLE')
        then
          -- There is no need add expressions where both base object type and base object name are empty or wildcard.
          --
          -- Consider construct(p_object_type => 'TABLE', p_object_names => 'X', p_object_names_include => 1) as an example.
          --
          -- Without this check this would lead to these items being added:
          --
          -- OBJECT MATCH
          --
          -- 1. "*:TABLE:X:*:*:*::*:*:*"
          --
          -- BASE OBJECT MATCH
          --
          -- 2. "*:CONSTRAINT:*:*:TABLE:X::*:*:*"
          -- 3. "*:INDEX:*:*::X::::"
          -- 4. "*:REF_CONSTRAINT:*:*:TABLE:X::*:*:*"
          -- 5. "*:SYNONYM:*:::::::"
          -- 6. "*:TRIGGER:*:::::::"
          -- 7. ":COMMENT::*:TABLE:X:*:::"
          -- 8. ":OBJECT_GRANT::*::X::*:*:*"
          --
          -- Clearly cases 5 and 6 where the base object info got lost should not be added to the list of inclusions/exclusions.
          l_result := true;
        end if;
      end if;

$if oracle_tools.pkg_schema_object_filter.c_debugging $then
      dbug.print(dbug."output", 'return: %s', l_result);
      dbug.leave;
$end

      return l_result;
    end must_skip_object;
  begin
$if oracle_tools.pkg_schema_object_filter.c_debugging $then
    dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.CONSTRUCT.ADD_ITEM (3)');
    dbug.print
    ( dbug."input"
    , 'p_case: %s; p_base_object: %s'
    , p_case
    , dbug.cast_to_varchar2(p_base_object)
    );
    dbug.print
    ( dbug."input"
    , 'p_object_schema: %s; p_object_type: %s; p_object_name: %s; p_base_object_type: %s; p_base_object_name: %s'
    , p_object_schema
    , p_object_type
    , p_object_name
    , p_base_object_type
    , p_base_object_name
    );
$end

    l_object := oracle_tools.t_schema_object.id
                ( p_object_schema => p_object_schema
                , p_object_type => p_object_type
                , p_object_name => p_object_name
                , p_base_object_schema => '*'
                , p_base_object_type => p_base_object_type
                , p_base_object_name => p_base_object_name
                , p_column_name => '*'
                , p_grantee => '*'
                , p_privilege => '*'
                , p_grantable => '*'
                );

    if not(must_skip_object(l_object))
    then
      if p_case in (3, 4)
      then
        add_item(l_exclude_object_tab, l_object);
      end if;

      if p_case in (2, 5, 6)
      then
        add_item(l_include_object_tab, l_object);
      end if;
    end if;

    -- do something extra for case 4
    if p_case = 4
    then
      -- include all objects (object name and base object name *) with the same object type
      l_object := oracle_tools.t_schema_object.id
                  ( p_object_schema => p_object_schema
                  , p_object_type => p_object_type
                  , p_object_name => '*'
                  , p_base_object_schema => '*'
                  , p_base_object_type => p_base_object_type
                  , p_base_object_name => '*'
                  , p_column_name => '*'
                  , p_grantee => '*'
                  , p_privilege => '*'
                  , p_grantable => '*'
                  );
      if not(must_skip_object(l_object))
      then
        add_item(l_include_object_tab, l_object);
      end if;
    end if;

$if oracle_tools.pkg_schema_object_filter.c_debugging $then
    dbug.leave;
$end
  end add_item;  

  procedure add_items
  ( p_object_tab in dbms_sql.varchar2a
  , p_exclude in boolean default false
  )
  is
    l_object_tab sys.odcivarchar2list := sys.odcivarchar2list();
  begin
$if oracle_tools.pkg_schema_object_filter.c_debugging $then
    dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.CONSTRUCT.ADD_ITEMS');
    dbug.print
    ( dbug."input"
    , 'p_object_tab.count: %s; p_exclude : %s'
    , p_object_tab.count
    , dbug.cast_to_varchar2(p_exclude)
    );
$end

    -- transform the list
    if p_object_tab.count > 0
    then
      for i_object_idx in p_object_tab.first .. p_object_tab.last
      loop
        l_object_tab.extend(1);
        l_object_tab(l_object_tab.last) := p_object_tab(i_object_idx);
      end loop;
    end if;

    for r in c_objects(l_object_tab, case when p_exclude then '!' end)
    loop
      add_item(r.id, r.cmp);
    end loop;

    if p_exclude
    then
      p_schema_object_filter.nr_excluded_objects$ := p_schema_object_filter.object_tab$.count;
    end if;

$if oracle_tools.pkg_schema_object_filter.c_debugging $then
    dbug.leave;
$end
  end add_items;
begin
$if oracle_tools.pkg_schema_object_filter.c_tracing $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.CONSTRUCT');
$if oracle_tools.pkg_schema_object_filter.c_debugging $then
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
$end

  -- old functionality
  oracle_tools.pkg_ddl_util.check_schema(p_schema => p_schema, p_network_link => null);
  check_object_type(p_object_type => p_object_type);
  oracle_tools.pkg_ddl_util.check_numeric_boolean(p_numeric_boolean => p_object_names_include, p_description => 'object names include');
  check_objects(p_object_names => p_object_names, p_object_names_include => p_object_names_include, p_description => 'object names');
  oracle_tools.pkg_ddl_util.check_numeric_boolean(p_numeric_boolean => p_grantor_is_schema, p_description => 'grantor is schema');

  p_schema_object_filter.schema$ := p_schema;
  p_schema_object_filter.grantor_is_schema$ := p_grantor_is_schema;
  p_schema_object_filter.object_tab$ := oracle_tools.t_text_tab();
  p_schema_object_filter.object_cmp_tab$ := oracle_tools.t_text_tab();
  p_schema_object_filter.nr_excluded_objects$ := 0;
  p_schema_object_filter.match_count$ := 0;
  p_schema_object_filter.match_count_ok$ := 0;
  p_schema_object_filter.match_perc_threshold$ := g_default_match_perc_threshold;

  if p_exclude_objects is not null
  then
    oracle_tools.pkg_str_util.split(p_str => p_exclude_objects, p_delimiter => chr(10), p_str_tab => l_exclude_object_tab);
  end if;

  if p_include_objects is not null
  then
    oracle_tools.pkg_str_util.split(p_str => p_include_objects, p_delimiter => chr(10), p_str_tab => l_include_object_tab);
  end if;

  -- old functionality?

  /*
  -- 1) p_object_names_include is null and p_object_type is null:
  --    nothing to do
  -- 2) p_object_names_include is null and p_object_type is not null:
  --    include search with object names * and object type (like 6)
  -- 3) p_object_names_include = 0 and p_object_type is null:
  --    exclude search for object names with object type *
  -- 4) p_object_names_include = 0 and p_object_type is not null:
  --    exclude search for object names with object type
  --    include search for object names * with object type
  -- 5) p_object_names_include = 1 and p_object_type is null:
  --    include search for object names with object type *
  -- 6) p_object_names_include = 1 and p_object_type is not null:
  --    include search for object names with object type
  */

  case
    when p_object_names_include is null and p_object_type is null
    then l_case := 1;
    when p_object_names_include is null and p_object_type is not null
    then l_case := 2;
    when p_object_names_include = 0 and p_object_type is null
    then l_case := 3;
    when p_object_names_include = 0 and p_object_type is not null
    then l_case := 4;
    when p_object_names_include = 1 and p_object_type is null
    then l_case := 5;
    when p_object_names_include = 1 and p_object_type is not null
    then l_case := 6;
  end case;

$if oracle_tools.pkg_schema_object_filter.c_debugging $then
  dbug.print(dbug."info", 'l_case: %s', l_case);
$end

  if l_case != 1
  then
    oracle_tools.pkg_str_util.split
    ( p_str => nvl(p_object_names, '*')
    , p_delimiter => ','
    , p_str_tab => l_object_name_tab
    );

$if oracle_tools.pkg_schema_object_filter.c_debugging $then
    dbug.print(dbug."info", 'l_object_name_tab.count: %s', l_object_name_tab.count);
$end

    if l_object_name_tab.count = 0
    then
      raise program_error;
    else
      for i_object_name_idx in l_object_name_tab.first .. l_object_name_tab.last
      loop
        cleanup_object(l_object_name_tab(i_object_name_idx));
$if oracle_tools.pkg_schema_object_filter.c_debugging $then
        dbug.print
        ( dbug."info"
        , 'l_object_name_tab(%s): %s'
        , i_object_name_idx
        , l_object_name_tab(i_object_name_idx)
        );
$end
        if l_object_name_tab(i_object_name_idx) is not null
        then
          if p_object_type = 'SYNONYM'
          then
            -- 1. SYNONYM <OBJECT>
            add_item
            ( p_case => l_case
            , p_object_type => p_object_type
            , p_object_name => l_object_name_tab(i_object_name_idx)
            );
            -- 2. PUBLIC SYNONYM X FOR <BASE OBJECT>
            add_item
            ( p_case => l_case
            , p_object_schema => 'PUBLIC'
            , p_object_type => p_object_type
            , p_base_object_type => '*' -- we have no information about the base object type
            , p_base_object_name => l_object_name_tab(i_object_name_idx)
            );
          elsif p_object_type in ( 'OBJECT_GRANT'
                                 , 'COMMENT'
                                 , 'REF_CONSTRAINT'
                                 , 'CONSTRAINT'
                                 )
          then
            add_item
            ( p_case => l_case
            , p_object_type => p_object_type
            , p_base_object_type => '*' -- we have no information about the base object type
            , p_base_object_name => l_object_name_tab(i_object_name_idx)
            );
          else
            add_item
            ( p_case => l_case
            , p_object_type => nvl(p_object_type, '*')
            , p_object_name => l_object_name_tab(i_object_name_idx)
            );
          end if;

          /* 

             NOTE dependent or granted objects

             To get the dependent or granted objects using a named object these are the rules.

             A) Object grants.

                The query 'select distinct type from dba_tab_privs order by 1' returns this:

                ANALYTIC VIEW
                DIRECTORY
                EDITION
                FUNCTION
                HIERARCHY
                INDEXTYPE
                JOB CLASS
                LIBRARY
                OPERATOR
                PACKAGE
                PROCEDURE
                QUEUE
                RESOURCE CONSUMER GROUP
                SEQUENCE
                TABLE
                TYPE
                UNKNOWN
                USER
                VIEW

             B) Synonyms.

                From the Oracle 19c documentation:

                Use the CREATE SYNONYM statement to create a synonym, which is
                an alternative name for a table, view, sequence, operator,
                procedure, stored function, package, materialized view, Java
                class schema object, user-defined object type, or another
                synonym.

                FUNCTION
                JAVA CLASS
                JAVA SOURCE
                MATERIALIZED VIEW
                OPERATOR
                PACKAGE
                PROCEDURE
                SEQUENCE
                SYNONYM
                TABLE
                TYPE
                VIEW

             C) Constraints.

                TABLE
                VIEW

             D) Comments.   

                MATERIALIZED VIEW
                TABLE
                VIEW

             E) Indexes.

                TABLE

             F) Triggers.

                TABLE
                VIEW

             So when p_object_type is one of those listed above (be careful to convert to a metadata object type)   
             you may add an expression for a base object.
          */
          if p_object_type in ( -- this list is reduced since not all object types mentioned in the NOTE are relevant
                                'FUNCTION'
                              , 'MATERIALIZED_VIEW'
                              , 'PACKAGE_SPEC'
                              , 'PROCEDURE'
                              , 'QUEUE'
                              , 'SEQUENCE'
                              , 'SYNONYM'
                              , 'TABLE'
                              , 'TYPE_SPEC'
                              , 'VIEW'
                              ) or
             p_object_type is null -- can be any of the above                 
          then
            -- Add entries for each dependent object type and
            -- let oracle_tools.t_schema_object.id() decide about setting the base object type
            -- inside add_item().
            for i_object_type_idx in l_dependent_md_object_type_tab.first .. l_dependent_md_object_type_tab.last
            loop
              -- skip these combinations
              continue when ( l_dependent_md_object_type_tab(i_object_type_idx) = 'OBJECT_GRANT' and
                              p_object_type in ( 'MATERIALIZED_VIEW' ) ) or
                            ( l_dependent_md_object_type_tab(i_object_type_idx) = 'SYNONYM' and
                              p_object_type in ( 'QUEUE' ) ) or
                            ( l_dependent_md_object_type_tab(i_object_type_idx) in ( 'CONSTRAINT', 'REF_CONSTRAINT' ) and
                              not(p_object_type is null or p_object_type in ( 'TABLE', 'VIEW' )) )  or
                            ( l_dependent_md_object_type_tab(i_object_type_idx) = 'COMMENT' and
                              not(p_object_type is null or p_object_type in ( 'MATERIALIZED_VIEW', 'TABLE', 'VIEW' )) )  or
                            ( l_dependent_md_object_type_tab(i_object_type_idx) = 'INDEX' and
                              not(p_object_type is null or p_object_type in ( 'TABLE' )) )  or
                            ( l_dependent_md_object_type_tab(i_object_type_idx) = 'TRIGGER' and
                              not(p_object_type is null or p_object_type in ( 'TABLE', 'VIEW' )) );

              add_item
              ( p_case => l_case
              , p_object_type => l_dependent_md_object_type_tab(i_object_type_idx)
              , p_base_object_type => nvl(p_object_type, '*')
              , p_base_object_name => l_object_name_tab(i_object_name_idx)
              , p_base_object => true
              );
            end loop;
          end if;
        end if;
      end loop;
    end if;
  end if;

  -- old and new functionality combined
  add_items(l_exclude_object_tab, true);
  add_items(l_include_object_tab);

  -- make the tables null if they are empty
  if p_schema_object_filter.object_tab$.count = 0
  then
    p_schema_object_filter.object_tab$ := null;
    p_schema_object_filter.object_cmp_tab$ := null;
  end if;

$if oracle_tools.pkg_schema_object_filter.c_debugging $then
  print(p_schema_object_filter);
$end

$if oracle_tools.pkg_schema_object_filter.c_tracing $then
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
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$else
  null;
$end
end print;

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
    matches_schema_object
    ( p_object_type => l_part_tab("OBJECT TYPE")
    , p_object_name => l_part_tab("OBJECT NAME")
    , p_base_object_type => l_part_tab("BASE OBJECT TYPE")
    , p_base_object_name => l_part_tab("BASE OBJECT NAME")
    , p_schema_object_filter => p_schema_object_filter
    , p_schema_object_id => p_schema_object_id
    );
end matches_schema_object;

procedure get_schema_objects
( p_schema_object_filter in out nocopy oracle_tools.t_schema_object_filter
, p_schema_object_tab out nocopy oracle_tools.t_schema_object_tab
)
is
$if oracle_tools.pkg_schema_object_filter.c_tracing $then
  l_module_name constant dbug.module_name_t := $$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'GET_SCHEMA_OBJECTS (1)';
$end  
  l_schema_md_object_type_tab constant oracle_tools.t_text_tab :=
    oracle_tools.pkg_ddl_util.get_md_object_type_tab('SCHEMA');

  type t_excluded_tables_tab is table of boolean index by all_tables.table_name%type;

  l_excluded_tables_tab t_excluded_tables_tab;
  l_schema constant t_schema_nn := p_schema_object_filter.schema();
  l_grantor_is_schema constant t_numeric_boolean := p_schema_object_filter.grantor_is_schema();
  l_step varchar2(30 char);
  l_named_object_tab oracle_tools.t_schema_object_tab;
  l_longops_rec oracle_tools.api_longops_pkg.t_longops_rec :=
    oracle_tools.api_longops_pkg.longops_init
    ( p_target_desc => 'procedure ' || 'GET_SCHEMA_OBJECTS'
    , p_totalwork => 10
    , p_op_name => 'what'
    , p_units => 'steps'
    );

  procedure process_schema_object
  ( p_schema_object in oracle_tools.t_schema_object
  , p_object_type in varchar2
  , p_object_name in varchar2
  , p_base_object_type in varchar2 default null
  , p_base_object_name in varchar2 default null
  )
  is
  begin
    p_schema_object_filter.match_count$ := p_schema_object_filter.match_count$ + 1;
    if matches_schema_object
       ( p_object_type => p_object_type
       , p_object_name => p_object_name
       , p_base_object_type => p_base_object_type
       , p_base_object_name => p_base_object_name
       , p_schema_object_filter => p_schema_object_filter
       , p_schema_object_id => p_schema_object.id()
       ) = 1
    then
      p_schema_object_tab.extend(1);
      p_schema_object_tab(p_schema_object_tab.last) := p_schema_object;
      p_schema_object_filter.match_count_ok$ := p_schema_object_filter.match_count_ok$ + 1;
    end if;
  end process_schema_object;

  procedure process_schema_object
  ( p_schema_object in oracle_tools.t_schema_object
  )
  is
  begin
    process_schema_object
    ( p_schema_object => p_schema_object
    , p_object_type => p_schema_object.object_type()
    , p_object_name => p_schema_object.object_name()
    , p_base_object_type => p_schema_object.base_object_type()
    , p_base_object_name => p_schema_object.base_object_name()
    );
  end process_schema_object;

  procedure cleanup
  is
  begin
    oracle_tools.api_longops_pkg.longops_done(l_longops_rec);
  end cleanup;
begin
$if oracle_tools.pkg_schema_object_filter.c_tracing $then
  dbug.enter(l_module_name);
$if oracle_tools.pkg_schema_object_filter.c_debugging $then
  p_schema_object_filter.print();
$end  
$end

  p_schema_object_tab := oracle_tools.t_schema_object_tab();

  select  value(obj)
  bulk collect
  into    l_named_object_tab
  from    table(oracle_tools.pkg_schema_object_filter.get_named_objects(l_schema)) obj;

  for i_idx in c_steps.first .. c_steps.last
  loop
    l_step := c_steps(i_idx);

$if oracle_tools.pkg_schema_object_filter.c_tracing $then
    dbug.enter(l_module_name || '.' || l_step);
$end    

    case l_step
      when "named objects"
      then
        for r in
        ( select  value(obj) as obj
          from    table(l_named_object_tab) obj
        )
        loop
          process_schema_object(r.obj, null, null); -- object_type and object_name have already been tested for exclusions
        end loop;

      -- object grants must depend on a base object already gathered, i.e. l_named_object_tab
      when "object grants"
      then
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
          process_schema_object
          ( oracle_tools.t_object_grant_object
            ( p_base_object => treat(r.base_object as oracle_tools.t_named_object)
            , p_object_schema => r.object_schema
            , p_grantee => r.grantee
            , p_privilege => r.privilege
            , p_grantable => r.grantable
            )
          );
        end loop;

      -- public synonyms and comments must depend on a base object already gathered, i.e. l_named_object_tab
      when "public synonyms and comments"
      then
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
          case r.object_type
            when 'SYNONYM'
            then
              process_schema_object
              ( oracle_tools.t_synonym_object
                ( p_base_object => treat(r.base_object as oracle_tools.t_named_object)
                , p_object_schema => r.object_schema
                , p_object_name => r.object_name
                )
              );
            when 'COMMENT'
            then
              process_schema_object
              ( oracle_tools.t_comment_object
                ( p_base_object => treat(r.base_object as oracle_tools.t_named_object)
                , p_object_schema => r.object_schema
                , p_column_name => r.column_name
                )
              );
          end case;
        end loop;

      -- constraints must depend on a base object already gathered, i.e. l_named_object_tab
      when "constraints"
      then
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
$if oracle_tools.pkg_ddl_util.c_exclude_not_null_constraints and oracle_tools.pkg_ddl_util.c_#138707615_1 $then
          -- We do NOT want a NOT NULL constraint, named or not.
          -- Since search_condition is a LONG we must use PL/SQL to filter
          if r.search_condition is not null and
             r.any_column_name is not null and
             r.search_condition = '"' || r.any_column_name || '" IS NOT NULL'
          then
            -- This is a not null constraint.
            -- Since search_condition has only one column, any column name is THE column name.
$if oracle_tools.pkg_schema_object_filter.c_debugging $then
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

          case r.object_type
            when 'REF_CONSTRAINT'
            then
              process_schema_object
              ( oracle_tools.t_ref_constraint_object
                ( p_base_object => treat(r.base_object as oracle_tools.t_named_object)
                , p_object_schema => r.object_schema
                , p_object_name => r.object_name
                , p_constraint_type => r.constraint_type
                , p_column_names => null
                )
              );

            when 'CONSTRAINT'
            then
              process_schema_object
              ( oracle_tools.t_constraint_object
                ( p_base_object => treat(r.base_object as oracle_tools.t_named_object)
                , p_object_schema => r.object_schema
                , p_object_name => r.object_name
                , p_constraint_type => r.constraint_type
                , p_search_condition => r.search_condition
                )
              );
          end case;
        end loop;

      -- these are not dependent on l_named_object_tab:
      -- * private synonyms from this schema pointing to a base object in ANY schema possible
      -- * triggers from this schema pointing to a base object in ANY schema possible
      when "private synonyms and triggers"
      then
        for r in
        ( select  t.*
          from    ( -- private synonyms for this schema which may point to another schema
                    with obj as
                    ( select  obj.owner
                      ,       obj.object_type
                      ,       obj.object_name
                      ,       obj.status
                      ,       obj.generated
                      ,       obj.temporary
                      ,       obj.subobject_name
                              -- use scalar subqueries for a (possible) better performance
                      ,       ( select substr(oracle_tools.t_schema_object.dict2metadata_object_type(obj.object_type), 1, 23) from dual ) as md_object_type
                      from    all_objects obj
                    )
                    select  s.owner as object_schema
                    ,       'SYNONYM' as object_type
                    ,       s.synonym_name as object_name
                    ,       obj.owner as base_object_schema
                    ,       obj.md_object_type as base_object_type
                    ,       obj.object_name as base_object_name
                    ,       null as column_name
                    from    all_synonyms s
                            inner join obj
                            on obj.owner = s.table_owner and obj.object_name = s.table_name
                    where   obj.object_type not like '%BODY'
                    and     obj.md_object_type member of l_schema_md_object_type_tab
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
                    ,       t.base_object_type as base_object_type
                    ,       t.table_name as base_object_name
                    ,       null as column_name
                    from    all_triggers t
                    where   t.owner = l_schema
                    and     t.base_object_type in ('TABLE', 'VIEW')
                  ) t
        )
        loop
          process_schema_object
          ( oracle_tools.t_schema_object.create_schema_object
            ( p_object_schema => r.object_schema
            , p_object_type => r.object_type
            , p_object_name => r.object_name
            , p_base_object_schema => r.base_object_schema
            , p_base_object_type => r.base_object_type
            , p_base_object_name => r.base_object_name
            , p_column_name => r.column_name
            )
          );
        end loop;

      -- these are not dependent on l_named_object_tab:
      -- * indexes from this schema pointing to a base object in ANY schema possible
      when "indexes"
      then
        for r in
        ( -- indexes
          select  i.owner as object_schema
          ,       'INDEX' as object_type
          ,       i.index_name as object_name
/* GJP 20170106 see oracle_tools.t_schema_object.chk()
          -- when the index is based on an object in another schema, no base info
          ,       case when i.owner = i.table_owner then i.table_owner end as base_object_schema
          ,       case when i.owner = i.table_owner then i.table_type end as base_object_type
          ,       case when i.owner = i.table_owner then i.table_name end as base_object_name
*/
          ,       i.table_owner as base_object_schema
          ,       i.table_type as base_object_type
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
          process_schema_object
          ( oracle_tools.t_index_object
            ( p_base_object =>
                oracle_tools.t_named_object.create_named_object
                ( p_object_schema => r.base_object_schema
                , p_object_type => r.base_object_type
                , p_object_name => r.base_object_name
                )
            , p_object_schema => r.object_schema
            , p_object_name => r.object_name
            , p_tablespace_name => r.tablespace_name
            )
          );
        end loop;
    end case;

    oracle_tools.api_longops_pkg.longops_show(l_longops_rec);
    
$if oracle_tools.pkg_schema_object_filter.c_tracing $then
    dbug.leave;
$end    
  end loop;

$if oracle_tools.pkg_schema_object_filter.c_debugging $then
  check_duplicates(p_schema_object_tab, c_steps(c_steps.last));
$end

  cleanup;

$if oracle_tools.pkg_schema_object_filter.c_tracing $then
$if oracle_tools.pkg_schema_object_filter.c_debugging $then
  dbug.print(dbug."output", 'cardinality(p_schema_object_tab): %s', cardinality(p_schema_object_tab));
$end  
  dbug.leave;
$end

exception
  when others
  then
    cleanup;
$if oracle_tools.pkg_schema_object_filter.c_tracing $then
    dbug.leave_on_error;
$end
    raise;
end get_schema_objects;

function get_schema_objects
( p_schema in varchar2 default user
, p_object_type in varchar2 default null
, p_object_names in varchar2 default null
, p_object_names_include in integer default null
, p_grantor_is_schema in integer default 0
, p_exclude_objects in clob default null
, p_include_objects in clob default null
)
return oracle_tools.t_schema_object_tab
pipelined
is
  l_schema_object_filter oracle_tools.t_schema_object_filter := null;
  l_schema_object_tab oracle_tools.t_schema_object_tab;
  l_program constant t_module := 'function ' || 'GET_SCHEMA_OBJECTS'; -- geen schema omdat l_program in dbms_application_info wordt gebruikt

  -- dbms_application_info stuff
  l_longops_rec oracle_tools.api_longops_pkg.t_longops_rec :=
    oracle_tools.api_longops_pkg.longops_init
    ( p_target_desc => l_program
    , p_op_name => 'fetch'
    , p_units => 'objects'
    );

  procedure cleanup
  is
  begin
    oracle_tools.api_longops_pkg.longops_done(l_longops_rec);
  end cleanup;
begin
$if oracle_tools.pkg_schema_object_filter.c_tracing $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'GET_SCHEMA_OBJECTS (2)');
$end

  l_schema_object_filter :=
    new oracle_tools.t_schema_object_filter
        ( p_schema => p_schema
        , p_object_type => p_object_type
        , p_object_names => p_object_names
        , p_object_names_include => p_object_names_include 
        , p_grantor_is_schema => p_grantor_is_schema 
        , p_exclude_objects => p_exclude_objects 
        , p_include_objects => p_include_objects 
        );

  oracle_tools.pkg_schema_object_filter.get_schema_objects
  ( p_schema_object_filter => l_schema_object_filter
  , p_schema_object_tab => l_schema_object_tab
  );

  if l_schema_object_tab is not null and l_schema_object_tab.count > 0
  then
    for i_idx in l_schema_object_tab.first .. l_schema_object_tab.last
    loop
      pipe row (l_schema_object_tab(i_idx));
      oracle_tools.api_longops_pkg.longops_show(l_longops_rec);
    end loop;
  end if;

  cleanup;

$if oracle_tools.pkg_schema_object_filter.c_tracing $then
  dbug.leave;
$end

  return; -- essential for pipelined functions
exception
  when no_data_needed
  then
    -- not a real error, just a way to some cleanup
    cleanup;
$if oracle_tools.pkg_schema_object_filter.c_tracing $then
    dbug.leave;
$end

  when no_data_found
  then
    cleanup;
$if oracle_tools.pkg_schema_object_filter.c_tracing $then
    dbug.leave_on_error;
$end
    oracle_tools.pkg_ddl_error.reraise_error(l_program);
    raise; -- to keep the compiler happy

  when others
  then
    cleanup;
$if oracle_tools.pkg_schema_object_filter.c_tracing $then
    dbug.leave_on_error;
$end
    raise;
end get_schema_objects;

$if oracle_tools.cfg_pkg.c_testing $then

procedure ut_construct
is
  l_schema_object_filter t_schema_object_filter;
  l_expected json_element_t;
begin
$if oracle_tools.pkg_schema_object_filter.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'GET_SCHEMA_OBJECTS (2)');
$end

  /*
  -- 1) p_object_names_include is null and p_object_type is null:
  --    impossible here
  -- 2) p_object_names_include is null and p_object_type is not null:
  --    include search with object names * and object type
  -- 3) p_object_names_include = 0 and p_object_type is null:
  --    exclude search for object names with object type *
  -- 4) p_object_names_include = 0 and p_object_type is not null:
  --    exclude search for object names with object type
  --    include search for object names * with object type
  -- 5) p_object_names_include = 1 and p_object_type is null:
  --    include search for object names with object type *
  -- 6) p_object_names_include = 1 and p_object_type is not null:
  --    include search for object names with object type
  */

  for i_try in 1..6
  loop
$if oracle_tools.pkg_schema_object_filter.c_debugging $then
    dbug.print(dbug."info", 'schema object filter try ' || i_try);
$end

    case i_try
      when 1
      then
        l_schema_object_filter := oracle_tools.t_schema_object_filter(p_schema => null);
        l_expected := json_element_t.parse('{
  "SCHEMA$" : null,
  "GRANTOR_IS_SCHEMA$" : 0,
  "NR_EXCLUDED_OBJECTS$" : 0,
  "MATCH_COUNT$" : 0,
  "MATCH_COUNT_OK$" : 0,
  "MATCH_PERC_THRESHOLD$" : 50
}');  

      when 2
      then
        l_schema_object_filter := oracle_tools.t_schema_object_filter(p_object_type => 'TABLE');
        l_expected := json_element_t.parse('{
  "SCHEMA$" : "ORACLE_TOOLS",
  "GRANTOR_IS_SCHEMA$" : 0,
  "OBJECT_TAB$" :
  [
    "%:CONSTRAINT:%:%:TABLE:%::%:%:%",
    "%:INDEX:%:%::%::::",
    "%:REF\\_CONSTRAINT:%:%:TABLE:%::%:%:%",
    "%:TABLE:%:%:%:%::%:%:%",
    ":COMMENT::%:TABLE:%:%:::"
  ],
  "OBJECT_CMP_TAB$" :
  [
    "~",
    "~",
    "~",
    "~",
    "~"
  ],
  "NR_EXCLUDED_OBJECTS$" : 0,
  "MATCH_COUNT$" : 0,
  "MATCH_COUNT_OK$" : 0,
  "MATCH_PERC_THRESHOLD$" : 50
}');

      when 3
      then
        l_schema_object_filter := oracle_tools.t_schema_object_filter
                                  ( p_schema => 'HR'
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
   "SCHEMA$" : "HR",
   "GRANTOR_IS_SCHEMA$" : 1,
   "OBJECT_TAB$" :
   [
     "%:%:DBMS\\_OUTPUT:%:%:%:%:%:%:%",
     "%:%:DBMS\\_SQL:%:%:%:%:%:%:%",
     "%:CONSTRAINT:%:%:%:DBMS\\_OUTPUT::%:%:%",
     "%:CONSTRAINT:%:%:%:DBMS\\_SQL::%:%:%",
     "%:INDEX:%:%::DBMS\\_OUTPUT::::",
     "%:INDEX:%:%::DBMS\\_SQL::::",
     "%:REF\\_CONSTRAINT:%:%:%:DBMS\\_OUTPUT::%:%:%",
     "%:REF\\_CONSTRAINT:%:%:%:DBMS\\_SQL::%:%:%",
     ":COMMENT::%:%:DBMS\\_OUTPUT:%:::",
     ":COMMENT::%:%:DBMS\\_SQL:%:::",
     ":OBJECT\\_GRANT::%::DBMS\\_OUTPUT::%:%:%",
     ":OBJECT\\_GRANT::%::DBMS\\_SQL::%:%:%"
   ],
   "OBJECT_CMP_TAB$" :
   [
     "!~",
     "!~",
     "!~",
     "!~",
     "!~",
     "!~",
     "!~",
     "!~",
     "!~",
     "!~",
     "!~",
     "!~"
   ],
   "NR_EXCLUDED_OBJECTS$" : 12,
   "MATCH_COUNT$" : 0,
   "MATCH_COUNT_OK$" : 0,
   "MATCH_PERC_THRESHOLD$" : 50
 }');

      when 4
      then
        -- duplicate objects should be ignored
        l_schema_object_filter := oracle_tools.t_schema_object_filter
                                  ( p_schema => 'HR'
                                  , p_object_type => 'OBJECT_GRANT'
                                  , p_object_names => 'DBMS_OUTPUT,DBMS_OUTPUT,DBMS_SQL,DBMS_SQL'
                                  , p_object_names_include => 0
                                  , p_grantor_is_schema => 1
                                  , p_exclude_objects => null
                                  , p_include_objects => null
                                  );
        l_expected := json_element_t.parse('
{
  "SCHEMA$" : "HR",
  "GRANTOR_IS_SCHEMA$" : 1,
  "OBJECT_TAB$" :
  [
    ":OBJECT\\_GRANT::%::DBMS\\_OUTPUT::%:%:%",
    ":OBJECT\\_GRANT::%::DBMS\\_SQL::%:%:%",
    ":OBJECT\\_GRANT::%::%::%:%:%"
  ],
  "OBJECT_CMP_TAB$" :
  [
    "!~",
    "!~",
    "~"
  ],
  "NR_EXCLUDED_OBJECTS$" : 2,
  "MATCH_COUNT$" : 0,
  "MATCH_COUNT_OK$" : 0,
  "MATCH_PERC_THRESHOLD$" : 50
}');

      when 5
      then
        l_schema_object_filter := oracle_tools.t_schema_object_filter
                                  ( p_schema => 'HR'
                                  , p_object_type => null
                                  , p_object_names => '
DBMS_OUTPUT,
DBMS_SQL
'
                                  , p_object_names_include => 1
                                  , p_grantor_is_schema => 1
                                  , p_exclude_objects => null
                                  , p_include_objects => null
                                  );
        l_expected := json_element_t.parse('{
   "SCHEMA$" : "HR",
   "GRANTOR_IS_SCHEMA$" : 1,
   "OBJECT_TAB$" :
   [
     "%:%:DBMS\\_OUTPUT:%:%:%:%:%:%:%",
     "%:%:DBMS\\_SQL:%:%:%:%:%:%:%",
     "%:CONSTRAINT:%:%:%:DBMS\\_OUTPUT::%:%:%",
     "%:CONSTRAINT:%:%:%:DBMS\\_SQL::%:%:%",
     "%:INDEX:%:%::DBMS\\_OUTPUT::::",
     "%:INDEX:%:%::DBMS\\_SQL::::",
     "%:REF\\_CONSTRAINT:%:%:%:DBMS\\_OUTPUT::%:%:%",
     "%:REF\\_CONSTRAINT:%:%:%:DBMS\\_SQL::%:%:%",
     ":COMMENT::%:%:DBMS\\_OUTPUT:%:::",
     ":COMMENT::%:%:DBMS\\_SQL:%:::",
     ":OBJECT\\_GRANT::%::DBMS\\_OUTPUT::%:%:%",
     ":OBJECT\\_GRANT::%::DBMS\\_SQL::%:%:%"
   ],
   "OBJECT_CMP_TAB$" :
   [
     "~",
     "~",
     "~",
     "~",
     "~",
     "~",
     "~",
     "~",
     "~",
     "~",
     "~",
     "~"
   ],
   "NR_EXCLUDED_OBJECTS$" : 0,
   "MATCH_COUNT$" : 0,
   "MATCH_COUNT_OK$" : 0,
   "MATCH_PERC_THRESHOLD$" : 50
 }');

      when 6
      then
        l_schema_object_filter := oracle_tools.t_schema_object_filter
                                  ( p_schema => 'HR'
                                  , p_object_type => 'PACKAGE_SPEC'
                                  , p_object_names => 'DBMS_METADATA,DBMS_VERSION'
                                  , p_object_names_include => 1
                                  , p_grantor_is_schema => 1
                                  , p_exclude_objects => null
                                  , p_include_objects => null
                                  );
        l_expected := json_element_t.parse('{
  "SCHEMA$" : "HR",
  "GRANTOR_IS_SCHEMA$" : 1,
  "OBJECT_TAB$" :
  [
    "%:PACKAGE\\_SPEC:DBMS\\_METADATA:%:%:%::%:%:%",
    "%:PACKAGE\\_SPEC:DBMS\\_VERSION:%:%:%::%:%:%",
    ":OBJECT\\_GRANT::%::DBMS\\_METADATA::%:%:%",
    ":OBJECT\\_GRANT::%::DBMS\\_VERSION::%:%:%"
  ],
  "OBJECT_CMP_TAB$" :
  [
    "~",
    "~",
    "~",
    "~"
  ],
  "NR_EXCLUDED_OBJECTS$" : 0,
  "MATCH_COUNT$" : 0,
  "MATCH_COUNT_OK$" : 0,
  "MATCH_PERC_THRESHOLD$" : 50
}');
    end case;

$if oracle_tools.pkg_schema_object_filter.c_debugging $then
    l_schema_object_filter.print();
$end

    ut.expect(serialize(l_schema_object_filter), 'test serialize ' || i_try).to_equal(l_expected);
  end loop;  

$if oracle_tools.pkg_schema_object_filter.c_debugging $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end ut_construct;

procedure ut_matches_schema_object
is
  l_id t_object;
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
          ).to_equal(case when l_object_tab(i_idx) = 'ORACLE_TOOLS:TABLE:schema_version_tools_ui:::::::' then 0 else 1 end);
        end if;
      end if;
    end loop;
  end loop try_loop;
end ut_matches_schema_object;

procedure ut_get_schema_objects
is
  pragma autonomous_transaction;

  l_schema_object_tab0 oracle_tools.t_schema_object_tab;
  l_schema_object_tab1 oracle_tools.t_schema_object_tab;
  l_schema t_schema;

  l_object_info_tab oracle_tools.t_object_info_tab;

  l_count pls_integer;

  l_program constant t_module := 'UT_GET_SCHEMA_OBJECTS';
begin
$if oracle_tools.pkg_schema_object_filter.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || l_program);
$end

$if oracle_tools.pkg_ddl_util.c_get_queue_ddl $then

  -- check queue tables
  for r in
  ( select  q.owner
    ,       q.queue_table
    from    all_queue_tables q
    where   rownum = 1
  )
  loop
    for i_test in 1..2
    loop
      select  count(*)
      into    l_count
      from    table
              ( oracle_tools.pkg_schema_object_filter.get_schema_objects
                ( r.owner
                , case i_test when 1 then null else 'AQ_QUEUE_TABLE' end
                , r.queue_table
                , 1
                )
              ) t
      where   t.object_type() in ('TABLE', 'AQ_QUEUE_TABLE');

      ut.expect(l_count, l_program || '#queue table count#' || r.owner || '.' || r.queue_table || '#' || i_test).to_equal(1);
    end loop;
  end loop;

$else

    /* ORA-00904: "KU$"."SCHEMA_OBJ"."TYPE": invalid identifier */

$end

  -- check materialized views, prebuilt or not
  for r in
  ( select  min(m.owner||'.'||m.mview_name) as mview_name
    ,       m.build_mode
    from    all_mviews m
    group by
            m.build_mode
  )
  loop
    for i_test in 1..3
    loop
      select  count(*)
      into    l_count
      from    table
              ( oracle_tools.pkg_schema_object_filter.get_schema_objects
                ( substr(r.mview_name, 1, instr(r.mview_name, '.')-1)
                , case i_test when 1 then null when 2 then 'MATERIALIZED_VIEW' when 3 then 'TABLE' end
                , substr(r.mview_name, instr(r.mview_name, '.')+1)
                , 1
                )
              ) t
      where   t.object_type() in ('TABLE', 'MATERIALIZED_VIEW');

      ut.expect
      ( l_count
      , l_program || '#mview count#' || r.mview_name || '#' || r.build_mode || '#' || i_test
      ).to_equal( case
                    when r.build_mode = 'PREBUILT'
                    then
                      case i_test
                        when 1
                        then 2 -- table and mv returned
                        else 1 -- else table or mv
                      end
                    else
                      case i_test
                        when 3
                        then 0 -- nothing returned
                        else 1 -- mv returned
                      end
                  end
                );
    end loop;
  end loop;

  -- check synonyms, indexes and triggers from this schema base on on abject from another schema
  for r in
  ( select  min(s.owner||'.'||s.synonym_name) as fq_object_name
    ,       'SYNONYM' as object_type
    from    all_synonyms s
    where   s.owner <> s.table_owner
    and     s.owner = user
    and     s.table_name is not null
    union
    select  min(t.owner||'.'||t.trigger_name) as fq_object_name
    ,       'TRIGGER' as object_type
    from    all_triggers t
    where   t.owner <> t.table_owner
    and     t.owner = user
    and     t.table_name is not null
    union
    select  min(i.owner||'.'||i.index_name) as fq_object_name
    ,       'INDEX' as object_type
    from    all_indexes i
    where   i.owner <> i.table_owner
    and     i.owner = user
    and     i.table_name is not null
$if oracle_tools.pkg_ddl_util.c_exclude_system_indexes $then
    and     i.generated = 'N'
$end      
  )
  loop
    if r.fq_object_name is not null
    then
      select  count(*)
      into    l_count
      from    table
              ( oracle_tools.pkg_schema_object_filter.get_schema_objects
                ( substr(r.fq_object_name, 1, instr(r.fq_object_name, '.')-1)
                , r.object_type
                , substr(r.fq_object_name, instr(r.fq_object_name, '.')+1)
                , 1
                )
              ) t;

      ut.expect
      ( l_count
      , l_program || '#object based on another schema count#' || r.fq_object_name
      ).to_equal(1);
    end if;
  end loop;

  commit;

$if oracle_tools.pkg_schema_object_filter.c_debugging $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end ut_get_schema_objects;

procedure ut_get_schema_object_filter
is
  l_schema_object_id_tab sys.odcivarchar2list;
  l_expected sys_refcursor;
  l_actual sys_refcursor;

  l_program constant t_module := $$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'UT_GET_SCHEMA_OBJECT_FILTER';
begin
$if oracle_tools.pkg_schema_object_filter.c_debugging $then
  dbug.enter(l_program);
$end

  select  id
  bulk collect
  into    l_schema_object_id_tab
  from    ( select  t.id() as id
            ,       row_number() over (partition by t.object_schema(), t.object_type() order by t.object_name() asc) as nr
            from    table
                    ( oracle_tools.pkg_schema_object_filter.get_schema_objects
                      ( p_schema => user
                      , p_object_type => null
                      , p_object_names => null
                      , p_object_names_include => null
                      , p_grantor_is_schema => 0
                      , p_exclude_objects => null
                      , p_include_objects => null
                      )
                    ) t
            order by
                    t.object_schema()
            ,       t.object_type()
          )
  where   nr = 1  
  ;

  for i_idx in l_schema_object_id_tab.first .. l_schema_object_id_tab.last
  loop
$if oracle_tools.pkg_schema_object_filter.c_debugging $then
    dbug.print(dbug."info", 'id: %s', l_schema_object_id_tab(i_idx));
$end

    open l_expected for
      select  l_schema_object_id_tab(i_idx) as id
      from    dual;
    open l_actual for
      select  t.id() as id
      from    table
              ( oracle_tools.pkg_schema_object_filter.get_schema_objects
                ( p_schema => user
                , p_include_objects => to_clob(l_schema_object_id_tab(i_idx))
                )
              ) t;
    ut.expect(l_actual, 'include ' || l_schema_object_id_tab(i_idx)).to_equal(l_expected);

    open l_expected for
      select  l_schema_object_id_tab(i_idx) as id
      from    dual
      where   0 = 1;
    open l_actual for
      select  t.id() as id
      from    table
              ( oracle_tools.pkg_schema_object_filter.get_schema_objects
                ( p_schema => user
                , p_exclude_objects => to_clob(l_schema_object_id_tab(i_idx))
                , p_include_objects => to_clob(l_schema_object_id_tab(i_idx))
                )
              ) t;
    ut.expect(l_actual, 'exclude and include ' || l_schema_object_id_tab(i_idx)).to_equal(l_expected);
end loop;

$if oracle_tools.pkg_schema_object_filter.c_debugging $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end ut_get_schema_object_filter;

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

