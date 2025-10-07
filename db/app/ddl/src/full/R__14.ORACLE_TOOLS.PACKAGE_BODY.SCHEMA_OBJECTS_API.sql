CREATE OR REPLACE PACKAGE BODY "ORACLE_TOOLS"."SCHEMA_OBJECTS_API" IS /* -*-coding: utf-8-*- */

-- PRIVATE
subtype t_module is varchar2(100);
subtype t_numeric_boolean is oracle_tools.pkg_ddl_defs.t_numeric_boolean;
subtype t_schema is oracle_tools.pkg_ddl_defs.t_schema;
subtype t_schema_nn is oracle_tools.pkg_ddl_defs.t_schema_nn;

-- steps in get_schema_objects
"named objects" constant varchar2(30 char) := 'base objects';
"object grants" constant varchar2(30 char) := 'OBJECT_GRANT'; -- from here on use a known metadata object type
"synonyms" constant varchar2(30 char) := 'SYNONYM';
"comments" constant varchar2(30 char) := 'COMMENT';
"constraints" constant varchar2(30 char) := 'CONSTRAINT';
"referential constraints" constant varchar2(30 char) := 'REF_CONSTRAINT';
"triggers" constant varchar2(30 char) := 'TRIGGER';
"indexes" constant varchar2(30 char) := 'INDEX';

c_steps constant sys.odcivarchar2list :=
  sys.odcivarchar2list
  ( "named objects"                 -- no base object
  , "object grants"                 -- base object (named)
  , "synonyms"                      -- base object (named)
  , "comments"                      -- base object (named)
  , "constraints"                   -- base object (named)
  , "referential constraints"       -- base object (named)
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

  l_schema_md_object_type_tab constant oracle_tools.pkg_ddl_defs.t_md_object_type_tab :=
    oracle_tools.pkg_ddl_defs.get_md_object_type_tab('SCHEMA');
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

$if oracle_tools.pkg_ddl_defs.c_get_queue_ddl $then

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
$if oracle_tools.pkg_ddl_defs.c_exclude_system_objects $then
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
                    -- use scalar subqueries for a (possible) better performance
            ,       ( select substr(oracle_tools.t_schema_object.dict2metadata_object_type(obj.object_type), 1, 23) from dual ) as md_object_type
            ,       ( select oracle_tools.pkg_ddl_defs.is_dependent_object_type(obj.object_type) from dual ) as is_dependent_object_type
            from    all_objects obj
            where   obj.owner = p_schema
            and     obj.object_type not in ('QUEUE', 'MATERIALIZED VIEW', 'TABLE', 'TRIGGER', 'INDEX', 'SYNONYM')
            and     not( obj.object_type = 'SEQUENCE' and substr(obj.object_name, 1, 5) = 'ISEQ$' )
$if oracle_tools.pkg_ddl_defs.c_exclude_system_objects $then
            and     obj.generated = 'N' -- GPA 2016-12-19 #136334705
$end                
                    -- OWNER         OBJECT_NAME                      SUBOBJECT_NAME
                    -- =====         ===========                      ==============
                    -- ORACLE_TOOLS  oracle_tools.t_table_column_ddl  $VSN_1
            and     obj.subobject_name is null
          )
          select  o.owner as object_schema
          ,       o.md_object_type as object_type
          ,       o.object_name
          from    obj o
          where   o.md_object_type member of l_schema_md_object_type_tab
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
  for i_idx in 1..p_schema_object_tab.count
  loop
    dbug.print(dbug."output", 'p_schema_object_tab(%s)', i_idx);
    p_schema_object_tab(i_idx).print();
  end loop;
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
, p_step in varchar2
, p_schema_object_tab out nocopy oracle_tools.t_schema_object_tab
)
is
$if oracle_tools.schema_objects_api.c_tracing $then
  l_module_name constant dbug.module_name_t := $$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'ADD_SCHEMA_OBJECTS (1)';
$end
  l_schema constant t_schema_nn := p_schema_object_filter.schema();
  l_grantor_is_schema constant t_numeric_boolean := p_schema_object_filter.grantor_is_schema();
  l_my_named_objects_count pls_integer := null;
begin
$if oracle_tools.schema_objects_api.c_tracing $then
  dbug.enter(l_module_name);
$if oracle_tools.schema_objects_api.c_debugging $then
  dbug.print
  ( dbug."input"
  , 'p_schema_object_filter not null?: %s; p_schema_object_filter_id: %s; p_step: %s: schema: %s; grantor_is_schema: %s'
  , dbug.cast_to_varchar2(p_schema_object_filter is not null)
  , p_schema_object_filter_id
  , p_step
  , l_schema
  , l_grantor_is_schema
  );
  if p_schema_object_filter is not null
  then
    p_schema_object_filter.print();
  end if;
$end  
$end

  case p_step
    when "named objects"
    then
      get_named_objects
      ( p_schema => l_schema
      , p_schema_object_tab => p_schema_object_tab
      );
      -- must immediately insert (and empty)
      oracle_tools.ddl_crud_api.add
      ( p_schema_object_tab => p_schema_object_tab
      , p_schema_object_filter_id => p_schema_object_filter_id
      , p_schema_object_filter => p_schema_object_filter
      );
      p_schema_object_tab.delete;
      -- there must be something in oracle_tools.v_my_named_schema_objects mnso
      select  count(*)
      into    l_my_named_objects_count
      from    oracle_tools.v_my_named_schema_objects mnso;

      if l_my_named_objects_count = 0
      then
        oracle_tools.pkg_ddl_error.raise_error
        ( oracle_tools.pkg_ddl_error.c_object_not_found
        , 'There are no named objects (ORACLE_TOOLS.V_MY_NAMED_SCHEMA_OBJECTS)'
        , oracle_tools.ddl_crud_api.get_session_id
        , 'session id'
        );
      end if;

$if oracle_tools.schema_objects_api.c_debugging $then
      dbug.print(dbug."info", 'l_my_named_objects_count: %s', l_my_named_objects_count);
$end

    -- object grants must depend on a base object already gathered (see above)
    when "object grants"
    then
      with v_my_object_grants_dict as
      ( select  p.table_schema as base_object_schema
        ,       p.table_name as base_object_name
        ,       p.grantee
        ,       p.privilege
                -- several grantors may have executed the same grant statement
        ,       max(p.grantable) as grantable -- YES comes after NO
        from    all_tab_privs p
        where   l_schema = p.table_schema
        and     ( l_grantor_is_schema = 0 or p.grantor = l_schema )
        and     p.grantee <> 'ADMIN' -- https://github.com/paulissoft/oracle-tools/issues/187
        group by
                p.table_schema
        ,       p.table_name
        ,       p.grantee
        ,       p.privilege
      )
      select  oracle_tools.t_object_grant_object
              ( p_base_object => value(mnso)
              , p_object_schema => null
              , p_grantee => p.grantee
              , p_privilege => p.privilege
              , p_grantable => p.grantable
              )
      bulk collect
      into    p_schema_object_tab                  
      from    oracle_tools.v_my_named_schema_objects mnso
              inner join v_my_object_grants_dict p
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
                  where   t.owner = l_schema
                  and     t.table_type in ('TABLE', 'VIEW')
                  and     t.comments is not null
                  union all
                  -- materialized view comments
                  select  m.owner             
                  ,       'MATERIALIZED_VIEW'
                  ,       m.mview_name        
                  ,       null                
                  from    all_mview_comments m
                  where   m.owner = l_schema
                  and     m.comments is not null
                  union all
                  -- column comments
                  select  c.owner
                  ,       ( select  o.object_type
                            from    all_objects o
                            where   o.owner = c.owner
                            and     o.object_name = c.table_name
                            -- GJP 2025-10-07
                            -- Getting this error (ORA-01427: single-row subquery returns more than one row) (BOOCPP15J).
                            -- Solution: added next line since OCPPMESSAGE had a TABLE and a TABLE PARTITION object (!).
                            and     o.object_type in ('TABLE', 'VIEW')
                          )
                  ,       c.table_name        
                  ,       c.column_name       
                  from    all_col_comments c
                  where   c.owner = l_schema
                  and     c.comments is not null
                ) c
      )
      select  oracle_tools.t_comment_object
              ( p_base_object => treat(value(mnso) as oracle_tools.t_named_object)
              , p_object_schema => c.base_object_schema
              , p_column_name => c.column_name
              )
      bulk collect
      into    p_schema_object_tab                  
      from    oracle_tools.v_my_named_schema_objects mnso
              inner join v_my_comments_dict c
              on c.base_object_schema = mnso.object_schema() and
                 c.base_object_type = mnso.object_type() and
                 c.base_object_name = mnso.object_name() and
                 mnso.dict_object_type() in ('TABLE', 'VIEW', 'MATERIALIZED VIEW');

    -- constraints must depend on a base object already gathered
    when "constraints"
    then
      p_schema_object_tab := oracle_tools.t_schema_object_tab();
      for r in
      ( -- constraints for objects in the same schema
        with v_my_constraints_dict as
        ( select  c.owner as object_schema
          ,       'CONSTRAINT' as object_type
          ,       c.constraint_name as object_name
          ,       c.owner as base_object_schema
          ,       c.table_name as base_object_name
          ,       c.constraint_type
          ,       c.search_condition
          from    all_constraints c
          where   c.owner = l_schema
          and     /* Type of constraint definition:
                     C (check constraint on a table)
                     P (primary key)
                     U (unique key)
                     R (referential integrity)
                     V (with check option, on a view)
                     O (with read only, on a view)
                  */
                  c.constraint_type in ('C', 'P', 'U')
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
        p_schema_object_tab.extend(1);
        p_schema_object_tab(p_schema_object_tab.last) :=
          oracle_tools.t_constraint_object
          ( p_base_object => treat(r.base_object as oracle_tools.t_named_object)
          , p_object_schema => r.object_schema
          , p_object_name => r.object_name
          , p_constraint_type => r.constraint_type
          , p_search_condition => r.search_condition
          );
      end loop;

    -- constraints must depend on a base object already gathered
    when "referential constraints"
    then
      -- constraints for objects in the same schema
      with v_my_constraints_dict as
      ( select  -- REFERENTIAL CONSTRAINT
                r.owner as object_schema
        ,       'REF_CONSTRAINT' as object_type
        ,       r.constraint_name as object_name
        ,       r.constraint_type
        ,       ro.object_type as base_object_type
        ,       r.owner as base_object_schema
        ,       r.table_name as base_object_name
                -- PRIMARY/UNIQUE KEY CONSTRAINT
        ,       k.owner as ref_object_schema -- referential constraint can be in another schema
        ,       'CONSTRAINT' as ref_object_type
        ,       k.constraint_name as ref_object_name
        ,       k.constraint_type as ref_constraint_type
        ,       ko.object_type as base_ref_object_type
        ,       k.owner as base_ref_object_schema
        ,       k.table_name as base_ref_object_name
        from    all_constraints r
                inner join all_objects ro
                on ro.owner = r.owner and ro.object_name = r.table_name and ro.object_type in ('TABLE', 'VIEW')
                inner join all_constraints k
                on k.owner = r.r_owner and k.constraint_name = r.r_constraint_name
                inner join all_objects ko
                on ko.owner = k.owner and ko.object_name = k.table_name and ko.object_type in ('TABLE', 'VIEW')
        where   r.owner = l_schema
        and     /* Type of constraint definition:
                   C (check constraint on a table)
                   P (primary key)
                   U (unique key)
                   R (referential integrity)
                   V (with check option, on a view)
                   O (with read only, on a view)
                */
                r.constraint_type in ('R')
        and     k.constraint_type in ('P', 'U')
      )
      select  oracle_tools.t_ref_constraint_object
              ( p_base_object => value(mnso)
              , p_object_schema => r.object_schema
              , p_object_name => r.object_name
              , p_constraint_type => r.constraint_type
              , p_column_names => null
              , p_ref_object =>
                  oracle_tools.t_constraint_object
                  ( p_base_object =>
                      oracle_tools.t_named_object.create_named_object
                      ( p_object_type => r.base_ref_object_type
                      , p_object_schema => r.base_ref_object_schema
                      , p_object_name => r.base_ref_object_name
                      )
                  , p_object_schema => r.ref_object_schema
                  , p_object_name => r.ref_object_name
                  , p_constraint_type => r.ref_constraint_type
                  , p_column_names => null
                  , p_search_condition => null
                  )
              )
      bulk collect
      into    p_schema_object_tab
      from    oracle_tools.v_my_named_schema_objects mnso
              inner join v_my_constraints_dict r /* this is where we are interested in */
              on r.base_object_schema = mnso.object_schema() and r.base_object_name = mnso.object_name()
      where   mnso.object_type() in ('TABLE', 'VIEW');

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
      into    p_schema_object_tab
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
      into    p_schema_object_tab
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
      into    p_schema_object_tab
      from    all_indexes i
      where   i.owner = l_schema
              -- GPA 2017-06-28 #147916863 - As a release operator I do not want comments without table or column.
      and     not(/*substr(i.index_name, 1, 5) = 'APEX$' or */substr(i.index_name, 1, 7) = 'I_MLOG$')
              -- GJP 2022-08-22
              -- When constraint_index = 'YES' the index is created as part of the constraint DDL,
              -- so it will not be listed as a separate DDL statement.
      and     not(i.constraint_index = 'YES')
$if oracle_tools.pkg_ddl_defs.c_exclude_system_indexes $then
      and     i.generated = 'N'
$end
      ;
  end case;

$if oracle_tools.schema_objects_api.c_tracing $then
$if oracle_tools.schema_objects_api.c_debugging $then
  dbug.print
  ( dbug."output"
  , 'cardinality(p_schema_object_tab): %s'
  , cardinality(p_schema_object_tab)
  );
  for i_idx in 1 .. nvl(cardinality(p_schema_object_tab), 0)
  loop
    dbug.print(dbug."output", 'p_schema_object_tab(%s)', i_idx);
    p_schema_object_tab(i_idx).print();
  end loop;
$end  
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end add_schema_objects;

procedure add_schema_objects
( p_schema_object_filter in oracle_tools.t_schema_object_filter
, p_schema_object_filter_id in positiven
, p_step in varchar2
)
is
  l_schema_object_tab oracle_tools.t_schema_object_tab;
begin
  add_schema_objects
  ( p_schema_object_filter => p_schema_object_filter 
  , p_schema_object_filter_id => p_schema_object_filter_id
  , p_step => p_step
  , p_schema_object_tab => l_schema_object_tab
  );
  if p_step = "named objects"
  then
    if cardinality(l_schema_object_tab) > 0 then raise program_error; end if;
  else
    oracle_tools.ddl_crud_api.add
    ( p_schema_object_tab => l_schema_object_tab
    , p_schema_object_filter_id => p_schema_object_filter_id
    , p_schema_object_filter => p_schema_object_filter
    );
  end if;  
end add_schema_objects;

procedure ddl_batch_process
is
  l_session_id constant t_session_id_nn := oracle_tools.ddl_crud_api.get_session_id;
  -- ORA-27452: "SCHEMA_OBJECTS_API.DDL_BATCH-3436872617-STOP" is an invalid name for a database object.
  -- ORA-27452: "SCHEMA_OBJECTS_API$DDL_BATCH-1851296641-STOP" is an invalid name for a database object.
  l_task_name_fmt constant varchar2(100 byte) := $$PLSQL_UNIT || '$DDL_BATCH$';
  l_task_name constant varchar2(100 byte) := l_task_name_fmt || to_char(l_session_id);
  l_count pls_integer;

  -- Here we substitute the session id into the statement since it may be executed by another session.
  l_sql_stmt constant varchar2(1000 byte) :=
    utl_lms.format_message
    ( q'[
begin
  oracle_tools.schema_objects_api.ddl_batch_process
  ( p_session_id => %s
  , p_start_id => :start_id
  , p_end_id => :end_id
  );
end;]'
    , to_char(l_session_id)
    );
  l_status number;
begin
$if oracle_tools.schema_objects_api.c_tracing $then
  dbug.enter($$PLSQL_UNIT || '.DDL_BATCH_PROCESS');
$end

  -- No need to check whether V_DEPENDENT_OR_GRANTED_OBJECT_TYPES contains rows: it always does.
  select  count(*)
  into    l_count
  from    oracle_tools.v_dependent_or_granted_object_types;

  if l_count <> c_steps.count - 1 -- skip first item
  then
    raise program_error;
  end if;

  -- Remove old USER_PARALLEL_EXECUTE_TASKS / USER_PARALLEL_EXECUTE_CHUNKS
  for r in
  ( select  distinct
            c.task_name
    from    user_parallel_execute_chunks c
            inner join user_parallel_execute_tasks t
            on t.task_name = c.task_name
    where   c.task_name like l_task_name_fmt || '%'
    and     c.start_ts < oracle_tools.ddl_crud_api.c_min_timestamp_to_keep
    and     t.status in ('FINISHED', 'FINISHED_WITH_ERROR', 'CRASHED')
  )
  loop
    dbms_parallel_execute.drop_task(r.task_name);
  end loop;

  declare
    -- ORA-29497: duplicate task name
    e_duplicate_task_name exception;
    pragma exception_init(e_duplicate_task_name, -29497);
  begin
    dbms_parallel_execute.create_task(l_task_name);
  exception
    when e_duplicate_task_name
    then
      oracle_tools.pkg_ddl_error.raise_error
      ( p_error_number => oracle_tools.pkg_ddl_error.c_duplicate_item
      , p_error_message => sqlerrm
      , p_context_info => l_task_name
      , p_context_label => 'task'
      );
  end;

  begin
    dbms_parallel_execute.create_chunks_by_number_col
    ( task_name => l_task_name
    , table_owner => 'ORACLE_TOOLS'
    , table_name => 'V_DEPENDENT_OR_GRANTED_OBJECT_TYPES'
    , table_column => 'NR'
    , chunk_size => case when oracle_tools.pkg_ddl_defs.c_default_parallel_level >= 1 then ceil(l_count / oracle_tools.pkg_ddl_defs.c_default_parallel_level) else 1 end
    );

$if oracle_tools.schema_objects_api.c_debugging $then
    dbug.print(dbug."info", 'starting dbms_parallel_execute.run_task');
$end

    declare
      -- ORA-27486: insufficient privileges
      e_insufficient_privileges exception;
      pragma exception_init(e_insufficient_privileges, -27486);
    begin
      -- Execute the DML in parallel
      dbms_parallel_execute.run_task
      ( l_task_name
      , l_sql_stmt
      , dbms_sql.native
      , parallel_level => oracle_tools.pkg_ddl_defs.c_default_parallel_level
      );
    exception
      when e_insufficient_privileges
      then
        -- Execute the DML in parallel
        dbms_parallel_execute.run_task
        ( l_task_name
        , l_sql_stmt
        , dbms_sql.native
        , parallel_level => 0
        );
    end;

$if oracle_tools.schema_objects_api.c_debugging $then
    dbug.print(dbug."info", 'stopped dbms_parallel_execute.run_task');
$end

    -- NOTE INTERRUPT: create a job to stop this task twice
    declare
      -- ORA-27486: insufficient privileges
      e_insufficient_privileges exception;
      pragma exception_init(e_insufficient_privileges, -27486);
      -- ORA-27477: "BCE_BO"."SCHEMA_OBJECTS_API$DDL_BATCH$1390583157$STOP" already exists
      e_job_already_exists exception;
      pragma exception_init(e_job_already_exists, -27477);
    begin
      for i_try in 1..2
      loop
        begin
          dbms_scheduler.create_job
          ( job_name => l_task_name || '$STOP'
          , job_type => 'PLSQL_BLOCK'
          , job_action => 'dbms_parallel_execute.stop_task(''' || l_task_name || ''');'
          , number_of_arguments => 0
          , start_date => systimestamp + interval '10' minute -- start after 10 minutes
          , repeat_interval => 'FREQ=MINUTELY;INTERVAL=10'    -- repeat every 10 minutes
          , end_date  => systimestamp + interval '21' minute  -- stop after 21 minutes (two times stop_task)
          , enabled => true
          , auto_drop => true
          );
          exit; -- OK
        exception
          when e_job_already_exists
          then
            if i_try = 2 then raise; end if;

            dbms_scheduler.drop_job
            ( job_name => l_task_name || '$STOP'
            , force => true
            , defer => false
            );
        end;
      end loop;
    exception
      when e_insufficient_privileges
      then null;
    end;

    -- If there is error, RESUME it for at most 2 times.
    <<try_loop>>
    for i_try in 1..2
    loop
      l_status := dbms_parallel_execute.task_status(l_task_name);
      exit try_loop when l_status = dbms_parallel_execute.finished;

$if oracle_tools.schema_objects_api.c_debugging $then
      dbug.print(dbug."info", 'dbms_parallel_execute.resume_task (try: %s, status: %s)', i_try, l_status);
$end
      dbms_parallel_execute.resume_task(l_task_name);
    end loop try_loop;

    -- drop this in any case since we are done
    begin
      dbms_scheduler.drop_job
      ( job_name => l_task_name || '$STOP'
      , force => true
      , defer => false
      );
    exception
      when others
      then null;
    end;
    
    if l_status = dbms_parallel_execute.finished
    then
      -- Done with processing; drop the task
      dbms_parallel_execute.drop_task(l_task_name);
    else
      oracle_tools.pkg_ddl_error.raise_error
      ( p_error_number => oracle_tools.pkg_ddl_error.c_batch_failed 
      , p_error_message => 'Task did not finish correctly: please look at USER_PARALLEL_EXECUTE_TASKS/USER_PARALLEL_EXECUTE_CHUNKS.'
      , p_context_info => l_task_name
      , p_context_label => 'task name'
      );
    end if;
  exception
    when others
    then
      -- Github issue #186: When a DBMS_PARALLEL_EXECUTE task fails it should NOT be dropped for further investigation.
      -- dbms_parallel_execute.drop_task(l_task_name);
      raise;      
  end;

$if oracle_tools.schema_objects_api.c_tracing $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end ddl_batch_process;

procedure add_schema_objects
( p_schema_object_filter in oracle_tools.t_schema_object_filter
, p_schema_object_filter_id in positiven
)
is
  l_schema_object_tab oracle_tools.t_schema_object_tab := null;
  l_start_time constant oracle_tools.schema_objects.updated%type := sys_extract_utc(systimestamp);
$if not(oracle_tools.schema_objects_api.c_use_ddl_batch_process) $then  
  l_all_schema_object_tab oracle_tools.t_schema_object_tab := oracle_tools.t_schema_object_tab();
$end  

$if oracle_tools.schema_objects_api.c_tracing $then
  l_module_name constant dbug.module_name_t := $$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'ADD_SCHEMA_OBJECTS (2)';
$end  
begin
$if oracle_tools.schema_objects_api.c_tracing $then
  dbug.enter(l_module_name);
$end

$if not(oracle_tools.schema_objects_api.c_use_ddl_batch_process) $then

  for i_idx in c_steps.first .. c_steps.last
  loop
    -- a necessary precondition for the other steps started via DBMS_PARALLEL_EXECUTE
    add_schema_objects
    ( p_schema_object_filter => p_schema_object_filter
    , p_schema_object_filter_id => p_schema_object_filter_id
    , p_step => c_steps(i_idx)
    , p_schema_object_tab => l_schema_object_tab
    );    
    case
      when c_steps(i_idx) = "named objects"
      then null;
      when nvl(cardinality(l_schema_object_tab), 0) = 0
      then null;
      when nvl(cardinality(l_all_schema_object_tab), 0) = 0
      then l_all_schema_object_tab := l_schema_object_tab;
      else l_all_schema_object_tab := l_all_schema_object_tab multiset union all l_schema_object_tab;      
    end case;
$if oracle_tools.schema_objects_api.c_debugging $then
    dbug.print
    ( dbug."output"
    , 'cardinality(l_all_schema_object_tab): %s'
    , cardinality(l_all_schema_object_tab)
    );
$end
  end loop;

  if cardinality(l_all_schema_object_tab) > 0
  then
    oracle_tools.ddl_crud_api.add
    ( p_schema_object_tab => l_all_schema_object_tab
    , p_schema_object_filter_id => p_schema_object_filter_id
    , p_schema_object_filter => p_schema_object_filter
    );
  end if;

$else

  -- a necessary precondition for the other steps started via DBMS_PARALLEL_EXECUTE
  add_schema_objects
  ( p_schema_object_filter => p_schema_object_filter
  , p_schema_object_filter_id => p_schema_object_filter_id
  , p_step => "named objects"
  );

  oracle_tools.ddl_crud_api.clear_batch;

  for r in
  ( select  v.nr
    ,       v.object_type
    from    oracle_tools.v_dependent_or_granted_object_types v
  )
  loop
    oracle_tools.ddl_crud_api.add
    ( p_object_type => r.object_type
    );
  end loop;

  commit; -- may need to make this an autonomous session

  ddl_batch_process;

$end -- $if not(oracle_tools.schema_objects_api.c_use_ddl_batch_process) $then

  oracle_tools.ddl_crud_api.purge_schema_objects(p_schema => p_schema_object_filter.schema(), p_reference_time => l_start_time);

$if oracle_tools.schema_objects_api.c_tracing $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end add_schema_objects;

-- PUBLIC

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
  dbug.print(dbug."input", 'p_generate_ddl_configuration_id: %s', p_generate_ddl_configuration_id);  
  dbug.print(dbug."input", 'p_add_schema_objects: %s', p_add_schema_objects);
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

  oracle_tools.ddl_crud_api.disable_parallel_status;
  
  add
  ( p_schema_object_filter => p_schema_object_filter
  , p_generate_ddl_configuration_id => p_generate_ddl_configuration_id
  , p_add_schema_objects => true
  );

  select  value(t) as obj
  bulk collect
  into    p_schema_object_tab
  from    oracle_tools.v_my_schema_objects t;

  oracle_tools.ddl_crud_api.reset_parallel_status;

$if oracle_tools.schema_objects_api.c_tracing $then
  dbug.leave;
exception
  when others
  then
    oracle_tools.ddl_crud_api.reset_parallel_status;
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
    oracle_tools.ddl_crud_api.reset_parallel_status;
    -- on error save so we can verify else rollback because we do not need the data
    oracle_tools.api_longops_pkg.longops_done(l_longops_rec);
    commit;
  end cleanup;
begin
$if oracle_tools.schema_objects_api.c_tracing $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'GET_SCHEMA_OBJECTS');
$end

  oracle_tools.ddl_crud_api.disable_parallel_status;

  l_schema_object_filter :=
    oracle_tools.t_schema_object_filter
    ( p_schema => p_schema
    , p_object_type => p_object_type
    , p_object_names => p_object_names
    , p_object_names_include => p_object_names_include
    , p_grantor_is_schema => 0
    , p_exclude_objects => p_exclude_objects
    , p_include_objects => p_include_objects
    );
  oracle_tools.ddl_crud_api.add
  ( p_schema_object_filter => l_schema_object_filter
  , p_transform_param_list => p_transform_param_list
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
$if oracle_tools.schema_objects_api.c_tracing $then
    dbug.leave_on_error;
$end
    oracle_tools.pkg_ddl_error.reraise_error(l_program);
    raise; -- to keep the compiler happy

  when others
  then
    cleanup;
$if oracle_tools.schema_objects_api.c_tracing $then
    dbug.leave_on_error;
$end
    raise;
end get_schema_objects;

function get_schema_objects
( p_session_id in t_session_id_nn
)
return oracle_tools.t_schema_object_tab
pipelined
is
  l_cursor integer := null;
  l_schema_object_tab oracle_tools.t_schema_object_tab;
begin
  loop
    oracle_tools.ddl_crud_api.fetch_schema_objects(p_session_id, l_cursor, l_schema_object_tab);

    if l_schema_object_tab.count > 0
    then
      for i_idx in l_schema_object_tab.first .. l_schema_object_tab.last
      loop
        pipe row (l_schema_object_tab(i_idx));
      end loop;
    end if;

    exit when l_cursor is null;
  end loop;

  return; -- essential
end get_schema_objects;

procedure ddl_batch_process
( p_session_id in t_session_id_nn
, p_start_id in number
, p_end_id in number
)
is
  cursor c_gdssdb
  is
    select  gdsb.seq
    ,       gdsb.object_type
    ,       oracle_tools.ddl_crud_api.get_schema_object_filter_id() as schema_object_filter_id
    from    oracle_tools.v_my_generate_ddl_session_batches gdsb -- filter on session_id already part of view
            inner join oracle_tools.v_dependent_or_granted_object_types v
            on v.object_type = gdsb.object_type
    where   gdsb.session_id = p_session_id
    and     gdsb.end_time is null        
    and     v.nr between p_start_id and p_end_id
    order by
            gdsb.session_id
    ,       gdsb.seq;

  type t_gdssdb_tab is table of c_gdssdb%rowtype;

  l_gdssdb_tab t_gdssdb_tab;

  -- to restore session id at the end
  l_session_id constant t_session_id_nn := oracle_tools.ddl_crud_api.get_session_id;

  procedure cleanup
  is
  begin
    oracle_tools.ddl_crud_api.set_session_id(l_session_id);
  end;
begin
  -- essential when in another process
  if oracle_tools.ddl_crud_api.get_session_id = p_session_id
  then
    null; -- OK
  else
    oracle_tools.ddl_crud_api.set_session_id(p_session_id);
  end if;

$if oracle_tools.schema_objects_api.c_tracing $then
  dbug.enter($$PLSQL_UNIT || '.DDL_BATCH_PROCESS (' || p_start_id || '-' || p_end_id || ')');
$if oracle_tools.schema_objects_api.c_debugging $then
  dbug.print(dbug."input", 'p_session_id: %s; p_start_id: %s; p_end_id: %s', p_session_id, p_start_id, p_end_id);
$end  
$end

  open c_gdssdb;
  fetch c_gdssdb bulk collect into l_gdssdb_tab;
  close c_gdssdb;

  if l_gdssdb_tab.count = 0
  then
    raise no_data_found; -- should not happen
  else
    for i_idx in l_gdssdb_tab.first .. l_gdssdb_tab.last
    loop
      oracle_tools.ddl_crud_api.set_batch_start_time(l_gdssdb_tab(i_idx).seq);
      commit;

      savepoint spt;        
      begin
        add_schema_objects
        ( p_schema_object_filter => oracle_tools.ddl_crud_api.get_schema_object_filter(p_schema_object_filter_id => l_gdssdb_tab(i_idx).schema_object_filter_id)
        , p_schema_object_filter_id => l_gdssdb_tab(i_idx).schema_object_filter_id
        , p_step => l_gdssdb_tab(i_idx).object_type
        );

        oracle_tools.ddl_crud_api.set_batch_end_time(l_gdssdb_tab(i_idx).seq);
        commit;
      exception
        when others
        then
          rollback to spt;
          oracle_tools.ddl_crud_api.set_batch_end_time(l_gdssdb_tab(i_idx).seq, sqlerrm);
          commit;
          raise;
      end;
    end loop;
  end if;

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
end ddl_batch_process;

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

$if oracle_tools.pkg_ddl_defs.c_get_queue_ddl $then

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
$if oracle_tools.pkg_ddl_defs.c_exclude_system_indexes $then
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

