CREATE OR REPLACE PACKAGE BODY "ORACLE_TOOLS"."DDL_CRUD_API" IS /* -*-coding: utf-8-*- */

-- PRIVATE

c_fetch_limit constant positiven := 100;

-- ORA-01400: cannot insert NULL into ("ORACLE_TOOLS"."GENERATED_DDLS"."LAST_DDL_TIME")
e_can_not_insert_null exception;
pragma exception_init(e_can_not_insert_null, -1400);

-- ORA-65114: space usage in container is too high
e_space_usage_too_high exception;
pragma exception_init(e_space_usage_too_high, -65114);

g_default_match_perc_threshold integer := 50;

c_session_id constant t_session_id_nn := to_number(sys_context('USERENV', 'SESSIONID'));

g_session_id t_session_id_nn := c_session_id;

g_min_timestamp_to_keep constant oracle_tools.generate_ddl_sessions.created%type := c_min_timestamp_to_keep;

subtype t_parallel_status_tab is dbms_sql.varchar2s;

g_parallel_status_tab t_parallel_status_tab; -- a stack of parallel status values for DML, DDL and QUERY

function get_schema_object_filter_id
( p_session_id in t_session_id_nn
)
return t_schema_object_filter_id
is
  l_schema_object_filter_id t_schema_object_filter_id;
begin
  select  gds.schema_object_filter_id
  into    l_schema_object_filter_id
  from    oracle_tools.generate_ddl_sessions gds
  where   gds.session_id = p_session_id;
  return l_schema_object_filter_id;
exception
  when no_data_found
  then
    return null;
end get_schema_object_filter_id;

function get_schema_object_filter
( p_session_id in t_session_id_nn
)
return oracle_tools.t_schema_object_filter
is
begin
  return get_schema_object_filter(p_schema_object_filter_id => get_schema_object_filter_id(p_session_id => p_session_id));
exception
  when no_data_found
  then
     return null;
end get_schema_object_filter;

function find_schema_object
( p_session_id in t_session_id_nn
, p_schema_object_id in varchar2
)
return oracle_tools.t_schema_object
is
  l_obj oracle_tools.t_schema_object := null;
begin
  select  so.obj
  into    l_obj
  from    oracle_tools.generate_ddl_session_schema_objects gdsso
          inner join oracle_tools.schema_object_filter_results sofr
          on sofr.schema_object_filter_id = gdsso.schema_object_filter_id and
             sofr.schema_object_id = gdsso.schema_object_id
          inner join oracle_tools.schema_objects so
          on so.id = sofr.schema_object_id          
  where   gdsso.session_id = p_session_id
  and     gdsso.schema_object_id = p_schema_object_id;

  return l_obj;
exception
  when no_data_found
  then return null;
end find_schema_object;

function match_perc
( p_session_id in t_session_id_nn
)
return integer
deterministic
is
  l_nr_objects_generate_ddl number;
  l_nr_objects number;
begin
  select  sum(t.generate_ddl) as nr_objects_generate_ddl
  ,       count(*) as nr_objects
  into    l_nr_objects_generate_ddl
  ,       l_nr_objects
  from    oracle_tools.v_schema_objects t
  where   t.session_id = p_session_id;

  return case when l_nr_objects > 0 then trunc((100 * l_nr_objects_generate_ddl) / l_nr_objects) else null end;
end match_perc;

procedure add_schema_object_filter
( p_session_id in t_session_id_nn
, p_schema_object_filter in oracle_tools.t_schema_object_filter
, p_generate_ddl_configuration_id in integer -- the GENERATE_DDL_CONFIGURATIONS.ID
, p_schema_object_filter_id out nocopy integer
)
is
  l_clob constant clob := p_schema_object_filter.repr();
  l_hash_bucket constant oracle_tools.schema_object_filters.hash_bucket%type :=
    sys.dbms_crypto.hash(l_clob, sys.dbms_crypto.hash_sh1);
  l_hash_bucket_nr oracle_tools.schema_object_filters.hash_bucket_nr%type;
  l_hash_buckets_equal pls_integer;
$if oracle_tools.ddl_crud_api.c_tracing $then
  l_module_name constant dbug.module_name_t := $$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'ADD_SCHEMA_OBJECT_FILTER';
$end
begin
$if oracle_tools.ddl_crud_api.c_tracing $then
  dbug.enter(l_module_name);
$if oracle_tools.ddl_crud_api.c_debugging $then
  dbug.print(dbug."input", 'p_session_id: %s', p_session_id);
  dbug.print(dbug."input", 'p_generate_ddl_configuration_id: %s', p_generate_ddl_configuration_id);  
$end
$end

  select  max(case when dbms_lob.compare(sof.obj_json, l_clob) = 0 then sof.id end) as id
  ,       nvl(max(sof.hash_bucket_nr), 0) + 1
  ,       count(*)
  into    p_schema_object_filter_id
  ,       l_hash_bucket_nr
  ,       l_hash_buckets_equal
  from    oracle_tools.schema_object_filters sof
  where   sof.hash_bucket = l_hash_bucket;

$if oracle_tools.ddl_crud_api.c_debugging $then
  dbug.print
  ( dbug."info"
  , 'p_schema_object_filter_id: %s; l_hash_bucket_nr: %s; l_hash_buckets_equal: %s'
  , p_schema_object_filter_id
  , l_hash_bucket_nr
  , l_hash_buckets_equal
  );
$end

  /*
  ** API_CALL_STACK_PKG before compilation:
  **
  ** OBJECT_TYPE  CREATED           LAST_DDL_TIME     TIMESTAMP           REMARK
  ** -----------  -------           -------------     ---------           ------
  ** PACKAGE      07/12/23 15:56:32 08/12/23 11:49:56 2023-12-08:11:49:56
  ** PACKAGE BODY 07/12/23 15:58:43 08/12/23 11:50:02 2023-12-08:11:50:02
  **
  ** After compile body:
  **
  ** OBJECT_TYPE  CREATED           LAST_DDL_TIME     TIMESTAMP
  ** -----------  -------           -------------     ---------
  ** PACKAGE      07/12/23 15:56:32 08/12/23 11:49:56 2023-12-08:11:49:56 no change
  ** PACKAGE BODY 07/12/23 15:58:43 13/11/24 09:11:02 2023-12-08:11:50:02 LAST_DDL_TIME changed
  **
  ** After compile specification:
  **
  ** OBJECT_TYPE  CREATED           LAST_DDL_TIME     TIMESTAMP
  ** -----------  -------           -------------     ---------
  ** PACKAGE      07/12/23 15:56:32 13/11/24 09:12:38 2023-12-08:11:49:56 LAST_DDL_TIME changed
  ** PACKAGE BODY 07/12/23 15:58:43 13/11/24 09:12:39 2023-12-08:11:50:02 LAST_DDL_TIME changed (1 sec later)
  */

  -- when not found add it
  if p_schema_object_filter_id is null
  then
    p_schema_object_filter.chk();
    insert into oracle_tools.schema_object_filters
    ( hash_bucket
    , hash_bucket_nr
    , obj_json
    )
    values
    ( l_hash_bucket
    , l_hash_bucket_nr
    , p_schema_object_filter.repr()
    )
    returning id into p_schema_object_filter_id;
  else
    update  oracle_tools.schema_object_filters sof
    set     sof.updated = sys_extract_utc(systimestamp)
    where   sof.id = p_schema_object_filter_id;

    if sql%rowcount = 0
    then raise program_error; -- should not happen
    end if;
  end if;

$if oracle_tools.ddl_crud_api.c_debugging $then
  dbug.print(dbug."info", 'p_schema_object_filter_id: %s', p_schema_object_filter_id);
$end

  -- cleanup on the fly
  delete_generate_ddl_sessions;

  -- either insert or update GENERATE_DDL_SESSIONS
  if get_schema_object_filter_id(p_session_id => p_session_id) is null
  then
    insert into oracle_tools.generate_ddl_sessions
    ( session_id
    , schema_object_filter_id
    , generate_ddl_configuration_id
    , username
    )
    values
    ( p_session_id
    , p_schema_object_filter_id
    , p_generate_ddl_configuration_id
    , sys_context('USERENV', 'CURRENT_SCHEMA')
    );
$if oracle_tools.ddl_crud_api.c_debugging $then
    dbug.print(dbug."info", '# rows inserted into generate_ddl_sessions: %s', sql%rowcount);
$end
  else
    -- make room for new objects/ddls
    delete
    from    oracle_tools.generate_ddl_session_schema_objects gdsso
    where   gdsso.session_id = p_session_id;

$if oracle_tools.ddl_crud_api.c_debugging $then
    dbug.print(dbug."info", '# rows deleted from generate_ddl_session_schema_objects: %s', sql%rowcount);
$end

    update  oracle_tools.generate_ddl_sessions gds
    set     gds.schema_object_filter_id = p_schema_object_filter_id
    ,       gds.generate_ddl_configuration_id = p_generate_ddl_configuration_id
    ,       gds.updated = sys_extract_utc(systimestamp)
    where   gds.session_id = p_session_id;

$if oracle_tools.ddl_crud_api.c_debugging $then
    dbug.print(dbug."info", '# rows updated for generate_ddl_sessions: %s', sql%rowcount);
$end
  end if;

$if oracle_tools.ddl_crud_api.c_tracing $then
$if oracle_tools.ddl_crud_api.c_debugging $then
  dbug.print(dbug."output", 'p_schema_object_filter_id: %s', p_schema_object_filter_id);
$end
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end add_schema_object_filter;

procedure add_schema_object
( p_session_id in t_session_id_nn
, p_schema_object in oracle_tools.t_schema_object
, p_schema_object_filter_id in t_schema_object_filter_id_nn
, p_schema_object_filter in oracle_tools.t_schema_object_filter
)
is
  l_schema_object_id constant oracle_tools.schema_objects.id%type := p_schema_object.id;
  l_last_ddl_time date;
  l_found pls_integer;
$if oracle_tools.ddl_crud_api.c_tracing $then
  l_module_name constant dbug.module_name_t := $$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'ADD_SCHEMA_OBJECT';
$end
begin
$if oracle_tools.ddl_crud_api.c_tracing $then
  dbug.enter(l_module_name);
$end

  -- check precondition (in GENERATE_DDL_SESSIONS and thus SCHEMA_OBJECT_FILTERS)
  if p_schema_object_filter_id is null
  then
    raise program_error;
  end if;

  -- merge into SCHEMA_OBJECTS (update last_ddl_time$)
  merge
  into    oracle_tools.schema_objects dst
  using   ( select  l_schema_object_id as id
            ,       p_schema_object as obj
            from    dual
          ) src
  on      ( src.id = dst.id )
  when    not matched
  then    insert ( id, obj ) values ( src.id, src.obj )
  when    matched 
  then    update
          set dst.obj.last_ddl_time$ = src.obj.last_ddl_time$
          ,   dst.updated = sys_extract_utc(systimestamp)
          delete where src.obj.last_ddl_time$ is null /* check constraint SCHEMA_OBJECTS$CK$OBJ$LAST_DDL_TIME$ */;

  -- merge into SCHEMA_OBJECT_FILTER_RESULTS (but only when not matched)
  merge
  into    oracle_tools.schema_object_filter_results dst
  using   ( select  p_schema_object_filter_id as schema_object_filter_id
            ,       l_schema_object_id as schema_object_id
            from    dual
          ) src
  on      ( src.schema_object_filter_id = dst.schema_object_filter_id and
            src.schema_object_id = src.schema_object_id )
  when    not matched
  then    insert ( schema_object_filter_id, schema_object_id, generate_ddl_details )
          values ( src.schema_object_filter_id, src.schema_object_id, p_schema_object_filter.matches_schema_object_details(src.schema_object_id) );

  /*
  -- Now the following tables have data for these parameters:
  -- * SCHEMA_OBJECT_FILTERS (precondition)
  -- * GENERATE_DDL_SESSIONS (precondition)
  -- * SCHEMA_OBJECTS
  -- * SCHEMA_OBJECT_FILTER_RESULTS
  */

  -- Ignore this entry when MATCHES_SCHEMA_OBJECT_DETAILS returns ' |_%'
  begin
    select  1
    into    l_found
    from    oracle_tools.schema_object_filter_results sofr
    where   sofr.schema_object_filter_id = p_schema_object_filter_id
    and     sofr.schema_object_id = l_schema_object_id
    and     sofr.generate_ddl in (1);
  exception
    when no_data_found
    then -- no match
      l_found := 0;
  end;

  if l_found = 1
  then
    merge
    into    oracle_tools.generate_ddl_session_schema_objects dst
    using   ( select  /* key */
                      gds.session_id
              ,       gd.schema_object_id
                      /* data */
              ,       p_schema_object_filter_id as schema_object_filter_id        
              ,       gd.last_ddl_time
              ,       gd.generate_ddl_configuration_id
              from    oracle_tools.generate_ddl_sessions gds
                      cross join oracle_tools.generated_ddls gd
              where   gds.session_id = p_session_id
              and     gd.schema_object_id = l_schema_object_id
              and     gd.last_ddl_time = p_schema_object.last_ddl_time$
              and     gd.generate_ddl_configuration_id = gds.generate_ddl_configuration_id
            ) src
    on      ( /* GENERATE_DDL_SESSION_SCHEMA_OBJECTS$PK */
              src.session_id = dst.session_id and
              src.schema_object_id = dst.schema_object_id
            )
    when    not matched
    then    insert ( session_id, schema_object_id, schema_object_filter_id, last_ddl_time, generate_ddl_configuration_id )
            values ( src.session_id, src.schema_object_id, src.schema_object_filter_id, src.last_ddl_time, src.generate_ddl_configuration_id )
    when    matched
    then    update
            set dst.schema_object_filter_id = src.schema_object_filter_id
            ,   dst.last_ddl_time = dst.last_ddl_time
            ,   dst.generate_ddl_configuration_id = src.generate_ddl_configuration_id;
  end if;

$if oracle_tools.ddl_crud_api.c_tracing $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end add_schema_object;

procedure add_schema_ddl
( p_session_id in t_session_id_nn
, p_schema_ddl in oracle_tools.t_schema_ddl
)
is
  l_generated_ddl_id oracle_tools.generated_ddls.id%type;
  l_generate_ddl_configuration_id oracle_tools.generate_ddl_configurations.id%type;
  l_chunk#_tab sys.odcinumberlist := sys.odcinumberlist();

$if oracle_tools.ddl_crud_api.c_tracing $then
  l_module_name constant dbug.module_name_t := $$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'ADD_SCHEMA_DDL';
$end
begin
$if oracle_tools.ddl_crud_api.c_tracing $then
  dbug.enter(l_module_name);
$end

  -- input checks
  case
    when p_schema_ddl is null
    then raise value_error;
    when p_schema_ddl.obj is null
    then raise value_error;
    when p_schema_ddl.obj.id is null
    then raise value_error;
    when p_session_id is null
    then raise value_error;
    else null;
  end case;

  p_schema_ddl.chk(null);

  if cardinality(p_schema_ddl.ddl_tab) > 0
  then
    -- create or retrieve a generate DDL configuration
    select  gds.generate_ddl_configuration_id
    into    l_generate_ddl_configuration_id
    from    oracle_tools.generate_ddl_sessions gds
    where   gds.session_id = p_session_id;

    begin    
      select  gd.id
      into    l_generated_ddl_id
      from    oracle_tools.generated_ddls gd
      where   gd.schema_object_id = p_schema_ddl.obj.id
      and     gd.last_ddl_time = p_schema_ddl.obj.last_ddl_time
      and     gd.generate_ddl_configuration_id = l_generate_ddl_configuration_id;
    exception
      when no_data_found
      then
        begin
          -- cleanup on the fly the DDLs who will not be needed anymore
          delete
          from    oracle_tools.generated_ddls gd
          where   gd.schema_object_id = p_schema_ddl.obj.id
          and     gd.last_ddl_time < p_schema_ddl.obj.last_ddl_time;

$if oracle_tools.ddl_crud_api.c_debugging $then
          dbug.print(dbug."info", '# rows deleted from generated_ddls: %s', sql%rowcount);
$end

          insert into oracle_tools.generated_ddls
          ( schema_object_id
          , last_ddl_time
          , generate_ddl_configuration_id
          )
          values
          ( p_schema_ddl.obj.id
          , p_schema_ddl.obj.last_ddl_time
          , l_generate_ddl_configuration_id
          )
          returning id into l_generated_ddl_id;
        exception
          when e_can_not_insert_null
          then raise_application_error
               ( oracle_tools.pkg_ddl_error.c_object_not_correct
               , 'No LAST_DDL_TIME for schema object id ' || p_schema_ddl.obj.id
               , true
               );
        end;
    end;

    -- bulk insert
    forall i_ddl_idx in p_schema_ddl.ddl_tab.first .. p_schema_ddl.ddl_tab.last
      insert into generated_ddl_statements
      ( generated_ddl_id
      , ddl#
      , verb
      )
      values
      ( l_generated_ddl_id
      , p_schema_ddl.ddl_tab(i_ddl_idx).ddl#()
      , p_schema_ddl.ddl_tab(i_ddl_idx).verb()
      );

    for i_ddl_idx in p_schema_ddl.ddl_tab.first .. p_schema_ddl.ddl_tab.last
    loop
      if cardinality(p_schema_ddl.ddl_tab(i_ddl_idx).text_tab) > 0
      then
        l_chunk#_tab.delete;
        for i_chunk_idx in p_schema_ddl.ddl_tab(i_ddl_idx).text_tab.first
                           ..
                           p_schema_ddl.ddl_tab(i_ddl_idx).text_tab.last
        loop
          l_chunk#_tab.extend(1);
          l_chunk#_tab(l_chunk#_tab.last) := i_chunk_idx;
        end loop;

        -- bulk insert
        forall i_chunk_idx in p_schema_ddl.ddl_tab(i_ddl_idx).text_tab.first
                              ..
                              p_schema_ddl.ddl_tab(i_ddl_idx).text_tab.last
          insert into generated_ddl_statement_chunks
          ( generated_ddl_id
          , ddl#
          , chunk#
          , chunk
          )
          values
          ( l_generated_ddl_id
          , p_schema_ddl.ddl_tab(i_ddl_idx).ddl#()
          , l_chunk#_tab(i_chunk_idx)
          , p_schema_ddl.ddl_tab(i_ddl_idx).text_tab(i_chunk_idx)
          );
      end if;
    end loop;

    /* flag that DDL has been generated */
    update  oracle_tools.generate_ddl_session_schema_objects gdsso
    set     gdsso.last_ddl_time = p_schema_ddl.obj.last_ddl_time
    ,       gdsso.generate_ddl_configuration_id = l_generate_ddl_configuration_id
    where   gdsso.session_id = p_session_id
    and     gdsso.schema_object_id = p_schema_ddl.obj.id;

    case sql%rowcount
      when 0
      then raise no_data_found;
      when 1
      then null;
      else raise too_many_rows;
    end case;
  else
    raise no_data_found;
  end if;

$if oracle_tools.ddl_crud_api.c_tracing $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end add_schema_ddl;

procedure add_batch
( p_session_id in t_session_id_nn
, p_schema in varchar2 default null
, p_transform_param_list in varchar2 default null
, p_object_schema in varchar2 default null
, p_object_type in varchar2 default null
, p_base_object_schema in varchar2 default null
, p_base_object_type in varchar2 default null
, p_object_name_tab in oracle_tools.t_text_tab default null
, p_base_object_name_tab in oracle_tools.t_text_tab default null
, p_nr_objects in integer default null
)
is
begin
  insert into oracle_tools.generate_ddl_session_batches
  ( session_id
  , seq
  , schema
  , transform_param_list
  , object_type
  , params
  )
  values
  ( p_session_id
  , (select nvl(max(gdsb.seq), 0) + 1 from oracle_tools.generate_ddl_session_batches gdsb where gdsb.session_id = p_session_id)
  , p_schema
  , p_transform_param_list
  , p_object_type
  , oracle_tools.t_schema_ddl_params
    ( null -- dummy$
    , p_object_schema
    , p_base_object_schema
    , p_base_object_type
    , p_object_name_tab
    , p_base_object_name_tab
    , p_nr_objects
    ).repr()
  );
end add_batch;

procedure add_schema_object_tab
( p_session_id in t_session_id_nn
, p_schema_object_tab in oracle_tools.t_schema_object_tab
, p_schema_object_filter_id in t_schema_object_filter_id_nn
, p_schema_object_filter in oracle_tools.t_schema_object_filter
)
is
$if oracle_tools.ddl_crud_api.c_tracing $then
  l_module_name constant dbug.module_name_t := $$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'ADD_SCHEMA_OBJECT_TAB';
$end
begin
$if oracle_tools.ddl_crud_api.c_tracing $then
  dbug.enter(l_module_name);
$if oracle_tools.ddl_crud_api.c_debugging $then
  dbug.print(dbug."input", 'p_session_id: %s; p_schema_object_filter_id: %s', p_session_id, p_schema_object_filter_id);
$end  
$end

  merge
  into    oracle_tools.schema_objects dst
  using   ( select  t.id
            ,       value(t) as obj
            from    table(p_schema_object_tab) t
          ) src
  on      ( src.id = dst.id )
  when    not matched
  then    insert ( id, obj ) values ( src.id, src.obj )
  when    matched 
  then    update set dst.obj.last_ddl_time$ = src.obj.last_ddl_time$, dst.updated = sys_extract_utc(systimestamp)
          delete where src.obj.last_ddl_time$ is null /* check constraint SCHEMA_OBJECTS$CK$OBJ$LAST_DDL_TIME$ */;

$if oracle_tools.ddl_crud_api.c_debugging $then
  dbug.print(dbug."info", '# rows inserted into schema_objects: %s', sql%rowcount);
$end  

  -- insert into SCHEMA_OBJECT_FILTER_RESULTS
  merge
  into    oracle_tools.schema_object_filter_results dst
  using   ( select  p_schema_object_filter_id as schema_object_filter_id
            ,       t.id as schema_object_id
            from    table(p_schema_object_tab) t
          ) src
  on      ( /* SCHEMA_OBJECT_FILTER_RESULTS$PK */
            src.schema_object_filter_id = dst.schema_object_filter_id and
            src.schema_object_id = dst.schema_object_id
          )
  when    not matched
  then    insert ( schema_object_filter_id, schema_object_id, generate_ddl_details )
          values ( src.schema_object_filter_id, src.schema_object_id, p_schema_object_filter.matches_schema_object_details(src.schema_object_id) );

$if oracle_tools.ddl_crud_api.c_debugging $then
  dbug.print(dbug."info", '# rows inserted into schema_object_filter_results: %s', sql%rowcount);
$end  

  /*
  -- Now the following tables have data for these parameters:
  -- * SCHEMA_OBJECT_FILTERS (precondition)
  -- * GENERATE_DDL_SESSIONS (precondition)
  -- * SCHEMA_OBJECTS
  -- * SCHEMA_OBJECT_FILTER_RESULTS
  */

  begin
    -- Ignore this entry when MATCHES_SCHEMA_OBJECT_DETAILS returns ' |_%'
    merge
    into    oracle_tools.generate_ddl_session_schema_objects dst
    using   ( select  -- key
                      p_session_id as session_id
              ,       t.id as schema_object_id
                      -- data
                      -- when DDL has been generated for this last_ddl_time, save that info so we will not generate DDL again
              ,       p_schema_object_filter_id as schema_object_filter_id
              ,       gd.last_ddl_time
              ,       gd.generate_ddl_configuration_id
              from    oracle_tools.generate_ddl_sessions gds
                      cross join table(p_schema_object_tab) t -- may contain duplicates (constraints)
                      inner join oracle_tools.schema_object_filter_results sofr
                      on sofr.schema_object_filter_id = gds.schema_object_filter_id and
                         sofr.schema_object_id = t.id and
                         sofr.generate_ddl in (1) 
                      left outer join oracle_tools.generated_ddls gd
                      on gd.schema_object_id = t.id and
                         gd.last_ddl_time = t.last_ddl_time() and
                         gd.generate_ddl_configuration_id = gds.generate_ddl_configuration_id
              where   gds.session_id = p_session_id
              and     gds.schema_object_filter_id = p_schema_object_filter_id
            ) src
    on      ( /* GENERATE_DDL_SESSION_SCHEMA_OBJECTS$PK */
              src.session_id = dst.session_id and
              src.schema_object_id = dst.schema_object_id
            )
    when    not matched
    then    insert ( session_id, schema_object_id, schema_object_filter_id, last_ddl_time, generate_ddl_configuration_id )
            values ( src.session_id, src.schema_object_id, src.schema_object_filter_id, src.last_ddl_time, src.generate_ddl_configuration_id )
    when    matched
    then    update
            set dst.schema_object_filter_id = src.schema_object_filter_id
            ,   dst.last_ddl_time = dst.last_ddl_time
            ,   dst.generate_ddl_configuration_id = src.generate_ddl_configuration_id;
  exception
    when e_space_usage_too_high
    then
      -- upsert
      for src in
      ( select  -- key
                p_session_id as session_id
        ,       t.id as schema_object_id
                -- data
                -- when DDL has been generated for this last_ddl_time, save that info so we will not generate DDL again
        ,       p_schema_object_filter_id as schema_object_filter_id
        ,       gd.last_ddl_time
        ,       gd.generate_ddl_configuration_id
        from    oracle_tools.generate_ddl_sessions gds
                cross join table(p_schema_object_tab) t -- may contain duplicates (constraints)
                inner join oracle_tools.schema_object_filter_results sofr
                on sofr.schema_object_filter_id = gds.schema_object_filter_id and
                   sofr.schema_object_id = t.id and
                   sofr.generate_ddl in (1) 
                left outer join oracle_tools.generated_ddls gd
                on gd.schema_object_id = t.id and
                   gd.last_ddl_time = t.last_ddl_time() and
                   gd.generate_ddl_configuration_id = gds.generate_ddl_configuration_id
        where   gds.session_id = p_session_id
        and     gds.schema_object_filter_id = p_schema_object_filter_id
      )
      loop
        update  oracle_tools.generate_ddl_session_schema_objects dst
        set     dst.schema_object_filter_id = src.schema_object_filter_id
        ,       dst.last_ddl_time = dst.last_ddl_time
        ,       dst.generate_ddl_configuration_id = src.generate_ddl_configuration_id
        where   src.session_id = dst.session_id
        and     src.schema_object_id = dst.schema_object_id;

        if sql%rowcount = 0
        then
          insert into oracle_tools.generate_ddl_session_schema_objects
          ( session_id
          , schema_object_id
          , schema_object_filter_id
          , last_ddl_time
          , generate_ddl_configuration_id
          )
          values
          ( src.session_id
          , src.schema_object_id
          , src.schema_object_filter_id
          , src.last_ddl_time
          , src.generate_ddl_configuration_id
          );
        end if;
      end loop;
  end;  

$if oracle_tools.ddl_crud_api.c_debugging $then
  dbug.print(dbug."info", '# rows inserted into generate_ddl_session_schema_objects: %s', sql%rowcount);
$end  

$if oracle_tools.ddl_crud_api.c_tracing $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end add_schema_object_tab;

procedure get_parallel_status
( p_parallel_status_tab in out nocopy t_parallel_status_tab -- push three parallel status values
)
is
$if oracle_tools.ddl_crud_api.c_tracing $then
  l_module_name constant dbug.module_name_t := $$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'GET_PARALLEL_STATUS';
$end
  l_old_count constant simple_integer := p_parallel_status_tab.count; -- old count at the start of this call
begin
$if oracle_tools.ddl_crud_api.c_tracing $then
  dbug.enter(l_module_name);
$end

  select  s.pdml_status
  ,       s.pddl_status
  ,       s.pq_status
  into    p_parallel_status_tab(l_old_count+1)
  ,       p_parallel_status_tab(l_old_count+2)
  ,       p_parallel_status_tab(l_old_count+3)
  from    v$session s
  where   s.audsid = c_session_id;

$if oracle_tools.ddl_crud_api.c_tracing $then
$if oracle_tools.ddl_crud_api.c_debugging $then
  dbug.print
  ( dbug."output"
  , 'Parallel DML: %s; parallel DDL: %s; parallel query: %s'
  , p_parallel_status_tab(l_old_count+1)
  , p_parallel_status_tab(l_old_count+2)
  , p_parallel_status_tab(l_old_count+3)
  );
$end  
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end get_parallel_status;

procedure set_parallel_status
( p_parallel_status_tab in out nocopy t_parallel_status_tab -- pop three parallel status values
)
is
  l_type varchar2(10 byte) := null;
  l_status varchar2(10 byte) := null;
  l_new_count constant simple_integer := p_parallel_status_tab.count - 3; -- new count after this call returns
  
$if oracle_tools.ddl_crud_api.c_tracing $then
  l_module_name constant dbug.module_name_t := $$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'SET_PARALLEL_STATUS';
$end
begin
$if oracle_tools.ddl_crud_api.c_tracing $then
  dbug.enter(l_module_name);
$if oracle_tools.ddl_crud_api.c_debugging $then
  dbug.print
  ( dbug."input"
  , 'Parallel DML: %s; parallel DDL: %s; parallel query: %s'
  , p_parallel_status_tab(l_new_count+1)
  , p_parallel_status_tab(l_new_count+2)
  , p_parallel_status_tab(l_new_count+3)
  );
$end  
$end

  for i_idx in reverse l_new_count+1 .. l_new_count+3
  loop    
    case 
      when upper(p_parallel_status_tab(i_idx)) in ('ENABLE' , 'ENABLED' ) then l_status := 'enable';
      when upper(p_parallel_status_tab(i_idx)) in ('DISABLE', 'DISABLED') then l_status := 'disable';
    end case;
    l_type :=
      case i_idx - l_new_count
        when 1 then 'dml'
        when 2 then 'ddl'
        when 3 then 'query'
      end;
    execute immediate 'alter session ' || l_status || ' parallel ' || l_type;  
    p_parallel_status_tab.delete(i_idx); -- so we don't call reset again without a disable first
  end loop;

$if oracle_tools.ddl_crud_api.c_tracing $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end set_parallel_status;

-- PUBLIC

procedure set_session_id
( p_session_id in t_session_id_nn
)
is
begin
  /*if p_session_id is null
  then
    raise value_error;
  els*/if p_session_id = c_session_id
  then
    g_session_id := p_session_id;
  else
    -- can only set session id for my own sessions or when I am ORACLE_TOOLS
    select  gds.session_id
    into    g_session_id
    from    oracle_tools.generate_ddl_sessions gds
    where   sys_context('USERENV', 'CURRENT_SCHEMA') in (gds.username, $$PLSQL_UNIT_OWNER)
    and     gds.session_id = p_session_id;
  end if;
end set_session_id;

function get_session_id
return t_session_id_nn
is
begin
  return g_session_id;
end get_session_id;

function get_schema_object_filter_id
return t_schema_object_filter_id
is
begin
  return get_schema_object_filter_id(p_session_id => get_session_id);
end get_schema_object_filter_id;

function get_schema_object_filter
return oracle_tools.t_schema_object_filter
is
begin
  return get_schema_object_filter(p_session_id => get_session_id);
end get_schema_object_filter;

function get_schema_object_filter
( p_schema_object_filter_id in t_schema_object_filter_id_nn
)
return oracle_tools.t_schema_object_filter
is
begin
  for r in
  ( select  sof.obj_json 
    from    oracle_tools.schema_object_filters sof
    where   sof.id = p_schema_object_filter_id
  )
  loop
    return treat(oracle_tools.t_object_json.deserialize('ORACLE_TOOLS.T_SCHEMA_OBJECT_FILTER', r.obj_json) as oracle_tools.t_schema_object_filter);
  end loop;
  return null;
end get_schema_object_filter;

function find_schema_object
( p_schema_object_id in varchar2
)
return oracle_tools.t_schema_object
is
begin
  PRAGMA INLINE (find_schema_object, 'YES');
  return find_schema_object(p_session_id => get_session_id, p_schema_object_id => p_schema_object_id);
end find_schema_object;

procedure default_match_perc_threshold
( p_match_perc_threshold in integer
)
is
begin
  g_default_match_perc_threshold := p_match_perc_threshold;
end default_match_perc_threshold;

function match_perc
return integer
deterministic
is
begin
  PRAGMA INLINE (match_perc, 'YES');
  return match_perc(get_session_id);
end match_perc;

function match_perc_threshold
return integer
deterministic
is
begin
  return g_default_match_perc_threshold;
end;

procedure add
( p_schema_object_filter in oracle_tools.t_schema_object_filter -- the schema object filter
, p_transform_param_list in varchar2 -- A comma separated list of transform parameters, see dbms_metadata.set_transform_param().
, p_generate_ddl_configuration_id out nocopy integer
)
is
  l_param_tab1 sys.odcivarchar2list;
  l_param_tab2 sys.odcivarchar2list;
  l_transform_param_list oracle_tools.generate_ddl_configurations.transform_param_list%type;
  l_db_version constant number := dbms_db_version.version + dbms_db_version.release / 10;
  l_last_ddl_time_schema date;
begin
  l_param_tab1 := oracle_tools.api_pkg.list2collection(p_value_list => p_transform_param_list, p_sep => ',');

  select  distinct upper(t.column_value) as param
  bulk collect
  into    l_param_tab2
  from    table(l_param_tab1) t
  order by
          param;

  l_transform_param_list := ',' || oracle_tools.api_pkg.collection2list(p_value_tab => l_param_tab2, p_sep => ',');

  select  max(o.last_ddl_time)
  into    l_last_ddl_time_schema
  from    all_objects o
  where   o.owner = $$PLSQL_UNIT_OWNER
  and     o.object_name in
          ( 'DDL_CRUD_API'
          , 'PKG_DDL_DEFS'
          , 'PKG_DDL_ERROR'
          , 'PKG_DDL_UTIL'
          , 'PKG_SCHEMA_OBJECT_FILTER'
          , 'PKG_STR_UTIL'
          , 'SCHEMA_OBJECTS_API'
          );

  begin
    insert
    into    oracle_tools.generate_ddl_configurations dst
    ( transform_param_list
    , db_version
    , last_ddl_time_schema
    )
    values
    ( l_transform_param_list
    , l_db_version
    , l_last_ddl_time_schema
    )
    returning id into p_generate_ddl_configuration_id;
$if oracle_tools.ddl_crud_api.c_debugging $then
  dbug.print(dbug."info", '# rows inserted into generate_ddl_configurations: %s', sql%rowcount);
$end
  exception
    when dup_val_on_index
    then
      -- should be there now: get the id
      select  gdc.id
      into    p_generate_ddl_configuration_id
      from    oracle_tools.generate_ddl_configurations gdc
      where   gdc.transform_param_list = l_transform_param_list
      and     gdc.db_version = l_db_version
      and     gdc.last_ddl_time_schema = l_last_ddl_time_schema;
  end;

  -- remove on the fly those configurations that will (probably) not be used anymore
  delete
  from   oracle_tools.generate_ddl_configurations gdc
  where  gdc.transform_param_list = l_transform_param_list
  and    ( gdc.db_version < l_db_version or
           ( gdc.db_version = l_db_version and gdc.last_ddl_time_schema < l_last_ddl_time_schema )
         );

$if oracle_tools.ddl_crud_api.c_debugging $then
  dbug.print(dbug."info", '# rows deleted from generate_ddl_configurations: %s', sql%rowcount);
$end
end add;

procedure add
( p_schema_object_filter in oracle_tools.t_schema_object_filter
, p_generate_ddl_configuration_id in integer -- the GENERATE_DDL_CONFIGURATIONS.ID
, p_schema_object_filter_id out nocopy integer
)
is
begin
  PRAGMA INLINE (add_schema_object_filter, 'YES');
  add_schema_object_filter
  ( p_session_id => get_session_id
  , p_schema_object_filter => p_schema_object_filter
  , p_generate_ddl_configuration_id => p_generate_ddl_configuration_id
  , p_schema_object_filter_id => p_schema_object_filter_id
  );
end add;  

procedure add
( p_schema_object in oracle_tools.t_schema_object
, p_schema_object_filter_id in t_schema_object_filter_id_nn
, p_schema_object_filter in oracle_tools.t_schema_object_filter
)
is
begin
  PRAGMA INLINE (add_schema_object, 'YES');
  add_schema_object
  ( p_session_id => get_session_id
  , p_schema_object => p_schema_object
  , p_schema_object_filter_id => p_schema_object_filter_id
  , p_schema_object_filter => p_schema_object_filter
  );
end add;

procedure add
( p_schema_ddl in oracle_tools.t_schema_ddl
)
is
begin
  PRAGMA INLINE (add_schema_ddl, 'YES');
  add_schema_ddl
  ( p_session_id => get_session_id
  , p_schema_ddl => p_schema_ddl
  );
end add;

procedure add
( p_schema_ddl_tab in oracle_tools.t_schema_ddl_tab
)
is
$if oracle_tools.ddl_crud_api.c_tracing $then
  l_module_name constant dbug.module_name_t := $$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'ADD (T_SCHEMA_DDL_TAB)';
$end
begin
$if oracle_tools.ddl_crud_api.c_tracing $then
  dbug.enter(l_module_name);
$end

  if p_schema_ddl_tab.count > 0
  then
    -- ORA-12899: value too large for column "ORACLE_TOOLS"."GENERATE_DDL_SESSION_SCHEMA_OBJECTS"."DDL"
    for i_idx in p_schema_ddl_tab.first .. p_schema_ddl_tab.last
    loop
      add
      ( p_schema_ddl => p_schema_ddl_tab(i_idx)
      );
    end loop;
  end if;

$if oracle_tools.ddl_crud_api.c_tracing $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end add;

procedure add
( p_schema in varchar2
, p_transform_param_list in varchar2
, p_object_schema in varchar2
, p_object_type in varchar2
, p_base_object_schema in varchar2
, p_base_object_type in varchar2
, p_object_name_tab in oracle_tools.t_text_tab
, p_base_object_name_tab in oracle_tools.t_text_tab
, p_nr_objects in integer
)
is
begin
  PRAGMA INLINE (add_batch, 'YES');
  add_batch
  ( p_session_id => get_session_id
  , p_schema => p_schema
  , p_transform_param_list => p_transform_param_list
  , p_object_schema => p_object_schema
  , p_object_type => p_object_type
  , p_base_object_schema => p_base_object_schema
  , p_base_object_type => p_base_object_type
  , p_object_name_tab => p_object_name_tab
  , p_base_object_name_tab => p_base_object_name_tab
  , p_nr_objects => p_nr_objects
  );
end add;

procedure add
( p_object_type in varchar2
)
is
begin
  PRAGMA INLINE (add_batch, 'YES');
  add_batch
  ( p_session_id => get_session_id
  , p_object_type => p_object_type
  );
end add;

procedure add
( p_schema_object_tab in oracle_tools.t_schema_object_tab
, p_schema_object_filter_id in t_schema_object_filter_id_nn
, p_schema_object_filter in oracle_tools.t_schema_object_filter
)
is
begin
  PRAGMA INLINE (add_schema_object_tab, 'YES');
  add_schema_object_tab
  ( p_session_id => get_session_id
  , p_schema_object_tab => p_schema_object_tab
  , p_schema_object_filter_id => p_schema_object_filter_id
  , p_schema_object_filter => p_schema_object_filter
  );
end add;

procedure clear_batch
is
  l_session_id constant t_session_id_nn := get_session_id;
begin
  delete
  from    oracle_tools.generate_ddl_session_batches gdsb
  where   gdsb.session_id = l_session_id;

$if oracle_tools.ddl_crud_api.c_debugging $then
  dbug.print(dbug."info", '# rows deleted from generate_ddl_session_batches: %s', sql%rowcount);
$end
end clear_batch;

procedure set_batch_start_time
( p_seq in integer
)
is
  l_session_id constant t_session_id_nn := get_session_id;
begin
  update  oracle_tools.generate_ddl_session_batches gdsb
  set     gdsb.start_time = sys_extract_utc(systimestamp)
  where   gdsb.session_id = l_session_id
  and     gdsb.seq = p_seq;

  case sql%rowcount
    when 0
    then raise no_data_found;
    when 1
    then null; -- ok
    else raise too_many_rows;
  end case;
end set_batch_start_time;

procedure set_batch_end_time
( p_seq in integer
, p_error_message in varchar2
)
is
  l_session_id constant t_session_id_nn := get_session_id;
begin
  update  oracle_tools.generate_ddl_session_batches gdsb
  set     gdsb.end_time = sys_extract_utc(systimestamp)
  ,       gdsb.error_message = p_error_message
  where   gdsb.session_id = l_session_id
  and     gdsb.seq = p_seq;

  case sql%rowcount
    when 0
    then raise no_data_found;
    when 1
    then null; -- ok
    else raise too_many_rows;
  end case;
end set_batch_end_time;

procedure clear_all_ddl_tables
is
begin
  delete
  from    oracle_tools.generate_ddl_configurations;

$if oracle_tools.ddl_crud_api.c_debugging $then
  dbug.print(dbug."info", '# rows deleted from generate_ddl_configurations: %s', sql%rowcount);
$end

  delete
  from    oracle_tools.schema_objects;

$if oracle_tools.ddl_crud_api.c_debugging $then
  dbug.print(dbug."info", '# rows deleted from schema_objects: %s', sql%rowcount);
$end

  delete
  from    oracle_tools.schema_object_filters;

$if oracle_tools.ddl_crud_api.c_debugging $then
  dbug.print(dbug."info", '# rows deleted from schema_object_filters: %s', sql%rowcount);
$end
end clear_all_ddl_tables;

procedure fetch_schema_objects
( p_session_id in t_session_id_nn
, p_cursor in out nocopy integer
, p_schema_object_tab out nocopy oracle_tools.t_schema_object_tab
)
is
$if oracle_tools.ddl_crud_api.c_tracing $then
  l_module_name constant dbug.module_name_t := $$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'FETCH_SCHEMA_OBJECTS';
$end

  l_cursor sys_refcursor;
  l_session_id t_session_id := null;

  procedure cleanup(p_close in boolean)
  is
  begin
    if l_session_id is not null
    then
      set_session_id(l_session_id);
    end if;
    if p_close and l_cursor%isopen
    then
      close l_cursor;
      p_cursor := null;
    end if;
  end cleanup;
begin
$if oracle_tools.ddl_crud_api.c_tracing $then
  dbug.enter(l_module_name);
$if oracle_tools.ddl_crud_api.c_debugging $then
  dbug.print(dbug."input", 'p_session_id: %s', p_session_id);
  dbug.print(dbug."input", 'p_cursor: %s', p_cursor);  
$end
$end

  if not dbms_sql.is_open(p_cursor)
  then
    l_session_id := get_session_id;
    set_session_id(p_session_id); -- just a check

    open l_cursor for
      select  so.obj
      from    oracle_tools.generate_ddl_sessions gds
              inner join oracle_tools.generate_ddl_session_schema_objects gdsso
              on gdsso.session_id = gds.session_id
              inner join oracle_tools.schema_object_filter_results sofr
              on sofr.schema_object_filter_id = gdsso.schema_object_filter_id and
                 sofr.schema_object_id = gdsso.schema_object_id
              inner join oracle_tools.schema_objects so
              on so.id = sofr.schema_object_id
      where   gds.session_id = p_session_id
      order by
              so.id;
  else
    l_cursor := dbms_sql.to_refcursor(p_cursor);
  end if;
  
  fetch l_cursor bulk collect into p_schema_object_tab limit c_fetch_limit;
  
  if p_schema_object_tab.count < c_fetch_limit
  then
    cleanup(true);
  else              
    p_cursor := dbms_sql.to_cursor_number(l_cursor);
    cleanup(false);
  end if;

$if oracle_tools.ddl_crud_api.c_tracing $then
$if oracle_tools.ddl_crud_api.c_debugging $then
  dbug.print(dbug."output", 'p_cursor: %s', p_cursor);  
  dbug.print(dbug."output", 'cardinality(p_schema_object_tab): %s', cardinality(p_schema_object_tab));  
$end
  dbug.leave;
$end
exception
  when others
  then
    cleanup(true);
$if oracle_tools.ddl_crud_api.c_tracing $then
    dbug.leave_on_error;
$end
    raise;
end fetch_schema_objects;

function get_display_ddl_sql_cursor
( p_session_id in t_session_id_nn -- The session id from V_MY_GENERATE_DDL_SESSIONS, i.e. must belong to your USERNAME.
, p_sort_objects_by_deps in t_numeric_boolean_nn default 0 -- Sort objects in dependency order to reduce the number of installation errors/warnings.
)
return t_display_ddl_sql_cur
is
$if oracle_tools.ddl_crud_api.c_tracing $then
  l_module_name constant dbug.module_name_t := $$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'GET_DISPLAY_DDL_SQL_CURSOR';
$end

  l_cursor t_display_ddl_sql_cur;
begin
$if oracle_tools.ddl_crud_api.c_tracing $then
  dbug.enter(l_module_name);
$if oracle_tools.ddl_crud_api.c_debugging $then
  dbug.print(dbug."input", 'p_session_id: %s', p_session_id);
  dbug.print(dbug."input", 'p_sort_objects_by_deps: %s', p_sort_objects_by_deps);
$end
$end

  -- must be like oracle_tools.v_my_schema_ddls
  if nvl(p_sort_objects_by_deps, 0) <> 0 
  then
    open l_cursor for
      with src as
      ( select  /*+ MATERIALIZE */
                src.schema_object_id
        ,       src.ddl#
        ,       src.verb
        ,       src.ddl_info
        ,       src.chunk#
        ,       src.chunk
        ,       src.last_chunk
        ,       src.obj as schema_object
        ,       case when src.obj is not null then src.obj.object_type_order() end as object_type_order
        ,       case when src.obj is not null then src.obj.object_schema() end as object_schema
        ,       case when src.obj is not null then src.obj.dict_object_type() end as dict_object_type
        ,       case when src.obj is not null then src.obj.object_name() end as object_name
        from    oracle_tools.v_my_schema_ddls src
      ), deps as
      ( select  /*+ MATERIALIZE */
                d.owner
        ,       d.type
        ,       d.name
        ,       count(*) as nr_deps
        from    all_dependencies d
                inner join src so
                on so.schema_object is not null and
                   so.object_schema = d.referenced_owner and
                   so.dict_object_type = d.referenced_type and
                   so.object_name = d.referenced_name
        where   -- don't count dependencies between specifications and their bodies
                d.owner <> d.referenced_owner
        or      d.name <> d.referenced_name
        group by
                d.owner
        ,       d.type
        ,       d.name
      )
      select  src.schema_object_id
      ,       src.ddl#
      ,       src.verb
      ,       src.ddl_info
      ,       src.chunk#
      ,       src.chunk
      ,       src.last_chunk
      ,       src.schema_object
      from    src
              left outer join deps d
              on d.owner = src.object_schema and d.type = src.dict_object_type and d.name = src.object_name
      order by
              src.object_type_order
      ,       d.nr_deps desc nulls last
      ,       src.schema_object_id
      ,       src.ddl#
      ,       src.chunk#;
  else
    open l_cursor for
      select  src.schema_object_id
      ,       src.ddl#
      ,       src.verb
      ,       src.ddl_info
      ,       src.chunk#
      ,       src.chunk
      ,       src.last_chunk
      ,       src.obj as schema_object
      from    oracle_tools.v_my_schema_ddls src
      order by
              src.schema_object_id
      ,       src.ddl#
      ,       src.chunk#;
  end if;
  
$if oracle_tools.ddl_crud_api.c_tracing $then
  dbug.leave;
$end

  return l_cursor;
exception
  when others
  then
$if oracle_tools.ddl_crud_api.c_tracing $then
    dbug.leave_on_error;
$end
    raise;
end get_display_ddl_sql_cursor;

procedure fetch_display_ddl_sql
( p_session_id in t_session_id_nn -- The session id from V_MY_GENERATE_DDL_SESSIONS, i.e. must belong to your USERNAME.
, p_sort_objects_by_deps in t_numeric_boolean_nn -- Sort objects in dependency order to reduce the number of installation errors/warnings.
, p_cursor in out nocopy integer
, p_display_ddl_sql_tab out t_display_ddl_sql_tab
)
is
$if oracle_tools.ddl_crud_api.c_tracing $then
  l_module_name constant dbug.module_name_t := $$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'FETCH_DISPLAY_DDL_SQL';
$end

  l_cursor t_display_ddl_sql_cur;
  l_session_id t_session_id := null;

  procedure cleanup(p_close in boolean)
  is
  begin
    if l_session_id is not null
    then
      set_session_id(l_session_id);
    end if;
    if p_close and l_cursor%isopen
    then
      close l_cursor;
      p_cursor := null;
    end if;
  end cleanup;
begin
$if oracle_tools.ddl_crud_api.c_tracing $then
  dbug.enter(l_module_name);
$if oracle_tools.ddl_crud_api.c_debugging $then
  dbug.print(dbug."input", 'p_session_id: %s', p_session_id);
  dbug.print(dbug."input", 'p_sort_objects_by_deps: %s', p_sort_objects_by_deps);
  dbug.print(dbug."input", 'p_cursor: %s', p_cursor);
$end
$end

  if not dbms_sql.is_open(p_cursor)
  then
    l_session_id := get_session_id;
    set_session_id(p_session_id); -- just a check

    l_cursor := get_display_ddl_sql_cursor
                ( p_session_id => p_session_id
                , p_sort_objects_by_deps => p_sort_objects_by_deps
                );
  else
    l_cursor := dbms_sql.to_refcursor(p_cursor);
  end if;
  
  fetch l_cursor bulk collect into p_display_ddl_sql_tab limit c_fetch_limit;
  
  if p_display_ddl_sql_tab.count < c_fetch_limit
  then
    cleanup(true);
  else
    p_cursor := dbms_sql.to_cursor_number(l_cursor);
    cleanup(false);
  end if;

$if oracle_tools.ddl_crud_api.c_tracing $then
$if oracle_tools.ddl_crud_api.c_debugging $then
  dbug.print(dbug."output", 'p_cursor: %s', p_cursor);  
  dbug.print(dbug."output", 'cardinality(p_display_ddl_sql_tab): %s', cardinality(p_display_ddl_sql_tab));  
$end
  dbug.leave;
$end
exception
  when others
  then
    cleanup(true);
$if oracle_tools.ddl_crud_api.c_tracing $then
    dbug.leave_on_error;
$end
    raise;
end fetch_display_ddl_sql;    

procedure set_ddl_output_written
( p_schema_object_id in varchar2
, p_ddl_output_written in integer
)
is
  l_session_id constant t_session_id := get_session_id;
begin
  update  oracle_tools.generate_ddl_session_schema_objects gdsso
  set     gdsso.ddl_output_written = p_ddl_output_written
  where   gdsso.session_id = l_session_id
  and     ( p_schema_object_id is null or gdsso.schema_object_id = p_schema_object_id );

  if sql%rowcount = 0 and p_schema_object_id is not null
  then
    oracle_tools.pkg_ddl_error.raise_error
    ( oracle_tools.pkg_ddl_error.c_reraise_with_backtrace
    , utl_lms.format_message
      ( 'Could not set ORACLE_TOOLS.GENERATE_DDL_SESSION_SCHEMA_OBJECTS.DDL_OUTPUT_WRITTEN to %s'
      , nvl(to_char(p_ddl_output_written), 'NULL')
      )
    , utl_lms.format_message('%s, "%s"', to_char(l_session_id), nvl(p_schema_object_id, '%'))
    , 'session id, schema object id'
    );
  end if;
end set_ddl_output_written;

procedure fetch_ddl_generate_report
( p_session_id in t_session_id_nn -- The session id from V_MY_GENERATE_DDL_SESSIONS, i.e. must belong to your USERNAME.
, p_cursor in out nocopy integer
, p_ddl_generate_report_tab out nocopy t_ddl_generate_report_tab
)
is
$if oracle_tools.ddl_crud_api.c_tracing $then
  l_module_name constant dbug.module_name_t := $$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'FETCH_DDL_GENERATE_REPORT';
$end

  l_cursor sys_refcursor;
  l_session_id t_session_id := null;

  procedure cleanup(p_close in boolean)
  is
  begin
    if l_session_id is not null
    then
      set_session_id(l_session_id);
    end if;
    if p_close and l_cursor%isopen
    then
      close l_cursor;
      p_cursor := null;
    end if;
  end cleanup;
begin
$if oracle_tools.ddl_crud_api.c_tracing $then
  dbug.enter(l_module_name);
$if oracle_tools.ddl_crud_api.c_debugging $then
  dbug.print(dbug."input", 'p_session_id: %s', p_session_id);
  dbug.print(dbug."input", 'p_cursor: %s', p_cursor);  
$end
$end

  if not dbms_sql.is_open(p_cursor)
  then
    l_session_id := get_session_id;
    set_session_id(p_session_id); -- just a check

    open l_cursor for
      select  gdc.transform_param_list
      ,       gdc.db_version
      ,       gdc.last_ddl_time_schema
      ,       so.obj as schema_object
      ,       sofr.generate_ddl
      ,       sofr.generate_ddl_info
      ,       case
                when gdsso.last_ddl_time is not null and gdsso.generate_ddl_configuration_id is not null
                then 1
                else 0
              end as ddl_generated
      ,       nvl(gdsso.ddl_output_written, 0) as ddl_output_written
      from    oracle_tools.generate_ddl_sessions gds
              inner join oracle_tools.generate_ddl_configurations gdc
              on gdc.id = gds.generate_ddl_configuration_id
              inner join oracle_tools.schema_object_filters sof
              on sof.id = gds.schema_object_filter_id
              inner join oracle_tools.schema_object_filter_results sofr
              on sofr.schema_object_filter_id = sof.id
              inner join oracle_tools.schema_objects so
              on so.id = sofr.schema_object_id
              left outer join oracle_tools.generate_ddl_session_schema_objects gdsso
              on gdsso.session_id = gds.session_id and
                 gdsso.schema_object_id = sofr.schema_object_id
      where   gds.session_id = p_session_id
      order by
              so.obj.id;
  else
    l_cursor := dbms_sql.to_refcursor(p_cursor);  
  end if;  

  fetch l_cursor bulk collect into p_ddl_generate_report_tab limit c_fetch_limit;
  
  if p_ddl_generate_report_tab.count < c_fetch_limit
  then
    cleanup(true);
  else
    p_cursor := dbms_sql.to_cursor_number(l_cursor);
    cleanup(false);
  end if;

$if oracle_tools.ddl_crud_api.c_tracing $then
$if oracle_tools.ddl_crud_api.c_debugging $then
  dbug.print(dbug."output", 'p_cursor: %s', p_cursor);  
  dbug.print(dbug."output", 'cardinality(p_ddl_generate_report_tab): %s', cardinality(p_ddl_generate_report_tab));  
$end
  dbug.leave;
$end
exception
  when others
  then
    cleanup(true);
$if oracle_tools.ddl_crud_api.c_tracing $then
    dbug.leave_on_error;
$end
    raise;
end fetch_ddl_generate_report;

procedure delete_generate_ddl_sessions
( p_session_id in t_session_id 
)
is
begin
  if p_session_id is null
  then
    delete
    from    oracle_tools.generate_ddl_sessions gds
    where   gds.created <= g_min_timestamp_to_keep;
  else
    delete
    from    oracle_tools.generate_ddl_sessions gds
    where   gds.session_id = p_session_id;
  end if;

$if oracle_tools.ddl_crud_api.c_debugging $then
  dbug.print(dbug."info", '# rows deleted from generate_ddl_sessions: %s', sql%rowcount);
$end

end delete_generate_ddl_sessions;  

procedure disable_parallel_status
is
  l_parallel_status_tab t_parallel_status_tab;

$if oracle_tools.ddl_crud_api.c_tracing $then
  l_module_name constant dbug.module_name_t := $$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'DISABLE_PARALLEL_STATUS';
$end
begin
$if oracle_tools.ddl_crud_api.c_tracing $then
  dbug.enter(l_module_name);
$end

  commit;
  get_parallel_status(g_parallel_status_tab);
  for i_idx in 1..3
  loop
    l_parallel_status_tab(i_idx) := 'DISABLED';
  end loop;
  set_parallel_status(l_parallel_status_tab);

$if oracle_tools.ddl_crud_api.c_tracing $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end disable_parallel_status;

procedure reset_parallel_status
is
$if oracle_tools.ddl_crud_api.c_tracing $then
  l_module_name constant dbug.module_name_t := $$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'RESET_PARALLEL_STATUS';
$end
begin
$if oracle_tools.ddl_crud_api.c_tracing $then
  dbug.enter(l_module_name);
$end

  commit;
  set_parallel_status(g_parallel_status_tab);

$if oracle_tools.ddl_crud_api.c_tracing $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end reset_parallel_status;

procedure purge_schema_objects
( p_schema in varchar2 -- The schema to inspect.
, p_reference_time in timestamp -- The reference timestamp.
)
is
begin
  delete
  from    oracle_tools.schema_objects so
  where   p_schema in (so.obj.object_schema(), so.obj.base_object_schema()) -- should use SCHEMA_OBJECTS$IDX$1 or SCHEMA_OBJECTS$IDX$2
  and     so.updated < p_reference_time
  and     so.obj.dict_last_ddl_time() is null;

$if oracle_tools.schema_objects_api.c_debugging $then
  dbug.print(dbug."info", '# rows deleted from SCHEMA_OBJECTS: %s', sql%rowcount);  
$end
end purge_schema_objects;

END DDL_CRUD_API;
/

