CREATE OR REPLACE PACKAGE BODY "ORACLE_TOOLS"."PKG_SCHEMA_OBJECT_FILTER" IS

subtype t_object is oracle_tools.pkg_ddl_util.t_object;
subtype t_numeric_boolean is oracle_tools.pkg_ddl_util.t_numeric_boolean;
subtype t_metadata_object_type is oracle_tools.pkg_ddl_util.t_metadata_object_type;
subtype t_md_object_type_tab is oracle_tools.pkg_ddl_util.t_md_object_type_tab;

"OBJECT SCHEMA" constant simple_integer := 1;
"OBJECT TYPE" constant simple_integer := 2;
"OBJECT NAME" constant simple_integer := 3;
"BASE OBJECT TYPE" constant simple_integer := 5;
"BASE OBJECT NAME" constant simple_integer := 6;

-- see static function T_SCHEMA_OBJECT.ID
c_nr_parts constant simple_integer := 10;

-- LOCAL

procedure cleanup_object(p_object in out nocopy varchar2)
is
begin
  -- remove TAB, CR and LF and then trim spaces
  p_object := trim(replace(replace(replace(p_object, chr(9)), chr(13)), chr(10)));
end cleanup_object;  

procedure matches_schema_object
( p_object_type in varchar2
, p_object_name in varchar2
, p_base_object_type in varchar2 default null
, p_base_object_name in varchar2 default null
, p_schema_object_filter in oracle_tools.t_schema_object_filter default null
, p_schema_object_id in varchar2 default null
, p_result out nocopy integer
, p_details out nocopy varchar2
)
is
$if oracle_tools.cfg_202410_pkg.c_improve_ddl_generation_performance $then

  function is_nested_table
  ( p_object_schema in varchar2
  , p_object_name in varchar2
  )
  return boolean
  is
    l_found pls_integer;
  begin
    if p_object_name not like 'SYSNT%' -- always treat them as nested table
    then
      -- otherwise use dictionary
      select  1
      into    l_found
      from    all_tables t
      where   t.owner = p_object_schema
      and     t.table_name = p_object_name
      and     t.nested = 'YES'; -- Exclude nested tables, their DDL is part of their parent table.
    end if;
    return true;
  exception
    when no_data_found
    then return false;
  end;

  -- NOTE: keep this in sync with pkg_ddl_util.is_exclude_name_expr() (i_object_exclude_name_expr_tab)
  procedure ignore_object
  ( p_object_type in varchar2
  , p_object_name in varchar2
  , p_base_object_type in varchar2
  , p_base_object_name in varchar2
  , p_result out nocopy integer
  , p_details out nocopy varchar2
  )
  is
  begin
    PRAGMA INLINE (is_nested_table, 'YES');
    p_result := 0;
    p_details := null;
    for i_case in -2 .. 16
    loop
      case i_case
        when -1
        then if p_object_type is null then p_details := 'object type null'; end if;
        
        when -2
        then if p_object_name is null then p_details := 'object name null'; end if;
        
        -- no dropped tables
        when 1
        then if p_object_type in ('TABLE', 'INDEX', 'TRIGGER', 'OBJECT_GRANT') and p_object_name like 'BIN$%' -- escape '\'
             then
               p_details := q'[object name like 'BIN$%']';
             end if;
        
        -- JAVA$CLASS$MD5$TABLE
        when 2
        then if p_object_type in ('TABLE') and p_object_name like 'JAVA$CLASS$MD5$TABLE' -- escape '\'
             then
               p_details := q'[object name like 'JAVA$CLASS$MD5$TABLE']';
             end if;
        
        -- no AQ indexes/views
        when 3
        then if p_object_type in ('INDEX', 'VIEW', 'OBJECT_GRANT') and p_object_name like 'AQ$%' -- escape '\'
             then
               p_details := q'[object name like 'AQ$%']';
             end if;
        
        -- no Flashback archive tables/indexes
        when 4
        then if p_object_type in ('TABLE', 'INDEX') and p_object_name like 'SYS\_FBA\_%' escape '\'
             then
               p_details := q'[object name like 'SYS\_FBA\_%' escape '\']';
             end if;
        
        -- no system generated indexes
        when 5
        then if p_object_type in ('INDEX') and p_object_name like 'SYS\_C%' escape '\'
             then
               p_details := q'[object name like 'SYS\_C%' escape '\']';
             end if;
        
        -- no generated types by declaring pl/sql table types in package specifications
        when 6
        then if p_object_type in ('SYNONYM', 'TYPE_SPEC', 'TYPE_BODY', 'OBJECT_GRANT') and p_object_name like 'SYS\_PLSQL\_%' escape '\'
             then
               p_details := q'[object name like 'SYS\_PLSQL\_%' escape '\']';
             end if;        
        
        -- see http://orasql.org/2012/04/28/a-funny-fact-about-collect/
        when 7
        then if p_object_type in ('SYNONYM', 'TYPE_SPEC', 'TYPE_BODY', 'OBJECT_GRANT') and p_object_name like 'SYSTP%' -- escape '\'
             then
               p_details := q'[object name like 'SYSTP%']';
             end if;        
        
        -- no datapump tables
        when 8
        then if p_object_type in ('TABLE', 'OBJECT_GRANT') and p_object_name like 'SYS\_SQL\_FILE\_SCHEMA%' escape '\'
             then
               p_details := q'[object name like 'SYS\_SQL\_FILE\_SCHEMA%' escape '\']';
             end if;        
        
        -- no datapump tables
        when 9
        then if p_object_type in ('TABLE', 'OBJECT_GRANT') and p_object_name like user || '\_DDL' escape '\'
             then
               p_details := q'[object name like user || '\_DDL' escape '\']';
             end if;
        
        -- no datapump tables
        when 10
        then if p_object_type in ('TABLE', 'OBJECT_GRANT') and p_object_name like user || '\_DML' escape '\'
             then
               p_details := q'[object name like user || '\_DML' escape '\']';
             end if;
        
        -- no Oracle generated datapump tables
        when 11
        then if p_object_type in ('TABLE', 'OBJECT_GRANT') and p_object_name like 'SYS\_EXPORT\_FULL\_%' escape '\'
             then
               p_details := q'[object name like 'SYS\_EXPORT\_FULL\_%' escape '\']';
             end if;
        
        -- no Flyway stuff and other Oracle things
        when 12
        then if p_object_type in ('TABLE', 'OBJECT_GRANT', 'INDEX', 'CONSTRAINT', 'REF_CONSTRAINT') and
                ( p_object_name like 'schema\_version%' escape '\' or
                  p_object_name like 'flyway\_schema\_history%' escape '\' or
                  p_object_name like 'CREATE$JAVA$LOB$TABLE%' /*escape '\'*/ )
             then
               p_details := q'[object name matches 'schema\_version%' or 'flyway\_schema\_history%' or 'CREATE$JAVA$LOB$TABLE%']';
             end if;
        
        -- no identity column sequences
        when 13
        then if p_object_type in ('SEQUENCE', 'OBJECT_GRANT') and p_object_name like 'ISEQ$$%' -- escape '\'
             then
               p_details := q'[object name like 'ISEQ$$%']';
             end if;        
        
        -- nested tables
        -- nested table indexes but here we must compare on base_object_name
        when 14
        then if p_object_type in ('TABLE', 'INDEX') and
                is_nested_table
                ( p_schema_object_filter.schema
                , case when p_object_type = 'TABLE' then p_object_name else p_base_object_name end
                )
             then
               p_details := q'[(base) object name is a nested table]';
             end if;
        
        -- no special type specs
        -- ORACLE_TOOLS:TYPE_SPEC:SYS_YOID0000142575$:::::::
        when 15
        then if p_object_type in ('TYPE_SPEC') and p_object_name like 'SYS\_YOID%' escape '\'
             then
               p_details := q'[object name like 'SYS\_YOID%' escape '\']';
             end if;        
        
        -- no nested table constraints
        -- /* SQL statement 16 (ALTER;ORACLE_TOOLS;CONSTRAINT;SYS_C0022887;ORACLE_TOOLS;TABLE;GENERATE_DDL_SESSION_BATCHES;;;;;2) */
        -- ALTER TABLE "ORACLE_TOOLS"."GENERATE_DDL_SESSION_BATCHES" DROP UNIQUE ("SYS_NC0001000011$") KEEP INDEX;
        when 16
        then if p_object_type in ('CONSTRAINT', 'REF_CONSTRAINT') and p_object_name like 'SYS\_NC%' escape '\'
             then
               p_details := q'[object name like 'SYS\_NC%' escape '\']';
             end if;
             
        else null;
      end case;
$if oracle_tools.pkg_schema_object_filter.c_debugging $then
      dbug.print
      ( dbug."info"
      , 'object type/name: "%s"; base object type/name: "%s"; ignore_object case: %s'
      , p_object_type || '|' || p_object_name
      , p_base_object_type || '|' || p_base_object_name
      , i_case
      );
$end
      if p_details is not null
      then
        p_details := 'case ' || to_char(i_case, 'FM00') || ': ' || p_details;
        p_result := i_case;
        exit;
      end if;
    end loop;
    -- just a check whether we correctly assigned p_details
    if (p_details is null) = (p_result = 0)
    then
      null; -- ok
    else
      raise program_error;
    end if;
    p_result := case when p_result >= 1 then 0 else 1 end;
  end ignore_object;

$end -- $if oracle_tools.cfg_202410_pkg.c_improve_ddl_generation_performance $then

  procedure search
  ( p_lwb in naturaln
  , p_upb in naturaln
  , p_result out nocopy integer
  , p_details out nocopy varchar2
  )
  is
    l_cmp simple_integer := -1;
  begin
    p_result := null;
    p_details := null;
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

      p_details :=
        utl_lms.format_message
        ( '[%s] compare "%s" "%s" "%s": %s'
        , to_char(i_idx)
        , p_schema_object_id
        , p_schema_object_filter.object_cmp_tab$(i_idx)
        , p_schema_object_filter.object_tab$(i_idx)
        , to_char(l_cmp)
        );

$if oracle_tools.pkg_schema_object_filter.c_debugging $then
      dbug.print(dbug."info", p_details);
$end

      case l_cmp
        when  0 then p_result := 1; exit; -- found: stop
        when -1 then p_result := 0; exit; -- will never find
        else null;
      end case;
    end loop search_loop;

    if p_result is null
    then
      p_details := null;
    end if;
    
    -- just a check whether we correctly assigned p_details
    if (p_details is null) = (p_result is null)
    then
      null; -- ok
    else
      raise program_error;
    end if;
    
    if p_result is null
    then
      if p_lwb <= p_upb then p_result := 0; end if;
    end if;
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
  , case when p_schema_object_filter is not null and p_schema_object_filter.object_tab$ is not null then p_schema_object_filter.object_tab$.count end
  , case when p_schema_object_filter is not null then p_schema_object_filter.nr_excluded_objects$ end
  );
$end

  PRAGMA INLINE (ignore_object, 'YES');
  PRAGMA INLINE (search, 'YES');

  p_result := 1;

  -- just a way to exit cases early
  <<result_loop>>
  loop
    -- exclude certain (semi-)dependent objects
    if p_base_object_type is not null and
       p_base_object_name is not null
    then
$if oracle_tools.pkg_schema_object_filter.c_debugging $then  
      dbug.print(dbug."info", 'case 1');
$end
$if not oracle_tools.cfg_202410_pkg.c_improve_ddl_generation_performance $then
      if oracle_tools.pkg_ddl_util.is_exclude_name_expr(p_base_object_type, p_base_object_name) = 1
      then
        p_result := 0;
      end if;
$else         
      ignore_object(p_base_object_type, p_base_object_name, null, null, p_result, p_details);
$end
       
      exit result_loop when p_result = 0;
    end if;

    -- exclude certain named objects
    if p_object_type is not null and
       p_object_name is not null
    then
$if oracle_tools.pkg_schema_object_filter.c_debugging $then  
      dbug.print(dbug."info", 'case 2');
$end
$if not oracle_tools.cfg_202410_pkg.c_improve_ddl_generation_performance $then
      if oracle_tools.pkg_ddl_util.is_exclude_name_expr(p_object_type, p_object_name) = 1
      then
        p_result := 0;
      end if;
$else         
      ignore_object(p_object_type, p_object_name, p_base_object_type, p_base_object_name, p_result, p_details);
$end

      exit result_loop when p_result = 0;
    end if;

    if p_schema_object_filter is null or
       p_schema_object_id is null or
       p_schema_object_filter.object_tab$ is null or
       p_schema_object_filter.object_tab$.count = 0
    then
$if oracle_tools.pkg_schema_object_filter.c_debugging $then  
      dbug.print(dbug."info", 'case 3');
$end
      p_result := 1;
      exit result_loop;
    end if;

    search(1, p_schema_object_filter.nr_excluded_objects$, p_result, p_details);    
    if p_result = 1
    then
$if oracle_tools.pkg_schema_object_filter.c_debugging $then  
      dbug.print(dbug."info", 'case 4');
$end
      -- any exclusion match; return 0
      p_result := 0; -- YES, correct we invert p_result
      exit result_loop;
    end if;

$if oracle_tools.pkg_schema_object_filter.c_debugging $then  
    dbug.print(dbug."info", 'case 5');
$end

    search
    ( p_schema_object_filter.nr_excluded_objects$ + 1
    , case
        when p_schema_object_filter is null or
             p_schema_object_filter.object_tab$ is null
        then 0
        else p_schema_object_filter.object_tab$.count
      end
    , p_result
    , p_details
    );
    -- check for inclusion match
    p_result := nvl
                ( p_result
                , 1 -- when there are no inclusions at all: OK
                );
    
    exit result_loop;
  end loop result_loop;

$if oracle_tools.pkg_schema_object_filter.c_debugging $then  
  dbug.print(dbug."output", 'p_result: %sl p_details: %s', p_result, p_details);
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end matches_schema_object;

procedure serialize
( p_schema_object_filter in oracle_tools.t_schema_object_filter
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
end serialize;

function repr
( p_schema_object_filter in oracle_tools.t_schema_object_filter
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

procedure construct
( p_schema in varchar2
, p_object_type in varchar2
, p_object_names in varchar2
, p_object_names_include in integer
, p_grantor_is_schema in integer
, p_exclude_objects in clob
, p_include_objects in clob
, p_schema_object_filter in out nocopy oracle_tools.t_schema_object_filter
)
is
  l_dependent_md_object_type_tab constant t_md_object_type_tab :=
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

    l_object := oracle_tools.t_schema_object.get_id
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
      l_object := oracle_tools.t_schema_object.get_id
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
  p_schema_object_filter.object_tab$ := oracle_tools.t_text_tab();
  p_schema_object_filter.object_cmp_tab$ := oracle_tools.t_text_tab();
  p_schema_object_filter.nr_excluded_objects$ := 0;

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
            -- let oracle_tools.t_schema_object.id decide about setting the base object type
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
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end  
end construct;

procedure matches_schema_object
( p_schema_object_filter in oracle_tools.t_schema_object_filter
, p_schema_object_id in varchar2
, p_result out nocopy integer 
, p_details out nocopy varchar2
)
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

  PRAGMA INLINE (matches_schema_object, 'YES');
  matches_schema_object
  ( p_object_type => l_part_tab("OBJECT TYPE")
  , p_object_name => l_part_tab("OBJECT NAME")
  , p_base_object_type => l_part_tab("BASE OBJECT TYPE")
  , p_base_object_name => l_part_tab("BASE OBJECT NAME")
  , p_schema_object_filter => p_schema_object_filter
  , p_schema_object_id => p_schema_object_id
  , p_result => p_result
  , p_details => p_details
  );
end matches_schema_object;

function matches_schema_object
( p_schema_object_filter in oracle_tools.t_schema_object_filter
, p_schema_object_id in varchar2
)
return integer
deterministic
is
  l_result integer;
  l_details varchar2(1000 char);
begin
  PRAGMA INLINE (matches_schema_object, 'YES');
  matches_schema_object
  ( p_schema_object_filter => p_schema_object_filter
  , p_schema_object_id => p_schema_object_id
  , p_result => l_result
  , p_details => l_details
  );
  
  return l_result;
end matches_schema_object;

function serialize
( p_schema_object_filter in oracle_tools.t_schema_object_filter
)
return json_object_t
is
  l_json_object json_object_t := json_object_t();
begin
$if oracle_tools.pkg_schema_object_filter.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.SERIALIZE');
$end

  serialize(p_schema_object_filter, l_json_object);

$if oracle_tools.pkg_schema_object_filter.c_debugging $then
  dbug.leave;
$end

  return l_json_object;
end serialize;

procedure print
( p_schema_object_filter in oracle_tools.t_schema_object_filter
)
is
  l_line_tab dbms_sql.varchar2a;
begin
-- !!! DO NOT use oracle_tools.pkg_schema_object_filter.c_debugging HERE !!!
$if oracle_tools.pkg_schema_object_filter.c_debugging $then  
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

$if oracle_tools.cfg_pkg.c_testing $then

procedure ut_construct
is
  l_schema_object_filter oracle_tools.t_schema_object_filter;
  l_expected json_element_t;
begin
$if oracle_tools.pkg_schema_object_filter.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'UT_CONSTRUCT');
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
  "NR_EXCLUDED_OBJECTS$" : 0
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
  "NR_EXCLUDED_OBJECTS$" : 0
}');

      when 3
      then
        l_schema_object_filter := oracle_tools.t_schema_object_filter
                                  ( p_schema => 'ORDSYS'
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
   "SCHEMA$" : "ORDSYS",
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
   "NR_EXCLUDED_OBJECTS$" : 12
 }');

      when 4
      then
        -- duplicate objects should be ignored
        l_schema_object_filter := oracle_tools.t_schema_object_filter
                                  ( p_schema => 'ORDSYS'
                                  , p_object_type => 'OBJECT_GRANT'
                                  , p_object_names => 'DBMS_OUTPUT,DBMS_OUTPUT,DBMS_SQL,DBMS_SQL'
                                  , p_object_names_include => 0
                                  , p_grantor_is_schema => 1
                                  , p_exclude_objects => null
                                  , p_include_objects => null
                                  );
        l_expected := json_element_t.parse('
{
  "SCHEMA$" : "ORDSYS",
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
  "NR_EXCLUDED_OBJECTS$" : 2
}');

      when 5
      then
        l_schema_object_filter := oracle_tools.t_schema_object_filter
                                  ( p_schema => 'ORDSYS'
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
   "SCHEMA$" : "ORDSYS",
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
   "NR_EXCLUDED_OBJECTS$" : 0
 }');

      when 6
      then
        l_schema_object_filter := oracle_tools.t_schema_object_filter
                                  ( p_schema => 'ORDSYS'
                                  , p_object_type => 'PACKAGE_SPEC'
                                  , p_object_names => 'DBMS_METADATA,DBMS_VERSION'
                                  , p_object_names_include => 1
                                  , p_grantor_is_schema => 1
                                  , p_exclude_objects => null
                                  , p_include_objects => null
                                  );
        l_expected := json_element_t.parse('{
  "SCHEMA$" : "ORDSYS",
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
  "NR_EXCLUDED_OBJECTS$" : 0
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

$end -- $if oracle_tools.cfg_pkg.c_testing $then

end pkg_schema_object_filter;
/

