CREATE OR REPLACE PACKAGE BODY "ORACLE_TOOLS"."SCHEMA_OBJECTS_API" IS /* -*-coding: utf-8-*- */

-- PRIVATE
subtype t_module is varchar2(100);
subtype t_numeric_boolean is oracle_tools.pkg_ddl_util.t_numeric_boolean;
subtype t_schema_nn is oracle_tools.pkg_ddl_util.t_schema_nn;

-- steps in get_schema_objects
"named objects" constant varchar2(30 char) := 'base objects';
"object grants" constant varchar2(30 char) := 'object grants';
"synonyms" constant varchar2(30 char) := 'synonyms';
"comments" constant varchar2(30 char) := 'comments';
"constraints" constant varchar2(30 char) := 'constraints';
"triggers" constant varchar2(30 char) := 'triggers';
"indexes" constant varchar2(30 char) := 'indexes';

c_steps constant sys.odcivarchar2list :=
  sys.odcivarchar2list
  ( "named objects"                 -- no base object
  , "object grants"                 -- base object (named)
  , "synonyms"                      -- base object (named)
  , "comments"                      -- base object (named)
  , "constraints"                   -- base object (named)
  , "triggers"                      -- base object (NOT named)
  , "indexes"                       -- base object (NOT named)
  );

procedure get_named_objects
( p_schema in varchar2
, p_schema_object_tab out nocopy oracle_tools.t_schema_object_tab
)
is
  type t_excluded_tables_tab is table of boolean index by all_tables.table_name%type;

  l_excluded_tables_tab t_excluded_tables_tab;

  l_schema_md_object_type_tab constant pkg_ddl_util.t_md_object_type_tab :=
    oracle_tools.pkg_ddl_util.get_md_object_type_tab('SCHEMA');
begin
$if oracle_tools.schema_objects_api.c_tracing $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'GET_NAMED_OBJECTS');
$if oracle_tools.schema_objects_api.c_debugging $then
  dbug.print(dbug."input", 'p_schema: %s', p_schema);
$end  
$end

  p_schema_object_tab := oracle_tools.t_schema_object_tab();

  for i_idx in 1 .. 4
  loop
$if oracle_tools.schema_objects_api.c_debugging $then
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

$if oracle_tools.schema_objects_api.c_debugging $then
          dbug.print(dbug."info", 'excluding queue table: %s', r.object_name);
$end

$if oracle_tools.pkg_ddl_util.c_get_queue_ddl $then

          p_schema_object_tab.extend(1);
          p_schema_object_tab(p_schema_object_tab.last) :=          
            oracle_tools.t_named_object.create_named_object
            ( p_object_schema => r.object_schema
            , p_object_type => r.object_type
            , p_object_name => r.object_name
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

$if oracle_tools.schema_objects_api.c_debugging $then
            dbug.print(dbug."info", 'excluding materialized view table: %s', r.object_name);
$end
          end if;

          -- this is a special case since we need to exclude first
          p_schema_object_tab.extend(1);
          p_schema_object_tab(p_schema_object_tab.last) :=          
            oracle_tools.t_materialized_view_object(r.object_schema, r.object_name);
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
            p_schema_object_tab.extend(1);
            p_schema_object_tab(p_schema_object_tab.last) :=          
              oracle_tools.t_table_object(r.object_schema, r.object_name, r.tablespace_name);

$if oracle_tools.schema_objects_api.c_debugging $then
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
          p_schema_object_tab.extend(1);
          p_schema_object_tab(p_schema_object_tab.last) :=          
            oracle_tools.t_named_object.create_named_object
            ( p_object_schema => r.object_schema
            , p_object_type => r.object_type
            , p_object_name => r.object_name
            );
        end loop;        
    end case;
  end loop;

$if oracle_tools.schema_objects_api.c_tracing $then
$if oracle_tools.schema_objects_api.c_debugging $then
  dbug.print(dbug."output", 'p_schema_object_tab.count: %s', p_schema_object_tab.count);
$end  
  dbug.leave;
$end

$if oracle_tools.schema_objects_api.c_tracing $then
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end get_named_objects;

procedure add_schema_objects
( p_schema_object_filter in oracle_tools.t_schema_object_filter
, p_schema_object_filter_id in positiven
)
is
$if oracle_tools.schema_objects_api.c_tracing $then
  l_module_name constant dbug.module_name_t := $$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'ADD_SCHEMA_OBJECTS';
$end  
  l_schema_md_object_type_tab constant oracle_tools.t_text_tab :=
    oracle_tools.pkg_ddl_util.get_md_object_type_tab('SCHEMA');
  l_tmp_schema_object_tab oracle_tools.t_schema_object_tab;
  l_all_schema_object_tab oracle_tools.t_schema_object_tab := oracle_tools.t_schema_object_tab();

  type t_excluded_tables_tab is table of boolean index by all_tables.table_name%type;

  l_excluded_tables_tab t_excluded_tables_tab;
  l_schema constant t_schema_nn := p_schema_object_filter.schema();
  l_grantor_is_schema constant t_numeric_boolean := p_schema_object_filter.grantor_is_schema();
  l_step varchar2(30 char);
  l_longops_rec oracle_tools.api_longops_pkg.t_longops_rec :=
    oracle_tools.api_longops_pkg.longops_init
    ( p_target_desc => 'procedure ' || 'ADD_SCHEMA_OBJECTS'
    , p_totalwork => 10
    , p_op_name => 'what'
    , p_units => 'steps'
    );

  procedure cleanup
  is
  begin
    oracle_tools.api_longops_pkg.longops_done(l_longops_rec);
  end cleanup;
begin
$if oracle_tools.schema_objects_api.c_tracing $then
  dbug.enter(l_module_name);
--$if oracle_tools.schema_objects_api.c_debugging $then
  p_schema_object_filter.print();
--$end  
$end

  for i_idx in c_steps.first .. c_steps.last
  loop
    l_step := c_steps(i_idx);
    -- essential to keep this line here
    l_tmp_schema_object_tab := oracle_tools.t_schema_object_tab();

$if oracle_tools.schema_objects_api.c_tracing $then
    dbug.enter(l_module_name || '.' || l_step);
$end    

    case l_step
      when "named objects"
      then
        get_named_objects
        ( p_schema => l_schema
        , p_schema_object_tab => l_tmp_schema_object_tab
        );
        -- so they will be part of v_my_schema_objects from this point on
        oracle_tools.ddl_crud_api.add
        ( p_schema_object_tab => l_tmp_schema_object_tab
        , p_schema_object_filter_id => p_schema_object_filter_id
        );
        l_tmp_schema_object_tab.delete;

      -- object grants must depend on a base object already gathered (see above)
      when "object grants"
      then
        select  oracle_tools.t_object_grant_object
                ( p_base_object => value(mnso)
                , p_object_schema => null
                , p_grantee => p.grantee
                , p_privilege => p.privilege
                , p_grantable => p.grantable
                )
        bulk collect
        into    l_tmp_schema_object_tab                  
        from    oracle_tools.v_my_named_schema_objects mnso
                inner join oracle_tools.v_my_object_grants_dict p
                on p.base_object_schema = mnso.object_schema() and p.base_object_name = mnso.object_name()
        where   mnso.object_type() not in ( 'PACKAGE_BODY'
                                          , 'TYPE_BODY'
                                          , 'MATERIALIZED_VIEW' -- grants are on underlying tables
                                          ); 
        
      when "comments"
      then
        with v_my_comments_dict as
        ( select  c.base_object_schema
          ,       c.base_object_type
          ,       c.base_object_name
          ,       c.column_name
          from    ( -- table/view comments
                    select  t.owner             as base_object_schema
                    ,       t.table_type        as base_object_type
                    ,       t.table_name        as base_object_name
                    ,       null                as column_name
                    from    all_tab_comments t
                    where   t.table_type in ('TABLE', 'VIEW')
                    and     t.comments is not null
                    union all
                    -- materialized view comments
                    select  m.owner             
                    ,       'MATERIALIZED_VIEW'
                    ,       m.mview_name        
                    ,       null                
                    from    all_mview_comments m
                    where   m.comments is not null
                    union all
                    -- column comments
                    select  c.owner             
                    ,       ( select  o.object_type
                              from    all_objects o
                              where   o.owner = c.owner
                              and     o.object_name = c.table_name
                            )                   
                    ,       c.table_name        
                    ,       c.column_name       
                    from    all_col_comments c
                    where   c.comments is not null
                  ) c
        )
        select  oracle_tools.t_comment_object
                ( p_base_object => treat(value(mnso) as oracle_tools.t_named_object)
                , p_object_schema => c.base_object_schema
                , p_column_name => c.column_name
                )
        bulk collect
        into    l_tmp_schema_object_tab                  
        from    oracle_tools.v_my_named_schema_objects mnso
                inner join v_my_comments_dict c
                on c.base_object_schema = mnso.object_schema() and
                   c.base_object_type = mnso.object_type() and
                   c.base_object_name = mnso.object_name() and
                   mnso.dict_object_type() in ('TABLE', 'VIEW', 'MATERIALIZED VIEW');

      -- constraints must depend on a base object already gathered
      when "constraints"
      then
        for r in
        ( -- constraints for objects in the same schema
          with v_my_constraints_dict as
          ( select  t.object_schema
            ,       t.object_type
            ,       t.object_name
            ,       t.base_object_schema
            ,       t.base_object_name
            ,       t.constraint_type
            ,       t.search_condition
            from    ( select  c.owner as object_schema
                      ,       case when c.constraint_type = 'R' then 'REF_CONSTRAINT' else 'CONSTRAINT' end as object_type
                      ,       c.constraint_name as object_name
                      ,       c.owner as base_object_schema
                      ,       c.table_name as base_object_name
                      ,       c.constraint_type
                      ,       c.search_condition
                      from    all_constraints c
                      where   /* Type of constraint definition:
                                 C (check constraint on a table)
                                 P (primary key)
                                 U (unique key)
                                 R (referential integrity)
                                 V (with check option, on a view)
                                 O (with read only, on a view)
                              */
                              c.constraint_type in ('C', 'P', 'U', 'R')
                    ) t
          )
          select  t.*
          from    ( select  value(mnso) as base_object
                    ,       c.object_schema
                    ,       c.object_type
                    ,       c.object_name
                    ,       c.constraint_type
                    ,       c.search_condition
                    from    oracle_tools.v_my_named_schema_objects mnso
                            inner join v_my_constraints_dict c /* this is where we are interested in */
                            on c.base_object_schema = mnso.object_schema() and c.base_object_name = mnso.object_name()
                    where   mnso.object_type() in ('TABLE', 'VIEW')
                  ) t
        )
        loop
          l_tmp_schema_object_tab.extend(1);

          case r.object_type
            when 'REF_CONSTRAINT'
            then
              l_tmp_schema_object_tab(l_tmp_schema_object_tab.last) :=
                oracle_tools.t_ref_constraint_object
                ( p_base_object => treat(r.base_object as oracle_tools.t_named_object)
                , p_object_schema => r.object_schema
                , p_object_name => r.object_name
                , p_constraint_type => r.constraint_type
                , p_column_names => null
                );

            when 'CONSTRAINT'
            then
              l_tmp_schema_object_tab(l_tmp_schema_object_tab.last) :=
                oracle_tools.t_constraint_object
                ( p_base_object => treat(r.base_object as oracle_tools.t_named_object)
                , p_object_schema => r.object_schema
                , p_object_name => r.object_name
                , p_constraint_type => r.constraint_type
                , p_search_condition => r.search_condition
                );
          end case;
        end loop;

      -- these are not dependent on named objects:
      -- * private synonyms from this schema pointing to a base object in ANY schema possible
      -- * triggers from this schema pointing to a base object in ANY schema possible
      when "synonyms"
      then
        -- private synonyms for this schema which may point to another schema
        with syn as
        ( select  /*+ MATERIALIZE */
                  s.owner
          ,       s.synonym_name
          ,       s.table_owner
          ,       s.table_name
          ,       s.db_link
          from    all_synonyms s
          where   ( s.owner = 'PUBLIC' and s.table_owner = l_schema ) -- public synonyms
          or      ( s.owner = l_schema )
        )
        select  oracle_tools.t_schema_object.create_schema_object
                ( p_object_schema => s.owner
                , p_object_type => 'SYNONYM'
                , p_object_name => s.synonym_name
                , p_base_object_schema => s.table_owner
                , p_base_object_type =>
                    nvl
                    ( case
                        when s.db_link is null
                        then ( select  max(mnso.object_type())
                               from    oracle_tools.v_my_named_schema_objects mnso
                               where   mnso.object_schema() = s.table_owner
                               and     mnso.object_name() = s.table_name
                               and     mnso.object_type() not in ('PACKAGE_BODY', 'TYPE_BODY', 'MATERIALIZED_VIEW')
                             )
                      end
                    , 'TABLE' -- assume its a table when the object could not be found (in this database schema)
                    )
                , p_base_object_name => s.table_name
                )
        bulk collect
        into    l_tmp_schema_object_tab
        from    syn s;

      when "triggers"
      then
        select  oracle_tools.t_schema_object.create_schema_object
                ( p_object_schema => t.object_schema
                , p_object_type => t.object_type
                , p_object_name => t.object_name
                , p_base_object_schema => t.base_object_schema
                , p_base_object_type => t.base_object_type
                , p_base_object_name => t.base_object_name
                , p_column_name => t.column_name
                )
        bulk collect
        into    l_tmp_schema_object_tab
        from    ( -- triggers for this schema which may point to another schema
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
                ) t;

      -- these are not dependent on named objects:
      -- * indexes from this schema pointing to a base object in ANY schema possible
      when "indexes"
      then
        select  oracle_tools.t_index_object
                ( p_base_object =>
                    oracle_tools.t_named_object.create_named_object
                    ( p_object_schema => i.table_owner
                    , p_object_type => i.table_type
                    , p_object_name => i.table_name
                    )
                , p_object_schema => i.owner
                , p_object_name => i.index_name
                , p_tablespace_name => i.tablespace_name
                )
        bulk collect
        into    l_tmp_schema_object_tab
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
        ;
    end case;

$if oracle_tools.schema_objects_api.c_tracing $then
    dbug.print(dbug."info", 'cardinality(l_tmp_schema_object_tab): %s', cardinality(l_tmp_schema_object_tab));
$end

    if l_tmp_schema_object_tab.count > 0
    then
      -- this is real fast
      l_all_schema_object_tab := l_all_schema_object_tab multiset union all l_tmp_schema_object_tab;
    end if;
    oracle_tools.api_longops_pkg.longops_show(l_longops_rec);

$if oracle_tools.schema_objects_api.c_tracing $then
    dbug.print(dbug."info", 'cardinality(l_all_schema_object_tab): %s', cardinality(l_all_schema_object_tab));
$end    

$if oracle_tools.schema_objects_api.c_tracing $then
    dbug.leave;
$end    
  end loop;

  oracle_tools.ddl_crud_api.add
  ( p_schema_object_tab => l_all_schema_object_tab
  , p_schema_object_filter_id => p_schema_object_filter_id
  );

  cleanup;

$if oracle_tools.schema_objects_api.c_tracing $then
  dbug.leave;
$end

exception
  when others
  then
    cleanup;
$if oracle_tools.schema_objects_api.c_tracing $then
    dbug.leave_on_error;
$end
    raise;
end add_schema_objects;

-- PUBLIC

/**/

procedure add
( p_schema_object_filter in oracle_tools.t_schema_object_filter
, p_generate_ddl_configuration_id in integer -- the GENERATE_DDL_CONFIGURATIONS.ID
, p_add_schema_objects in boolean
)
is
  l_schema_object_filter_id integer := null;
$if oracle_tools.schema_objects_api.c_tracing $then
  l_module_name constant dbug.module_name_t := $$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'ADD (T_SCHEMA_OBJECT_FILTER)';
$end
begin
$if oracle_tools.schema_objects_api.c_tracing $then
  dbug.enter(l_module_name);
$if oracle_tools.schema_objects_api.c_debugging $then
  dbug.print(dbug."input", 'p_add_schema_objects: %s', p_add_schema_objects);
  dbug.print(dbug."input", 'p_generate_ddl_configuration_id: %s', p_generate_ddl_configuration_id);  
$end
$end

  oracle_tools.ddl_crud_api.add
  ( p_schema_object_filter => p_schema_object_filter
  , p_generate_ddl_configuration_id => p_generate_ddl_configuration_id
  , p_schema_object_filter_id => l_schema_object_filter_id
  );

  if p_add_schema_objects
  then
    add_schema_objects
    ( p_schema_object_filter => p_schema_object_filter
    , p_schema_object_filter_id => l_schema_object_filter_id
    );
  end if;

$if oracle_tools.schema_objects_api.c_tracing $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end add;

procedure get_schema_objects
( p_schema_object_filter in oracle_tools.t_schema_object_filter
, p_generate_ddl_configuration_id in integer -- the GENERATE_DDL_CONFIGURATIONS.ID
, p_schema_object_tab out nocopy oracle_tools.t_schema_object_tab
)
is
  l_schema_object_filter_id positiven := 1;
$if oracle_tools.schema_objects_api.c_tracing $then
  l_module_name constant dbug.module_name_t := $$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'GET_SCHEMA_OBJECTS (1)';
$end
begin
$if oracle_tools.schema_objects_api.c_tracing $then
  dbug.enter(l_module_name);
$end

  add
  ( p_schema_object_filter => p_schema_object_filter
  , p_generate_ddl_configuration_id => p_generate_ddl_configuration_id
  , p_add_schema_objects => true
  );
  
  select  value(t) as obj
  bulk collect
  into    p_schema_object_tab
  from    oracle_tools.v_my_schema_objects t;

$if oracle_tools.schema_objects_api.c_tracing $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end get_schema_objects;

function get_schema_objects
( p_schema in varchar2
, p_object_type in varchar2
, p_object_names in varchar2
, p_object_names_include in integer
, p_grantor_is_schema in integer
, p_exclude_objects in clob
, p_include_objects in clob
, p_transform_param_list in varchar2
)
return oracle_tools.t_schema_object_tab
pipelined
is
  pragma autonomous_transaction;
  
  l_schema_object_filter oracle_tools.t_schema_object_filter := null;
  l_generate_ddl_configuration_id integer := null;
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
    -- on error save so we can verify else rollback because we do not need the data
    oracle_tools.api_longops_pkg.longops_done(l_longops_rec);
  end cleanup;
begin
$if oracle_tools.schema_objects_api.c_tracing $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'GET_SCHEMA_OBJECTS');
$end

  oracle_tools.ddl_crud_api.add
  ( p_schema => p_schema
  , p_object_type => p_object_type
  , p_object_names => p_object_names
  , p_object_names_include => p_object_names_include
  , p_grantor_is_schema => p_grantor_is_schema
  , p_exclude_objects => p_exclude_objects
  , p_include_objects => p_include_objects
  , p_transform_param_list => p_transform_param_list
  , p_schema_object_filter => l_schema_object_filter
  , p_generate_ddl_configuration_id => l_generate_ddl_configuration_id
  );
  add
  ( p_schema_object_filter => l_schema_object_filter
  , p_generate_ddl_configuration_id => l_generate_ddl_configuration_id
  , p_add_schema_objects => true
  );

  commit; -- must be done before the pipe row

  for r in ( select value(t) as obj from oracle_tools.v_my_schema_objects t )
  loop
    pipe row (r.obj);
    oracle_tools.api_longops_pkg.longops_show(l_longops_rec);
  end loop;

  cleanup;

$if oracle_tools.schema_objects_api.c_tracing $then
  dbug.leave;
$end

  return; -- essential for pipelined functions
exception
  when no_data_needed
  then
    -- not a real error, just a way to some cleanup
    cleanup;
$if oracle_tools.schema_objects_api.c_tracing $then
    dbug.leave;
$end

  when no_data_found
  then
    cleanup;
    commit;
$if oracle_tools.schema_objects_api.c_tracing $then
    dbug.leave_on_error;
$end
    oracle_tools.pkg_ddl_error.reraise_error(l_program);
    raise; -- to keep the compiler happy

  when others
  then
    cleanup;
    commit;
$if oracle_tools.schema_objects_api.c_tracing $then
    dbug.leave_on_error;
$end
    raise;
end get_schema_objects;

$if oracle_tools.cfg_pkg.c_testing $then

procedure ut_get_schema_objects
is
  pragma autonomous_transaction;

  l_schema_object_tab0 oracle_tools.t_schema_object_tab;
  l_schema_object_tab1 oracle_tools.t_schema_object_tab;
  l_schema t_schema;

  l_count pls_integer;

  l_program constant t_module := 'UT_GET_SCHEMA_OBJECTS';
begin
$if oracle_tools.schema_objects_api.c_debugging $then
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
              ( oracle_tools.schema_objects_api.get_schema_objects
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
              ( oracle_tools.schema_objects_api.get_schema_objects
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
              ( oracle_tools.schema_objects_api.get_schema_objects
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

$if oracle_tools.schema_objects_api.c_debugging $then
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
$if oracle_tools.schema_objects_api.c_debugging $then
  dbug.enter(l_program);
$end

  select  id
  bulk collect
  into    l_schema_object_id_tab
  from    ( select  t.id as id
            ,       row_number() over (partition by t.object_schema(), t.object_type() order by t.object_name() asc) as nr
            from    table
                    ( oracle_tools.schema_objects_api.get_schema_objects
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
$if oracle_tools.schema_objects_api.c_debugging $then
    dbug.print(dbug."info", 'id: %s', l_schema_object_id_tab(i_idx));
$end

    open l_expected for
      select  l_schema_object_id_tab(i_idx) as id
      from    dual;
    open l_actual for
      select  t.id as id
      from    table
              ( oracle_tools.schema_objects_api.get_schema_objects
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
      select  t.id as id
      from    table
              ( oracle_tools.schema_objects_api.get_schema_objects
                ( p_schema => user
                , p_exclude_objects => to_clob(l_schema_object_id_tab(i_idx))
                , p_include_objects => to_clob(l_schema_object_id_tab(i_idx))
                )
              ) t;
    ut.expect(l_actual, 'exclude and include ' || l_schema_object_id_tab(i_idx)).to_equal(l_expected);
end loop;

$if oracle_tools.schema_objects_api.c_debugging $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end ut_get_schema_object_filter;

$end

END SCHEMA_OBJECTS_API;
/

